import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nona_chat/core/network/app_http_client.dart';
import 'package:nona_chat/core/services/mcp/local_tools.dart';
import 'package:nona_chat/core/services/network_log_service.dart'
    show NetworkLogType;

/// 脚本化客户端：按 URI 返回预置 HTML。
class _FetchClient extends AppHttpClient {
  _FetchClient(this.body, {this.status = 200});

  final String body;
  final int status;

  @override
  Future<http.Response> send({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    List<int>? bodyBytes,
    NetworkLogType type = NetworkLogType.other,
    Duration? timeout,
    bool retry = true,
  }) async {
    return http.Response(
      this.body,
      status,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  @override
  Future<http.StreamedResponse> sendStreamed({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    Duration? connectTimeout,
    bool Function()? isCancelled,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppHttpClient original;
  setUp(() => original = AppHttpClient.instance);
  tearDown(() => AppHttpClient.overrideForTesting(original));

  group('LocalTools 注册表', () {
    test('all() 含 5 个内置工具且名称带 builtin__ 前缀', () {
      final tools = LocalTools.all();
      expect(tools, hasLength(5));
      expect(
        tools.map((t) => t.definition.name),
        containsAll(['builtin__fetch', 'builtin__time_info', 'builtin__calculator',
            'builtin__memory_tool', 'builtin__clipboard']),
      );
    });

    test('find 精确匹配 / 未知返回 null', () {
      expect(LocalTools.find('builtin__time_info'), isNotNull);
      expect(LocalTools.find('builtin__nope'), isNull);
    });

    test('schemas() 展平为 function 格式并携带 parameters', () {
      final schemas = LocalTools.schemas();
      expect(schemas, hasLength(5));
      final fetch = schemas.firstWhere(
        (s) => (s['function'] as Map<String, dynamic>)['name'] == 'builtin__fetch',
      );
      final fn = fetch['function'] as Map<String, dynamic>;
      expect(fn['parameters'], isNotNull);
      expect(fn['description'], isNotEmpty);
    });
  });

  group('builtin__calculator', () {
    test('合法表达式求值', () async {
      final result = await LocalTools.find('builtin__calculator')!.handler({
        'expression': '2 + 3 * 4',
      });
      expect(result.isError, isFalse);
      expect(result.content, contains('14'));
    });

    test('空表达式 → 错误', () async {
      final result = await LocalTools.find('builtin__calculator')!.handler({});
      expect(result.isError, isTrue);
      expect(result.content, contains('required'));
    });

    test('非法表达式 → 错误', () async {
      final result = await LocalTools.find('builtin__calculator')!.handler({
        'expression': '2 +*',
      });
      expect(result.isError, isTrue);
      expect(result.content, contains('cannot evaluate'));
    });
  });

  group('builtin__time', () {
    test('返回日期/时间/周几/时区', () async {
      final result = await LocalTools.find('builtin__time_info')!.handler({});
      expect(result.isError, isFalse);
      expect(result.content, contains('date:'));
      expect(result.content, contains('time:'));
      expect(result.content, contains('weekday:'));
      expect(result.content, contains('timezone:'));
      expect(result.content, contains('unix_ts:'));
    });
  });

  group('builtin__fetch', () {
    final handler = LocalTools.find('builtin__fetch')!.handler;

    test('缺 url → 错误', () async {
      final r = await handler({});
      expect(r.isError, isTrue);
      expect(r.content, contains('url is required'));
    });

    test('非 http(s) URL → 错误', () async {
      final r = await handler({'url': 'file:///etc/passwd'});
      expect(r.isError, isTrue);
      expect(r.content, contains('only http(s)'));
    });

    test('回环地址被拦截（SSRF 防护）', () async {
      for (final url in [
        'http://localhost/x',
        'http://127.0.0.1/x',
        'http://[::1]/x',
        'http://10.0.0.1/x',
      ]) {
        final r = await handler({'url': url});
        expect(r.isError, isTrue, reason: url);
        expect(r.content, contains('blocked'));
      }
    });

    test('非 200 → 错误', () async {
      AppHttpClient.overrideForTesting(_FetchClient('', status: 503));
      final r = await handler({'url': 'https://example.com/x'});
      expect(r.isError, isTrue);
      expect(r.content, contains('HTTP 503'));
    });

    test('HTML 转纯文本 + 截断', () async {
      AppHttpClient.overrideForTesting(
        _FetchClient('<html><body><h1>标题</h1><p>正文内容</p></body></html>'),
      );
      final r = await handler({'url': 'https://example.com/x'});
      expect(r.isError, isFalse);
      expect(r.content, contains('标题'));
      expect(r.content, contains('正文内容'));

      // 截断：limit=5
      AppHttpClient.overrideForTesting(
        _FetchClient('<p>${'x' * 100}</p>'),
      );
      final short = await handler({'url': 'https://example.com/y', 'maxLength': 5});
      expect(short.content, contains('(truncated)'));
    });

    test('超过 1MB → 错误', () async {
      AppHttpClient.overrideForTesting(
        _FetchClient('<p>${'x' * 1024 * 1024}</p>'),
      );
      final r = await handler({'url': 'https://example.com/big'});
      expect(r.isError, isTrue);
      expect(r.content, contains('1MB limit'));
    });

    test('空页面 → (empty page)', () async {
      AppHttpClient.overrideForTesting(_FetchClient('<html></html>'));
      final r = await handler({'url': 'https://example.com/empty'});
      expect(r.content, '(empty page)');
    });
  });

  group('builtin__clipboard', () {
    test('write 后 read 往返', () async {
      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboard ?? ''};
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      final handler = LocalTools.find('builtin__clipboard')!.handler;
      final w = await handler({'action': 'write', 'text': 'hello'});
      expect(w.isError, isFalse);
      final r = await handler({'action': 'read'});
      expect(r.content, contains('hello'));
    });

    test('缺 text → 错误；未知 action → 错误', () async {
      final handler = LocalTools.find('builtin__clipboard')!.handler;
      final w = await handler({'action': 'write'});
      expect(w.isError, isTrue);
      final u = await handler({'action': 'nope'});
      expect(u.isError, isTrue);
    });
  });

  group('builtin__memory', () {
    test('create/edit/delete 与错误分支', () async {
      final handler = LocalTools.find('builtin__memory_tool')!.handler;
      // create
      final created = await handler({'action': 'create', 'content': '事实一'});
      expect(created.isError, isFalse);
      expect(created.content, contains('memory created'));
      final id = created.content.split('id=')[1].split(' ')[0];
      // edit
      final edited = await handler({
        'action': 'edit',
        'id': id,
        'content': '事实一改',
      });
      expect(edited.content, contains('memory updated'));
      // delete
      final deleted = await handler({'action': 'delete', 'id': id});
      expect(deleted.content, contains('memory deleted'));
      // 错误分支
      expect(
        (await handler({'action': 'create'})).isError,
        isTrue,
      );
      expect(
        (await handler({'action': 'edit', 'id': id})).isError,
        isTrue,
      );
      expect(
        (await handler({'action': 'delete'})).isError,
        isTrue,
      );
      expect(
        (await handler({'action': 'unknown'})).isError,
        isTrue,
      );
    });
  });
}

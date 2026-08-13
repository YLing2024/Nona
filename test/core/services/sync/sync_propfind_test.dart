import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/sync/sync_clients.dart';

/// 起一个本地 HTTP 服务器返回 [body]，跑 [fn] 后关闭。
Future<T> withServer<T>(
  String body,
  int statusCode,
  Future<T> Function(WebDavClient client) fn,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final done = Completer<void>();
  server.listen((req) async {
    try {
      req.response.statusCode = statusCode;
      req.response.headers.set('Content-Type', 'application/xml');
      req.response.write(body);
      await req.response.close();
    } finally {
      done.complete();
    }
  });
  try {
    final client = WebDavClient(baseUrl: 'http://127.0.0.1:${server.port}/');
    return await fn(client);
  } finally {
    await server.close(force: true);
    await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test 默认拦截所有 HTTP 返回 400；解除以使用本地 HttpServer
  setUp(() => HttpOverrides.global = null);
  tearDown(() => HttpOverrides.global = null);

  group('WebDavClient PROPFIND 解析（多命名空间前缀）', () {
    final multiNsBody = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:ns0="http://example.com/ns">
  <d:response>
    <d:href>/backups/</d:href>
    <d:propstat><d:prop><d:displayname>backups</d:displayname></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/backups/a.json</d:href>
    <d:propstat><d:prop>
      <ns0:getcontentlength>1024</ns0:getcontentlength>
      <ns0:getlastmodified>Mon, 12 Aug 2024 10:00:00 GMT</ns0:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/backups/space%20name.json</d:href>
    <d:propstat><d:prop>
      <d:getcontentlength>2048</d:getcontentlength>
      <d:getlastmodified>Tue, 13 Aug 2024 12:30:00 GMT</d:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/backups/subdir/</d:href>
    <d:propstat><d:prop><d:displayname>subdir</d:displayname></d:prop></d:propstat>
  </d:response>
</d:multistatus>''';

    test('容忍 d:/ns0:/无前缀混合命名空间并跳过目录', () async {
      final files = await withServer(multiNsBody, 207, (c) => c.list('backups'));
      expect(files, hasLength(2), reason: '目录项（/backups/ 与子目录）应被跳过');
      // list() 按 modified 降序（最新在前）
      expect(files[0].name, 'space name.json', reason: 'URL 编码 href 应解码');
      expect(files[0].size, 2048);
      expect(files[0].modified, DateTime.utc(2024, 8, 13, 12, 30));
      expect(files[1].name, 'a.json');
      expect(files[1].size, 1024);
      expect(files[1].modified, DateTime.utc(2024, 8, 12, 10));
    });

    test('无 getlastmodified 时 modified 为 null', () async {
      final body = '''<?xml version="1.0"?>
<multistatus xmlns="DAV:">
  <response>
    <href>/backups/x.json</href>
    <propstat><prop>
      <getcontentlength>512</getcontentlength>
    </prop></propstat>
  </response>
</multistatus>''';
      final files = await withServer(body, 207, (c) => c.list('backups'));
      expect(files, hasLength(1));
      expect(files.first.name, 'x.json');
      expect(files.first.modified, isNull);
    });

    test('4xx 响应返回空列表（不抛错）', () async {
      final files = await withServer('<error/>', 404, (c) => c.list('backups'));
      expect(files, isEmpty);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/services/chat_protocol.dart' show ProviderKind;
import 'package:nona_chat/core/services/provider_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';

import '../../support/reset_globals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
    resetGlobalState();
  });

  /// 启动本地 HTTP 服务器。
  Future<HttpServer> startServer(
    Future<void> Function(HttpRequest req) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      try {
        await handler(req);
      } catch (_) {
      } finally {
        try {
          await req.response.close();
        } catch (_) {}
      }
    });
    addTearDown(() async {
      await server.close(force: true);
    });
    return server;
  }

  group('ProviderService 联网方法', () {
    test('fetchModels 解析能力字段并回退映射表', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 200;
        req.response.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        req.response.write(jsonEncode({
          'data': [
            {'id': 'vision-model', 'supported_features': ['vision']},
            {'id': 'gpt-4o-mini'},
            {'id': 'unknown-model'},
          ],
        }));
      });

      final service = ProviderService();
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
      );
      final models = await service.fetchModels(provider);
      final byId = {for (final m in models) m.$1: m.$2};

      expect(byId['vision-model']?.multimodal, isTrue,
          reason: '接口声明的 vision 能力应生效');
      expect(byId['gpt-4o-mini']?.multimodal, isTrue,
          reason: '内置映射表中 gpt-4o-mini 为多模态，应回退命中');
      expect(byId['unknown-model']?.multimodal, isFalse);
      expect(byId['unknown-model']?.reasoning, isFalse);
    });

    test('fetchModels 非 200 抛出异常并含错误信息', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 404;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"error":{"message":"模型接口不存在"}}');
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
      );
      await expectLater(
        ProviderService().fetchModels(provider),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('模型接口不存在'),
        )),
      );
    });

    test('testModel 200 返回成功与耗时', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"id":"m"}');
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
      );
      final result = await ProviderService().testModel(provider, 'gpt-4o-mini');
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.displayLabel, '${result.elapsedMs}ms');
    });

    test('testModel 非 200 返回失败与错误信息', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 401;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"error":{"message":"密钥无效"}}');
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
      );
      final result = await ProviderService().testModel(provider, 'gpt-4o-mini');
      expect(result.success, isFalse);
      expect(result.error, contains('密钥无效'));
    });

    test('clearStaleDefaultModels 清除悬空的默认模型', () async {
      await SettingsService().save(const AppSettings(
        chatModel: 'ghost-model',
        defaultAgentModel: 'ghost-model',
        titleModel: 'ghost-model',
      ));
      await ProviderService().save([
        ChatProvider(id: 'p1', name: 'T', modelIds: ['gpt-4o']),
      ]);
      await ProviderService().clearStaleDefaultModels();
      final settings = await SettingsService().load();
      expect(settings.chatModel, '');
      expect(settings.defaultAgentModel, '');
      expect(settings.titleModel, '');
    });
  });

  group('F1-3 按协议分派', () {
    test('anthropic fetchModels 走 x-api-key + /models', () async {
      late Map<String, String> headers;
      final server = await startServer((req) async {
        headers = <String, String>{};
        req.headers.forEach((n, v) => headers[n] = v.join(','));
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({
          'data': [
            {'id': 'claude-3-7-sonnet', 'type': 'model'},
            {'id': 'claude-3-5-haiku', 'type': 'model'},
          ],
        }));
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        kind: ProviderKind.anthropic,
      );
      final models = await ProviderService().fetchModels(provider);
      expect(models.map((m) => m.$1), contains('claude-3-7-sonnet'));
      expect(headers['x-api-key'], 'sk-test');
      expect(headers['anthropic-version'], isNotNull);
    });

    test('anthropic testModel 走 /messages 且带 max_tokens', () async {
      late Map<String, dynamic> body;
      final server = await startServer((req) async {
        final raw = await utf8.decoder.bind(req).join();
        body = jsonDecode(raw) as Map<String, dynamic>;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"id":"m"}');
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        kind: ProviderKind.anthropic,
      );
      final result =
          await ProviderService().testModel(provider, 'claude-3-5-haiku');
      expect(result.success, isTrue);
      expect(body['model'], 'claude-3-5-haiku');
      expect(body['max_tokens'], 16);
      expect(body['messages'].first['role'], 'user');
    });

    test('gemini fetchModels 解析 models 数组并过滤名字前缀', () async {
      late Uri requestUri;
      final server = await startServer((req) async {
        requestUri = req.uri;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({
          'models': [
            {
              'name': 'models/gemini-2.0-flash',
              'supportedGenerationMethods': ['generateContent'],
            },
            {
              'name': 'models/gemma-3-27b',
              'supportedGenerationMethods': ['embedContent'],
            },
          ],
        }));
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}/v1beta',
        apiKey: 'sk-test',
        kind: ProviderKind.gemini,
      );
      final models = await ProviderService().fetchModels(provider);
      expect(requestUri.queryParameters['key'], 'sk-test');
      expect(
        models.map((m) => m.$1),
        contains('gemini-2.0-flash'),
      );
    });

    test('gemini testModel 走 streamGenerateContent 限制输出', () async {
      late Map<String, dynamic> body;
      late Uri requestUri;
      final server = await startServer((req) async {
        requestUri = req.uri;
        final raw = await utf8.decoder.bind(req).join();
        body = jsonDecode(raw) as Map<String, dynamic>;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{}');
      });
      final provider = ChatProvider(
        id: 'p1',
        name: 'T',
        baseUrl: 'http://127.0.0.1:${server.port}/v1beta',
        apiKey: 'sk-test',
        kind: ProviderKind.gemini,
      );
      final result =
          await ProviderService().testModel(provider, 'gemini-2.0-flash');
      expect(result.success, isTrue);
      expect(requestUri.path, contains('streamGenerateContent'));
      expect(body['generationConfig']['maxOutputTokens'], 1);
    });
  });

  group('TestResultStorage', () {
    test('save/load 往返，null 结果被跳过', () async {
      await TestResultStorage.save('p1', {
        'model-a': const ModelTestResult(success: true, elapsedMs: 10),
        'model-b': null,
      });
      final results = await TestResultStorage.load('p1');
      expect(results, hasLength(1));
      expect(results['model-a']?.success, isTrue);
      expect(results['model-a']?.elapsedMs, 10);
      expect(results['model-b'], isNull);
    });

    test('无数据返回空 Map', () async {
      expect(await TestResultStorage.load('no-such-provider'), isEmpty);
    });
  });
}

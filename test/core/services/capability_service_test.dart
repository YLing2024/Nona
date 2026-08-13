import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/services/model_capability_service.dart';

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

  group('ModelCapabilityService', () {
    test('load 读取内置静态表并支持精确/别名/前缀查找', () async {
      final service = ModelCapabilityService();
      final map = await service.load();
      expect(map['gpt-4o']?.multimodal, isTrue);
      expect(map['o1']?.reasoning, isTrue);

      expect(service.lookup('gpt-4o')?.multimodal, isTrue);
      expect(service.lookup('gpt-4o-2024-05-13')?.multimodal, isTrue,
          reason: '别名应命中');
      expect(service.lookup('openai/gpt-4o')?.multimodal, isTrue,
          reason: '去 provider 前缀后应命中');
      expect(service.lookup('未知模型'), isNull);
    });

    test('info 返回版本与来源（内置表）', () async {
      final info = await ModelCapabilityService().info();
      expect(info.fromNetwork, isFalse);
      expect(info.version, isNotNull);
    });

    test('updateFromNetwork 解析 LiteLLM 目录并缓存', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 200;
        req.response.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        req.response.write(jsonEncode({
          'gpt-4o': {
            'mode': 'chat',
            'supports_vision': true,
            'supports_reasoning': false,
          },
          'openai/o1': {
            'mode': 'chat',
            'supports_vision': false,
            'supports_reasoning': true,
          },
          'embedding-model': {'mode': 'embedding', 'supports_vision': false},
        }));
      });

      final service = ModelCapabilityService();
      final version = await service.updateFromNetwork(
        url: 'http://127.0.0.1:${server.port}/capabilities',
      );
      expect(version, isNotEmpty);

      expect(service.lookup('gpt-4o')?.multimodal, isTrue);
      expect(service.lookup('o1')?.reasoning, isTrue,
          reason: 'openai/o1 的去前缀键应命中');
      expect(service.lookup('embedding-model'), isNull,
          reason: '非对话模型被过滤');

      final info = await service.info();
      expect(info.fromNetwork, isTrue);

      // 新实例从本地缓存读取（持久化验证）
      final cached = ModelCapabilityService();
      await cached.load();
      expect(cached.lookup('gpt-4o')?.multimodal, isTrue);
    });
  });
}

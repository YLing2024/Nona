import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/services/usage/balance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F2-4 余额查询单测。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  Future<HttpServer> startServer(
    Map<String, dynamic> body, {
    int status = 200,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.statusCode = status;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(body));
      await req.response.close();
    });
    return server;
  }

  test('OpenRouter 默认：total_credits - total_usage', () async {
    final server = await startServer({
      'data': {'total_credits': 100.0, 'total_usage': 23.5},
    });
    final provider = ChatProvider(
      id: 'p1',
      name: 'T',
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'k',
    );
    final result = await BalanceService().fetch(provider);
    expect(result.ok, isTrue);
    expect(result.value, closeTo(76.5, 0.001));
    await server.close(force: true);
  });

  test('OpenAI 系默认：data.total_usage', () async {
    final server = await startServer({
      'data': {'total_usage': 42.0},
    });
    final provider = ChatProvider(
      id: 'p1',
      name: 'T',
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'k',
    );
    final result = await BalanceService().fetch(provider);
    expect(result.value, closeTo(42.0, 0.001));
    await server.close(force: true);
  });

  test('自定义路径表达式（数组下标 + 减法）', () async {
    final server = await startServer({
      'data': {
        'accounts': [
          {'balance': 50.0},
          {'balance': 20.0},
        ],
      },
    });
    final provider = ChatProvider(
      id: 'p1',
      name: 'T',
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'k',
      balanceResultPath: 'data.accounts[0].balance - data.accounts[1].balance',
    );
    final result = await BalanceService().fetch(provider);
    expect(result.value, closeTo(30.0, 0.001));
    await server.close(force: true);
  });

  test('5 分钟缓存：第二次不请求', () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests++;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'data': {'total_credits': 5.0, 'total_usage': 1.0}}));
      await req.response.close();
    });
    final provider = ChatProvider(
      id: 'p1',
      name: 'T',
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'k',
    );
    final svc = BalanceService();
    await svc.fetch(provider);
    await svc.fetch(provider);
    expect(requests, 1, reason: '缓存命中不应再次请求');
    await svc.fetch(provider, force: true);
    expect(requests, 2, reason: '强制刷新应重新请求');
    await server.close(force: true);
  });

  test('非 200 返回错误', () async {
    final server = await startServer({'error': 'x'}, status: 401);
    final provider = ChatProvider(
      id: 'p1',
      name: 'T',
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'k',
    );
    final result = await BalanceService().fetch(provider);
    expect(result.ok, isFalse);
    expect(result.error, contains('401'));
    await server.close(force: true);
  });

  test('路径表达式纯函数', () {
    final data = {
      'data': {
        'total_usage': 10.5,
        'nested': {'value': [1, 2, 3]},
      },
    };
    expect(BalanceService.extractBalance(data, ChatProvider(id: 'x', name: 'x')), 10.5);
    final p = ChatProvider(
      id: 'x',
      name: 'x',
      balanceResultPath: 'data.nested.value[2]',
    );
    expect(BalanceService.extractBalance(data, p), 3.0);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/services/chat_service.dart';
import 'package:nona_chat/services/mcp/mcp_client.dart';
import 'package:nona_chat/services/mcp/tool_loop.dart';
import 'package:nona_chat/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_test 默认 mock HttpClient（400），恢复真实网络
  setUp(() => HttpOverrides.global = null);

  group('MCP 客户端（真实 HttpServer）', () {
    test('initialize + tools/list + tools/call 全流程', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        requests.add(body);
        final method = body['method'] as String;
        Map<String, dynamic> result;
        if (method == 'initialize') {
          result = {
            'protocolVersion': '2025-03-26',
            'capabilities': {},
            'serverInfo': {'name': 'test-server', 'version': '1.0'},
          };
        } else if (method == 'tools/list') {
          result = {
            'tools': [
              {
                'name': 'get_weather',
                'description': '查询天气',
                'inputSchema': {
                  'type': 'object',
                  'properties': {'city': {'type': 'string'}},
                  'required': ['city'],
                },
              },
            ],
          };
        } else if (method == 'tools/call') {
          result = {
            'content': [
              {'type': 'text', 'text': '北京，晴，25°C'},
            ],
          };
        } else {
          result = {};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}),
        );
        await request.response.close();
      });

      final client = McpClient(baseUrl: 'http://127.0.0.1:${server.port}/mcp');
      await client.initialize();
      expect(client.serverInfo?['name'], 'test-server');

      final tools = await client.listTools();
      expect(tools, hasLength(1));
      expect(tools.first.name, 'get_weather');
      expect(tools.first.description, '查询天气');

      final result = await client.callTool('get_weather', {'city': '北京'});
      expect(result.content, contains('晴'));
      expect(result.isError, isFalse);

      // 请求均带 jsonrpc 2.0 与递增 id
      expect(requests.first['jsonrpc'], '2.0');
      expect(requests.first['method'], 'initialize');
      expect(requests.last['method'], 'tools/call');
      await server.close(force: true);
    });

    test('服务端错误抛出 McpException', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'error': {'code': -32601, 'message': '方法不存在'},
          }),
        );
        await request.response.close();
      });

      final client = McpClient(baseUrl: 'http://127.0.0.1:${server.port}/mcp');
      await expectLater(
        client.callTool('x', const {}),
        throwsA(isA<McpException>()),
      );
      await server.close(force: true);
    });

    test('SSE 包装响应可解析', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        request.response.headers
          ..contentType = ContentType.text
          ..set('Cache-Control', 'no-cache');
        request.response.write(
          'data: {"jsonrpc":"2.0","id":${body['id']},"result":{"tools":[]}}\n\n',
        );
        await request.response.close();
      });

      final client = McpClient(baseUrl: 'http://127.0.0.1:${server.port}/mcp');
      expect(await client.listTools(), isEmpty);
      await server.close(force: true);
    });
  });

  group('工具调用循环（ToolLoopRunner）', () {
    /// 模拟 OpenAI 服务端：首轮返回 tool_calls，次轮返回最终文本。
    Future<HttpServer> startLoopServer() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        final messages = body['messages'] as List<dynamic>;
        final hasToolResult = messages.any(
          (m) => m is Map && m['role'] == 'tool',
        );
        request.response.headers
          ..contentType = ContentType.text
          ..set('Cache-Control', 'no-cache');
        if (!hasToolResult) {
          // 首轮：请求工具
          request.response.write(
            'data: {"choices":[{"delta":{"tool_calls":['
            '{"index":0,"id":"call_1","type":"function",'
            '"function":{"name":"get_weather","arguments":"{\\"city\\":\\"北京\\"}"}}'
            ']}}]}\n\n'
            'data: [DONE]\n\n',
          );
        } else {
          // 次轮：最终回答
          request.response.write(
            'data: {"choices":[{"delta":{"content":"北京今天晴天"}}]}\n\n'
            'data: {"choices":[{"delta":{}}],"usage":{"prompt_tokens":30,"completion_tokens":10,"total_tokens":40}}\n\n'
            'data: [DONE]\n\n',
          );
        }
        await request.response.close();
      });
      return server;
    }

    test('生成 → 工具调用 → 结果回传 → 最终回复', () async {
      final server = await startLoopServer();
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'k',
        model: 'gpt-4o',
        providerKind: 'openai',
        chatAutoRetry: false,
      );

      var toolCalls = 0;
      final result = await ToolLoopRunner.run(
        settings: settings,
        messages: [ChatMessage(role: 'user', content: '北京天气如何？')],
        options: const ChatOptions(),
        tools: [
          {
            'type': 'function',
            'function': {
              'name': 'get_weather',
              'description': '查询天气',
              'parameters': {
                'type': 'object',
                'properties': {'city': {'type': 'string'}},
              },
            },
          },
        ],
        onToolCall: (call) async {
          toolCalls++;
          expect(call.name, 'get_weather');
          expect(call.arguments, contains('北京'));
          return const McpToolResult(content: '北京，晴，25°C');
        },
      );

      expect(toolCalls, 1);
      expect(result.content, '北京今天晴天');
      // ignore: avoid_print
      print('USAGE DEBUG: prompt=${result.usage?.promptTokens} '
          'completion=${result.usage?.completionTokens}');
      expect(result.usage?.promptTokens, 30);
      expect(result.usage?.completionTokens, 10);
      await server.close(force: true);
    });

    test('工具执行失败不中断循环（结果标记错误）', () async {
      final server = await startLoopServer();
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'k',
        model: 'gpt-4o',
        providerKind: 'openai',
        chatAutoRetry: false,
      );
      final result = await ToolLoopRunner.run(
        settings: settings,
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
        tools: [
          {
            'type': 'function',
            'function': {'name': 'get_weather', 'description': 'x'},
          },
        ],
        onToolCall: (call) async => throw Exception('服务不可用'),
      );
      expect(result.content, '北京今天晴天');
      await server.close(force: true);
    });

    test('无工具时单轮直接返回', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.write(
          'data: {"choices":[{"delta":{"content":"直接回答"}}]}\n\n'
          'data: [DONE]\n\n',
        );
        await request.response.close();
      });
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'k',
        model: 'm',
        providerKind: 'openai',
        chatAutoRetry: false,
      );
      final result = await ToolLoopRunner.run(
        settings: settings,
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
      );
      expect(result.content, '直接回答');
      await server.close(force: true);
    });
  });

  group('sendChatWithTools 取消', () {
    test('取消后以 ChatCancelledException 结束', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.text;
        // 持续输出，等待取消
        for (var i = 0; i < 1000; i++) {
          request.response.write(
            'data: {"choices":[{"delta":{"content":"x"}}]}\n\n',
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await request.response.close();
      });
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'k',
        model: 'm',
        providerKind: 'openai',
        chatAutoRetry: false,
      );
      final handle = ChatService().sendChatWithTools(
        settings: settings,
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
        tools: [
          {
            'type': 'function',
            'function': {'name': 't', 'description': 'x'},
          },
        ],
        onToolCall: (call) async => const McpToolResult(content: 'ok'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(handle.isCancelled, isFalse);
      await handle.cancel();
      expect(handle.isCancelled, isTrue);
      await expectLater(handle.result, throwsA(isA<ChatCancelledException>()));
      await server.close(force: true);
    });
  });
}

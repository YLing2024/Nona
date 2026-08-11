import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/services/mcp/mcp_client.dart';
import 'package:nona_chat/services/mcp/tool_loop.dart';
import 'package:nona_chat/services/settings_service.dart';

/// F1-1/F1-2：Anthropic / Gemini 流式工具调用两轮循环（本地 mock SSE server）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => HttpOverrides.global = null);

  group('Anthropic 流式工具调用（F1-1）', () {
    Future<HttpServer> startServer(
      List<Map<String, dynamic>> bodies,
      List<List<dynamic>> allMessages, {
      int rounds = 2,
    }) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        try {
          final raw = await utf8.decoder.bind(req).join();
          final body = jsonDecode(raw) as Map<String, dynamic>;
          bodies.add(body);
          allMessages.add(body['messages'] as List<dynamic>);
          final messages = body['messages'] as List<dynamic>;
          final hasToolResult = messages.any((m) {
            final content = (m as Map)['content'];
            return content is List &&
                content.any((c) => c is Map && c['type'] == 'tool_result');
          });
          req.response.headers
            ..contentType = ContentType.text
            ..set('Cache-Control', 'no-cache');
          if (rounds == 2 && !hasToolResult) {
            // 首轮：请求工具（thinking 与 tool_use 同帧不串扰）
            req.response.write(
              'data: {"type":"message_start","message":{"usage":{"input_tokens":10}}}\n\n'
              'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking"}}\n\n'
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"分析中"}}\n\n'
              'data: {"type":"content_block_stop","index":0}\n\n'
              'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"get_weather"}}\n\n'
              'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{&quot;city&quot;:"}}\n\n'
              'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"&quot;beijing&quot;}"}}\n\n'
              'data: {"type":"content_block_stop","index":1}\n\n'
              'data: {"type":"message_delta","usage":{"output_tokens":4}}\n\n'
              'data: {"type":"message_stop"}\n\n',
            );
          } else {
            // 次轮：最终回答
            req.response.write(
              'data: {"type":"message_start","message":{"usage":{"input_tokens":20}}}\n\n'
              'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"北京今天晴天"}}\n\n'
              'data: {"type":"message_delta","usage":{"output_tokens":6}}\n\n'
              'data: {"type":"message_stop"}\n\n',
            );
          }
        } catch (_) {
        } finally {
          try {
            await req.response.close();
          } catch (_) {}
        }
      });
      return server;
    }

    test('2 轮工具循环成功且请求体为 Anthropic 格式', () async {
      final bodies = <Map<String, dynamic>>[];
      final allMessages = <List<dynamic>>[];
      final server = await startServer(bodies, allMessages);
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        model: 'claude-3-7-sonnet',
        providerKind: 'anthropic',
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
          expect(call.id, 'toolu_1');
          expect(call.name, 'get_weather');
          expect(call.arguments, '{"city":"beijing"}');
          return const McpToolResult(content: '北京，晴，25°C');
        },
      );

      expect(toolCalls, 1);
      expect(result.content, '北京今天晴天');

      // 首轮请求体：tools 为 Anthropic 格式
      final first = bodies.first;
      expect(first['tools'], [
        {
          'name': 'get_weather',
          'description': '查询天气',
          'input_schema': {
            'type': 'object',
            'properties': {'city': {'type': 'string'}},
          },
        },
      ]);
      expect(first['tool_choice'], {'type': 'auto'});

      // 次轮请求体：assistant 带 tool_use 块，tool 结果带 tool_result 块
      final secondMessages = allMessages[1];
      final assistantMsg = secondMessages.cast<Map<String, dynamic>>().firstWhere(
        (m) => m['role'] == 'assistant',
      );
      final content = assistantMsg['content'] as List;
      expect(
        content.any((c) => c is Map && c['type'] == 'tool_use'),
        isTrue,
        reason: 'assistant 消息应携带 tool_use 块',
      );
      final toolResultMsg = secondMessages.cast<Map<String, dynamic>>().firstWhere(
        (m) {
          final c = m['content'];
          return c is List &&
              c.any((x) => x is Map && x['type'] == 'tool_result');
        },
      );
      final resultBlock = (toolResultMsg['content'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['type'] == 'tool_result');
      expect(resultBlock['tool_use_id'], 'toolu_1');
      await server.close(force: true);
    });
  });

  group('Gemini 流式工具调用（F1-2）', () {
    Future<HttpServer> startServer(
      List<Map<String, dynamic>> bodies,
    ) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        try {
          final raw = await utf8.decoder.bind(req).join();
          final body = jsonDecode(raw) as Map<String, dynamic>;
          bodies.add(body);
          final contents = body['contents'] as List<dynamic>;
          final hasFnResponse = contents.any((c) {
            final parts = (c as Map)['parts'] as List;
            return parts.any(
              (p) => p is Map && p.containsKey('functionResponse'),
            );
          });
          req.response.headers
            ..contentType = ContentType.text
            ..set('Cache-Control', 'no-cache');
          if (!hasFnResponse) {
            req.response.write(
              'data: {"candidates":[{"content":{"parts":[{"functionCall":{"name":"get_weather","args":{"city":"beijing"}}}]}}],"usageMetadata":{"promptTokenCount":8,"candidatesTokenCount":3}}\n\n'
              'data: {}\n\n',
            );
          } else {
            req.response.write(
              'data: {"candidates":[{"content":{"parts":[{"text":"北京今天晴天"}]}}],"usageMetadata":{"promptTokenCount":12,"candidatesTokenCount":5}}\n\n'
              'data: {}\n\n',
            );
          }
        } catch (_) {
        } finally {
          try {
            await req.response.close();
          } catch (_) {}
        }
      });
      return server;
    }

    test('2 轮工具循环成功且请求体为 Gemini 格式', () async {
      final bodies = <Map<String, dynamic>>[];
      final server = await startServer(bodies);
      final settings = AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}/v1beta',
        apiKey: 'sk-test',
        model: 'gemini-2.0-flash',
        providerKind: 'gemini',
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
          expect(call.id, 'gemini_get_weather');
          expect(call.name, 'get_weather');
          expect(call.arguments, contains('beijing'));
          return const McpToolResult(content: '北京，晴，25°C');
        },
      );

      expect(toolCalls, 1);
      expect(result.content, '北京今天晴天');

      // 首轮请求体：tools 为 Gemini functionDeclarations 格式
      final first = bodies.first;
      expect(first['tools'], [
        {
          'functionDeclarations': [
            {
              'name': 'get_weather',
              'description': '查询天气',
              'parameters': {
                'type': 'object',
                'properties': {'city': {'type': 'string'}},
              },
            },
          ],
        },
      ]);

      // 次轮请求体：model 消息带 functionCall part；user 消息带 functionResponse
      final second = bodies.last;
      final contents = second['contents'] as List;
      final modelMsg = contents.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['role'] == 'model',
      );
      expect(
        (modelMsg['parts'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p.containsKey('functionCall')),
        isTrue,
      );
      final fnResp = contents.cast<Map<String, dynamic>>().firstWhere((c) {
        return (c['parts'] as List)
            .cast<Map<String, dynamic>>()
            .any((p) => p.containsKey('functionResponse'));
      });
      final respPart = (fnResp['parts'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p.containsKey('functionResponse'));
      expect(respPart['functionResponse']['name'], 'get_weather');
      expect(respPart['functionResponse']['response']['result'], contains('晴'));
      await server.close(force: true);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/services/chat/sse_parser.dart';
import 'package:nona_chat/services/chat_service.dart';
import 'package:nona_chat/services/protocol/protocol_factory.dart';
import 'package:nona_chat/services/settings_service.dart';

void main() {
  AppSettings settingsFor(HttpServer server, String kind,
          {String baseUrl = ''}) =>
      AppSettings(
        baseUrl: baseUrl.isEmpty ? 'http://127.0.0.1:${server.port}' : baseUrl,
        apiKey: 'sk-test',
        model: 'claude-3-7-sonnet',
        providerKind: kind,
        chatAutoRetry: false,
      );

  List<ChatMessage> history() => [
    ChatMessage(role: 'user', content: '你好'),
  ];

  /// 服务器：捕获请求并回放 SSE（与 chat_service_test 相同模式）。
  Future<HttpServer> startServer(
    Future<void> Function(HttpRequest req) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      try {
        await handler(req);
      } catch (_) {
        // 客户端取消等场景下写响应可能失败，忽略
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

  group('Anthropic 协议', () {
    test('SSE 流式：text_delta + thinking_delta + usage 汇总', () async {
      final bodies = <Map<String, dynamic>>[];
      late Map<String, String> headers;
      final server = await startServer((req) async {
        headers = <String, String>{};
        req.headers.forEach((name, values) => headers[name] = values.join(','));
        final raw = await utf8.decoder.bind(req).join();
        bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        req.response.headers
          ..contentType = ContentType.text
          ..set('Cache-Control', 'no-cache');
        req.response.write(
          'data: {"type":"message_start","message":{"usage":{"input_tokens":12}}}\n\n'
          'data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"让我想想"}}\n\n'
          'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"你好！"}}\n\n'
          'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":" 有什么可以帮你？"}}\n\n'
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":7}}\n\n'
          'data: {"type":"message_stop"}\n\n',
        );
      });

      final content = <String>[];
      final reasoning = <String>[];
      final handle = ChatService().sendChat(
        settings: settingsFor(server, 'anthropic'),
        messages: history(),
        onPartial: content.add,
        onReasoning: reasoning.add,
      );
      final result = await handle.result;

      expect(result.content, '你好！ 有什么可以帮你？');
      expect(content, ['你好！', ' 有什么可以帮你？']);
      expect(reasoning, ['让我想想']);
      expect(result.usage?.promptTokens, 12);
      expect(result.usage?.completionTokens, 7);

      expect(headers['x-api-key'], 'sk-test');
      expect(headers['anthropic-version'], '2023-06-01');
      final body = bodies.single;
      expect(body['model'], 'claude-3-7-sonnet');
      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '你好'},
          ],
        },
      ]);
      expect(body['max_tokens'], 4096);
    });

    test('系统提示词提取到 system 字段', () async {
      final bodies = <Map<String, dynamic>>[];
      final server = await startServer((req) async {
        final raw = await utf8.decoder.bind(req).join();
        bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        req.response.write(
          'data: {"type":"message_start","message":{"usage":{"input_tokens":1}}}\n\n'
          'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"ok"}}\n\n'
          'data: {"type":"message_stop"}\n\n',
        );
      });

      final handle = ChatService().sendChat(
        settings: settingsFor(server, 'anthropic'),
        messages: history(),
        options: const ChatOptions(systemPrompt: '你是测试助手'),
      );
      await handle.result;
      final body = bodies.single;
      expect(body['system'], '你是测试助手');
      expect(
        body['messages'].where((m) => m['role'] == 'system'),
        isEmpty,
        reason: 'system 消息不应混入 messages',
      );
    });

    test('多模态图片转 base64 source 格式', () async {
      final bodies = <Map<String, dynamic>>[];
      final server = await startServer((req) async {
        final raw = await utf8.decoder.bind(req).join();
        bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        req.response.write(
          'data: {"type":"message_start","message":{"usage":{"input_tokens":1}}}\n\n'
          'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"ok"}}\n\n'
          'data: {"type":"message_stop"}\n\n',
        );
      });

      final handle = ChatService().sendChat(
        settings: settingsFor(server, 'anthropic'),
        messages: [
          ChatMessage(
            role: 'user',
            content: '看图',
            images: [
              ChatImage(
                url: 'data:image/png;base64,aGVsbG8=',
                mimeType: 'image/png',
              ),
            ],
          ),
        ],
      );
      await handle.result;
      final content = bodies.single['messages'].first['content'] as List;
      final imagePart = content.cast<Map<String, dynamic>>().firstWhere(
        (p) => p['type'] == 'image',
      );
      expect(
        imagePart['source'],
        {
          'type': 'base64',
          'media_type': 'image/png',
          'data': 'aGVsbG8=',
        },
      );
    });
  });

  group('Gemini 协议', () {
    test('SSE 流式：text part + usageMetadata + thought 分离', () async {
      final bodies = <Map<String, dynamic>>[];
      late Map<String, String> headers;
      final server = await startServer((req) async {
        headers = <String, String>{};
        req.headers.forEach((name, values) => headers[name] = values.join(','));
        final raw = await utf8.decoder.bind(req).join();
        bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        req.response.headers
          ..contentType = ContentType.text
          ..set('Cache-Control', 'no-cache');
        req.response.write(
          'data: {"candidates":[{"content":{"parts":[{"text":"思考","thought":true}]}'
          '}],"usageMetadata":{"promptTokenCount":5,"candidatesTokenCount":3}}\n\n'
          'data: {"candidates":[{"content":{"parts":[{"text":"回答一"}]}}]}\n\n'
          'data: {"candidates":[{"content":{"parts":[{"text":" 回答二"}]}}]}\n\n'
          'data: {}\n\n',
        );
      });

      final content = <String>[];
      final reasoning = <String>[];
      final handle = ChatService().sendChat(
        settings: settingsFor(
          server,
          'gemini',
          baseUrl: 'http://127.0.0.1:${server.port}/v1beta',
        ),
        messages: history(),
        onPartial: content.add,
        onReasoning: reasoning.add,
      );
      final result = await handle.result;

      expect(result.content, '回答一 回答二');
      expect(content, ['回答一', ' 回答二']);
      expect(reasoning, ['思考']);
      expect(result.usage?.promptTokens, 5);
      expect(result.usage?.completionTokens, 3);

      expect(headers['x-goog-api-key'], 'sk-test');
      final body = bodies.single;
      expect(body['contents'], [
        {
          'role': 'user',
          'parts': [
            {'text': '你好'},
          ],
        },
      ]);
      expect(body['generationConfig']['temperature'], isNotNull);
    });

    test('system 提示词进 system_instruction，路径为 streamGenerateContent',
        () async {
      final bodies = <Map<String, dynamic>>[];
      late Uri requestUri;
      final server = await startServer((req) async {
        requestUri = req.uri;
        final raw = await utf8.decoder.bind(req).join();
        bodies.add(jsonDecode(raw) as Map<String, dynamic>);
        req.response.write(
          'data: {"candidates":[{"content":{"parts":[{"text":"ok"}]}}]}\n\n'
          'data: {}\n\n',
        );
      });

      final handle = ChatService().sendChat(
        settings: settingsFor(
          server,
          'gemini',
          baseUrl: 'http://127.0.0.1:${server.port}/v1beta',
        ),
        messages: history(),
        options: const ChatOptions(systemPrompt: '系统指令'),
      );
      await handle.result;
      expect(requestUri.path, contains('streamGenerateContent'));
      expect(
        bodies.single['system_instruction'],
        {'parts': [{'text': '系统指令'}]},
      );
    });
  });

  group('显式协议', () {
    test('openai 协议保持原有行为', () async {
      final server = await startServer((req) async {
        req.response.write(
          'data: {"choices":[{"delta":{"content":"hi"}}]}\n\n'
          'data: [DONE]\n\n',
        );
      });
      final handle = ChatService().sendChat(
        settings: AppSettings(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'k',
          model: 'm',
          providerKind: 'openai',
        ),
        messages: history(),
      );
      final result = await handle.result;
      expect(result.content, 'hi');
    });
  });

  group('SSE 解析器三态契约（A4）', () {
    SseStreamParser build({bool streaming = true}) {
      return SseStreamParser(
        protocol: ProtocolFactory.resolve('openai', ''),
        streaming: streaming,
      );
    }

    test('OpenAI 流式 tool_calls 分片按 index 累积（A3）', () {
      final parser = build();
      String chunk(String payload) => 'data: ${jsonEncode({
            'choices': [
              {'delta': {'tool_calls': jsonDecode(payload) as List<dynamic>}},
            ],
          })}';
      parser.handleLine(
        chunk(
          jsonEncode([
            {
              'index': 0,
              'id': 'call_1',
              'function': {'name': 'get_weather', 'arguments': ''},
            },
          ]),
        ),
      );
      parser.handleLine(
        chunk(
          jsonEncode([
            {
              'index': 0,
              'function': {'arguments': '{"city":'},
            },
          ]),
        ),
      );
      parser.handleLine(
        chunk(
          jsonEncode([
            {'index': 0, 'function': {'arguments': '"beijing"}'}},
          ]),
        ),
      );
      parser.handleLine('data: [DONE]');
      parser.handleDone();

      expect(parser.hasToolCalls, isTrue);
      final calls = parser.collectedToolCalls;
      expect(calls, hasLength(1));
      expect(calls.single.id, 'call_1');
      expect(calls.single.name, 'get_weather');
      expect(calls.single.arguments, '{"city":"beijing"}');
    });

    test('连续 1000 个合法空块不进入暂存缓冲', () {
      final parser = build();
      for (var i = 0; i < 1000; i++) {
        parser.handleLine(
          'data: {"choices":[{"delta":{"role":"assistant"}}]}',
        );
      }
      parser.handleLine('data: [DONE]');
      expect(parser.rawBuffer, isEmpty, reason: '合法空块不得堆积缓冲');
      expect(parser.pendingInitialData, isEmpty);
      expect(parser.gotDelta, isFalse);
    });

    test('畸形流超限截断：rawBuffer 超 512KB 被清空', () {
      final parser = build(streaming: false);
      final bigLine = '{"a": "${'x' * 1000}"}';
      var total = 0;
      var truncated = false;
      while (total <= 512 * 1024) {
        parser.handleLine(bigLine);
        total += bigLine.length;
        if (parser.rawBuffer.isEmpty) truncated = true;
      }
      expect(truncated, isTrue, reason: '超限后缓冲应被清空');
      expect(parser.rawBuffer, isEmpty);
    });

    test('unrecognized 块暂存后 handleDone 走整包 JSON 兜底', () {
      final parser = build(streaming: false);
      // 非流式：OpenAI 返回整包 JSON（message.content 形状）
      parser.handleLine('data: {"choices":[{"message":{"content":"兜底成功"}}]}');
      parser.handleDone();
      expect(parser.error, isNull);
      expect(parser.content.toString(), '兜底成功');
    });
  });
}

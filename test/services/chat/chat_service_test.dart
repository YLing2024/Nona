import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/services/app_http_client.dart';
import 'package:nona_chat/services/chat_service.dart';
import 'package:nona_chat/services/settings_service.dart';

void main() {
  setUp(() => AppHttpClient.overrideBackoff(null));
  tearDown(() => AppHttpClient.overrideBackoff(null));

  AppSettings settingsFor(HttpServer server) => AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
      );

  /// 启动本地 HTTP 服务器，handler 负责写响应并关闭。
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

  /// 按 SSE 协议写多行数据（每行以 \n 结尾，事件间空行）。
  Future<void> writeSse(HttpResponse res, List<String> events) async {
    res.statusCode = 200;
    res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    for (final e in events) {
      res.write('$e\n\n');
    }
    await res.flush();
  }

  List<ChatMessage> history() => [
        ChatMessage(role: 'user', content: '你好'),
      ];

  test('流式：多段 content 增量通过 onPartial 回调并拼接完整结果', () async {
    final requestBodies = <String>[];
    final server = await startServer((req) async {
      requestBodies.add(await utf8.decoder.bind(req).join());
      await writeSse(req.response, [
        r'data: {"choices":[{"delta":{"content":"Hello "}}]}',
        r'data: {"choices":[{"delta":{"content":"world"}}]}',
        r'data: [DONE]',
      ]);
    });

    final partials = <String>[];
    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
      onPartial: partials.add,
    );
    final result = await handle.result;

    expect(partials, ['Hello ', 'world']);
    expect(result.content, 'Hello world');

    // 校验请求体：model / stream / 消息内容
    final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
    expect(body['model'], 'gpt-4o-mini');
    expect(body['stream'], isTrue);
    final msgs = body['messages'] as List<dynamic>;
    expect(msgs.first['role'], 'user');
    expect(msgs.first['content'], '你好');
  });

  test('流式：reasoning_content 走 onReasoning，内容走 onPartial', () async {
    final server = await startServer((req) async {
      await writeSse(req.response, [
        r'data: {"choices":[{"delta":{"reasoning_content":"思考中"}}]}',
        r'data: {"choices":[{"delta":{"content":"结论"}}]}',
        r'data: [DONE]',
      ]);
    });

    final partials = <String>[];
    final reasonings = <String>[];
    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
      onPartial: partials.add,
      onReasoning: reasonings.add,
    );
    final result = await handle.result;

    expect(reasonings, ['思考中']);
    expect(partials, ['结论']);
    expect(result.content, '结论');
  });

  test('流式：usage 块被解析到 result.usage', () async {
    final server = await startServer((req) async {
      await writeSse(req.response, [
        r'data: {"choices":[{"delta":{"content":"x"}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}',
        r'data: [DONE]',
      ]);
    });

    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
    );
    final result = await handle.result;
    expect(result.usage?.promptTokens, 10);
    expect(result.usage?.completionTokens, 5);
    expect(result.usage?.totalTokens, 15);
  });

  test('流式：断包分块写入（逐字节）仍能完整解析', () async {
    final server = await startServer((req) async {
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType('text', 'event-stream');
      const sse = r'''data: {"choices":[{"delta":{"content":"分块"}}]}

data: {"choices":[{"delta":{"content":"数据"}}]}

data: [DONE]

''';
      // 逐字节写入，模拟网络断包
      for (final c in sse.split('')) {
        req.response.add(utf8.encode(c));
        await req.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });

    final partials = <String>[];
    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
      onPartial: partials.add,
    );
    final result = await handle.result;
    expect(result.content, '分块数据');
    expect(partials, ['分块', '数据']);
  });

  test('非流式：SSE 包装的 message.content 一次返回', () async {
    final server = await startServer((req) async {
      await writeSse(req.response, [
        r'data: {"choices":[{"message":{"content":"完整回复"}}]}',
      ]);
    });

    var partialCalled = false;
    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
      options: const ChatOptions(stream: false),
      onPartial: (_) => partialCalled = true,
    );
    final result = await handle.result;
    expect(partialCalled, isFalse);
    expect(result.content, '完整回复');
  });

  test('非流式：整包 JSON 分多行到达（无 data: 前缀）能被合并解析', () async {
    final server = await startServer((req) async {
      req.response.statusCode = 200;
      req.response.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      req.response.write('{\n');
      req.response.write('  "choices": [\n');
      req.response.write('    {\n');
      req.response.write('      "message": {\n');
      req.response.write('        "content": "多行回复"\n');
      req.response.write('      }\n');
      req.response.write('    }\n');
      req.response.write('  ]\n');
      req.response.write('}\n');
    });

    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
      options: const ChatOptions(stream: false),
    );
    final result = await handle.result;
    expect(result.content, '多行回复');
  });

  test('空系统提示词不入请求，空内容消息被过滤', () async {
    final requestBodies = <String>[];
    final server = await startServer((req) async {
      requestBodies.add(await utf8.decoder.bind(req).join());
      await writeSse(req.response, [
        r'data: {"choices":[{"delta":{"content":"ok"}}]}',
        r'data: [DONE]',
      ]);
    });

    await ChatService()
        .sendChat(
          settings: settingsFor(server),
          messages: [
            ChatMessage(role: 'user', content: ''),
            ChatMessage(role: 'user', content: '保留'),
          ],
        )
        .result;

    final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
    final msgs = body['messages'] as List<dynamic>;
    expect(msgs, hasLength(1));
    expect(msgs.first['content'], '保留');
  });

  test('带系统提示词时前置 system 消息', () async {
    final requestBodies = <String>[];
    final server = await startServer((req) async {
      requestBodies.add(await utf8.decoder.bind(req).join());
      await writeSse(req.response, [
        r'data: {"choices":[{"delta":{"content":"ok"}}]}',
        r'data: [DONE]',
      ]);
    });

    await ChatService()
        .sendChat(
          settings: settingsFor(server),
          messages: history(),
          options: const ChatOptions(systemPrompt: '  你是助手  '),
        )
        .result;

    final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
    final msgs = body['messages'] as List<dynamic>;
    expect(msgs, hasLength(2));
    expect(msgs.first['role'], 'system');
    expect(msgs.first['content'], '你是助手');
  });

  test('HTTP 非 200：抛出 ChatException 并提取 error.message', () async {
    final server = await startServer((req) async {
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"error":{"message":"Invalid API key provided"}}');
    });

    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
    );
    await expectLater(
      handle.result,
      throwsA(isA<ChatException>().having(
        (e) => e.message,
        'message',
        contains('Invalid API key provided'),
      )),
    );
  });

  test('空响应（无内容）抛出 ChatException', () async {
    final server = await startServer((req) async {
      await writeSse(req.response, [r'data: [DONE]']);
    });

    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
    );
    await expectLater(
      handle.result,
      throwsA(isA<ChatException>().having(
        (e) => e.code,
        'code',
        ChatException.emptyResponse,
      )),
    );
  });

  test('cancel 后 result 以 ChatCancelledException 结束', () async {
    final server = await startServer((req) async {
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType('text', 'event-stream');
      // 持续输出，等待客户端取消
      for (var i = 0; i < 1000; i++) {
        req.response.write('data: {"choices":[{"delta":{"content":"x"}}]}\n\n');
        await req.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    final handle = ChatService().sendChat(
      settings: settingsFor(server),
      messages: history(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(handle.isCancelled, isFalse);
    await handle.cancel();
    expect(handle.isCancelled, isTrue);
    await expectLater(handle.result, throwsA(isA<ChatCancelledException>()));
  });

  test('连接失败抛出 ChatException（网络请求失败，重试耗尽后）', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);

    final started = DateTime.now();
    final handle = ChatService().sendChat(
      settings: AppSettings(
        baseUrl: 'http://127.0.0.1:$port',
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
      ),
      messages: history(),
    );
    await expectLater(
      handle.result,
      throwsA(isA<ChatException>().having(
        (e) => e.code,
        'code',
        ChatException.networkFailed,
      )),
    );
    // 自动重试：3 次尝试（含首次）+ 1s/2s 退避，总耗时不少于退避时间
    expect(DateTime.now().difference(started), greaterThanOrEqualTo(
      const Duration(seconds: 3),
    ));
  });

  test('关闭自动重试后连接失败只尝试一次', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);

    final started = DateTime.now();
    final handle = ChatService().sendChat(
      settings: AppSettings(
        baseUrl: 'http://127.0.0.1:$port',
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
        chatAutoRetry: false,
      ),
      messages: history(),
    );
    await expectLater(
      handle.result,
      throwsA(isA<ChatException>()),
    );
    // 无退避等待：单次尝试远快于重试版本（重试版 ≥ 3s 退避 + 多次连接耗时）。
    // 上限放宽到 10s，避免慢机（连接阶段超时抖动）误报 flake。
    expect(DateTime.now().difference(started), lessThan(
      const Duration(seconds: 10),
    ));
  });

  test('429 响应触发自动重试并在重试后成功', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      if (requests == 1) {
        request.response
          ..statusCode = 429
          ..headers.contentType = ContentType.json
          ..write('{"error":{"message":"rate limited"}}');
        await request.response.close();
        return;
      }
      request.response.headers
        ..contentType = ContentType.text
        ..set('Cache-Control', 'no-cache');
      request.response.write(
        'data: ${jsonEncode({
              'choices': [
                {'delta': {'content': 'hello'}, 'index': 0},
              ],
            })}\n\n'
        'data: ${jsonEncode({
              'choices': [
                {'delta': {'content': ' world'}, 'index': 0},
              ],
            })}\n\n'
        'data: [DONE]\n\n',
      );
      await request.response.close();
    });

    final chunks = <String>[];
    final handle = ChatService().sendChat(
      settings: AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
      ),
      messages: history(),
      onPartial: chunks.add,
    );
    final result = await handle.result;
    expect(requests, 2);
    expect(result.content, 'hello world');
    expect(chunks, ['hello', ' world']);
    await server.close(force: true);
  });

  test('关闭自动重试后 500 响应直接失败', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response
        ..statusCode = 500
        ..headers.contentType = ContentType.json
        ..write('{"error":{"message":"boom"}}');
      await request.response.close();
    });

    final handle = ChatService().sendChat(
      settings: AppSettings(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
        chatAutoRetry: false,
      ),
      messages: history(),
    );
    await expectLater(
      handle.result,
      throwsA(isA<ChatException>().having(
        (e) => e.message,
        'message',
        contains('HTTP 500'),
      )),
    );
    expect(requests, 1);
    await server.close(force: true);
  });

  group('多模态图片消息', () {
    test('带图片消息的请求体使用 content 数组', () async {
      final requestBodies = <String>[];
      final server = await startServer((req) async {
        requestBodies.add(await utf8.decoder.bind(req).join());
        await writeSse(req.response, [
          r'data: {"choices":[{"delta":{"content":"ok"}}]}',
          r'data: [DONE]',
        ]);
      });

      await ChatService()
          .sendChat(
            settings: settingsFor(server),
            messages: [
              ChatMessage(
                role: 'user',
                content: '看这张图',
                images: const [
                  ChatImage(
                    url: 'data:image/png;base64,AAA',
                    mimeType: 'image/png',
                  ),
                ],
              ),
            ],
          )
          .result;

      final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
      final msgs = body['messages'] as List<dynamic>;
      expect(msgs, hasLength(1));
      final content = msgs.first['content'] as List<dynamic>;
      expect(content, hasLength(2));
      expect(content[0], {'type': 'text', 'text': '看这张图'});
      expect(content[1]['type'], 'image_url');
      expect(content[1]['image_url']['url'], 'data:image/png;base64,AAA');
    });

    test('正文为空的纯图片消息不被过滤', () async {
      final requestBodies = <String>[];
      final server = await startServer((req) async {
        requestBodies.add(await utf8.decoder.bind(req).join());
        await writeSse(req.response, [
          r'data: {"choices":[{"delta":{"content":"ok"}}]}',
          r'data: [DONE]',
        ]);
      });

      await ChatService()
          .sendChat(
            settings: settingsFor(server),
            messages: [
              ChatMessage(
                role: 'user',
                content: ' ',
                images: const [
                  ChatImage(url: 'https://x/a.png', mimeType: 'image/png'),
                ],
              ),
            ],
          )
          .result;

      final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
      final msgs = body['messages'] as List<dynamic>;
      expect(msgs, hasLength(1));
      final content = msgs.first['content'] as List<dynamic>;
      expect(content.single['type'], 'image_url');
    });

    test('文本空且无图片的消息仍被过滤', () async {
      final requestBodies = <String>[];
      final server = await startServer((req) async {
        requestBodies.add(await utf8.decoder.bind(req).join());
        await writeSse(req.response, [
          r'data: {"choices":[{"delta":{"content":"ok"}}]}',
          r'data: [DONE]',
        ]);
      });

      await ChatService()
          .sendChat(
            settings: settingsFor(server),
            messages: [ChatMessage(role: 'user', content: '  ')],
          )
          .result;

      final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
      expect(body['messages'] as List<dynamic>, isEmpty);
    });
  });

  group('sendSimple（轻量非流式）', () {
    test('返回助手正文并发送系统提示词与低 temperature', () async {
      final requestBodies = <String>[];
      final server = await startServer((req) async {
        requestBodies.add(await utf8.decoder.bind(req).join());
        req.response.statusCode = 200;
        req.response.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        req.response.write(
          '{"choices":[{"message":{"content":"会话标题"}}],"usage":{"prompt_tokens":10,"completion_tokens":5}}',
        );
      });

      final title = await ChatService().sendSimple(
        settings: settingsFor(server),
        userMessage: '今天天气怎么样？',
        systemPrompt: '生成标题',
        maxTokens: 20,
      );
      expect(title, '会话标题');

      final body = jsonDecode(requestBodies.single) as Map<String, dynamic>;
      expect(body['stream'], isFalse);
      expect(body['max_tokens'], 20);
      expect(body['temperature'], 0.0);
      final msgs = body['messages'] as List<dynamic>;
      expect(msgs, hasLength(2));
      expect(msgs.first['role'], 'system');
      expect(msgs.first['content'], '生成标题');
      expect(msgs.last['content'], '今天天气怎么样？');
    });

    test('返回空白时抛出异常', () async {
      final server = await startServer((req) async {
        req.response.statusCode = 200;
        req.response.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        req.response.write('{"choices":[{"message":{"content":"   "}}]}');
      });

      await expectLater(
        ChatService().sendSimple(
          settings: settingsFor(server),
          userMessage: 'x',
        ),
        throwsA(isA<ChatException>()),
      );
    });
  });
}

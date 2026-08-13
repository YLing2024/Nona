import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/core/models/agent.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/services/chat_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => HttpOverrides.global = null);

  group('自定义请求头/请求体', () {
    test('发送时合并自定义头与请求体', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      late Map<String, String> receivedHeaders;
      late Map<String, dynamic> receivedBody;
      server.listen((request) async {
        receivedHeaders = <String, String>{};
        request.headers.forEach((k, v) => receivedHeaders[k] = v.join(','));
        final raw = await utf8.decoder.bind(request).join();
        receivedBody = jsonDecode(raw) as Map<String, dynamic>;
        request.response.write(
          'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n'
          'data: [DONE]\n\n',
        );
        await request.response.close();
      });

      final handle = ChatService().sendChat(
        settings: AppSettings(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'sk-test',
          model: 'gpt-4o',
          providerKind: 'openai',
          chatAutoRetry: false,
        ),
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
        customHeaders: {'X-Trace-Id': 'abc-123'},
        customBody: {'extra_field': 'custom'},
      );
      await handle.result;

      expect(receivedHeaders['x-trace-id'], 'abc-123');
      expect(receivedBody['extra_field'], 'custom');
      expect(receivedBody['model'], 'gpt-4o');
      await server.close(force: true);
    });
  });

  group('Agent 记忆序列化', () {
    test('memories 往返', () {
      final agent = Agent(
        id: 'a1',
        name: '助手',
        memories: ['记忆一', '记忆二'],
      );
      final restored = Agent.fromJson(agent.toJson());
      expect(restored.memories, ['记忆一', '记忆二']);
    });

    test('缺失 memories 默认为空', () {
      final agent = Agent.fromJson({'id': 'a', 'name': 'n'});
      expect(agent.memories, isEmpty);
    });
  });
}

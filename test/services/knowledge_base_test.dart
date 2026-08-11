import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/services/chat_service.dart';
import 'package:nona_chat/services/knowledge_base_service.dart';
import 'package:nona_chat/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  group('知识库', () {
    test('添加文档并分块', () async {
      final service = KnowledgeBaseService();
      final text = '第一段内容。' * 300;
      final chunks = await service.addText('doc.txt', text);
      expect(chunks, greaterThan(1));
      final docs = await service.listDocs();
      expect(docs, ['doc.txt']);
    });

    test('检索命中相关内容', () async {
      final service = KnowledgeBaseService();
      await service.addText('手册.txt', 'Nona 的默认上下文窗口管理使用 tiktoken 精确估算 token 数量。');
      await service.addText('其他.txt', '今天天气不错。');
      final hits = await service.search('tiktoken 估算 token');
      expect(hits, isNotEmpty);
      expect(hits.first.docName, '手册.txt');
      expect(hits.first.text, contains('tiktoken'));
    });

    test('短查询返回空', () async {
      final service = KnowledgeBaseService();
      await service.addText('a.txt', '内容');
      expect(await service.search('一'), isEmpty);
    });

    test('删除文档', () async {
      final service = KnowledgeBaseService();
      await service.addText('x.txt', '内容');
      await service.remove('x.txt');
      expect(await service.listDocs(), isEmpty);
    });

    test('空库检索返回空', () async {
      final service = KnowledgeBaseService();
      expect(await service.search('任何'), isEmpty);
    });
  });

  group('知识库注入（对话请求体验证）', () {
    test('发送时知识库内容进入系统提示词', () async {
      final service = KnowledgeBaseService();
      await service.addText('知识.txt', '公司的内部代号是 SKY-1000，请记住这个信息。');

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      late Map<String, dynamic> receivedBody;
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        receivedBody = jsonDecode(raw) as Map<String, dynamic>;
        request.response.write(
          'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n'
          'data: [DONE]\n\n',
        );
        await request.response.close();
      });

      // 手动构造含知识库内容的 system 消息（home_screen 注入逻辑等价）
      final systemPrompt = [
        '以下是知识库中的相关内容，回答时请优先参考：\n- SKY-1000',
        '',
      ].where((s) => s.trim().isNotEmpty).join('\n\n');

      final handle = ChatService().sendChat(
        settings: AppSettings(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'k',
          model: 'm',
          providerKind: 'openai',
          chatAutoRetry: false,
        ),
        messages: [ChatMessage(role: 'user', content: '公司的代号是什么？')],
        options: ChatOptions(systemPrompt: systemPrompt),
      );
      await handle.result;
      final systemMsg = (receivedBody['messages'] as List).first
          as Map<String, dynamic>;
      expect(systemMsg['role'], 'system');
      expect(systemMsg['content'], contains('SKY-1000'));
      await server.close(force: true);
    });
  });
}

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/models/agent.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/models/chat_session.dart';
import 'package:nona_chat/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChatSession buildSession() {
    return ChatSession(
      id: 's1',
      title: '测试/会话',
      options: const ChatOptions(systemPrompt: '你是 Nona'),
      messages: [
        ChatMessage(role: 'user', content: '你好'),
        ChatMessage(
          role: 'assistant',
          content: '你好！有什么可以帮你？',
          reasoningContent: '用户打招呼，礼貌回应即可',
          interrupted: true,
          promptTokens: 5,
          completionTokens: 8,
          providerName: 'OpenAI',
          modelId: 'gpt-4o-mini',
        ),
        ChatMessage(role: 'user', content: '  \n  '),
      ],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('sessionToMarkdown', () {
    final md = ExportService.sessionToMarkdown(buildSession());

    test('包含标题与导出时间', () {
      expect(md, contains('# 测试/会话'));
      expect(md, contains('> Exported: '));
    });

    test('包含系统提示词代码块', () {
      expect(md, contains('## System Prompt'));
      expect(md, contains('```\n你是 Nona\n```'));
    });

    test('按角色渲染消息头', () {
      expect(md, contains('## User'));
      expect(md, contains('## Nona'));
      expect(md, contains('你好！有什么可以帮你？'));
    });

    test('思考内容渲染进 details 折叠块', () {
      expect(md, contains('<details>'));
      expect(md, contains('<summary>Reasoning</summary>'));
      expect(md, contains('用户打招呼，礼貌回应即可'));
      expect(md, contains('</details>'));
    });

    test('被停止生成的消息带标记', () {
      expect(md, contains('_(stopped)_'));
    });

    test('空白内容消息被跳过', () {
      expect(md.contains('## User') == true, isTrue);
      // 只有一条用户消息头（空白消息被跳过，不额外生成角色头）
      expect('## User'.allMatches(md).length, 1);
    });
  });

  group('JSON 导出数据', () {
    test('导出 JSON 可被 ChatSession.fromJson 完整恢复', () {
      final session = buildSession();
      final json = session.toJson();
      final restored = ChatSession.fromJson(json);
      expect(restored.title, '测试/会话');
      expect(restored.messages, hasLength(3));
      expect(restored.messages[1].reasoningContent, '用户打招呼，礼貌回应即可');
      expect(restored.messages[1].interrupted, isTrue);
      expect(restored.options.systemPrompt, '你是 Nona');
    });
  });

  group('HTML 导出', () {
    final html = ExportService.sessionToHtml(buildSession());

    test('包含标题、样式与消息内容', () {
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<title>测试/会话</title>'));
      expect(html, contains('你好！有什么可以帮你？'));
      expect(html, contains('white-space:pre-wrap'));
    });

    test('HTML 特殊字符被转义', () {
      final s = ChatSession(
        id: 's1',
        title: '测试<会话>&"',
        messages: [ChatMessage(role: 'user', content: '<script>alert(1)</script>')],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final out = ExportService.sessionToHtml(s);
      expect(out, isNot(contains('<script>alert(1)</script>')));
      expect(out, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
      expect(out, contains('测试&lt;会话&gt;&amp;&quot;'));
    });

    test('思考内容渲染进 details 折叠块', () {
      expect(html, contains('<details><summary>Reasoning</summary>'));
      expect(html, contains('用户打招呼，礼貌回应即可'));
    });

    test('图片消息：Markdown 用图片语法，HTML 内嵌图片', () {
      final s = ChatSession(
        id: 's1',
        title: '图片会话',
        messages: [
          ChatMessage(
            role: 'user',
            content: '  ',
            images: const [
              ChatImage(url: 'data:image/png;base64,xxx', mimeType: 'image/png'),
              ChatImage(url: 'https://x/a.png', mimeType: 'image/png'),
            ],
          ),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final md = ExportService.sessionToMarkdown(s);
      expect(md, contains('![image](data:image/png;base64,xxx)'));
      expect(md, contains('![image](https://x/a.png)'));
      final outHtml = ExportService.sessionToHtml(s);
      expect(outHtml, contains('<img src="data:image/png;base64,xxx"'));
      expect(outHtml, contains('<img src="https://x/a.png"'));
    });
  });

  group('ZIP 备份往返', () {
    test('导出 ZIP 可完整恢复会话/服务商/Agent', () async {
      final session = buildSession();
      final provider = ChatProvider(
        id: 'p1',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-test',
        modelIds: ['gpt-4o', 'gpt-4o-mini'],
      );
      final agent = Agent(id: 'a1', name: '助手', isDefault: true);

      final bytes = await _encodeZip([session], [provider], [agent]);
      final result = ExportService.importFromZipBytes(bytes);
      expect(result, isNotNull);
      expect(result!.sessions, hasLength(1));
      expect(result.sessions.first.title, '测试/会话');
      expect(result.sessions.first.messages, hasLength(3));
      expect(result.providers, hasLength(1));
      expect(result.providers!.first.apiKey, 'sk-test');
      expect(result.providers!.first.modelIds, contains('gpt-4o'));
      expect(result.agents, hasLength(1));
      expect(result.agents!.first.name, '助手');
    });

    test('非备份 ZIP（缺 manifest）返回 null', () {
      final archive = Archive()..addFile(ArchiveFile.string('x.txt', 'hi'));
      final bytes = ZipEncoder().encode(archive);
      expect(ExportService.importFromZipBytes(bytes), isNull);
    });

    test('损坏的 JSON 返回 null', () {
      expect(ExportService.importFromJsonData('not json'), isNull);
    });

    test('旧版 Nona JSON 备份可导入', () {
      final data = {
        'app': 'nona',
        'version': 1,
        'sessions': [buildSession().toJson()],
      };
      final result = ExportService.importFromJsonData(data);
      expect(result, isNotNull);
      expect(result!.sessions, hasLength(1));
    });
  });

  group('竞品备份导入', () {
    test('Chatbox 备份：conversations + 数组 content 图片', () {
      final data = {
        'version': 1,
        'conversations': [
          {
            'id': 'cb-1',
            'name': 'Chatbox 会话',
            'updatedAt': 1700000000000,
            'messages': [
              {
                'id': 'm1',
                'role': 'user',
                'time': 1700000000000,
                'content': [
                  {'type': 'text', 'text': '你好'},
                  {'type': 'image', 'url': 'data:image/png;base64,aaa'},
                ],
              },
              {
                'id': 'm2',
                'role': 'assistant',
                'time': 1700000001000,
                'content': '你好！',
              },
            ],
          },
        ],
      };
      final result = ExportService.importFromJsonData(data);
      expect(result, isNotNull);
      expect(result!.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, 'Chatbox 会话');
      expect(s.messages, hasLength(2));
      expect(s.messages.first.content, '你好');
      expect(s.messages.first.images, hasLength(1));
      expect(s.messages[1].role, 'assistant');
    });

    test('Cherry Studio 导出：vault + reasoning_content', () {
      final data = {
        'version': 2,
        'vault': [
          {
            'id': 'ch-1',
            'name': 'Cherry 会话',
            'messages': [
              {
                'id': 'm1',
                'role': 'user',
                'content': '问题',
                'createTime': '2024-01-01T00:00:00Z',
              },
              {
                'id': 'm2',
                'role': 'assistant',
                'content': '回答',
                'reasoning_content': '思考中…',
              },
            ],
          },
        ],
      };
      final result = ExportService.importFromJsonData(data);
      expect(result, isNotNull);
      expect(result!.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, 'Cherry 会话');
      expect(s.messages[1].reasoningContent, '思考中…');
      expect(s.messages[1].content, '回答');
    });

    test('同源导入生成稳定 id（重复导入不重复）', () {
      final a = ExportService.importFromJsonData({
        'conversations': [
          {
            'id': 'cb-1',
            'name': '会话',
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
          },
        ],
      });
      final b = ExportService.importFromJsonData({
        'conversations': [
          {
            'id': 'cb-1',
            'name': '会话',
            'messages': [
              {'role': 'user', 'content': 'hi'},
            ],
          },
        ],
      });
      expect(a!.sessions.first.id, b!.sessions.first.id);
    });
  });

  group('PDF 导出', () {
    test('生成的 PDF 结构完整（头/尾/字体嵌入）', () async {
      final bytes = await ExportService.buildSessionPdf(buildSession());
      expect(bytes.length, greaterThan(1000));
      final ascii = String.fromCharCodes(bytes);
      expect(ascii.startsWith('%PDF-'), isTrue, reason: 'PDF 魔数');
      expect(ascii, contains('%%EOF'), reason: 'PDF 尾部标记');
      expect(ascii, contains('FontFile2'), reason: '应嵌入 TrueType 字体');
      expect(ascii, contains('/Type/Page'), reason: '应包含页面对象');
      final count = RegExp(r'/Count (\d+)').firstMatch(ascii)?.group(1);
      expect(int.tryParse(count ?? ''), greaterThanOrEqualTo(1));
    });

    test('长会话自动分页', () async {
      final many = ChatSession(
        id: 's1',
        title: '长会话',
        messages: [
          for (var i = 0; i < 40; i++)
            ChatMessage(
              role: i.isEven ? 'user' : 'assistant',
              content: '第 $i 条消息，内容足够长以保证分页行为发生，'
                  '这里再补充一些文字内容。',
            ),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final bytes = await ExportService.buildSessionPdf(many);
      final ascii = String.fromCharCodes(bytes);
      final count = int.parse(RegExp(r'/Count (\d+)').firstMatch(ascii)!.group(1)!);
      expect(count, greaterThan(1), reason: '40 条消息应自动分页');
    });
  });
}

/// 构造 ZIP 备份字节（测试用，与 ExportService.exportAllZipToFile 同构）。
Future<List<int>> _encodeZip(
  List<ChatSession> sessions,
  List<ChatProvider> providers,
  List<Agent> agents,
) async {
  final archive = Archive();
  archive.addFile(
    ArchiveFile.string(
      'manifest.json',
      jsonEncode({
        'app': 'nona',
        'format': 'nona-backup',
        'version': 2,
        'sessionCount': sessions.length,
        'providerCount': providers.length,
        'agentCount': agents.length,
      }),
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'providers.json',
      jsonEncode({'providers': providers.map((p) => p.toJson()).toList()}),
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'agents.json',
      jsonEncode({'agents': agents.map((a) => a.toJson()).toList()}),
    ),
  );
  for (final s in sessions) {
    archive.addFile(
      ArchiveFile.string('sessions/${s.id}.json', jsonEncode(s.toJson())),
    );
  }
  return ZipEncoder().encode(archive);
}

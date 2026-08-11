import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_session.dart';
import 'package:nona_chat/services/memory/memory_service.dart';
import 'package:nona_chat/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F4-3 记忆系统单测。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  group('记忆 CRUD 与作用域', () {
    test('按作用域增删查', () async {
      final svc = MemoryService();
      final m = await svc.add(
        scope: MemoryScope.agent,
        scopeRef: 'agent-1',
        content: '用户喜欢简洁的回答',
        category: 'preference',
      );
      expect(m, isNotNull);

      final agentMemories = await svc.list(
        scope: MemoryScope.agent,
        scopeRef: 'agent-1',
      );
      expect(agentMemories, hasLength(1));
      expect(agentMemories.first.category, 'preference');

      // 不同作用域隔离
      expect(await svc.list(scope: MemoryScope.global), isEmpty);

      await svc.remove(m!.id);
      expect(
        await svc.list(scope: MemoryScope.agent, scopeRef: 'agent-1'),
        isEmpty,
      );
    });

    test('同语义内容覆盖而非重复', () async {
      final svc = MemoryService();
      await svc.add(
        scope: MemoryScope.global,
        content: '用户在上海工作',
      );
      await svc.add(
        scope: MemoryScope.global,
        content: '用户在上海工作，喜欢咖啡',
      );
      final memories = await svc.list(scope: MemoryScope.global);
      expect(memories, hasLength(1), reason: '同语义记忆应合并覆盖');
      expect(memories.first.content, '用户在上海工作，喜欢咖啡');
    });

    test('上限 50 条时淘汰最旧非置顶', () async {
      final svc = MemoryService();
      for (var i = 0; i < 55; i++) {
        await svc.add(scope: MemoryScope.global, content: '记忆条目 $i');
      }
      final memories = await svc.list(scope: MemoryScope.global);
      expect(memories.length, lessThanOrEqualTo(MemoryService.kMaxMemories));
    });

    test('会话级记忆读写', () async {
      final svc = MemoryService();
      final session = ChatSession(
        id: 's1',
        title: 't',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await svc.setSessionMemory(session, '用户正在开发 Flutter 应用');
      expect(session.memory, contains('Flutter'));
    });

    test('buildInjection 顺序：会话 → Agent → 全局', () async {
      final svc = MemoryService();
      final text = svc.buildInjection(
        sessionMemory: '会话记忆A',
        agentMemories: [
          Memory(
            id: '1',
            scope: MemoryScope.agent,
            content: 'Agent记忆B',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        globalMemories: [
          Memory(
            id: '2',
            scope: MemoryScope.global,
            content: '全局记忆C',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );
      expect(text.indexOf('会话记忆A'), lessThan(text.indexOf('Agent记忆B')));
      expect(text.indexOf('Agent记忆B'), lessThan(text.indexOf('全局记忆C')));
    });

    test('超过 15 条记忆时 bigram 打分取 top', () async {
      final svc = MemoryService();
      final memories = [
        for (var i = 0; i < 20; i++)
          Memory(
            id: '$i',
            scope: MemoryScope.agent,
            content: '与咖啡相关的记忆条目 $i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];
      final text = svc.buildInjection(
        sessionMemory: '',
        agentMemories: memories,
        globalMemories: const [],
        query: '咖啡',
      );
      expect(text.contains('咖啡'), isTrue);
    });
  });

  group('自动提取', () {
    test('模型输出 JSON 解析与合并', () async {
      // 直接测内部解析：非 JSON 按行提取
      final items = MemoryService.parseExtraction(
        '[{"category":"fact","content":"用户会 Dart"},'
        '{"category":"preference","content":"喜欢暗色主题"},'
        '{"category":"todo","content":"明天提交代码"}]',
      );
      expect(items, hasLength(3));
      expect(items[0]['category'], 'fact');
      expect(items[1]['category'], 'preference');
      expect(items[2]['category'], 'todo');
    });

    test('全流程：mock 模型 → 自动提取入 Agent 记忆', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        req.response.headers.contentType = ContentType.json;
        req.response.write(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content':
                      '[{"category":"fact","content":"用户住在北京"}]',
                },
              },
            ],
          }),
        );
        await req.response.close();
      });
      final svc = MemoryService();
      final session = ChatSession(
        id: 's1',
        title: 't',
        messages: [
          for (var i = 0; i < 12; i++)
            ChatMessage(
              role: i.isEven ? 'user' : 'assistant',
              content: '第 $i 轮对话内容，讨论生活与工作安排。',
            ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final count = await svc.extractAndMerge(
        session,
        agentId: 'agent-1',
        settings: AppSettings(
          baseUrl: 'http://127.0.0.1:${server.port}',
          apiKey: 'k',
          model: 'm',
          chatAutoRetry: false,
        ),
      );
      expect(count, 1);
      final memories = await svc.list(
        scope: MemoryScope.agent,
        scopeRef: 'agent-1',
      );
      expect(memories, hasLength(1));
      expect(memories.first.content, contains('北京'));
      await server.close(force: true);
    });
  });
}

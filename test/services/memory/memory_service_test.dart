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

  group('P2 分级提取（规则路）', () {
    test('偏好命中：我喜欢/请以后 → P0 偏好候选并落库', () async {
      final svc = MemoryService();
      final count = await svc.extractMessage(
        text: '以后都给我用中文回复。',
        scope: MemoryScope.agent,
        scopeRef: 'agent-1',
      );
      expect(count, 1);
      final memories = await svc.list(
        scope: MemoryScope.agent,
        scopeRef: 'agent-1',
      );
      expect(memories, hasLength(1));
      expect(memories.first.category, 'preference');
      expect(memories.first.tags, contains('偏好'));
      expect(memories.first.content, contains('中文'));
      expect(memories.first.priority, MemoryPriority.auto);
    });

    test('纠正命中：不对/其实我是 → correction 候选，引导语被去掉', () async {
      final candidates = MemoryService.extractCandidates('不对，其实我是北京人');
      expect(candidates, hasLength(1));
      expect(candidates.first.priority, 'P0');
      expect(candidates.first.category, 'correction');
      expect(candidates.first.correction, isTrue);
      expect(candidates.first.content, '其实我是北京人');
      expect(candidates.first.content.length, lessThanOrEqualTo(100));

      final svc = MemoryService();
      await svc.extractMessage(
        text: '不对，其实我是北京人',
        scope: MemoryScope.global,
      );
      final memories = await svc.list(scope: MemoryScope.global);
      expect(memories, hasLength(1));
      expect(memories.first.category, 'correction');
      expect(memories.first.tags, ['纠正']);
      expect(memories.first.content, contains('北京'));
    });

    test('无关消息不产生任何提取', () async {
      final candidates = MemoryService.extractCandidates(
        '今天天气不错，我们去公园散步吧。',
      );
      expect(candidates, isEmpty);

      final svc = MemoryService();
      final count = await svc.extractMessage(
        text: '今天天气不错，我们去公园散步吧。',
        scope: MemoryScope.global,
      );
      expect(count, 0);
      expect(await svc.list(scope: MemoryScope.global), isEmpty);
    });

    test('enabled=false 直接返回，不提取不落库', () async {
      final svc = MemoryService();
      final count = await svc.extractMessage(
        text: '以后都不要给我推荐咖啡了',
        scope: MemoryScope.global,
        enabled: false,
      );
      expect(count, 0);
      expect(await svc.list(scope: MemoryScope.global), isEmpty);

      expect(await svc.extractWithLLM('我喜欢简洁回答', enabled: false), 0);
    });

    test('超 100 字句子被截断', () async {
      final long = '以后都${'字' * 120}';
      final candidates = MemoryService.extractCandidates(long);
      expect(candidates, hasLength(1));
      expect(candidates.first.content.length, lessThanOrEqualTo(100));
    });

    test('extraction prompt 资产可加载且包含分级要求', () async {
      final svc = MemoryService();
      final prompt = await svc.loadExtractionPrompt();
      expect(prompt, contains('P0'));
      expect(prompt, contains('correction'));
      expect(prompt, contains('100'));
    });
  });

  group('记忆 v2 数据层', () {
    test('tags / priority / use_count / last_used_at / history 往返', () async {
      final svc = MemoryService();
      final m = await svc.add(
        scope: MemoryScope.global,
        content: '用户喜欢咖啡',
        tags: const ['偏好', '生活'],
        priority: MemoryPriority.core,
      );
      expect(m, isNotNull);
      expect(m!.tags, ['偏好', '生活']);
      expect(m.priority, MemoryPriority.core);
      expect(m.useCount, 0);
      expect(m.lastUsedAt, isNull);
      expect(m.history, isEmpty);

      await svc.recordUse(m.id);
      final used = (await svc.list(scope: MemoryScope.global)).single;
      expect(used.useCount, 1);
      expect(used.lastUsedAt, isNotNull);

      // update 换内容 → 旧内容进 history，tags/priority 保留
      await svc.update(m.id, '用户喜欢手冲咖啡', 'preference');
      final updated = (await svc.list(scope: MemoryScope.global)).single;
      expect(updated.content, '用户喜欢手冲咖啡');
      expect(updated.tags, ['偏好', '生活']);
      expect(updated.priority, MemoryPriority.core);
      expect(updated.history, hasLength(1));
      expect(updated.history.first.content, '用户喜欢咖啡');
    });

    test('语义合并覆盖时旧内容进历史版本', () async {
      final svc = MemoryService();
      await svc.add(scope: MemoryScope.global, content: '用户在上海工作');
      await svc.add(
        scope: MemoryScope.global,
        content: '用户在上海工作，喜欢咖啡',
      );
      final memories = await svc.list(scope: MemoryScope.global);
      expect(memories, hasLength(1), reason: '同语义记忆应合并覆盖');
      expect(memories.first.content, '用户在上海工作，喜欢咖啡');
      expect(memories.first.history, hasLength(1));
      expect(memories.first.history.first.content, '用户在上海工作');
    });

    test('core 记忆不被自动合并降级为 auto', () async {
      final svc = MemoryService();
      await svc.add(
        scope: MemoryScope.global,
        content: '用户喜欢简洁的回答',
        priority: MemoryPriority.core,
      );
      await svc.add(
        scope: MemoryScope.global,
        content: '用户喜欢简洁的回答，不要寒暄',
      );
      final memories = await svc.list(scope: MemoryScope.global);
      expect(memories, hasLength(1));
      expect(memories.first.priority, MemoryPriority.core);
    });

    test('MemorySpaceConfig 默认预算 + fromRow/fromJson', () async {
      final cfg = MemorySpaceConfig.fromJson({
        'scope': 'agent',
        'scope_ref': 'a1',
        'max_items': 100,
        'max_inject_tokens': 500,
        'max_item_chars': 80,
        'extraction_interval': 5,
      });
      expect(cfg.scope, MemoryScope.agent);
      expect(cfg.scopeRef, 'a1');
      expect(cfg.maxItems, 100);
      expect(cfg.maxInjectTokens, 500);
      expect(cfg.maxItemChars, 80);
      expect(cfg.extractionInterval, 5);

      // 缺字段回落默认预算
      final defaults = MemorySpaceConfig.fromJson({'scope': 'global'});
      expect(defaults.maxItems, 200);
      expect(defaults.maxInjectTokens, 800);
      expect(defaults.maxItemChars, 100);
      expect(defaults.extractionInterval, 10);
    });
  });

  group('v1→v2 迁移', () {
    test('首启把 Agent.memories 写入 memories（scope=agent, priority=core）且幂等', () async {
      SharedPreferences.setMockInitialValues({
        'agents_initialized': true,
        'agents_default_migrated': true,
        'agents': jsonEncode([
          {
            'id': 'agent-1',
            'name': 'A',
            'memories': ['记忆一', '   '],
            'kbIds': <String>[],
          },
          {
            'id': 'agent-2',
            'name': 'B',
            'memories': ['记忆二'],
            'kbIds': <String>[],
          },
        ]),
      });
      final svc = MemoryService();
      await svc.migrateV1Memories();

      final m1 = await svc.list(scope: MemoryScope.agent, scopeRef: 'agent-1');
      expect(m1, hasLength(1), reason: '空串/空白条目跳过');
      expect(m1.first.content, '记忆一');
      expect(m1.first.priority, MemoryPriority.core);
      expect(m1.first.pinned, isFalse);

      final m2 = await svc.list(scope: MemoryScope.agent, scopeRef: 'agent-2');
      expect(m2, hasLength(1));
      expect(m2.first.content, '记忆二');
      expect(m2.first.priority, MemoryPriority.core);

      // 幂等：再次调用不重复写入
      await svc.migrateV1Memories();
      expect(
        await svc.list(scope: MemoryScope.agent, scopeRef: 'agent-1'),
        hasLength(1),
      );
      expect(
        await svc.list(scope: MemoryScope.agent, scopeRef: 'agent-2'),
        hasLength(1),
      );
    });
  });

  test('规则路：偏好命中生成 core 记忆', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(scope: MemoryScope.global, userText: '以后都用简洁风格回答，我喜欢简洁');
    expect(n, greaterThanOrEqualTo(1));
    final list = await svc.list(scope: MemoryScope.global);
    expect(list.any((m) => m.content.contains('简洁')), isTrue);
  });

  test('规则路：无关消息不产生记忆', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(scope: MemoryScope.global, userText: '今天天气怎么样？');
    expect(n, 0);
  });

  test('规则路：enabled=false 不提取', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(scope: MemoryScope.global, userText: '我喜欢简洁', enabled: false);
    expect(n, 0);
  });


  test('规则路：偏好命中生成 core 记忆', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(
        scope: MemoryScope.global, userText: '以后都用简洁风格回答，我喜欢简洁');
    expect(n, greaterThanOrEqualTo(1));
    final list = await svc.list(scope: MemoryScope.global);
    expect(list.any((m) => m.content.contains('简洁')), isTrue);
  });

  test('规则路：无关消息不产生记忆', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(
        scope: MemoryScope.global, userText: '今天天气怎么样？');
    expect(n, 0);
  });

  test('规则路：enabled=false 不提取', () async {
    final svc = MemoryService();
    final n = await svc.extractFromMessages(
        scope: MemoryScope.global, userText: '我喜欢简洁', enabled: false);
    expect(n, 0);
  });

test('注入：token 预算截断 + 统计', () async {
    final svc = MemoryService();
    await svc.add(scope: MemoryScope.global, content: '用户喜欢简洁的回答', category: 'preference', priority: MemoryPriority.core);
    await svc.add(scope: MemoryScope.global, content: '用户在杭州工作', category: 'fact');
    final text = svc.buildInjection(sessionMemory: '', agentMemories: [], globalMemories: await svc.list(scope: MemoryScope.global), query: '我喜欢简洁');
    expect(text, contains('简洁'));
    final stats = svc.lastInjectionStats;
    expect(stats, isNotNull);
    expect(stats!.injectedCount, greaterThanOrEqualTo(1));
    expect(stats.capacity, 800);
    await svc.recordUseLast();
  });
}

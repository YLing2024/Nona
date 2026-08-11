import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/services/world_book_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F5 世界书单测（内存库）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('条目 CRUD 与触发', () {
    test('保存/列出/删除', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: '王国的历史',
          keywords: ['王国'],
          content: '王国建立于千年之前，首都是翡翠城。',
          priority: 200,
        ),
      );
      final entries = await svc.list();
      expect(entries, hasLength(1));
      expect(entries.first.title, '王国的历史');
      expect(entries.first.priority, 200);

      await svc.delete(entries.first.id);
      expect(await svc.list(), isEmpty);
    });

    test('关键词触发：命中注入，未命中不注入', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: '龙',
          keywords: ['龙'],
          content: '龙是古老的生物，住在山间洞穴。',
          injectionPosition: 'after_system_prompt',
        ),
      );
      await svc.reload();

      final hit = svc.buildInjection([
        ChatMessage(role: 'user', content: '告诉我关于龙的事情'),
      ]);
      expect(hit.systemPromptAdd, contains('龙是古老的生物'));

      final miss = svc.buildInjection([
        ChatMessage(role: 'user', content: '今天天气如何'),
      ]);
      expect(miss.isEmpty, isTrue);
    });

    test('scan_depth 只扫描最近 N 条用户消息', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: '魔杖',
          keywords: ['魔杖'],
          content: '魔杖由冬青木制成。',
          scanDepth: 1,
        ),
      );
      await svc.reload();
      // 魔杖出现在 3 条之前的用户消息，scan_depth=1 不命中
      final miss = svc.buildInjection([
        ChatMessage(role: 'user', content: '魔杖是什么？'),
        ChatMessage(role: 'assistant', content: '回答。'),
        ChatMessage(role: 'user', content: '你好'),
      ]);
      expect(miss.isEmpty, isTrue);
      // 最近一条命中
      final hit = svc.buildInjection([
        ChatMessage(role: 'user', content: '你好'),
        ChatMessage(role: 'assistant', content: '回答。'),
        ChatMessage(role: 'user', content: '魔杖是什么？'),
      ]);
      expect(hit.isEmpty, isFalse);
    });

    test('常驻条目始终注入', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: '旁白',
          keywords: const [],
          content: '你是一名资深冒险向导。',
          constantActive: true,
          injectionPosition: 'before_system_prompt',
        ),
      );
      await svc.reload();
      final result = svc.buildInjection([
        ChatMessage(role: 'user', content: '你好'),
      ]);
      expect(result.systemPromptAdd, contains('资深冒险向导'));
    });

    test('注入预算 800 token 截断', () async {
      final svc = WorldBookService();
      for (var i = 0; i < 5; i++) {
        await svc.save(
          WorldBookEntry(
            id: '',
            title: '条目$i',
            keywords: ['k$i'],
            content: 'x' * 300,
            priority: 100 - i,
            injectionPosition: 'after_system_prompt',
          ),
        );
      }
      await svc.reload();
      final result = svc.buildInjection([
        ChatMessage(role: 'user', content: 'k1 k2 k3 k4'),
      ]);
      // 预算 800：最多注入约 2-3 条 300 字符条目
      expect(result.systemPromptAdd.length, lessThanOrEqualTo(1000));
      expect(result.systemPromptAdd, isNotEmpty);
    });

    test('消息数组插入：top_of_chat 与 bottom_of_chat', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: 'A',
          keywords: ['魔法'],
          content: '魔法世界入口。',
          injectionPosition: 'top_of_chat',
        ),
      );
      await svc.save(
        WorldBookEntry(
          id: '',
          title: 'B',
          keywords: ['魔法'],
          content: '结尾补充。',
          injectionPosition: 'bottom_of_chat',
        ),
      );
      await svc.reload();
      final result = svc.buildInjection([
        ChatMessage(role: 'user', content: '魔法是什么'),
      ]);
      expect(result.messageInserts, hasLength(2));
      expect(result.messageInserts.first.$2, '魔法世界入口。');
      expect(result.messageInserts.last.$2, '结尾补充。');
    });

    test('JSON 导入导出往返', () async {
      final svc = WorldBookService();
      final json = jsonEncode({
        'app': 'nona',
        'type': 'world_book',
        'entries': [
          {
            'title': '精灵',
            'keywords': ['精灵'],
            'content': '精灵擅长弓箭与魔法。',
            'priority': 150,
          },
        ],
      });
      final count = await svc.importJson(json);
      expect(count, 1);
      final entries = await svc.list();
      expect(entries.first.title, '精灵');

      final exported = await svc.exportJson();
      expect(exported, contains('精灵'));
    });

    test('大小写敏感开关', () async {
      final svc = WorldBookService();
      await svc.save(
        WorldBookEntry(
          id: '',
          title: 'T',
          keywords: ['Magic'],
          content: 'magic content',
          caseSensitive: true,
        ),
      );
      await svc.reload();
      final hit = svc.buildInjection([
        ChatMessage(role: 'user', content: 'Tell me about Magic'),
      ]);
      expect(hit.isEmpty, isFalse);
      final miss = svc.buildInjection([
        ChatMessage(role: 'user', content: 'tell me about magic'),
      ]);
      expect(miss.isEmpty, isTrue);
    });
  });
}

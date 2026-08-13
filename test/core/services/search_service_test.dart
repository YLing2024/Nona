import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/search_service.dart';

ChatSession makeSession(
  String id, {
  String title = '会话',
  List<ChatMessage> messages = const [],
  DateTime? updatedAt,
}) {
  return ChatSession(
    id: id,
    title: title,
    messages: messages,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  final sessions = [
    makeSession(
      's1',
      title: 'Flutter 开发',
      messages: [
        ChatMessage(role: 'user', content: '怎么配置多服务商？'),
        ChatMessage(role: 'assistant', content: '在设置中添加服务商即可。'),
      ],
      updatedAt: DateTime(2024, 1, 3),
    ),
    makeSession(
      's2',
      title: '闲聊',
      messages: [
        ChatMessage(role: 'user', content: '今天天气不错'),
        ChatMessage(role: 'assistant', content: '是的，服务商配置完成后就可以聊天了'),
      ],
      updatedAt: DateTime(2024, 1, 5),
    ),
    makeSession(
      's3',
      title: '空会话',
      messages: const [],
      updatedAt: DateTime(2024, 1, 2),
    ),
  ];

  group('SearchService.search', () {
    test('空查询返回空列表', () {
      expect(SearchService.search(sessions, ''), isEmpty);
      expect(SearchService.search(sessions, '   '), isEmpty);
    });

    test('大小写不敏感匹配消息内容', () {
      final hits = SearchService.search(sessions, '服务商');
      // s1 两条消息都命中 + s2 一条 = 3 条命中，覆盖 2 个会话
      expect(hits, hasLength(3));
      expect(hits.map((h) => h.session.id).toSet(), {'s1', 's2'});
    });

    test('命中位置正确', () {
      final hits = SearchService.search(sessions, '天气');
      expect(hits, hasLength(1));
      expect(hits.single.session.id, 's2');
      expect(hits.single.messageIndex, 0);
      expect(hits.single.matchStart, '今天天气不错'.indexOf('天气'));
    });

    test('按会话更新时间倒序排序', () {
      final hits = SearchService.search(sessions, '服务商');
      expect(hits.first.session.id, 's2', reason: 's2 更新（1-5）应排前');
      expect(hits.last.session.id, 's1');
    });

    test('标题命中优先于消息命中，且纯标题命中会产出条目', () {
      final extra = makeSession(
        's4',
        title: '服务商配置指南',
        messages: [ChatMessage(role: 'user', content: '随便聊聊')],
        updatedAt: DateTime(2024, 1, 1),
      );
      final all = [...sessions, extra];
      final hits = SearchService.search(all, '服务商');
      // 标题命中的 s4 置顶；纯标题命中指向首条用户消息
      expect(hits.first.session.id, 's4');
      expect(hits.first.messageIndex, 0);
    });

    test('标题命中但会话为空时不产出条目', () {
      final empty = makeSession('s-empty', title: '服务商相关');
      expect(SearchService.search([empty], '服务商'), isEmpty);
    });

    test('snippet 截断匹配位置前后文本', () {
      final long = makeSession(
        's5',
        messages: [
          ChatMessage(
            role: 'user',
            content: '${'a' * 100}目标关键词${'b' * 100}',
          ),
        ],
      );
      final hits = SearchService.search([long], '目标关键词');
      expect(hits.single.snippet(), startsWith('…'));
      expect(hits.single.snippet(), endsWith('…'));
      expect(hits.single.snippet(), contains('目标关键词'));
    });

    test('空消息不匹配', () {
      final s = makeSession('s6', messages: [ChatMessage(role: 'user', content: '')]);
      expect(SearchService.search([s], '服务商'), isEmpty);
    });
  });

  group('SearchService.highlight', () {
    test('命中段标记为 match', () {
      final spans = SearchService.highlight('配置服务商服务商配置', '服务商');
      expect(spans.where((s) => s.isMatch).length, 2);
      final texts = spans.map((s) => s.text).join('');
      expect(texts, '配置服务商服务商配置');
    });

    test('无命中返回单段非匹配', () {
      final spans = SearchService.highlight('hello world', 'xyz');
      expect(spans, hasLength(1));
      expect(spans.single.text, 'hello world');
      expect(spans.single.isMatch, isFalse);
    });

    test('大小写不敏感', () {
      final spans = SearchService.highlight('Hello HELLO hello', 'hello');
      expect(spans.where((s) => s.isMatch).length, 3);
    });

    test('空文本/空查询安全', () {
      final e1 = SearchService.highlight('', 'x');
      expect(e1, hasLength(1));
      expect(e1.single.text, '');
      final e2 = SearchService.highlight('abc', '');
      expect(e2.single.text, 'abc');
    });
  });

  group('SearchService.titleMatches', () {
    test('标题命中判断', () {
      expect(SearchService.titleMatches(sessions.first, 'flutter'), isTrue);
      expect(SearchService.titleMatches(sessions.first, '开发'), isTrue);
      expect(SearchService.titleMatches(sessions.first, '服务商'), isFalse);
    });
  });
}

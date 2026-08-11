import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/db/nona_database.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/models/chat_session.dart';
import 'package:nona_chat/services/search_service.dart';
import 'package:nona_chat/services/session_persistence.dart';
import 'package:nona_chat/services/session_persistence_sqlite.dart';

/// 可暂停的旧存储 fake：迁移期间的 readAll 被门闩挡住，
/// 用于构造「迁移未完成时并发读」竞态。
class _GatedLegacy implements SessionPersistence {
  final List<ChatSession> sessions;
  final Completer<void> gate = Completer<void>();
  bool readStarted = false;

  _GatedLegacy(this.sessions);

  @override
  Future<List<ChatSession>?> readAll() async {
    readStarted = true;
    await gate.future;
    return sessions;
  }

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {}

  @override
  Future<void> writeSession(ChatSession session) async {}

  @override
  Future<void> deleteSession(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaDatabase db;
  late SessionPersistenceSqlite persistence;

  ChatSession makeSession(String id, {String title = '会话', int messages = 2}) {
    return ChatSession(
      id: id,
      title: title,
      options: const ChatOptions(systemPrompt: '测试提示词'),
      messages: List.generate(
        messages,
        (i) => ChatMessage(
          role: i.isEven ? 'user' : 'assistant',
          content: '消息 $i 内容：Flutter 搜索索引测试',
        ),
      ),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
      pinned: id == 's-pin',
    );
  }

  setUp(() async {
    db = NonaDatabase();
    final opened = await db.open();
    if (opened == null) {
      // 原因需在 CI 日志可见（可 grep SKIP）
      // ignore: avoid_print
      print('SKIP: sqlite3 不可用（NonaDatabase.open 返回 null）');
      markTestSkipped('sqlite3 不可用');
    }
    persistence = SessionPersistenceSqlite(db);
  });

  tearDown(() => db.close());

  test('writeAll 后 readAll 完整读回（顺序/选项/置顶/时间）', () async {
    final sessions = [
      makeSession('s1', title: '会话一'),
      makeSession('s-pin', title: '置顶会话'),
    ];
    await persistence.writeAll(sessions);

    final loaded = await persistence.readAll();
    expect(loaded, isNotNull);
    expect(loaded!.length, 2);
    expect(loaded[0].id, 's1');
    expect(loaded[0].options.systemPrompt, '测试提示词');
    expect(loaded[1].pinned, isTrue);
    expect(loaded[1].createdAt, DateTime(2024, 1, 1));
    expect(loaded[1].messages[1].content, contains('搜索索引'));
  });

  test('writeSession 增量写入并可读回', () async {
    await persistence.writeAll([makeSession('s1')]);
    final updated = makeSession('s1', title: '更新后');
    updated.messages.add(ChatMessage(role: 'user', content: '追加的消息'));
    updated.updatedAt = DateTime(2024, 2, 1);
    await persistence.writeSession(updated);

    final loaded = await persistence.readAll();
    expect(loaded, hasLength(1));
    expect(loaded!.first.title, '更新后');
    expect(loaded.first.messages, hasLength(3));
    expect(loaded.first.updatedAt, DateTime(2024, 2, 1));
  });

  test('deleteSession 后不再返回', () async {
    await persistence.writeAll([makeSession('s1'), makeSession('s2')]);
    await persistence.deleteSession('s1');
    final loaded = await persistence.readAll();
    expect(loaded!.map((s) => s.id), ['s2']);
  });

  test('迁移进行中并发读全部等待迁移完成，不返回空列表', () async {
    final legacy = _GatedLegacy([makeSession('legacy-1', title: '旧会话')]);
    db.wasFresh = true;
    final p = SessionPersistenceSqlite(db, legacy: legacy);

    // 10 个并发首启动读，全部挂在迁移门闩上
    final futures = List.generate(10, (_) => p.readAll());
    // 让迁移真正开始（等一个微任务），再断言所有读都在等待
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(legacy.readStarted, isTrue, reason: '迁移应已开始');
    var resolved = 0;
    for (final f in futures) {
      unawaited(f.then((_) => resolved++));
    }
    await Future<void>.delayed(Duration.zero);
    expect(resolved, 0, reason: '迁移未完成时读必须阻塞');

    legacy.gate.complete();
    final results = await Future.wait(futures);
    for (final r in results) {
      expect(r, isNotNull, reason: '并发读不能返回空列表');
      expect(r!.single.id, 'legacy-1');
    }
  });

  test('空库 readAll 返回 null', () async {
    expect(await persistence.readAll(), isNull);
  });

  group('bigram 索引搜索', () {
    test('命中消息内容并携带会话与匹配位置', () async {
      await persistence.writeAll([
        makeSession('s1', title: 'Flutter 入门'),
        ChatSession(
          id: 's2',
          title: '无关会话',
          messages: [
            ChatMessage(role: 'user', content: '今天天气不错'),
          ],
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);

      final hits = await persistence.search('搜索索引');
      expect(hits, isNotEmpty);
      final hit = hits.first;
      expect(hit.session.id, 's1');
      expect(hit.message.content, contains('搜索索引'));
      expect(hit.messageIndex, greaterThanOrEqualTo(0));
      final pos = hit.message.content.indexOf('搜索索引');
      expect(pos, greaterThanOrEqualTo(0));
    });

    test('标题命中但消息未命中时定位到用户消息', () async {
      await persistence.writeAll([
        ChatSession(
          id: 's1',
          title: '特殊标题关键词xyz',
          messages: [
            ChatMessage(role: 'user', content: '第一条用户消息'),
            ChatMessage(role: 'assistant', content: '回复'),
          ],
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);
      final hits = await persistence.search('xyz');
      expect(hits, isNotEmpty);
      expect(hits.first.session.id, 's1');
      expect(hits.first.messageIndex, 0);
    });

    test('无命中返回空列表', () async {
      await persistence.writeAll([makeSession('s1')]);
      expect(await persistence.search('完全不存在的词'), isEmpty);
    });

    test('更新消息后索引同步更新', () async {
      await persistence.writeAll([makeSession('s1')]);
      final updated = makeSession('s1');
      updated.messages[0].content = '苹果香蕉橘子';
      updated.messages[1].content = '橙子葡萄';
      await persistence.writeSession(updated);

      expect(await persistence.search('苹果'), isNotEmpty);
      expect(await persistence.search('搜索索引'), isEmpty);
    });

    test('删除会话后索引同步清理', () async {
      await persistence.writeAll([makeSession('s1', title: '索引删除测试')]);
      await persistence.deleteSession('s1');
      expect(await persistence.search('索引删除'), isEmpty);
    });
  });

  group('bigrams', () {
    test('不足 2 字符返回空', () {
      expect(bigrams(''), isEmpty);
      expect(bigrams('a'), isEmpty);
    });

    test('字符 bigram 切分', () {
      expect(bigrams('ab'), ['ab']);
      expect(bigrams('abcd'), ['ab', 'bc', 'cd']);
      expect(bigrams('你好世界'), ['你好', '好世', '世界']);
    });
  });
}

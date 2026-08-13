import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/database/dao/session_dao.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/models/citation_source.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/models/chat_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late SessionDao dao;

  setUp(() async {
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    dao = SessionDao(db);
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  ChatSession makeSession(
    String id, {
    String title = '会话',
    bool pinned = false,
    DateTime? updatedAt,
    List<String> tags = const [],
    int? truncateIndex,
    List<ChatMessage>? messages,
    List<CompressedBlock> blocks = const [],
  }) {
    return ChatSession(
      id: id,
      title: title,
      options: const ChatOptions(systemPrompt: '提示词'),
      messages: messages ??
          [
            ChatMessage(role: 'user', content: '你好'),
            ChatMessage(role: 'assistant', content: '回复'),
          ],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 2),
      pinned: pinned,
      tags: tags,
      truncateIndex: truncateIndex,
      compressedBlocks: blocks,
    );
  }

  group('SessionDao v6/v7 字段往返', () {
    test('tags/truncateIndex 写入并读回', () async {
      await dao.writeAll([
        makeSession('s1', tags: ['工作', '研究'], truncateIndex: 3),
      ]);
      final loaded = await dao.readAll();
      final s = loaded!.single;
      expect(s.tags, ['工作', '研究']);
      expect(s.truncateIndex, 3);
      expect(s.options.systemPrompt, '提示词');
    });

    test('无标签会话 tags 为空列表', () async {
      await dao.writeAll([makeSession('s1')]);
      final loaded = await dao.readAll();
      expect(loaded!.single.tags, isEmpty);
    });

    test('citations 写入并读回（B-03）', () async {
      await dao.writeAll([
        ChatSession(
          id: 's1',
          title: '引用会话',
          messages: [
            ChatMessage(
              role: 'assistant',
              content: '回答[1]',
              citations: const [
                CitationSource(
                  index: 1,
                  title: '来源一',
                  url: 'https://example.com/a',
                  snippet: '摘要',
                  sourceName: '搜索',
                ),
              ],
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ]);
      final loaded = await dao.readAll();
      final msg = loaded!.single.messages.single;
      expect(msg.citations, hasLength(1));
      expect(msg.citations.first.title, '来源一');
      expect(msg.citations.first.index, 1);
    });

    test('压缩块往返（含消息 JSON）', () async {
      final s = makeSession(
        's1',
        blocks: [
          CompressedBlock(
            id: 'b1',
            startIndex: 0,
            endIndex: 1,
            summary: '摘要内容',
            messages: [
              ChatMessage(role: 'user', content: '被压缩的消息'),
            ],
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      await dao.writeAll([s]);
      final loaded = await dao.readAll();
      final block = loaded!.single.compressedBlocks.single;
      expect(block.summary, '摘要内容');
      expect(block.messages.single.content, '被压缩的消息');
    });
  });

  group('SessionDao 排序与写路径', () {
    test('writeAll 按传入顺序写入（sort_order=索引）', () async {
      await dao.writeAll([
        makeSession('a'),
        makeSession('b'),
      ]);
      final loaded = await dao.readAll();
      expect(loaded!.map((s) => s.id), ['a', 'b']);
    });

    test('writeSession 保留原 sort_order', () async {
      await dao.writeAll([makeSession('a')]);
      final updated = makeSession('a', title: '改名');
      await dao.writeSession(updated);
      final loaded = await dao.readAll();
      expect(loaded!.single.title, '改名');
      // 排序位置不变（写入第二条再验证）
      await dao.writeAll([
        makeSession('b'),
        makeSession('a'),
      ]);
      final re = await dao.readAll();
      expect(re!.map((s) => s.id), ['b', 'a']);
    });

    test('deleteSession 级联清理压缩块与索引', () async {
      final s = makeSession(
        's1',
        blocks: [
          CompressedBlock(
            id: 'b1',
            startIndex: 0,
            endIndex: 0,
            summary: 'x',
            messages: const [],
            createdAt: DateTime(2024),
          ),
        ],
      );
      await dao.writeAll([s]);
      await dao.deleteSession('s1');
      expect(await dao.readAll(), isNull);
      expect(await dao.search('你好'), isEmpty);
    });

    test('writeAll 覆盖旧数据（删除列表外会话）', () async {
      await dao.writeAll([makeSession('old')]);
      await dao.writeAll([makeSession('new')]);
      final loaded = await dao.readAll();
      expect(loaded!.map((s) => s.id), ['new']);
    });
  });

  group('SessionDao 搜索', () {
    test('中文 bigram 命中与定位', () async {
      await dao.writeAll([
        makeSession('s1', messages: [
          ChatMessage(role: 'user', content: '今天天气真不错'),
        ]),
      ]);
      final hits = await dao.search('天气');
      expect(hits, isNotEmpty);
      expect(hits.first.message.content, contains('天气'));
    });

    test('标题命中但无消息命中定位首条用户消息', () async {
      await dao.writeAll([
        makeSession('s1', title: '唯一标题关键词abc'),
      ]);
      final hits = await dao.search('abc');
      expect(hits, isNotEmpty);
      expect(hits.first.messageIndex, 0);
      expect(hits.first.message.role, 'user');
    });

    test('reindexMessage 更新单条索引', () async {
      await dao.writeAll([
        makeSession('s1', messages: [
          ChatMessage(role: 'user', content: '苹果'),
        ]),
      ]);
      expect(await dao.search('苹果'), isNotEmpty);
      // 同步更新正文再重建索引（reindexMessage 只负责索引）
      await dao.updateMessageIncremental(
        sessionId: 's1',
        messageIndex: 0,
        content: '香蕉',
      );
      await dao.reindexMessage(
        sessionId: 's1',
        messageId: 's1:0',
        content: '香蕉',
      );
      expect(await dao.search('苹果'), isEmpty);
      expect(await dao.search('香蕉'), isNotEmpty);
    });
  });
}

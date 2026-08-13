import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/database/dao/session_dao.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/checkpoint_service.dart';
import 'package:nona_chat/core/utils/checkpoint_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LatestWinsCheckpointWriter', () {
    test('多次 add 只保留最新值并串行写入', () async {
      final written = <String>[];
      final writer = LatestWinsCheckpointWriter<String>(
        (v) async {
          written.add(v);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        minInterval: const Duration(milliseconds: 5),
      );
      writer.add('a');
      writer.add('b');
      writer.add('c');
      await writer.barrier();
      expect(written, ['a', 'c'], reason: 'b 应被 c 覆盖（latest-wins）');
    });

    test('finalize 丢弃 pending 并写终态，终态不被中间值超越', () async {
      final written = <String>[];
      final writer = LatestWinsCheckpointWriter<String>(
        (v) async {
          written.add(v);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        minInterval: const Duration(milliseconds: 5),
      );
      writer.add('a');
      writer.add('b');
      await writer.finalize('final');
      expect(written.last, 'final');
      expect(written, isNot(contains('b')));
      // finalize 后不再接收
      writer.add('c');
      await writer.barrier();
      expect(written.last, 'final');
    });

    test('写入失败在 barrier 时抛出，后续写入仍继续', () async {
      var fail = true;
      final writer = LatestWinsCheckpointWriter<String>(
        (v) async {
          if (fail) throw StateError('write failed');
        },
        minInterval: const Duration(milliseconds: 1),
      );
      writer.add('a');
      await expectLater(writer.barrier(), throwsStateError);
      fail = false;
      writer.add('b');
      await writer.barrier();
    });
  });

  group('CheckpointService 落库', () {
    late NonaAppDatabase db;
    late CheckpointService service;

    setUp(() async {
      resetNonaDatabaseForTest();
      db = (await openNonaDatabase(forceMemory: true))!;
      service = CheckpointService(database: db);
    });

    tearDown(() async {
      await db.close();
      resetNonaDatabaseForTest();
    });

    test('checkpoint 增量写入消息内容与 streaming 标记', () async {
      final dao = SessionDao(db);
      // 先写入一条占位消息（模拟发送开始时 persist 的空消息）
      await dao.writeAll([
        _makeSession('s1', 1),
      ]);
      await dao.updateMessageIncremental(
        sessionId: 's1',
        messageIndex: 0,
        content: '',
        streamingState: 'streaming',
      );

      service.checkpoint(
        const MessageCheckpoint(
          sessionId: 's1',
          messageIndex: 0,
          content: '部分内容一',
          reasoning: '',
        ),
      );
      service.checkpoint(
        const MessageCheckpoint(
          sessionId: 's1',
          messageIndex: 0,
          content: '部分内容一二',
          reasoning: '思考中',
        ),
      );
      await service.finalizeMessage(
        const MessageCheckpoint(
          sessionId: 's1',
          messageIndex: 0,
          content: '最终内容',
          reasoning: '最终思考',
        ),
      );

      final loaded = await dao.readAll();
      final msg = loaded!.first.messages.first;
      expect(msg.content, '最终内容');
      expect(msg.reasoningContent, '最终思考');
      expect(msg.streamingState, isNull, reason: '终态应清 streaming 标记');
    });

    test('beginRun/endRun 状态机 + recover 把遗留 streaming 消息置 failed', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        _makeSession('s1', 1),
      ]);
      await dao.updateMessageIncremental(
        sessionId: 's1',
        messageIndex: 0,
        content: '断线前最后内容',
        streamingState: 'streaming',
      );

      // 模拟一次崩溃：直接运行 recover（不清 streaming）
      await service.recover();

      final loaded = await dao.readAll();
      final msg = loaded!.first.messages.first;
      expect(msg.failed, isTrue, reason: '遗留 streaming 消息应标记 failed 可重试');
      expect(msg.content, '断线前最后内容', reason: '内容保留为最后 checkpoint');
      expect(msg.streamingState, isNull);
    });
  });
}

ChatSession _makeSession(String id, int messageCount) {
  final now = DateTime(2024, 1, 1);
  return ChatSession(
    id: id,
    title: '会话',
    messages: List.generate(
      messageCount,
      (i) => ChatMessage(
        role: i.isEven ? 'user' : 'assistant',
        content: '消息 $i',
      ),
    ),
    createdAt: now,
    updatedAt: now,
  );
}

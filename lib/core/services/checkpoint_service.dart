import 'dart:async';

import '../utils/checkpoint_writer.dart';
import '../database/dao/generation_run_dao.dart';
import '../database/dao/session_dao.dart';
import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import '../utils/logger.dart';

/// 一次消息检查点快照。
class MessageCheckpoint {
  final String sessionId;
  final int messageIndex;
  final String content;
  final String reasoning;
  final String? toolCallsJson;

  /// 是否处于流式中间态（true=写 streaming 标记；false=终态清标记）。
  final bool streaming;

  const MessageCheckpoint({
    required this.sessionId,
    required this.messageIndex,
    required this.content,
    required this.reasoning,
    this.toolCallsJson,
    this.streaming = true,
  });
}

/// 流式生成检查点服务（B-06）。
///
/// - 流式期间每帧把「当前 content + reasoning + toolEvents」经
///   [LatestWinsCheckpointWriter] 增量落库（消息行 UPDATE，不重写整会话）；
/// - `GenerationRuns` 状态机（preparing→requesting→streaming→终态），
///   乐观并发 revision 校验；
/// - 启动恢复 [recover]：遗留 streaming 消息回填已存内容并置 failed。
class CheckpointService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;
  LatestWinsCheckpointWriter<MessageCheckpoint>? _writer;

  CheckpointService({NonaAppDatabase? database}) : _explicitDb = database;

  /// 解析数据库（实例内缓存）。
  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  LatestWinsCheckpointWriter<MessageCheckpoint> _writerFor(
    NonaAppDatabase db,
  ) =>
      _writer ??= LatestWinsCheckpointWriter(
        (c) => _persistCheckpoint(db, c),
        minInterval: const Duration(milliseconds: 250),
      );

  Future<void> _persistCheckpoint(
    NonaAppDatabase db,
    MessageCheckpoint c,
  ) async {
    await SessionDao(db).updateMessageIncremental(
      sessionId: c.sessionId,
      messageIndex: c.messageIndex,
      content: c.content,
      reasoningContent: c.reasoning,
      toolCallsJson: c.toolCallsJson,
      streamingState: c.streaming ? 'streaming' : null,
      clearStreamingState: !c.streaming,
    );
  }

  /// 流式检查点（latest-wins，250ms 节流）。
  void checkpoint(MessageCheckpoint c) {
    final db = _cachedDb;
    if (db == null) return;
    // writer 懒初始化：db 解析完成前不丢 checkpoint（用缓存 Future）
    _ensureWriter().then((w) {
      w.add(c);
    });
  }

  Future<LatestWinsCheckpointWriter<MessageCheckpoint>> _ensureWriter() async {
    final db = await _db;
    if (db == null) {
      throw StateError('数据库不可用，无法 checkpoint');
    }
    return _writerFor(db);
  }

  /// 终态写：丢弃中间 checkpoint，写入最终内容并清 streaming 标记。
  Future<void> finalizeMessage(MessageCheckpoint c) async {
    final db = await _db;
    if (db == null) return;
    try {
      await _writerFor(
        db,
      ).finalize(MessageCheckpoint(sessionId: c.sessionId, messageIndex: c.messageIndex, content: c.content, reasoning: c.reasoning, toolCallsJson: c.toolCallsJson, streaming: false));
    } catch (e) {
      Logger.error('ckpt', 'checkpoint 终态写失败（主路径 persist 仍会兜底）', e);
    }
  }

  /// 清除消息的 streaming 标记（失败/取消且无内容可写时）。
  Future<void> clearStreamingFlag({
    required String sessionId,
    required int messageIndex,
  }) async {
    final db = await _db;
    if (db == null) return;
    try {
      await _writerFor(db).barrier();
    } catch (_) {}
    try {
      await SessionDao(db).updateMessageIncremental(
        sessionId: sessionId,
        messageIndex: messageIndex,
        streamingState: null,
        clearStreamingState: true,
      );
    } catch (e) {
      Logger.error('ckpt', '清除 streaming 标记失败', e);
    }
  }

  /// 等待排空（应用退出前调用）。
  Future<void> barrier() async {
    final writer = _writer;
    if (writer == null) return;
    try {
      await writer.barrier();
    } catch (_) {}
  }

  // ---------------- GenerationRuns 状态机 ----------------

  /// 开始一次生成运行（preparing→requesting→streaming）。
  Future<String?> beginRun({String? sessionId, String? messageId}) async {
    final db = await _db;
    if (db == null) return null;
    try {
      final dao = GenerationRunDao(db);
      final id = await dao.create(sessionId: sessionId, messageId: messageId);
      await dao.transition(id, 'requesting', expectedStateRevision: 0);
      await dao.transition(id, 'streaming');
      return id;
    } catch (e) {
      Logger.error('ckpt', 'beginRun 失败', e);
      return null;
    }
  }

  /// 终态迁移（completed/failed/cancelled）。
  Future<void> endRun(String? runId, String state, {String? errorCode}) async {
    if (runId == null) return;
    final db = await _db;
    if (db == null) return;
    try {
      await GenerationRunDao(db).transition(runId, state, errorCode: errorCode);
    } catch (e) {
      Logger.error('ckpt', 'endRun 失败', e);
    }
  }

  /// 启动恢复：遗留 active run 置 interrupted；遗留 streaming 消息
  /// 回填已存内容、置 failed（可重试）。
  Future<void> recover() async {
    final db = await _db;
    if (db == null) return;
    try {
      final dao = SessionDao(db);
      // 1. 按 GenerationRuns 重置遗留运行
      final stale = await GenerationRunDao(db).resetStale();
      for (final run in stale) {
        final messageId = run.messageId;
        final sessionId = run.sessionId;
        if (messageId == null || sessionId == null) continue;
        // 解析 'sessionId:index'
        final sep = messageId.lastIndexOf(':');
        if (sep <= 0) continue;
        final index = int.tryParse(messageId.substring(sep + 1));
        if (index == null) continue;
        await dao.updateMessageIncremental(
          sessionId: sessionId,
          messageIndex: index,
          failed: true,
          streamingState: null,
          clearStreamingState: true,
        );
      }
      // 2. 兜底：直接扫描遗留 streaming 消息（防御 run 行缺失）
      final rows = await db
          .customSelect(
            "SELECT session_id, message_index FROM messages "
            "WHERE streaming_state = 'streaming'",
          )
          .get();
      for (final r in rows) {
        await dao.updateMessageIncremental(
          sessionId: r.data['session_id'] as String,
          messageIndex: r.data['message_index'] as int,
          failed: true,
          streamingState: null,
          clearStreamingState: true,
        );
      }
    } catch (e) {
      Logger.error('ckpt', '启动恢复失败（不影响启动）', e);
    }
  }
}

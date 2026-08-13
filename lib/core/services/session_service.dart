import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';
import '../utils/logger.dart';
import 'search_service.dart';
import 'session_persistence.dart';
import 'session_persistence_factory.dart';
import 'sync/change_log_service.dart';

/// 会话持久化服务。
///
/// 桌面/移动端基于 SQLite（会话/消息表 + bigram 搜索索引，
/// 失败时回退文件存储）；Web 端退化为 shared_preferences。
/// 首次启动发现旧版 shared_preferences 数据时自动迁移。
class SessionService {
  static const _kLegacySessions = 'chat_sessions';

  final SessionPersistence _persistence;

  /// 持久化串行链：避免并发读改写丢更新/乱序覆盖。
  Future<void>? _persistChain;

  /// X-04：变更日志（增量同步埋点；测试可注入）。
  final ChangeLogService _changeLog;

  SessionService({SessionPersistence? persistence, ChangeLogService? changeLog})
      : _persistence = persistence ?? createSessionPersistence(),
        _changeLog = changeLog ?? ChangeLogService();

  Future<List<ChatSession>> load() async {
    final stored = await _persistence.readAll();
    if (stored != null) return stored;

    final legacy = await _loadLegacy();
    if (legacy != null) {
      await _persistence.writeAll(legacy);
      await _clearLegacy();
      return legacy;
    }
    return [];
  }

  /// 全量保存（覆盖全部会话）。
  ///
  /// 仅用于迁移 / 导入 / 恢复等一次性全量场景；
  /// 聊天管线请走 [saveSession] / [deleteById] 增量路径，
  /// 避免每次发送都触发全表 DELETE + 全量重建索引。
  /// 写入按调用顺序串行执行，防止并发覆盖。
  ///
  /// 单次写入失败不会污染持久化链：错误被记录并跳过，
  /// 后续保存照常执行（避免一次 SQLITE_BUSY/磁盘错误导致
  /// 本进程内所有后续保存永久失效）。
  Future<void> saveAll(List<ChatSession> sessions) {
    // X-04：变更日志（全量保存视为各会话 upsert）
    for (final s in sessions) {
      unawaited(_changeLog.record(entity: 'session', entityId: s.id, op: 'upsert'));
    }
    return _enqueue(() => _persistence.writeAll(sessions));
  }

  /// 增量保存单个会话（其余会话不动）。
  Future<void> saveSession(ChatSession session) {
    unawaited(_changeLog.record(entity: 'session', entityId: session.id, op: 'upsert'));
    return _enqueue(() => _persistence.writeSession(session));
  }

  /// 删除单个会话。
  Future<void> delete(ChatSession session) {
    return deleteById(session.id);
  }

  /// 按 id 删除单个会话（其余会话不动）。
  Future<void> deleteById(String sessionId) {
    unawaited(_changeLog.record(entity: 'session', entityId: sessionId, op: 'delete'));
    return _enqueue(() => _persistence.deleteSession(sessionId));
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = (_persistChain ?? Future.value()).then((_) async {
      try {
        await action();
      } catch (e) {
        Logger.error('session', '会话持久化失败，本次写入已跳过', e);
      }
    });
    _persistChain = next;
    return next;
  }

  /// 全文搜索：底层存储支持索引时走 bigram 索引，
  /// 否则回退内存全量扫描。
  Future<List<MessageSearchHit>> search(String query, {int limit = 50}) async {
    final indexed = _persistence as IndexedSessionSearch?;
    if (indexed != null) {
      return indexed.search(query, limit: limit);
    }
    return SearchService.search(await load(), query);
  }

  /// 读取旧版 shared_preferences 中保存的全部会话；不存在返回 null。
  Future<List<ChatSession>?> _loadLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLegacySessions);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// 迁移成功后清理旧键，避免下次重复迁移。
  Future<void> _clearLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLegacySessions);
  }
}

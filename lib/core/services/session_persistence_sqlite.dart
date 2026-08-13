import 'dart:async';

import '../database/dao/session_dao.dart';
import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import '../models/chat_session.dart';
import '../utils/logger.dart';
import 'search_service.dart';
import 'session_persistence.dart';
import 'session_persistence_io.dart';

/// 旧文件存储迁移的三态。
enum _MigrationState { notStarted, running, done }

/// SQLite 会话持久化（drift 实现）：会话/消息表 + bigram 倒排索引。
///
/// - 首次使用自动从旧文件存储迁移（保留原文件作备份）；
/// - 数据库不可用（无原生 sqlite3 库的环境，如部分测试环境）时
///   自动回退到文件存储（其内部再退化内存）；
/// - 实现 [IndexedSessionSearch]：消息全文搜索走 bigram 索引。
class SessionPersistenceSqlite
    implements SessionPersistence, IndexedSessionSearch {
  /// 显式注入的数据库实例（测试用）；null 时懒加载工厂单例。
  final NonaAppDatabase? _explicitDb;

  /// 回退存储（数据库不可用时）。
  SessionPersistence? _fallback;

  /// 旧文件存储（迁移数据源）；测试可注入受控 fake。
  final SessionPersistence? _legacy;

  /// 迁移状态：三态避免并发首启动时重复迁移 / 读空库。
  _MigrationState _migration = _MigrationState.notStarted;

  /// 迁移进行中时，并发调用方等待其完成。
  Completer<void>? _migrationCompleter;

  SessionDao? _dao;

  SessionPersistenceSqlite(
    this._explicitDb, {
    SessionPersistence? legacy,
  }) : _legacy = legacy;

  /// 懒加载版本：数据库经 [openNonaDatabase] 单例打开。
  SessionPersistenceSqlite.lazy({SessionPersistence? legacy})
      : _explicitDb = null,
        _legacy = legacy;

  Future<NonaAppDatabase?> _resolveDb() async =>
      _explicitDb ?? await openNonaDatabase();

  SessionDao _daoFor(NonaAppDatabase db) => _dao ??= SessionDao(db);

  Future<SessionPersistence> _active() async {
    final db = await _resolveDb();
    if (db == null) {
      _fallback ??= SessionPersistenceIo();
      return _fallback!;
    }
    await _ensureMigrated(db);
    return this;
  }

  /// 仅在新创建的数据库上执行一次旧文件存储迁移。
  ///
  /// 以 `wasFresh`（数据库文件本次打开前不存在）为准而非「表为空」：
  /// 旧逻辑在每次启动都检查空表，用户删光全部会话后重启会被残留的
  /// 文件存储重新导入，造成「已删除会话复活」。迁移后不清理旧文件，
  /// 但新库不再重复导入。
  ///
  /// 并发安全：首个调用方执行迁移，其余调用方等待同一个 completer，
  /// 不会出现「跳过迁移直接读空库返回空列表」的竞态。
  Future<void> _ensureMigrated(NonaAppDatabase db) async {
    if (_migration == _MigrationState.done) return;
    if (_migration == _MigrationState.running) {
      await _migrationCompleter!.future;
      return;
    }
    _migration = _MigrationState.running;
    final completer = _migrationCompleter = Completer<void>();
    try {
      if (db.wasFresh) {
        final count = await _daoFor(db).readAll();
        if (count == null || count.isEmpty) {
          final file = _legacy ?? SessionPersistenceIo();
          final stored = await file.readAll();
          if (stored != null && stored.isNotEmpty) {
            await _daoFor(db).writeAll(stored);
          }
        }
      }
      _migration = _MigrationState.done;
    } catch (e) {
      Logger.warn('session', 'SQLite file migration failed (skipped)');
      Logger.error('session', 'migration failed', e);
      // 失败后复位，允许下次调用重试迁移
      _migration = _MigrationState.notStarted;
    } finally {
      completer.complete();
    }
  }

  @override
  Future<List<ChatSession>?> readAll() async {
    final active = await _active();
    if (active != this) return active.readAll();
    return _daoFor((await _resolveDb())!).readAll();
  }

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    final active = await _active();
    if (active != this) return active.writeAll(sessions);
    await _daoFor((await _resolveDb())!).writeAll(sessions);
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    final active = await _active();
    if (active != this) return active.writeSession(session);
    await _daoFor((await _resolveDb())!).writeSession(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    final active = await _active();
    if (active != this) return active.deleteSession(id);
    await _daoFor((await _resolveDb())!).deleteSession(id);
  }

  // ---------------- 索引搜索 ----------------

  @override
  Future<List<MessageSearchHit>> search(
    String query, {
    int limit = 50,
  }) async {
    final db = await _resolveDb();
    if (db == null) {
      // 数据库不可用时回退文件存储做内存扫描，
      // 避免「存储里明明有会话却搜不到」的假空结果。
      final fallback = await _active();
      final all = await fallback.readAll();
      final hits = SearchService.search(all ?? const [], query);
      return hits.take(limit).toList();
    }
    return _daoFor(db).search(query, limit: limit);
  }
}

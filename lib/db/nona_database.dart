import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';
import 'db.dart' show Database, sqlite3;
import 'env.dart' show isFlutterTest;
import 'fs.dart' show fileExists, pathSeparator;
import 'schema_migrations.dart';

/// SQLite 数据库封装（会话 / 消息 / bigram 搜索索引）。
///
/// - 数据库文件位于应用支持目录 `nona.db`；
/// - 环境不可用（如纯 Dart 测试无插件/无 sqlite3 动态库）时自动降级为
///   进程内内存数据库；仍失败时标记 [available] 为 false，
///   由持久化层回退到文件/内存存储；
/// - 打开结果按 Future 记忆化：并发首调共享同一次打开，避免
///    `_attempted` 竞态导致永久分叉到文件存储。
class NonaDatabase {
  Database? _db;
  bool _attempted = false;
  Future<Database?>? _opening;

  /// 数据库文件是否为本次打开时新建（旧版文件存储迁移仅在新库上执行，
  /// 防止「删光会话后重启被旧文件复活」）。
  bool wasFresh = false;

  /// 数据库是否可用。
  bool get available => _db != null;

  /// 打开数据库（幂等，并发调用共享同一次打开）；失败时 [available] 为 false。
  Future<Database?> open() {
    if (_db != null) return Future.value(_db);
    return _opening ??= _openOnce();
  }

  Future<Database?> _openOnce() async {
    if (_attempted) return null;
    _attempted = true;
    try {
      Database db;
      String? dbPath;
      try {
        // 测试环境（FakeAsync 中 platform channel 永不完成）直接走内存库
        if (isFlutterTest) {
          throw StateError('测试环境，使用内存数据库');
        }
        final support = await getApplicationSupportDirectory();
        dbPath = '${support.path}$pathSeparator${'nona.db'}';
        wasFresh = !fileExists(dbPath);
        db = sqlite3.open(dbPath);
      } catch (_) {
        // 无插件环境（测试/Web）：内存数据库
        db = sqlite3.openInMemory();
        wasFresh = false;
      }
      _initSchema(db);
      _db = db;
      return db;
    } catch (e) {
      Logger.warn('db', 'SQLite 不可用，回退文件存储');
      Logger.error('db', '打开数据库失败', e);
      return null;
    }
  }

  void _initSchema(Database db) {
    db.execute('PRAGMA foreign_keys = ON;');
    // WAL 允许并发读；busy_timeout 让并发写等待而非立刻 SQLITE_BUSY
    try {
      db.execute('PRAGMA journal_mode = WAL;');
    } catch (_) {}
    try {
      db.execute('PRAGMA busy_timeout = 5000;');
    } catch (_) {}
    db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        options_json TEXT NOT NULL,
        provider_id TEXT,
        model_id TEXT,
        agent_id TEXT,
        pinned INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        message_index INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        reasoning_content TEXT NOT NULL DEFAULT '',
        images_json TEXT NOT NULL DEFAULT '[]',
        documents_json TEXT NOT NULL DEFAULT '[]',
        alternatives_json TEXT NOT NULL DEFAULT '[]',
        tool_call_id TEXT,
        tool_calls_json TEXT,
        interrupted INTEGER NOT NULL DEFAULT 0,
        failed INTEGER NOT NULL DEFAULT 0,
        prompt_tokens INTEGER,
        completion_tokens INTEGER,
        elapsed_ms INTEGER,
        provider_name TEXT,
        model_id TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_messages_session
        ON messages(session_id, message_index);
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS message_tokens (
        token TEXT NOT NULL,
        session_id TEXT NOT NULL,
        message_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (token, message_id, position)
      );
    ''');
    // 增量 schema 升级：按注册表顺序执行（见 schema_migrations.dart）
    applySchemaMigrations(db);
  }

  void close() {
    _db?.dispose();
    _db = null;
    _opening = null;
  }
}

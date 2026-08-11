import '../utils/logger.dart';
import 'db.dart' show Database;

/// 单步 schema 迁移：把数据库从版本 `i` 升级到 `i + 1`。
typedef SchemaMigration = void Function(Database db);

/// 迁移注册表：数组下标即「目标版本 - 1」，按序执行。
///
/// 新增表/列时在末尾追加一个迁移函数并同步更新版本预期
/// （[applySchemaMigrations] 执行后 user_version == 本表长度）。
const List<SchemaMigration> kSchemaMigrations = [
  addMessageDetailColumns, // v0 → v1
  addCompactionAndUsage, // v1 → v2
  addKnowledgeBase, // v2 → v3
  addMemories, // v3 → v4
  addWorldBook, // v4 → v5
  addMemoryV2, // v5 → v6
];

/// 从当前 user_version 顺序执行剩余迁移，全部完成后更新版本号。
///
/// 单个迁移失败不中断后续（记日志），避免一次损坏阻塞全部升级。
void applySchemaMigrations(Database db) {
  try {
    final version =
        db.select('PRAGMA user_version').first.columnAt(0) as int;
    for (var v = version; v < kSchemaMigrations.length; v++) {
      kSchemaMigrations[v](db);
      db.execute('PRAGMA user_version = ${v + 1}');
    }
  } catch (e) {
    Logger.warn('db', 'schema 迁移失败（写入将回退）');
    Logger.error('db', 'applySchemaMigrations 失败', e);
  }
}

/// v0 → v1：早期版本可能建过缺少新列的 `messages` 表
/// （CREATE TABLE IF NOT EXISTS 不会补列），旧库上直接 INSERT
/// 会抛「no column named ...」。逐列检查 PRAGMA table_info 补缺失列。
void addMessageDetailColumns(Database db) {
  final columns = db
      .select('PRAGMA table_info(messages)')
      .map((r) => r['name'] as String)
      .toSet();
  const additions = <String, String>{
    'documents_json': "TEXT NOT NULL DEFAULT '[]'",
    'alternatives_json': "TEXT NOT NULL DEFAULT '[]'",
    'tool_call_id': 'TEXT',
    'tool_calls_json': 'TEXT',
  };
  for (final e in additions.entries) {
    if (columns.contains(e.key)) continue;
    try {
      db.execute('ALTER TABLE messages ADD COLUMN ${e.key} ${e.value}');
    } catch (_) {
      // 并发迁移时可能已被补上，忽略
    }
  }
}

/// v1 → v2：摘要压缩（F3-1）+ 成本统计（F3-2）+ 图片生成历史（F1-4）。
void addCompactionAndUsage(Database db) {
  _addColumnIfMissing(db, 'sessions', 'summary', "TEXT NOT NULL DEFAULT ''");
  _addColumnIfMissing(db, 'sessions', 'summary_tokens', 'INTEGER');
  _addColumnIfMissing(db, 'messages', 'sent_at', 'INTEGER');
  db.execute('''
    CREATE TABLE IF NOT EXISTS compressed_blocks (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      start_index INTEGER NOT NULL,
      end_index INTEGER NOT NULL,
      summary TEXT NOT NULL,
      messages_json TEXT NOT NULL DEFAULT '[]',
      created_at INTEGER NOT NULL
    );
  ''');
  db.execute(
    'CREATE INDEX IF NOT EXISTS idx_blocks_session '
    'ON compressed_blocks(session_id, start_index)',
  );
  db.execute('''
    CREATE TABLE IF NOT EXISTS usage_daily (
      model_id TEXT NOT NULL,
      provider_name TEXT NOT NULL,
      date TEXT NOT NULL,
      prompt_tokens INTEGER NOT NULL DEFAULT 0,
      completion_tokens INTEGER NOT NULL DEFAULT 0,
      calls INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (model_id, provider_name, date)
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS gen_media (
      id TEXT PRIMARY KEY,
      prompt TEXT NOT NULL,
      model_id TEXT NOT NULL,
      path TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'image',
      created_at INTEGER NOT NULL
    );
  ''');
}

/// v2 → v3：知识库 SQLite 化（F4-1）。
void addKnowledgeBase(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS kb_libraries (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS kb_documents (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'text',
      library_id TEXT NOT NULL DEFAULT 'default',
      embedding_model TEXT,
      chunk_count INTEGER NOT NULL DEFAULT 0,
      enabled INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS kb_chunks (
      id TEXT PRIMARY KEY,
      doc_id TEXT NOT NULL REFERENCES kb_documents(id) ON DELETE CASCADE,
      position INTEGER NOT NULL DEFAULT 0,
      text TEXT NOT NULL,
      tokens INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS kb_bigrams (
      bigram TEXT NOT NULL,
      chunk_id TEXT NOT NULL REFERENCES kb_chunks(id) ON DELETE CASCADE,
      PRIMARY KEY (bigram, chunk_id)
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS kb_vectors (
      chunk_id TEXT PRIMARY KEY REFERENCES kb_chunks(id) ON DELETE CASCADE,
      dim INTEGER NOT NULL,
      vec BLOB NOT NULL
    );
  ''');
  db.execute('CREATE INDEX IF NOT EXISTS idx_kb_chunks_doc ON kb_chunks(doc_id, position)');
  db.execute('CREATE INDEX IF NOT EXISTS idx_kb_bigrams_key ON kb_bigrams(bigram)');
  db.execute('CREATE INDEX IF NOT EXISTS idx_kb_docs_lib ON kb_documents(library_id)');
  // 默认库（全局）
  try {
    db.execute(
      'INSERT OR IGNORE INTO kb_libraries (id, name, created_at, updated_at) '
      "VALUES ('default', '默认库', ?, ?)",
      [DateTime.now().millisecondsSinceEpoch, DateTime.now().millisecondsSinceEpoch],
    );
  } catch (_) {}
}

/// v3 → v4：记忆系统（F4-3）。
void addMemories(Database db) {
  _addColumnIfMissing(db, 'sessions', 'memory', "TEXT NOT NULL DEFAULT ''");
  db.execute('''
    CREATE TABLE IF NOT EXISTS memories (
      id TEXT PRIMARY KEY,
      scope TEXT NOT NULL CHECK(scope IN ('global','agent','session')),
      scope_ref TEXT,
      content TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'fact',
      pinned INTEGER NOT NULL DEFAULT 0,
      source_message_id TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('CREATE INDEX IF NOT EXISTS idx_memories_scope ON memories(scope, scope_ref)');
}

/// v4 → v5：世界书（F5）。
void addWorldBook(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS world_book_entries (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      keywords_json TEXT NOT NULL DEFAULT '[]',
      content TEXT NOT NULL,
      priority INTEGER NOT NULL DEFAULT 100,
      scan_depth INTEGER NOT NULL DEFAULT 1,
      case_sensitive INTEGER NOT NULL DEFAULT 0,
      injection_position TEXT NOT NULL DEFAULT 'top_of_chat',
      role TEXT NOT NULL DEFAULT 'user',
      constant_active INTEGER NOT NULL DEFAULT 0,
      scope TEXT NOT NULL DEFAULT 'global',
      scope_ref TEXT,
      enabled INTEGER NOT NULL DEFAULT 1
    );
  ''');
}

/// v5 → v6：记忆 v2 数据层（F4-3 升级）。
///
/// - memories 表补 v2 列（幂等 [addMemoryV2]）；
/// - 新增 memory_spaces（作用域预算，PK(scope, scope_ref) 区分空间）；
/// - 新增 memory_state（增量提取游标：session_id → last_index）。
void addMemoryV2(Database db) {
  _addColumnIfMissing(db, 'memories', 'tags_json', "TEXT DEFAULT '[]'");
  _addColumnIfMissing(db, 'memories', 'priority', "TEXT DEFAULT 'auto'");
  _addColumnIfMissing(db, 'memories', 'use_count', 'INTEGER DEFAULT 0');
  _addColumnIfMissing(db, 'memories', 'last_used_at', 'INTEGER');
  _addColumnIfMissing(db, 'memories', 'history_json', "TEXT DEFAULT '[]'");
  db.execute('''
    CREATE TABLE IF NOT EXISTS memory_spaces (
      scope TEXT NOT NULL,
      scope_ref TEXT NOT NULL DEFAULT '',
      max_items INTEGER NOT NULL DEFAULT 200,
      max_inject_tokens INTEGER NOT NULL DEFAULT 800,
      max_item_chars INTEGER NOT NULL DEFAULT 100,
      extraction_interval INTEGER NOT NULL DEFAULT 10,
      PRIMARY KEY (scope, scope_ref)
    );
  ''');
  db.execute('''
    CREATE TABLE IF NOT EXISTS memory_state (
      session_id TEXT PRIMARY KEY,
      last_index INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL
    );
  ''');
}

/// ALTER TABLE 加列辅助（幂等）。
void _addColumnIfMissing(Database db, String table, String name, String ddl) {
  final columns = db
      .select('PRAGMA table_info($table)')
      .map((r) => r['name'] as String)
      .toSet();
  if (columns.contains(name)) return;
  try {
    db.execute('ALTER TABLE $table ADD COLUMN $name $ddl');
  } catch (_) {
    // 并发迁移时可能已被补上，忽略
  }
}

import 'package:drift/drift.dart';

import 'nona_tables.dart';

part 'nona_app_database.g.dart';

/// Nona 主数据库（drift 化）。
///
/// - schemaVersion = 7；
/// - 旧库（user_version ≤ 5）在 [onUpgrade] 中先执行旧版数组式迁移
///   （[kLegacyMigrations] 移植，幂等），再执行 v6/v7 增量步骤；
/// - 新库由 drift `createAll` 直接建全量 v7 schema；
/// - 打开/降级/回退语义见 [NonaDatabaseFactory]（core/database/nona_db_factory*）。
@DriftDatabase(
  tables: [
    Sessions,
    Messages,
    MessageTokens,
    CompressedBlocks,
    UsageDaily,
    GenMedia,
    KbLibraries,
    KbDocuments,
    KbChunks,
    KbBigrams,
    KbVectors,
    Memories,
    WorldBookEntries,
    WorldBooks,
    ProviderGroups,
    SearchKeys,
    QuickPhrases,
    InstructionInjections,
    Tags,
    GenerationRuns,
    ChangeLog,
    RouteEvents,
    Workflows,
    WorkflowRuns,
  ],
)
class NonaAppDatabase extends _$NonaAppDatabase {
  NonaAppDatabase(super.e);

  /// 数据库文件是否为本次打开时新建（旧文件存储迁移仅在新库上执行，
  /// 防止「删光会话后重启被旧文件复活」）。
  bool wasFresh = false;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: _onUpgrade,
    beforeOpen: (details) async {
      await _ensurePragmas();
    },
  );

  /// PRAGMA：外键 / WAL / busy_timeout。
  Future<void> _ensurePragmas() async {
    await customStatement('PRAGMA foreign_keys = ON');
    try {
      await customSelect('PRAGMA journal_mode = WAL').get();
    } catch (_) {}
    try {
      await customStatement('PRAGMA busy_timeout = 5000');
    } catch (_) {}
  }

  /// 升级入口：旧库先跑旧版数组迁移（带幂等修复），再执行增量步骤。
  Future<void> _onUpgrade(Migrator m, int from, int to) async {
    if (from < 6) {
      await _runLegacyMigrations();
    }
    if (to >= 6 && from < 6) {
      await m.addColumn(sessions, sessions.tagsJson);
      await m.addColumn(sessions, sessions.truncateIndex);
      await m.addColumn(messages, messages.partsJson);
      await m.addColumn(messages, messages.citationsJson);
      await m.addColumn(messages, messages.toolStepsJson);
      await m.addColumn(messages, messages.streamingState);
      await m.addColumn(worldBookEntries, worldBookEntries.useRegex);
      await m.addColumn(worldBookEntries, worldBookEntries.bookId);
      await m.addColumn(worldBookEntries, worldBookEntries.injectDepth);
      await m.createTable(worldBooks);
      // 旧版索引兜底修复（旧库可能缺索引）
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_messages_session '
        'ON messages(session_id, message_index)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_blocks_session '
        'ON compressed_blocks(session_id, start_index)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kb_chunks_doc '
        'ON kb_chunks(doc_id, position)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kb_bigrams_key '
        'ON kb_bigrams(bigram)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kb_docs_lib '
        'ON kb_documents(library_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_memories_scope '
        'ON memories(scope, scope_ref)',
      );
    }
    if (to >= 7 && from < 7) {
      await m.createTable(providerGroups);
      await m.createTable(searchKeys);
      await m.createTable(quickPhrases);
      await m.createTable(instructionInjections);
      await m.createTable(tags);
      await m.createTable(generationRuns);
      await m.createTable(changeLog);
      await m.createTable(routeEvents);
      await m.createTable(workflows);
      await m.createTable(workflowRuns);
    }
  }

  /// 旧版数组式迁移（v0→v5，从 schema_migrations.dart 移植为异步 drift API）。
  /// 逐条幂等：补列前查 PRAGMA table_info，建表带 IF NOT EXISTS。
  Future<void> _runLegacyMigrations() async {
    final version = await _userVersion();
    for (var v = version; v < kLegacyMigrations.length; v++) {
      await kLegacyMigrations[v](this);
      await customStatement('PRAGMA user_version = ${v + 1}');
    }
  }

  Future<int> _userVersion() async {
    final row = await customSelect('PRAGMA user_version').get();
    return row.first.data.values.first as int;
  }

  /// 确保默认知识库存在（旧版迁移在建表时插入；drift 新库需要补）。
  Future<void> ensureDefaultLibrary() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      'INSERT OR IGNORE INTO kb_libraries (id, name, created_at, updated_at) '
      "VALUES ('default', '默认库', ?, ?)",
      [now, now],
    );
  }
}

/// 旧迁移步骤：把数据库从版本 `i` 升级到 `i + 1`。
typedef LegacyMigration = Future<void> Function(NonaAppDatabase db);

/// 迁移注册表：数组下标即「目标版本 - 1」，按序执行。
const List<LegacyMigration> kLegacyMigrations = [
  _addMessageDetailColumns, // v0 → v1
  _addCompactionAndUsage, // v1 → v2
  _addKnowledgeBase, // v2 → v3
  _addMemories, // v3 → v4
  _addWorldBook, // v4 → v5
];

/// v0 → v1：早期版本可能建过缺少新列的 `messages` 表。
Future<void> _addMessageDetailColumns(NonaAppDatabase db) async {
  final columns = await _tableColumns(db, 'messages');
  const additions = <String, String>{
    'documents_json': "TEXT NOT NULL DEFAULT '[]'",
    'alternatives_json': "TEXT NOT NULL DEFAULT '[]'",
    'tool_call_id': 'TEXT',
    'tool_calls_json': 'TEXT',
  };
  for (final e in additions.entries) {
    if (columns.contains(e.key)) continue;
    try {
      await db.customStatement(
        'ALTER TABLE messages ADD COLUMN ${e.key} ${e.value}',
      );
    } catch (_) {}
  }
}

/// v1 → v2：摘要压缩 + 成本统计 + 图片生成历史。
Future<void> _addCompactionAndUsage(NonaAppDatabase db) async {
  await _addColumnIfMissing(db, 'sessions', 'summary', "TEXT NOT NULL DEFAULT ''");
  await _addColumnIfMissing(db, 'sessions', 'summary_tokens', 'INTEGER');
  await _addColumnIfMissing(db, 'messages', 'sent_at', 'INTEGER');
  await db.customStatement('''
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
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_blocks_session '
    'ON compressed_blocks(session_id, start_index)',
  );
  await db.customStatement('''
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
  await db.customStatement('''
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

/// v2 → v3：知识库 SQLite 化。
Future<void> _addKnowledgeBase(NonaAppDatabase db) async {
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS kb_libraries (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');
  await db.customStatement('''
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
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS kb_chunks (
      id TEXT PRIMARY KEY,
      doc_id TEXT NOT NULL REFERENCES kb_documents(id) ON DELETE CASCADE,
      position INTEGER NOT NULL DEFAULT 0,
      text TEXT NOT NULL,
      tokens INTEGER NOT NULL DEFAULT 0
    );
  ''');
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS kb_bigrams (
      bigram TEXT NOT NULL,
      chunk_id TEXT NOT NULL REFERENCES kb_chunks(id) ON DELETE CASCADE,
      PRIMARY KEY (bigram, chunk_id)
    );
  ''');
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS kb_vectors (
      chunk_id TEXT PRIMARY KEY REFERENCES kb_chunks(id) ON DELETE CASCADE,
      dim INTEGER NOT NULL,
      vec BLOB NOT NULL
    );
  ''');
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_kb_chunks_doc ON kb_chunks(doc_id, position)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_kb_bigrams_key ON kb_bigrams(bigram)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_kb_docs_lib ON kb_documents(library_id)',
  );
  final now = DateTime.now().millisecondsSinceEpoch;
  try {
    await db.customStatement(
      'INSERT OR IGNORE INTO kb_libraries (id, name, created_at, updated_at) '
      "VALUES ('default', '默认库', ?, ?)",
      [now, now],
    );
  } catch (_) {}
}

/// v3 → v4：记忆系统。
Future<void> _addMemories(NonaAppDatabase db) async {
  await _addColumnIfMissing(db, 'sessions', 'memory', "TEXT NOT NULL DEFAULT ''");
  await db.customStatement('''
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
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_memories_scope ON memories(scope, scope_ref)',
  );
}

/// v4 → v5：世界书。
Future<void> _addWorldBook(NonaAppDatabase db) async {
  await db.customStatement('''
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

/// ALTER TABLE 加列辅助（幂等）。
Future<void> _addColumnIfMissing(
  NonaAppDatabase db,
  String table,
  String name,
  String ddl,
) async {
  final columns = await _tableColumns(db, table);
  if (columns.contains(name)) return;
  try {
    await db.customStatement('ALTER TABLE $table ADD COLUMN $name $ddl');
  } catch (_) {}
}

/// 读取表列名集合。
Future<Set<String>> _tableColumns(NonaAppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.data['name'] as String).toSet();
}

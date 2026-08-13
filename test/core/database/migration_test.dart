import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// 旧版手写 DDL 的 v1 基础表（对齐 lib/db/nona_database.dart 历史版本）。
void _createLegacyV1Schema(sqlite3.Database db) {
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('''
    CREATE TABLE sessions (
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
    CREATE TABLE messages (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      message_index INTEGER NOT NULL,
      role TEXT NOT NULL,
      content TEXT NOT NULL,
      reasoning_content TEXT NOT NULL DEFAULT '',
      images_json TEXT NOT NULL DEFAULT '[]',
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
  ''');
  db.execute(
    'CREATE INDEX idx_messages_session ON messages(session_id, message_index)',
  );
  db.execute('''
    CREATE TABLE message_tokens (
      token TEXT NOT NULL,
      session_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      PRIMARY KEY (token, message_id, position)
    );
  ''');
}

/// v1 → v5：逐版本执行与旧 schema_migrations.dart 相同的升级。
void _applyLegacyMigrations(sqlite3.Database db) {
  void addColumn(String table, String name, String ddl) {
    final columns = db
        .select('PRAGMA table_info($table)')
        .map((r) => r['name'] as String)
        .toSet();
    if (columns.contains(name)) return;
    db.execute('ALTER TABLE $table ADD COLUMN $name $ddl');
  }

  // v0→v1
  addColumn('messages', 'documents_json', "TEXT NOT NULL DEFAULT '[]'");
  addColumn('messages', 'alternatives_json', "TEXT NOT NULL DEFAULT '[]'");
  // v1→v2
  addColumn('sessions', 'summary', "TEXT NOT NULL DEFAULT ''");
  addColumn('sessions', 'summary_tokens', 'INTEGER');
  addColumn('messages', 'sent_at', 'INTEGER');
  db.execute('''
    CREATE TABLE compressed_blocks (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      start_index INTEGER NOT NULL,
      end_index INTEGER NOT NULL,
      summary TEXT NOT NULL,
      messages_json TEXT NOT NULL DEFAULT '[]',
      created_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE usage_daily (
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
    CREATE TABLE gen_media (
      id TEXT PRIMARY KEY,
      prompt TEXT NOT NULL,
      model_id TEXT NOT NULL,
      path TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'image',
      created_at INTEGER NOT NULL
    );
  ''');
  // v2→v3
  db.execute('''
    CREATE TABLE kb_libraries (
      id TEXT PRIMARY KEY, name TEXT NOT NULL,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE kb_documents (
      id TEXT PRIMARY KEY, name TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'text',
      library_id TEXT NOT NULL DEFAULT 'default',
      embedding_model TEXT, chunk_count INTEGER NOT NULL DEFAULT 0,
      enabled INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE kb_chunks (
      id TEXT PRIMARY KEY,
      doc_id TEXT NOT NULL REFERENCES kb_documents(id) ON DELETE CASCADE,
      position INTEGER NOT NULL DEFAULT 0,
      text TEXT NOT NULL, tokens INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    CREATE TABLE kb_bigrams (
      bigram TEXT NOT NULL,
      chunk_id TEXT NOT NULL REFERENCES kb_chunks(id) ON DELETE CASCADE,
      PRIMARY KEY (bigram, chunk_id)
    );
  ''');
  db.execute('''
    CREATE TABLE kb_vectors (
      chunk_id TEXT PRIMARY KEY REFERENCES kb_chunks(id) ON DELETE CASCADE,
      dim INTEGER NOT NULL, vec BLOB NOT NULL
    );
  ''');
  db.execute(
    "INSERT INTO kb_libraries (id, name, created_at, updated_at) "
    "VALUES ('default', '默认库', 1, 1)",
  );
  // v3→v4
  addColumn('sessions', 'memory', "TEXT NOT NULL DEFAULT ''");
  db.execute('''
    CREATE TABLE memories (
      id TEXT PRIMARY KEY,
      scope TEXT NOT NULL CHECK(scope IN ('global','agent','session')),
      scope_ref TEXT, content TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'fact',
      pinned INTEGER NOT NULL DEFAULT 0,
      source_message_id TEXT,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    );
  ''');
  // v4→v5
  db.execute('''
    CREATE TABLE world_book_entries (
      id TEXT PRIMARY KEY, title TEXT NOT NULL,
      keywords_json TEXT NOT NULL DEFAULT '[]', content TEXT NOT NULL,
      priority INTEGER NOT NULL DEFAULT 100,
      scan_depth INTEGER NOT NULL DEFAULT 1,
      case_sensitive INTEGER NOT NULL DEFAULT 0,
      injection_position TEXT NOT NULL DEFAULT 'top_of_chat',
      role TEXT NOT NULL DEFAULT 'user',
      constant_active INTEGER NOT NULL DEFAULT 0,
      scope TEXT NOT NULL DEFAULT 'global', scope_ref TEXT,
      enabled INTEGER NOT NULL DEFAULT 1
    );
  ''');
  db.execute('PRAGMA user_version = 5');
}

void main() {
  test('旧库 v5 → v7 升级：数据无丢失且新表/新列就绪', () async {
    final tmp = File(
      '${Directory.systemTemp.createTempSync('nona_mig_test').path}'
      '/nona.db',
    );
    try {
      // 1. 用旧 DDL 建库并填充样本数据，user_version=5
      final legacy = sqlite3.sqlite3.open(tmp.path);
      _createLegacyV1Schema(legacy);
      _applyLegacyMigrations(legacy);
      final now = DateTime(2024, 5, 1).millisecondsSinceEpoch;
      legacy.execute(
        'INSERT INTO sessions (id, title, options_json, pinned, sort_order, '
        'created_at, updated_at, summary, summary_tokens, memory) '
        "VALUES ('s1', '旧会话', '{\"systemPrompt\":\"旧提示\"}', 1, 0, ?, ?, "
        "'旧摘要', 42, '旧记忆')",
        [now, now],
      );
      legacy.execute(
        'INSERT INTO messages (id, session_id, message_index, role, content, '
        'reasoning_content, images_json, documents_json, alternatives_json, '
        'tool_call_id, tool_calls_json, interrupted, failed, prompt_tokens, '
        'completion_tokens, elapsed_ms, provider_name, model_id, sent_at) '
        "VALUES ('s1:0', 's1', 0, 'user', '你好世界', '', '[]', '[]', '[]', "
        'NULL, NULL, 0, 0, 10, 20, 30, NULL, NULL, ?)',
        [now],
      );
      legacy.execute(
        'INSERT INTO message_tokens (token, session_id, message_id, position) '
        "VALUES ('你好', 's1', 's1:0', 0), ('好世', 's1', 's1:0', 1), "
        "('世界', 's1', 's1:0', 2)",
      );
      legacy.execute(
        'INSERT INTO compressed_blocks (id, session_id, start_index, end_index,'
        ' summary, messages_json, created_at) VALUES (?, ?, 0, 0, ?, ?, ?)',
        ['s1:block1', 's1', '块摘要', '[]', now],
      );
      legacy.execute(
        "INSERT INTO memories (id, scope, scope_ref, content, category, "
        "pinned, source_message_id, created_at, updated_at) "
        "VALUES ('m1', 'global', NULL, '记得用户喜欢 Flutter', 'fact', 0, "
        "NULL, ?, ?)",
        [now, now],
      );
      legacy.execute(
        "INSERT INTO world_book_entries (id, title, keywords_json, content) "
        "VALUES ('wb1', '角色', '[\"王子\"]', '你是王子')",
      );
      legacy.execute(
        "INSERT INTO usage_daily (model_id, provider_name, date, "
        "prompt_tokens, completion_tokens, calls) "
        "VALUES ('gpt-4o', 'openai', '2024-05-01', 10, 20, 1)",
      );
      legacy.dispose();

      // 2. drift 打开旧库：触发 onUpgrade v5→v7
      final db = NonaAppDatabase(NativeDatabase(File(tmp.path)));
      db.wasFresh = false;

      // 3. 数据完整
      final sessions = await (db.select(db.sessions)).get();
      expect(sessions, hasLength(1));
      expect(sessions.first.title, '旧会话');
      expect(sessions.first.summary, '旧摘要');
      expect(sessions.first.summaryTokens, 42);
      expect(sessions.first.memory, '旧记忆');
      expect(sessions.first.pinned, isTrue);
      expect(jsonDecode(sessions.first.optionsJson), {
        'systemPrompt': '旧提示',
      });

      final messages = await (db.select(db.messages)).get();
      expect(messages, hasLength(1));
      expect(messages.first.content, '你好世界');
      expect(messages.first.promptTokens, 10);
      expect(messages.first.completionTokens, 20);
      expect(messages.first.sentAt, now);

      final tokens = await (db.select(db.messageTokens)).get();
      expect(tokens, hasLength(3));

      final blocks = await (db.select(db.compressedBlocks)).get();
      expect(blocks, hasLength(1));
      expect(blocks.first.summary, '块摘要');

      final memories = await (db.select(db.memories)).get();
      expect(memories, hasLength(1));
      expect(memories.first.content, contains('Flutter'));

      final wb = await (db.select(db.worldBookEntries)).get();
      expect(wb, hasLength(1));
      expect(wb.first.title, '角色');

      final usage = await (db.select(db.usageDaily)).get();
      expect(usage, hasLength(1));
      expect(usage.first.calls, 1);

      // 4. v6/v7 新列就绪（旧行读回默认值）
      expect(sessions.first.tagsJson, isNull);
      expect(sessions.first.truncateIndex, isNull);
      expect(messages.first.partsJson, isNull);
      expect(messages.first.citationsJson, isNull);
      expect(messages.first.toolStepsJson, isNull);
      expect(messages.first.streamingState, isNull);
      expect(wb.first.useRegex, isFalse);
      expect(wb.first.bookId, isNull);

      // 5. v6/v7 新表可写可读
      await db.into(db.worldBooks).insert(
        WorldBooksCompanion.insert(id: 'book1', name: '书一'),
      );
      await db.into(db.generationRuns).insert(
        GenerationRunsCompanion.insert(
          id: 'run1',
          sessionId: const Value('s1'),
          messageId: const Value('s1:0'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.into(db.tags).insert(TagsCompanion.insert(id: 't1', name: '工作'));
      await db.into(db.quickPhrases).insert(
        QuickPhrasesCompanion.insert(id: 'q1', title: '短语', content: '内容'),
      );
      await db.into(db.instructionInjections).insert(
        InstructionInjectionsCompanion.insert(
          id: 'i1',
          title: '注入',
          prompt: '提示',
        ),
      );
      await db.into(db.providerGroups).insert(
        ProviderGroupsCompanion.insert(id: 'g1', name: '组一'),
      );
      await db.into(db.searchKeys).insert(
        SearchKeysCompanion.insert(id: 'k1', engineId: 'tavily', key: 'sk'),
      );
      await db.into(db.workflows).insert(
        WorkflowsCompanion.insert(
          id: 'w1',
          name: '工作流',
          triggerJson: '{"type":"manual"}',
          actionsJson: '[]',
          updatedAt: now,
        ),
      );

      expect((await (db.select(db.worldBooks)).get()), hasLength(1));
      expect((await (db.select(db.generationRuns)).get()).first.state,
          'preparing');
      expect((await (db.select(db.tags)).get()).first.name, '工作');
      expect((await (db.select(db.workflows)).get()).first.name, '工作流');

      // 6. user_version 收敛到 7，索引就绪
      final version = await db
          .customSelect('PRAGMA user_version')
          .get()
          .then((r) => r.first.data['user_version'] as int);
      expect(version, 7);
      final idx = await db
          .customSelect('PRAGMA index_list(messages)')
          .get();
      expect(idx, isNotEmpty);

      await db.close();
    } finally {
      if (tmp.existsSync()) tmp.deleteSync();
    }
  });

  test('新库直接建全量 v7 schema（含全部新表）', () async {
    final db = NonaAppDatabase(NativeDatabase.memory());
    db.wasFresh = true;
    await db.customSelect('PRAGMA user_version').get();
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE "
          "'sqlite_%' ORDER BY name",
        )
        .get();
    final names = tables.map((r) => r.data['name'] as String).toSet();
    for (final t in [
      'sessions',
      'messages',
      'message_tokens',
      'compressed_blocks',
      'usage_daily',
      'gen_media',
      'kb_libraries',
      'kb_documents',
      'kb_chunks',
      'kb_bigrams',
      'kb_vectors',
      'memories',
      'world_book_entries',
      'world_books',
      'provider_groups',
      'search_keys',
      'quick_phrases',
      'instruction_injections',
      'tags',
      'generation_runs',
      'change_log',
      'route_events',
      'workflows',
      'workflow_runs',
    ]) {
      expect(names, contains(t), reason: '新库应包含表 $t');
    }
    await db.close();
  });

  test('已是 v7 的库打开为幂等空操作（不重写 schema）', () async {
    final tmp = File(
      '${Directory.systemTemp.createTempSync('nona_mig_idem').path}/nona.db',
    );
    try {
      // 用 drift 建全量 v7 库
      var db = NonaAppDatabase(NativeDatabase(File(tmp.path)));
      await db.customSelect('SELECT 1').get();
      await db.close();
      // 用 raw sqlite3 记录 messages 的列集与行数据
      final probe = sqlite3.sqlite3.open(tmp.path);
      final before = probe
          .select('PRAGMA table_info(messages)')
          .map((r) => r['name'] as String)
          .toList();
      probe.execute(
        "INSERT INTO sessions (id, title, options_json, created_at, updated_at) "
        "VALUES ('x', 't', '{}', 0, 0)",
      );
      probe.dispose();
      // 重新打开：v7 无升级动作，数据保留
      db = NonaAppDatabase(NativeDatabase(File(tmp.path)));
      final sessions = await (db.select(db.sessions)).get();
      expect(sessions, hasLength(1));
      final after = await db
          .customSelect('PRAGMA table_info(messages)')
          .get()
          .then((r) => r.map((e) => e.data['name'] as String).toList());
      expect(after, before);
      await db.close();
    } finally {
      if (tmp.existsSync()) tmp.deleteSync();
    }
  });
}

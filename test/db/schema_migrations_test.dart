import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/db/schema_migrations.dart';
import 'package:sqlite3/sqlite3.dart';

/// 建一个模拟 v0 旧库：messages 表缺少数个新列。
Database openLegacyDb() {
  final db = sqlite3.openInMemory();
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
      interrupted INTEGER NOT NULL DEFAULT 0,
      failed INTEGER NOT NULL DEFAULT 0,
      prompt_tokens INTEGER,
      completion_tokens INTEGER,
      elapsed_ms INTEGER,
      provider_name TEXT,
      model_id TEXT
    );
  ''');
  return db;
}

int userVersion(Database db) =>
    db.select('PRAGMA user_version').first.columnAt(0) as int;

Set<String> messageColumns(Database db) =>
    db.select('PRAGMA table_info(messages)').map((r) => r['name'] as String).toSet();

void main() {
  test('全新库执行迁移后 user_version 等于注册表长度', () {
    final db = sqlite3.openInMemory();
    db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        message_index INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL
      );
    ''');
    applySchemaMigrations(db);
    expect(userVersion(db), kSchemaMigrations.length);
    db.dispose();
  });

  test('旧库缺少的新列被补齐且数据保留', () {
    final db = openLegacyDb();
    db.execute('''
      INSERT INTO sessions (id, title, options_json, created_at, updated_at)
      VALUES ('s1', 't', '{}', 0, 0);
    ''');
    db.execute('''
      INSERT INTO messages (id, session_id, message_index, role, content)
      VALUES ('m1', 's1', 0, 'user', '旧数据');
    ''');
    applySchemaMigrations(db);
    final columns = messageColumns(db);
    expect(columns, containsAll(['documents_json', 'alternatives_json',
        'tool_call_id', 'tool_calls_json']));
    expect(userVersion(db), kSchemaMigrations.length);
    // 新列有默认值，旧数据行仍可读
    final row = db.select('SELECT * FROM messages WHERE id = "m1"').single;
    expect(row['content'], '旧数据');
    db.dispose();
  });

  test('迁移幂等：重复执行不报错且版本号不变', () {
    final db = openLegacyDb();
    applySchemaMigrations(db);
    final version = userVersion(db);
    applySchemaMigrations(db);
    expect(userVersion(db), version);
    db.dispose();
  });

  test('已是最新版本时迁移为空操作', () {
    final db = openLegacyDb();
    db.execute('PRAGMA user_version = ${kSchemaMigrations.length}');
    applySchemaMigrations(db);
    expect(userVersion(db), kSchemaMigrations.length);
    expect(messageColumns(db), isNot(contains('tool_calls_json')),
        reason: '已声明为最新版本的库不应再被改写');
    db.dispose();
  });

  test('v6：memories 补 v2 列并建 memory_spaces / memory_state', () {
    final db = openLegacyDb();
    applySchemaMigrations(db);
    final memCols = db
        .select('PRAGMA table_info(memories)')
        .map((r) => r['name'] as String)
        .toSet();
    expect(memCols, containsAll([
      'tags_json', 'priority', 'use_count', 'last_used_at', 'history_json',
    ]));
    expect(db.select('SELECT * FROM memory_spaces'), isEmpty);
    expect(db.select('SELECT * FROM memory_state'), isEmpty);
    db.dispose();
  });

  test('v6 迁移幂等：重复执行不新增列/表', () {
    final db = openLegacyDb();
    applySchemaMigrations(db);
    final version = userVersion(db);
    applySchemaMigrations(db);
    expect(userVersion(db), version);
    final memCols = db
        .select('PRAGMA table_info(memories)')
        .map((r) => r['name'] as String)
        .toSet();
    expect(memCols, containsAll([
      'tags_json', 'priority', 'use_count', 'last_used_at', 'history_json',
    ]));
    db.dispose();
  });
}

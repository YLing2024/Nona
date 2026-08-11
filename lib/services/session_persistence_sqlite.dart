import 'dart:async';
import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../db/nona_database.dart';
import '../models/chat_message.dart';
import '../models/chat_options.dart';
import '../models/chat_session.dart';
import '../utils/logger.dart';
import 'document_extractor.dart' show ChatDocument;
import 'search_service.dart';
import 'session_persistence.dart';
import 'session_persistence_io.dart';

/// 旧文件存储迁移的三态。
enum _MigrationState { notStarted, running, done }

/// SQLite 会话持久化：会话/消息表 + bigram 倒排索引。
///
/// - 首次使用自动从旧文件存储迁移（保留原文件作备份）；
/// - 数据库不可用（无原生 sqlite3 库的环境，如部分测试环境）时
///   自动回退到文件存储（其内部再退化内存）；
/// - 实现 [IndexedSessionSearch]：消息全文搜索走 bigram 索引。
class SessionPersistenceSqlite
    implements SessionPersistence, IndexedSessionSearch {
  final NonaDatabase _database;

  /// 回退存储（数据库不可用时）。
  SessionPersistence? _fallback;

  /// 旧文件存储（迁移数据源）；测试可注入受控 fake。
  final SessionPersistence? _legacy;

  /// 迁移状态：三态避免并发首启动时重复迁移 / 读空库。
  _MigrationState _migration = _MigrationState.notStarted;

  /// 迁移进行中时，并发调用方等待其完成。
  Completer<void>? _migrationCompleter;

  SessionPersistenceSqlite(this._database, {SessionPersistence? legacy})
      : _legacy = legacy;

  Future<SessionPersistence> _active() async {
    final db = await _database.open();
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
  Future<void> _ensureMigrated(Database db) async {
    if (_migration == _MigrationState.done) return;
    if (_migration == _MigrationState.running) {
      await _migrationCompleter!.future;
      return;
    }
    _migration = _MigrationState.running;
    final completer = _migrationCompleter = Completer<void>();
    try {
      if (_database.wasFresh) {
        final count = db
            .select('SELECT COUNT(*) AS c FROM sessions')
            .first['c'] as int;
        if (count == 0) {
          final file = _legacy ?? SessionPersistenceIo();
          final stored = await file.readAll();
          if (stored != null && stored.isNotEmpty) {
            _writeAllInternal(db, stored);
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
    final db = await _database.open();
    final rows =
        db!
            .select(
              'SELECT * FROM sessions '
              'ORDER BY sort_order ASC, created_at DESC',
            )
            .toList();
    if (rows.isEmpty) return null;
    final result = <ChatSession>[];
    for (final row in rows) {
      final session = _sessionFromRow(row, db);
      if (session != null) result.add(session);
    }
    return result;
  }

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    final active = await _active();
    if (active != this) return active.writeAll(sessions);
    final db = await _database.open();
    _writeAllInternal(db!, sessions);
  }

  void _writeAllInternal(Database db, List<ChatSession> sessions) {
    db.execute('BEGIN TRANSACTION');
    try {
      db.execute('DELETE FROM message_tokens');
      db.execute('DELETE FROM messages');
      db.execute('DELETE FROM sessions');
      for (var i = 0; i < sessions.length; i++) {
        _insertSession(db, sessions[i], i);
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    final active = await _active();
    if (active != this) return active.writeSession(session);
    final db = await _database.open();
    db!.execute('BEGIN TRANSACTION');
    try {
      // 保留原 sort_order（无则追加到末尾）
      final existing = db.select(
        'SELECT sort_order FROM sessions WHERE id = ?',
        [session.id],
      );
      final order = existing.isEmpty
          ? db
                  .select(
                    'SELECT COALESCE(MAX(sort_order), -1) + 1 AS c FROM sessions',
                  )
                  .first['c'] as int
          : existing.first['sort_order'] as int;
      _deleteSessionInternal(db, session.id);
      _insertSession(db, session, order);
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    final active = await _active();
    if (active != this) return active.deleteSession(id);
    final db = await _database.open();
    db!.execute('BEGIN TRANSACTION');
    try {
      _deleteSessionInternal(db, id);
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ---------------- SQLite 内部 ----------------

  void _insertSession(Database db, ChatSession s, int order) {
    db.execute(
      'INSERT OR REPLACE INTO sessions '
      '(id, title, options_json, provider_id, model_id, agent_id, pinned, '
      ' sort_order, created_at, updated_at, summary, summary_tokens, memory) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        s.id,
        s.title,
        jsonEncode(s.options.toJson()),
        s.providerId,
        s.modelId,
        s.agentId,
        s.pinned ? 1 : 0,
        order,
        s.createdAt.millisecondsSinceEpoch,
        s.updatedAt.millisecondsSinceEpoch,
        s.summary,
        s.summaryTokens,
        s.memory,
      ],
    );
    for (final block in s.compressedBlocks) {
      db.execute(
        'INSERT OR REPLACE INTO compressed_blocks '
        '(id, session_id, start_index, end_index, summary, messages_json, '
        ' created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          '${s.id}:${block.id}',
          s.id,
          block.startIndex,
          block.endIndex,
          block.summary,
          jsonEncode(block.messages.map((m) => m.toJson()).toList()),
          block.createdAt.millisecondsSinceEpoch,
        ],
      );
    }
    for (var i = 0; i < s.messages.length; i++) {
      final m = s.messages[i];
      final id = '${s.id}:$i';
      db.execute(
        'INSERT OR REPLACE INTO messages '
        '(id, session_id, message_index, role, content, reasoning_content, '
        ' images_json, documents_json, alternatives_json, tool_call_id, '
        ' tool_calls_json, interrupted, failed, prompt_tokens, '
        ' completion_tokens, elapsed_ms, provider_name, model_id, sent_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          s.id,
          i,
          m.role,
          m.content,
          m.reasoningContent,
          jsonEncode(m.images.map((img) => img.toJson()).toList()),
          jsonEncode([
            for (final d in m.documents) {'name': d.name, 'text': d.text},
          ]),
          jsonEncode(m.alternatives.map((a) => a.toJson()).toList()),
          m.toolCallId,
          m.toolCallsJson,
          m.interrupted ? 1 : 0,
          m.failed ? 1 : 0,
          m.promptTokens,
          m.completionTokens,
          m.elapsedMs,
          m.providerName,
          m.modelId,
          m.sentAt?.millisecondsSinceEpoch,
        ],
      );
    }
    _indexSession(db, s);
  }

  void _deleteSessionInternal(Database db, String sessionId) {
    db.execute(
      'DELETE FROM message_tokens WHERE session_id = ?',
      [sessionId],
    );
    db.execute(
      'DELETE FROM compressed_blocks WHERE session_id = ?',
      [sessionId],
    );
    db.execute('DELETE FROM messages WHERE session_id = ?', [sessionId]);
    db.execute('DELETE FROM sessions WHERE id = ?', [sessionId]);
  }

  /// 会话消息正文 bigram 索引（增量重建单会话）。
  void _indexSession(Database db, ChatSession s) {
    for (var i = 0; i < s.messages.length; i++) {
      final content = s.messages[i].content.toLowerCase();
      if (content.length < 2) continue;
      final id = '${s.id}:$i';
      final tokens = bigrams(content);
      for (var p = 0; p < tokens.length; p++) {
        db.execute(
          'INSERT OR REPLACE INTO message_tokens '
          '(token, session_id, message_id, position) VALUES (?, ?, ?, ?)',
          [tokens[p], s.id, id, p],
        );
      }
    }
  }

  ChatSession? _sessionFromRow(Row row, Database db) {
    try {
      final options = ChatOptions.fromJson(
        jsonDecode(row['options_json'] as String) as Map<String, dynamic>,
      );
      final messageRows = db.select(
        'SELECT * FROM messages WHERE session_id = ? ORDER BY message_index ASC',
        [row['id']],
      );
      final messages = <ChatMessage>[];
      for (final m in messageRows) {
        messages.add(_messageFromRow(m));
      }
      final blockRows = db.select(
        'SELECT * FROM compressed_blocks WHERE session_id = ? '
        'ORDER BY start_index ASC',
        [row['id']],
      );
      final blocks = <CompressedBlock>[];
      for (final b in blockRows) {
        blocks.add(
          CompressedBlock(
            id: b['id'] as String,
            startIndex: b['start_index'] as int,
            endIndex: b['end_index'] as int,
            summary: b['summary'] as String,
            messages: (jsonDecode(b['messages_json'] as String) as List<dynamic>)
                .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              b['created_at'] as int,
            ),
          ),
        );
      }
      return ChatSession(
        id: row['id'] as String,
        title: row['title'] as String,
        options: options,
        providerId: row['provider_id'] as String?,
        modelId: row['model_id'] as String?,
        agentId: row['agent_id'] as String?,
        pinned: (row['pinned'] as int) == 1,
        messages: messages,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['updated_at'] as int,
        ),
        summary: row['summary'] as String? ?? '',
        summaryTokens: row['summary_tokens'] as int?,
        memory: row['memory'] as String? ?? '',
        compressedBlocks: blocks,
      );
    } catch (e) {
      Logger.warn('session', 'corrupt session record skipped: $e');
      return null;
    }
  }

  ChatMessage _messageFromRow(Row m) => ChatMessage(
    role: m['role'] as String,
    content: m['content'] as String,
    reasoningContent: m['reasoning_content'] as String,
    images: _parseImages(m['images_json'] as String),
    documents: _parseDocuments(m['documents_json'] as String?),
    alternatives: _parseAlternatives(m['alternatives_json'] as String?),
    toolCallId: m['tool_call_id'] as String?,
    toolCallsJson: m['tool_calls_json'] as String?,
    interrupted: (m['interrupted'] as int) == 1,
    failed: (m['failed'] as int) == 1,
    promptTokens: m['prompt_tokens'] as int?,
    completionTokens: m['completion_tokens'] as int?,
    elapsedMs: m['elapsed_ms'] as int?,
    providerName: m['provider_name'] as String?,
    modelId: m['model_id'] as String?,
    sentAt: (m['sent_at'] as int?) == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['sent_at'] as int),
  );

  List<ChatImage> _parseImages(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<ChatDocument> _parseDocuments(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>)
            ChatDocument(
              name: e['name'] as String? ?? '',
              text: e['text'] as String? ?? '',
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  List<ChatMessage> _parseAlternatives(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ---------------- 索引搜索 ----------------

  @override
  Future<List<MessageSearchHit>> search(
    String query, {
    int limit = 50,
  }) async {
    final db = await _database.open();
    if (db == null) {
      // 数据库不可用时回退文件存储做内存扫描，
      // 避免「存储里明明有会话却搜不到」的假空结果。
      final fallback = await _active();
      final all = await fallback.readAll();
      final hits = SearchService.search(all ?? const [], query);
      return hits.take(limit).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // 标题命中优先
    final titleIds = db
        .select(
          'SELECT id FROM sessions WHERE lower(title) LIKE ?',
          ['%$q%'],
        )
        .map((r) => r['id'] as String)
        .toSet();

    final hits = <MessageSearchHit>[];
    if (q.length >= 2) {
      final tokens = bigrams(q);
      final rows = db.select(
        'SELECT message_id, COUNT(*) AS hits FROM message_tokens '
        'WHERE token IN (${List.filled(tokens.length, '?').join(',')}) '
        'GROUP BY message_id ORDER BY hits DESC LIMIT ?',
        [...tokens, limit * 4],
      );
      for (final row in rows) {
        if (hits.length >= limit) break;
        final messageId = row['message_id'] as String;
        final hit = _hitFromMessageId(db, messageId, q);
        if (hit != null) hits.add(hit);
      }
      // 标题命中但无消息命中：定位最早用户消息
      for (final sid in titleIds) {
        if (hits.any((h) => h.session.id == sid)) continue;
        final session = _sessionFromRow(
          db.select('SELECT * FROM sessions WHERE id = ?', [sid]).first,
          db,
        );
        if (session == null) continue;
        final idx = session.messages.indexWhere((m) => m.role == 'user');
        final target = idx >= 0 ? idx : 0;
        if (session.messages.isNotEmpty && session.messages.length > target) {
          hits.add(
            MessageSearchHit(
              session: session,
              messageIndex: target,
              message: session.messages[target],
              matchStart: 0,
            ),
          );
        }
      }
    } else {
      // 单字符查询：直接子串扫描
      final sessions = await readAll();
      for (final s in sessions ?? const <ChatSession>[]) {
        for (var i = 0; i < s.messages.length; i++) {
          if (hits.length >= limit) break;
          final pos = s.messages[i].content.toLowerCase().indexOf(q);
          if (pos >= 0) {
            hits.add(
              MessageSearchHit(
                session: s,
                messageIndex: i,
                message: s.messages[i],
                matchStart: pos,
              ),
            );
          }
        }
        if (hits.length >= limit) break;
      }
    }

    // 排序：标题命中优先 → 更新时间倒序
    hits.sort((a, b) {
      final aTitle = titleIds.contains(a.session.id);
      final bTitle = titleIds.contains(b.session.id);
      if (aTitle != bTitle) return aTitle ? -1 : 1;
      return b.session.updatedAt.compareTo(a.session.updatedAt);
    });
    return hits;
  }

  MessageSearchHit? _hitFromMessageId(Database db, String messageId, String q) {
    final rows = db.select(
      'SELECT m.session_id, m.message_index FROM messages m '
      'WHERE m.id = ?',
      [messageId],
    );
    if (rows.isEmpty) return null;
    final sessionId = rows.first['session_id'] as String;
    final index = rows.first['message_index'] as int;
    final sessionRows = db.select(
      'SELECT * FROM sessions WHERE id = ?',
      [sessionId],
    );
    if (sessionRows.isEmpty) return null;
    final session = _sessionFromRow(sessionRows.first, db);
    if (session == null || index >= session.messages.length) return null;
    final m = session.messages[index];
    final pos = m.content.toLowerCase().indexOf(q);
    if (pos < 0) return null;
    return MessageSearchHit(
      session: session,
      messageIndex: index,
      message: m,
      matchStart: pos,
    );
  }
}

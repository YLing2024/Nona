import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../backup_archive.dart';
import 'importer_utils.dart';

/// Kelivo（drift SQLite）导入器。
///
/// 结构：`conversation_rows` + `message_rows`（messageOrder 排序，
/// groupId/version 表达重生成版本 → Nona alternatives）。
class KelivoImporter {
  /// 嗅探：数据库含 conversation_rows 与 message_rows 表。
  static bool matchesFile(String path) {
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        final rows = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name IN ('conversation_rows', 'message_rows')",
        );
        return rows.length == 2;
      } finally {
        db.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  /// 导入。
  static BackupImportResult importFile(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final rows = db.select(
        'SELECT * FROM conversation_rows ORDER BY updated_at ASC',
      );
      final sessions = <ChatSession>[];
      final failures = <ImportFailure>[];
      for (var i = 0; i < rows.length; i++) {
        try {
          final session = _sessionFromRow(db, rows[i]);
          if (session != null) sessions.add(session);
        } catch (e) {
          failures.add(ImportFailure(index: i, reason: e.toString()));
        }
      }
      return BackupImportResult(sessions: sessions, failedItems: failures);
    } finally {
      db.dispose();
    }
  }

  static ChatSession? _sessionFromRow(Database db, Row row) {
    final id = row['id'] as String;
    final messageRows = db.select(
      'SELECT * FROM message_rows WHERE conversation_id = ? '
      'ORDER BY message_order ASC',
      [id],
    );
    if (messageRows.isEmpty) return null;
    // 按 groupId 分组：同一 groupId 的多个 version → alternatives
    final byGroup = <String?, List<Row>>{};
    for (final m in messageRows) {
      final groupId = m['group_id'] as String?;
      byGroup.putIfAbsent(groupId, () => []).add(m);
    }
    final messages = <ChatMessage>[];
    for (final group in byGroup.values) {
      group.sort((a, b) => (b['version'] as int? ?? 0)
          .compareTo(a['version'] as int? ?? 0));
      // 最新版本为主消息，其余为 alternatives
      final latest = group.first;
      final main = _messageFromRow(latest);
      if (main == null) continue;
      final alts = <ChatMessage>[...main.alternatives];
      for (final old in group.skip(1)) {
        final alt = _messageFromRow(old);
        if (alt != null) alts.add(alt);
      }
      main.alternatives = alts;
      messages.add(main);
    }
    messages.sort(
      (a, b) => (a.sentAt ?? DateTime(0)).compareTo(b.sentAt ?? DateTime(0)),
    );
    if (messages.isEmpty) return null;
    return ChatSession(
      id: stableSessionId('kelivo', id),
      title: (row['title'] as String? ?? '').trim().isEmpty
          ? 'Imported from Kelivo'
          : row['title'] as String,
      messages: messages,
      pinned: (row['is_pinned'] as int? ?? 0) == 1,
      createdAt: _time(row['created_at']),
      updatedAt: _time(row['updated_at']),
      summary: row['summary'] as String? ?? '',
    );
  }

  static ChatMessage? _messageFromRow(Row m) {
    final role = m['role'] as String? ?? 'user';
    final content = m['content'] as String? ?? '';
    final reasoning = m['reasoning_text'] as String?;
    final toolCallsJson = _toolCallsFrom(m);
    if (content.trim().isEmpty && (reasoning == null || reasoning.isEmpty) &&
        toolCallsJson == null) {
      return null;
    }
    return ChatMessage(
      role: role,
      content: content,
      reasoningContent: reasoning ?? '',
      toolCallsJson: toolCallsJson,
      promptTokens: m['prompt_tokens'] as int?,
      completionTokens: m['completion_tokens'] as int?,
      elapsedMs: m['duration_ms'] as int?,
      modelId: m['model_id'] as String?,
      sentAt: _time(m['timestamp']),
    );
  }

  /// 从 role=tool 消息提取 tool_call_id（Kelivo tool 消息的 content 为结果）。
  static String? _toolCallsFrom(Row m) {
    if (m['role'] != 'tool') return null;
    final callId = m['id'] as String;
    return jsonEncode([
      {
        'id': callId,
        'type': 'function',
        'function': {'name': 'kelivo_tool', 'arguments': '{}'},
      },
    ]);
  }

  static DateTime _time(Object? v) {
    // Kelivo 时间戳为微秒
    if (v is int && v > 0) {
      return DateTime.fromMicrosecondsSinceEpoch(v);
    }
    return DateTime.now();
  }
}

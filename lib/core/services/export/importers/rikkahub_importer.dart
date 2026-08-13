import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../backup_archive.dart';
import 'importer_utils.dart';

/// RikkaHub（Room SQLite）导入器。
///
/// 结构：`conversation` 表（nodes 为 JSON 序列化的消息节点数组，
/// 节点内 messages 为 UIMessage JSON），`memory` 表（助手记忆）。
/// 按调研报告：nodes → 展开 UIMessage → 线性消息列表。
class RikkaHubImporter {
  /// 嗅探：数据库文件含 conversation 表且含 nodes 列。
  static bool matchesFile(String path) {
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        final tables = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='conversation'",
        );
        if (tables.isEmpty) return false;
        final cols = db
            .select('PRAGMA table_info(conversation)')
            .map((r) => r['name'] as String)
            .toSet();
        return cols.contains('nodes');
      } finally {
        db.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  /// 导入：返回 (会话列表, 失败条数, 记忆文本列表)。
  static BackupImportResult importFile(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final rows = db.select(
        'SELECT * FROM conversation ORDER BY create_at ASC',
      );
      final sessions = <ChatSession>[];
      final failures = <ImportFailure>[];
      for (var i = 0; i < rows.length; i++) {
        try {
          final session = _sessionFromRow(rows[i]);
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

  static ChatSession? _sessionFromRow(Row row) {
    final nodesRaw = row['nodes'] as String? ?? '';
    final messages = _parseNodes(nodesRaw);
    if (messages.isEmpty) return null;
    final createAt = row['create_at'] as int? ?? 0;
    final updateAt = row['update_at'] as int? ?? createAt;
    return ChatSession(
      id: stableSessionId('rikkahub', row['id'] as String),
      title: (row['title'] as String? ?? '').trim().isEmpty
          ? 'Imported from RikkaHub'
          : row['title'] as String,
      messages: messages,
      pinned: (row['is_pinned'] as int? ?? 0) == 1,
      createdAt: createAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(createAt)
          : DateTime.now(),
      updatedAt: updateAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(updateAt)
          : DateTime.now(),
      summary: row['custom_system_prompt'] as String? ?? '',
    );
  }

  /// 解析 nodes JSON（节点数组 → 每个节点选中分支的消息列表）。
  static List<ChatMessage> _parseNodes(String nodesRaw) {
    if (nodesRaw.isEmpty) return const [];
    try {
      final nodes = jsonDecode(nodesRaw) as List<dynamic>;
      final result = <ChatMessage>[];
      for (final node in nodes) {
        if (node is! Map<String, dynamic>) continue;
        final messages = node['messages'];
        if (messages is! List) continue;
        for (final m in messages) {
          if (m is! Map<String, dynamic>) continue;
          final parsed = _parseUiMessage(m);
          if (parsed != null) result.add(parsed);
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// UIMessage JSON → ChatMessage。
  static ChatMessage? _parseUiMessage(Map<String, dynamic> m) {
    final role = m['role'] as String? ?? 'user';
    final parts = m['parts'] as List<dynamic>? ?? const [];
    final sb = StringBuffer();
    final images = <ChatImage>[];
    var reasoning = '';
    String? toolCallsJson;
    for (final p in parts) {
      if (p is! Map<String, dynamic>) continue;
      final type = p['type'] as String?;
      switch (type) {
        case 'text':
          sb.write(p['text'] ?? '');
        case 'reasoning':
          reasoning = p['reasoning'] as String? ?? '';
        case 'image':
          final url = p['url'] as String?;
          if (url != null) images.add(imageFromUrl(url));
        case 'tool_call':
          toolCallsJson = jsonEncode([
            {
              'id': p['toolCallId'] ?? '',
              'type': 'function',
              'function': {
                'name': p['toolName'] ?? '',
                'arguments': jsonEncode(p['arguments'] ?? const {}),
              },
            },
          ]);
        case 'tool':
          // 工具结果：append 为文本
          final result = p['result'];
          if (result != null) {
            sb.writeln(
              '[tool ${p['toolName'] ?? ''}]: '
              '${result is String ? result : jsonEncode(result)}',
            );
          }
      }
    }
    if (sb.isEmpty && images.isEmpty && reasoning.isEmpty) return null;
    return ChatMessage(
      role: role.toLowerCase() == 'assistant'
          ? 'assistant'
          : role.toLowerCase() == 'system'
          ? 'system'
          : role.toLowerCase() == 'tool'
          ? 'tool'
          : 'user',
      content: sb.toString().trim(),
      images: images,
      reasoningContent: reasoning,
      toolCallsJson: toolCallsJson,
      sentAt: _parseTime(m['createdAt']),
    );
  }

  static DateTime? _parseTime(Object? v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is num && v > 0) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }
}

import 'dart:convert';

import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../backup_archive.dart';
import 'importer_utils.dart';

/// NextChat 备份解析：`backup.json`（含 chatMap/messageMap 或直接会话数组）。
class NextChatImporter {
  static bool matches(Map<String, dynamic> data) =>
      data['chatMap'] is Map || data['messageMap'] is Map;

  static BackupImportResult parse(Map<String, dynamic> data) {
    final sessions = <ChatSession>[];
    final failures = <ImportFailure>[];

    // 新版：chatMap/messageMap 分离存储
    final chatMap = data['chatMap'];
    final messageMap = data['messageMap'];
    if (chatMap is Map<String, dynamic> &&
        messageMap is Map<String, dynamic>) {
      final chats = chatMap.entries.toList()
        ..sort((a, b) {
          final ta = (a.value as Map<String, dynamic>)['time'] ?? 0;
          final tb = (b.value as Map<String, dynamic>)['time'] ?? 0;
          return (ta as num).compareTo(tb as num);
        });
      for (var i = 0; i < chats.length; i++) {
        try {
          final chat = chats[i].value as Map<String, dynamic>;
          final messages = _collectMessages(chat, messageMap);
          if (messages.isEmpty) continue;
          final now = DateTime.now();
          sessions.add(
            ChatSession(
            id: stableSessionId('nextchat', chat['id'] as String? ?? chats[i].key),
              title: _title(chat),
              messages: messages,
              createdAt: _time(chat['time']) ?? now,
              updatedAt: _time(chat['time']) ?? now,
            ),
          );
        } catch (e) {
          failures.add(ImportFailure(index: i, reason: e.toString()));
        }
      }
      return BackupImportResult(sessions: sessions, failedItems: failures);
    }

    // 旧版：sessions 数组
    final list = data['sessions'] as List<dynamic>? ?? [];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c is! Map<String, dynamic>) continue;
      try {
        final rawMessages = c['messages'] as List<dynamic>? ?? const [];
        final messages = <ChatMessage>[];
        for (final m in rawMessages) {
          if (m is! Map<String, dynamic>) continue;
          final parsed = _messageFromNextChat(m);
          if (parsed != null) messages.add(parsed);
        }
        if (messages.isEmpty) continue;
        final now = DateTime.now();
        sessions.add(
          ChatSession(
            id: stableSessionId('nextchat', c['id'] as String? ??
                '${now.microsecondsSinceEpoch}'),
            title: (c['name'] as String? ?? '').trim().isEmpty
                ? 'Imported from NextChat'
                : c['name'] as String,
            messages: messages,
            createdAt: _time(c['time']) ?? now,
            updatedAt: _time(c['time']) ?? now,
          ),
        );
      } catch (e) {
        failures.add(ImportFailure(index: i, reason: e.toString()));
      }
    }
    return BackupImportResult(sessions: sessions, failedItems: failures);
  }

  static List<ChatMessage> _collectMessages(
    Map<String, dynamic> chat,
    Map<String, dynamic> messageMap,
  ) {
    final ids = (chat['messages'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final result = <ChatMessage>[];
    for (final id in ids) {
      final raw = messageMap[id];
      if (raw is! Map<String, dynamic>) continue;
      final m = _messageFromNextChat(raw);
      if (m != null) result.add(m);
    }
    return result;
  }

  static ChatMessage? _messageFromNextChat(Map<String, dynamic> m) {
    final role = m['role'] as String? ?? 'user';
    final content = m['content'] as String? ?? '';
    final sb = StringBuffer(content);
    final images = <ChatImage>[];
    // 多模态：parts 数组（新版 NextChat）
    final parts = m['parts'];
    if (parts is List) {
      for (final p in parts) {
        if (p is! Map<String, dynamic>) continue;
        final pType = p['type'] as String?;
        if (pType == 'text') {
          sb.write(p['text'] ?? '');
        } else if (pType == 'image_url') {
          final url = (p['image_url'] as Map<String, dynamic>?)?['url'];
          if (url is String) images.add(imageFromUrl(url));
        }
      }
    }
    final reasoning = m['reasoning_content'] as String?;
    // 工具调用消息（保留 toolCallsJson）
    final toolCalls = m['tool_calls'];
    String? toolCallsJson;
    if (toolCalls is List) {
      toolCallsJson = jsonEncode(
        toolCalls.whereType<Map<String, dynamic>>().toList(),
      );
    }
    if (sb.isEmpty && images.isEmpty && toolCallsJson == null) return null;
    return ChatMessage(
      role: role,
      content: sb.toString().trim(),
      images: images,
      reasoningContent: reasoning ?? '',
      toolCallsJson: toolCallsJson,
      sentAt: _time(m['time']),
    );
  }

  static String _title(Map<String, dynamic> chat) {
    final t = chat['topic'] as String? ?? chat['name'] as String? ?? '';
    return t.trim().isEmpty ? 'Imported from NextChat' : t;
  }

  static DateTime? _time(Object? v) {
    if (v is int && v > 0) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

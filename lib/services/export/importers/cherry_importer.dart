import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../backup_archive.dart';
import 'importer_utils.dart';

/// Cherry Studio 导出解析：
/// 新版 `{vault: [{id, name, messages, topics}]}` 或旧版 `{messages, topics}`。
class CherryStudioImporter {
  static bool matches(Map<String, dynamic> data) =>
      data['vault'] is List ||
      data['topics'] is List ||
      data['chat'] is List;

  /// 逐会话容错解析：单条损坏消息/会话计入 [BackupImportResult.failedItems]。
  static BackupImportResult parse(Map<String, dynamic> data) {
    final vault = data['vault'];
    final List<dynamic> chats;
    if (vault is List) {
      chats = vault;
    } else {
      // 旧版单会话导出：messages 直接挂根
      chats = [data];
    }
    final result = <ChatSession>[];
    final failures = <ImportFailure>[];
    for (var i = 0; i < chats.length; i++) {
      final c = chats[i];
      if (c is! Map<String, dynamic>) {
        failures.add(ImportFailure(index: i, reason: 'not an object'));
        continue;
      }
      try {
        final messages = <ChatMessage>[];
        final rawMessages = c['messages'] as List<dynamic>? ?? const [];
        for (var j = 0; j < rawMessages.length; j++) {
          final m = rawMessages[j];
          if (m is! Map<String, dynamic>) continue;
          try {
            final parsed = messageFrom(m);
            if (parsed != null) messages.add(parsed);
          } catch (e) {
            failures.add(ImportFailure(index: i, reason: 'message $j: $e'));
          }
        }
        if (messages.isEmpty) continue;
        final now = DateTime.now();
        result.add(
          ChatSession(
            id: stableSessionId(
              'cherry',
              c['id'] as String? ?? '${now.microsecondsSinceEpoch}',
            ),
            title: (c['name'] as String? ?? '').trim().isEmpty
                ? 'Imported from Cherry Studio'
                : c['name'] as String,
            messages: messages,
            createdAt: parseImportTime(c['createdAt']) ?? now,
            updatedAt: parseImportTime(c['updatedAt']) ?? now,
          ),
        );
      } catch (e) {
        failures.add(ImportFailure(index: i, reason: e.toString()));
      }
    }
    return BackupImportResult(sessions: result, failedItems: failures);
  }

  /// 解析单条 Cherry Studio 消息：content 可为字符串或 [{type, text, url}]。
  static ChatMessage? messageFrom(Map<String, dynamic> m) {
    final role = m['role'] as String? ?? 'user';
    final raw = m['content'];
    final sb = StringBuffer();
    final images = <ChatImage>[];
    if (raw is String) {
      sb.write(raw);
    } else if (raw is List) {
      for (final part in raw) {
        if (part is! Map<String, dynamic>) continue;
        final type = part['type'] as String? ?? 'text';
        final text = part['text'] as String?;
        if (type == 'text' && text != null) sb.write(text);
        if (type == 'image') {
          final url = (part['url'] ?? part['image']) as String?;
          if (url != null) images.add(imageFromUrl(url));
        }
      }
    }
    // 推理内容（deepseek 等）
    final reasoning = m['reasoning_content'] as String? ?? m['thinking'] as String?;
    if (sb.isEmpty &&
        images.isEmpty &&
        (reasoning == null || reasoning.isEmpty)) {
      return null;
    }
    return ChatMessage(
      role: role,
      content: sb.toString().trim(),
      images: images,
      reasoningContent: reasoning ?? '',
    );
  }
}

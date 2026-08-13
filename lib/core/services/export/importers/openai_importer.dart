import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../backup_archive.dart';
import 'importer_utils.dart';

/// OpenAI 官方导出解析：`conversations.json`。
///
/// 结构：`[{"title", "create_time", "update_time", "mapping": {
///   "&lt;id&gt;": {"message": {"role", "content": {"parts": [...]}, ...},
///              "parent": "&lt;parentId&gt;"}}]`。
/// mapping 嵌套树递归展平 → 按 create_time 排序 → 消息。
class OpenAiImporter {
  static bool matches(Map<String, dynamic> data) =>
      data.containsKey('mapping') &&
      data['mapping'] is Map &&
      (data['title'] is String || data['title'] == null);

  static BackupImportResult parse(Map<String, dynamic> data) {
    final sessions = <ChatSession>[];
    final failures = <ImportFailure>[];
    try {
      final messages = _flattenMapping(data['mapping'] as Map<String, dynamic>);
      if (messages.isEmpty) return const BackupImportResult(sessions: []);
      final now = DateTime.now();
      sessions.add(
        ChatSession(
          id: stableSessionId(
            'openai',
            data['id'] as String? ?? '${now.microsecondsSinceEpoch}',
          ),
          title: (data['title'] as String? ?? '').trim().isEmpty
              ? 'Imported from ChatGPT'
              : data['title'] as String,
          messages: messages,
          createdAt: _time(data['create_time']) ?? now,
          updatedAt: _time(data['update_time']) ?? now,
        ),
      );
    } catch (e) {
      failures.add(ImportFailure(index: 0, reason: e.toString()));
    }
    return BackupImportResult(sessions: sessions, failedItems: failures);
  }

  /// 递归展平 mapping 树（DFS，按 parent 链排序）。
  static List<ChatMessage> _flattenMapping(Map<String, dynamic> mapping) {
    final byId = <String, Map<String, dynamic>>{};
    for (final e in mapping.entries) {
      if (e.value is Map<String, dynamic>) {
        byId[e.key] = e.value as Map<String, dynamic>;
      }
    }
    final result = <ChatMessage>[];
    void visit(String id) {
      final node = byId[id];
      if (node == null) return;
      final message = node['message'];
      if (message is Map<String, dynamic>) {
        final m = _messageFromOpenAi(message);
        if (m != null) result.add(m);
      }
      final children = node['children'] as List<dynamic>? ?? const [];
      for (final child in children) {
        visit(child.toString());
      }
    }

    // 从根节点开始（无 parent 的节点）
    final roots = byId.entries
        .where((e) => e.value['parent'] == null)
        .map((e) => e.key)
        .toList();
    for (final root in roots) {
      visit(root);
    }
    return result;
  }

  static ChatMessage? _messageFromOpenAi(Map<String, dynamic> message) {
    final role = message['author'] as Map<String, dynamic>?;
    final roleName = role?['role'] as String? ?? 'user';
    final content = message['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    final sb = StringBuffer();
    final images = <ChatImage>[];
    for (final p in parts) {
      if (p is String) {
        sb.write(p);
      } else if (p is Map<String, dynamic>) {
        final ct = p['content_type'] as String?;
        if (ct == 'text') {
          sb.write(p['text'] ?? '');
        } else if (ct == 'image_url') {
          final url = (p['image_url'] as Map<String, dynamic>?)?['url'];
          if (url is String) images.add(imageFromUrl(url));
        } else if (ct == 'input_audio') {
          sb.writeln('[audio input]');
        }
      }
    }
    final reasoning = message['reasoning'] as Map<String, dynamic>?;
    final reasoningText = reasoning?['summary'] as List<dynamic>? ?? const [];
    final reasoningSb = StringBuffer();
    for (final s in reasoningText) {
      if (s is Map<String, dynamic>) reasoningSb.write(s['text'] ?? '');
    }
    if (sb.isEmpty && images.isEmpty && reasoningSb.isEmpty) return null;
    return ChatMessage(
      role: roleName == 'tool' ? 'tool' : (roleName == 'system' ? 'system' : roleName == 'assistant' ? 'assistant' : 'user'),
      content: sb.toString().trim(),
      images: images,
      reasoningContent: reasoningSb.toString().trim(),
      sentAt: _time(message['create_time']),
    );
  }

  static DateTime? _time(Object? v) {
    if (v is num && v > 0) {
      return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
    }
    return null;
  }
}

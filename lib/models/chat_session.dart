import 'chat_message.dart';
import 'chat_options.dart';

/// 一个会话，包含标题、上下文参数与消息列表。
class ChatSession {
  final String id;
  String title;
  ChatOptions options;

  /// 会话上下文来源 Agent 的 id，null 表示自定义配置。
  String? agentId;

  /// 会话使用的服务商 id 与模型 id，null 表示使用默认服务商。
  String? providerId;
  String? modelId;

  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  /// 是否置顶（置顶会话显示在会话列表最上方）。
  bool pinned;

  ChatSession({
    required this.id,
    required this.title,
    this.options = const ChatOptions(),
    this.agentId,
    this.providerId,
    this.modelId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  /// 创建一个新的空会话。
  factory ChatSession.create() {
    final now = DateTime.now();
    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: '新对话',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 根据第一条用户消息生成会话标题。
  void updateTitleFromFirstMessage() {
    for (final m in messages) {
      if (m.role == 'user') {
        final text = m.content.trim().replaceAll('\n', ' ');
        if (text.isNotEmpty) {
          title = text.length > 20 ? '${text.substring(0, 20)}…' : text;
        }
        return;
      }
    }
  }

  /// 复制会话（新 id，标题带副本后缀，保留全部消息与参数）。
  ChatSession duplicate() {
    final now = DateTime.now();
    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: '$title（副本）',
      options: options,
      agentId: agentId,
      providerId: providerId,
      modelId: modelId,
      messages: messages
          .map(
            (m) => ChatMessage(
              role: m.role,
              content: m.content,
              reasoningContent: m.reasoningContent,
              interrupted: m.interrupted,
              failed: m.failed,
              promptTokens: m.promptTokens,
              completionTokens: m.completionTokens,
              elapsedMs: m.elapsedMs,
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 删除 [index] 及之后的所有消息。
  void truncateMessagesFrom(int index) {
    if (index >= 0 && index < messages.length) {
      messages.removeRange(index, messages.length);
    }
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? '新对话',
      options: ChatOptions.fromJson(json['options'] as Map<String, dynamic>?),
      agentId: json['agentId'] as String?,
      providerId: json['providerId'] as String?,
      modelId: json['modelId'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'options': options.toJson(),
    'agentId': agentId,
    'providerId': providerId,
    'modelId': modelId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pinned': pinned,
  };
}

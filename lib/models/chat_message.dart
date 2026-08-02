/// 单条聊天消息。
class ChatMessage {
  /// 消息角色：user / assistant / system。
  final String role;

  /// 消息正文（流式输出时会被累加更新）。
  String content;

  /// 思考内容（assistant 专属，流式时累加更新）。
  String reasoningContent;

  ChatMessage({
    required this.role,
    required this.content,
    this.reasoningContent = '',
  });

  /// 转为 OpenAI API 请求中的消息格式。
  Map<String, dynamic> toApiJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      reasoningContent: json['reasoningContent'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'reasoningContent': reasoningContent,
  };
}

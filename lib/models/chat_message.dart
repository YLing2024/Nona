/// 单条聊天消息。
class ChatMessage {
  /// 消息角色：user / assistant / system。
  final String role;

  /// 消息正文（流式输出时会被累加更新）。
  String content;

  /// 思考内容（assistant 专属，流式时累加更新）。
  String reasoningContent;

  /// 生成是否被用户手动停止（assistant 专属）。
  bool interrupted;

  /// 请求是否失败（assistant 专属，失败但保留部分内容时标记）。
  bool failed;

  /// 本次回复的 prompt 用量（tokens），assistant 专属。
  int? promptTokens;

  /// 本次回复的 completion 用量（tokens），assistant 专属。
  int? completionTokens;

  /// 生成耗时（毫秒），assistant 专属。
  int? elapsedMs;

  /// 本次回复使用的服务商名称与模型 id（assistant 专属，用于消息头标注）。
  String? providerName;
  String? modelId;

  ChatMessage({
    required this.role,
    required this.content,
    this.reasoningContent = '',
    this.interrupted = false,
    this.failed = false,
    this.promptTokens,
    this.completionTokens,
    this.elapsedMs,
    this.providerName,
    this.modelId,
  });

  /// 转为 OpenAI API 请求中的消息格式。
  Map<String, dynamic> toApiJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      reasoningContent: json['reasoningContent'] as String? ?? '',
      interrupted: json['interrupted'] as bool? ?? false,
      failed: json['failed'] as bool? ?? false,
      promptTokens: json['promptTokens'] as int?,
      completionTokens: json['completionTokens'] as int?,
      elapsedMs: json['elapsedMs'] as int?,
      providerName: json['providerName'] as String?,
      modelId: json['modelId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'reasoningContent': reasoningContent,
    'interrupted': interrupted,
    'failed': failed,
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
    'elapsedMs': elapsedMs,
    'providerName': providerName,
    'modelId': modelId,
  };
}

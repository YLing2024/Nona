import 'chat_message.dart';
import 'chat_options.dart';

/// 一次摘要压缩的记录：被压缩消息区间 + 摘要 + 原始消息（展开/还原用）。
class CompressedBlock {
  final String id;
  final int startIndex;
  final int endIndex;
  final String summary;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  const CompressedBlock({
    required this.id,
    required this.startIndex,
    required this.endIndex,
    required this.summary,
    required this.messages,
    required this.createdAt,
  });

  factory CompressedBlock.fromJson(Map<String, dynamic> json) =>
      CompressedBlock(
        id: json['id'] as String,
        startIndex: json['startIndex'] as int? ?? 0,
        endIndex: json['endIndex'] as int? ?? 0,
        summary: json['summary'] as String? ?? '',
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startIndex': startIndex,
    'endIndex': endIndex,
    'summary': summary,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}

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

  /// 摘要压缩（F3-1）：最早消息被压缩成的会话摘要，随请求注入。
  String summary;

  /// 摘要估算 token 数（供预算管理）。
  int? summaryTokens;

  /// 压缩记录（被压缩消息区间 + 原始消息）。
  List<CompressedBlock> compressedBlocks;

  /// 会话级记忆（F4-3，sessions.memory 列）。
  String memory;

  /// 标签 id 列表（G-06，sessions.tags_json 列）。
  List<String> tags;

  /// 上下文清除标记：截断到该消息索引（B-08，可恢复，sessions.truncate_index）。
  int? truncateIndex;

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
    this.summary = '',
    this.summaryTokens,
    this.compressedBlocks = const [],
    this.memory = '',
    this.tags = const [],
    this.truncateIndex,
  });

  /// 创建一个新的空会话；[defaultTitle] 为本地化默认标题，
  /// 未提供时使用内置中文默认值（旧数据兼容）。
  factory ChatSession.create({String? defaultTitle}) {
    final now = DateTime.now();
    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: defaultTitle ?? 'New chat',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 压缩的原始消息总数（跨全部压缩块）。
  int get compressedMessageCount =>
      compressedBlocks.fold(0, (sum, b) => sum + b.messages.length);

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

  /// 复制会话（新 id，标题带副本后缀，保留全部消息与参数）；
  /// [copySuffix] 为本地化副本后缀。
  ChatSession duplicate({String copySuffix = ' (copy)'}) {
    final now = DateTime.now();
    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: '$title$copySuffix',
      options: options,
      agentId: agentId,
      providerId: providerId,
      modelId: modelId,
      messages: messages
          .map(
            (m) => ChatMessage(
              role: m.role,
              content: m.content,
              images: m.images,
              documents: m.documents,
              alternatives: m.alternatives,
              reasoningContent: m.reasoningContent,
              interrupted: m.interrupted,
              failed: m.failed,
              promptTokens: m.promptTokens,
              completionTokens: m.completionTokens,
              elapsedMs: m.elapsedMs,
              providerName: m.providerName,
              modelId: m.modelId,
              toolCallId: m.toolCallId,
              toolCallsJson: m.toolCallsJson,
              citations: m.citations,
              partsJson: m.partsJson,
              toolStepsJson: m.toolStepsJson,
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
      tags: tags,
      truncateIndex: truncateIndex,
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
      title: json['title'] as String? ?? 'New chat',
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
      summary: json['summary'] as String? ?? '',
      summaryTokens: json['summaryTokens'] as int?,
      memory: json['memory'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      truncateIndex: json['truncateIndex'] as int?,
      compressedBlocks: (json['compressedBlocks'] as List<dynamic>? ?? [])
          .map((b) => CompressedBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
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
    'summary': summary,
    if (summaryTokens != null) 'summaryTokens': summaryTokens,
    'memory': memory,
    if (tags.isNotEmpty) 'tags': tags,
    if (truncateIndex != null) 'truncateIndex': truncateIndex,
    'compressedBlocks': compressedBlocks.map((b) => b.toJson()).toList(),
  };
}

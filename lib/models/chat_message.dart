import 'dart:convert';

import '../services/document_extractor.dart' show ChatDocument;

/// 一条用户消息携带的图片（多模态输入）。
class ChatImage {
  /// 图片地址：本地文件转为 `data:image/png;base64,...` 的 Data URL，
  /// 或直接使用 http(s) 网络图片地址。
  final String url;

  /// MIME 类型，例如 image/png / image/jpeg。
  final String mimeType;

  const ChatImage({required this.url, required this.mimeType});

  bool get isDataUrl => url.startsWith('data:');

  bool get isNetwork => url.startsWith('http://') || url.startsWith('https://');

  /// OpenAI 视觉接口单张图片的近似 token 开销（估算，用于上下文管理）。
  int get estimatedTokens {
    if (!isDataUrl) return 85;
    // base64 体积 → 字节数 → 粗略像素级 token 估算
    final prefixLen = url.indexOf(',');
    if (prefixLen <= 0) return 85;
    final bytes = (url.length - prefixLen - 1) * 3 ~/ 4;
    // 经验值：约每 3KB 图片 ≈ 85 token（512x512 左右）
    return 85 * (bytes ~/ 3000) + 85;
  }

  factory ChatImage.fromDataUrl(String dataUrl) {
    final mime = Uri.tryParse(dataUrl)?.data?.mimeType ?? 'image/*';
    return ChatImage(url: dataUrl, mimeType: mime);
  }

  factory ChatImage.fromJson(Map<String, dynamic> json) => ChatImage(
    url: json['url'] as String,
    mimeType: json['mimeType'] as String? ?? 'image/*',
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'mimeType': mimeType,
  };
}

/// 单条聊天消息。
class ChatMessage {
  /// 消息角色：user / assistant / system。
  final String role;

  /// 消息正文（流式输出时会被累加更新）。
  String content;

  /// 用户消息附带的图片（多模态输入）。
  /// 非 final：OCR（F1-5）成功后清空以「替换为文本」。
  List<ChatImage> images;

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

  /// 工具角色消息：对应的工具调用 id（tool 专属）。
  String? toolCallId;

  /// assistant 消息的 tool_calls JSON 字符串（工具调用循环使用）。
  String? toolCallsJson;

  /// 消息发送时间（F3-2 统计用；回填时取会话更新时间）。
  DateTime? sentAt;

  /// 附加文档（PDF/DOCX/TXT 提取的文本）。
  final List<ChatDocument> documents;

  /// 同一位置的历史版本（重新生成时保存的旧回复，不含当前内容）。
  List<ChatMessage> alternatives;

  ChatMessage({
    required this.role,
    required this.content,
    this.images = const [],
    this.documents = const [],
    this.alternatives = const [],
    this.reasoningContent = '',
    this.interrupted = false,
    this.failed = false,
    this.promptTokens,
    this.completionTokens,
    this.elapsedMs,
    this.providerName,
    this.modelId,
    this.toolCallId,
    this.toolCallsJson,
    this.sentAt,
  });

  /// 生成一个仅正文变化的副本（重新生成时保存旧版本用）。
  ChatMessage withContent(String newContent, {String? newReasoning}) =>
      ChatMessage(
        role: role,
        content: newContent,
        images: images,
        documents: documents,
        alternatives: alternatives,
        reasoningContent: newReasoning ?? reasoningContent,
        interrupted: interrupted,
        failed: failed,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        elapsedMs: elapsedMs,
        providerName: providerName,
        modelId: modelId,
        toolCallId: toolCallId,
        toolCallsJson: toolCallsJson,
      );

  /// 是否有可发送的正文（文本、图片、文档，或工具调用消息）。
  ///
  /// 工具角色消息即使正文为空也必须保留：`tool_calls` / `tool_call_id`
  /// 必须伴随其对应的 assistant/tool 消息一起发送，否则 API 会报 400。
  bool get hasSendableContent =>
      content.trim().isNotEmpty ||
      images.isNotEmpty ||
      documents.isNotEmpty ||
      toolCallId != null ||
      toolCallsJson != null;

  /// 转为 OpenAI API 请求中的消息格式。
  ///
  /// 无图片/文档时保持纯文本 `content` 字符串（兼容旧接口）；
  /// 有图片时输出 `content` 数组（`text` + `image_url` 多模态格式）；
  /// 文档文本拼入 text part；tool 消息附带 tool_call_id。
  Map<String, dynamic> toApiJson() {
    // 工具调用消息：content 可为空，必须携带 tool_calls（正文为空时省略
    // content 字段，避免空数组被部分服务端拒绝）。
    if (toolCallsJson != null) {
      return {
        'role': role,
        if (content.trim().isNotEmpty) 'content': content,
        'tool_calls': jsonDecode(toolCallsJson!) as List<dynamic>,
      };
    }
    // 纯文本工具结果消息。
    if (toolCallId != null && images.isEmpty && documents.isEmpty) {
      return {'role': role, 'content': content, 'tool_call_id': toolCallId};
    }
    if (images.isEmpty && documents.isEmpty) {
      return {'role': role, 'content': content};
    }
    final documentText = [
      for (final doc in documents) '[doc: ${doc.name}]\n${doc.text}',
    ].join('\n\n');
    return {
      'role': role,
      'content': [
        if (documentText.isNotEmpty)
          {'type': 'text', 'text': documentText},
        if (content.trim().isNotEmpty) {'type': 'text', 'text': content},
        for (final img in images)
          {
            'type': 'image_url',
            'image_url': {'url': img.url},
          },
      ],
      if (toolCallId != null) 'tool_call_id': toolCallId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => ChatImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map(
            (e) => ChatDocument(
              name: (e as Map<String, dynamic>)['name'] as String? ?? '',
              text: e['text'] as String? ?? '',
            ),
          )
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
      reasoningContent: json['reasoningContent'] as String? ?? '',
      interrupted: json['interrupted'] as bool? ?? false,
      failed: json['failed'] as bool? ?? false,
      promptTokens: json['promptTokens'] as int?,
      completionTokens: json['completionTokens'] as int?,
      elapsedMs: json['elapsedMs'] as int?,
      providerName: json['providerName'] as String?,
      modelId: json['modelId'] as String?,
      toolCallId: json['toolCallId'] as String?,
      toolCallsJson: json['toolCallsJson'] as String?,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'images': images.map((e) => e.toJson()).toList(),
    'documents': [
      for (final d in documents) {'name': d.name, 'text': d.text},
    ],
    'alternatives': alternatives.map((e) => e.toJson()).toList(),
    'reasoningContent': reasoningContent,
    'interrupted': interrupted,
    'failed': failed,
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
    'elapsedMs': elapsedMs,
    'providerName': providerName,
    'modelId': modelId,
    'toolCallId': toolCallId,
    'toolCallsJson': toolCallsJson,
    if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
  };
}

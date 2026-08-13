import 'dart:convert';

/// F-04：工具调用步骤（渲染用，随消息落库 tool_steps_json）。
class ToolStep {
  final String callId;

  /// 工具名。
  final String name;

  /// 参数 JSON 字符串。
  final String argumentsJson;

  /// executing / done / error / waitingApproval。
  String status;

  /// 结果摘要（超长截断）。
  String resultText;

  /// 结果中的图片（data url 或网络地址）。
  final List<String> resultImages;

  /// 开始时间。
  final DateTime startedAt;

  ToolStep({
    required this.callId,
    required this.name,
    required this.argumentsJson,
    this.status = 'executing',
    this.resultText = '',
    this.resultImages = const [],
    required this.startedAt,
  });

  factory ToolStep.fromJson(Map<String, dynamic> json) => ToolStep(
    callId: json['callId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    argumentsJson: json['argumentsJson'] as String? ?? '{}',
    status: json['status'] as String? ?? 'executing',
    resultText: json['resultText'] as String? ?? '',
    resultImages: (json['resultImages'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'callId': callId,
    'name': name,
    'argumentsJson': argumentsJson,
    'status': status,
    'resultText': resultText,
    'resultImages': resultImages,
    'startedAt': startedAt.toIso8601String(),
  };

  ToolStep copyWith({
    String? status,
    String? resultText,
    List<String>? resultImages,
  }) => ToolStep(
    callId: callId,
    name: name,
    argumentsJson: argumentsJson,
    status: status ?? this.status,
    resultText: resultText ?? this.resultText,
    resultImages: resultImages ?? this.resultImages,
    startedAt: startedAt,
  );
}

/// 工具步骤 JSON 编解码。
class ToolStepsCodec {
  ToolStepsCodec._();

  static List<ToolStep> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) ToolStep.fromJson(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<ToolStep> steps) =>
      jsonEncode(steps.map((s) => s.toJson()).toList());
}

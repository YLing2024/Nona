import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../chat_service.dart' show ChatUsage;
import 'protocol_adapter.dart';
import 'protocol_factory.dart' show ProviderKind;

/// OpenAI 兼容协议（chat/completions）。
class OpenAiAdapter implements ProtocolAdapter {
  const OpenAiAdapter();

  @override
  ProviderKind get kind => ProviderKind.openai;

  /// 结束标记判断（OpenAI 流式 `[DONE]` 字符串）。
  static bool isDoneMarker(String data) => data == '[DONE]';

  @override
  Uri uriFor(String baseUrl, String model) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/chat/completions');
  }

  @override
  Map<String, String> headersFor(String apiKey) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  @override
  Map<String, dynamic> buildBody(
    String model,
    ChatOptions options,
    List<ChatMessage> apiMessages,
    List<Map<String, dynamic>>? tools,
  ) {
    return {
      'model': model,
      'messages': apiMessages.map((m) => m.toApiJson()).toList(),
      'stream': options.stream,
      if (options.reasoningEffort != null)
        'reasoning_effort': options.reasoningEffort,
      'temperature': options.temperature,
      'top_p': options.topP,
      'presence_penalty': options.presencePenalty,
      'frequency_penalty': options.frequencyPenalty,
      if (options.maxTokens != null) 'max_tokens': options.maxTokens,
      if (options.n != null) 'n': options.n,
      if (options.stop.isNotEmpty) 'stop': options.stop,
      if (options.seed != null) 'seed': options.seed,
      if (options.responseFormat != null)
        'response_format': {'type': options.responseFormat},
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      if (tools != null && tools.isNotEmpty) 'tool_choice': 'auto',
    };
  }

  @override
  ParsedDelta parseDelta(Map<String, dynamic> json) {
    final usageJson = json['usage'] as Map<String, dynamic>?;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      if (usageJson == null) return const ParsedDelta.unrecognized();
      return ParsedDelta.delta(StreamDelta(usage: ChatUsage.fromJson(usageJson)));
    }
    final delta = (choices.first as Map<String, dynamic>)['delta']
        as Map<String, dynamic>?;
    if (delta == null) {
      // 无 delta 字段：非 OpenAI 流式格式（如整包 `message.content` 包装），
      // 交给整包 JSON 兜底解析
      if (usageJson == null) return const ParsedDelta.unrecognized();
      return ParsedDelta.delta(StreamDelta(usage: ChatUsage.fromJson(usageJson)));
    }
    final content = delta['content'] as String?;
    final reasoning =
        (delta['reasoning_content'] ?? delta['reasoning']) as String?;
    final toolCalls = _extractToolCalls(delta['tool_calls'] as List<dynamic>?);
    if (content != null && content.isNotEmpty) {
      return ParsedDelta.delta(
        StreamDelta(
          content: content,
          reasoning: (reasoning == null || reasoning.isEmpty)
              ? null
              : reasoning,
          usage: usageJson == null ? null : ChatUsage.fromJson(usageJson),
          toolCalls: toolCalls,
        ),
      );
    }
    if (reasoning != null && reasoning.isNotEmpty) {
      return ParsedDelta.delta(
        StreamDelta(
          reasoning: reasoning,
          usage: usageJson == null ? null : ChatUsage.fromJson(usageJson),
          toolCalls: toolCalls,
        ),
      );
    }
    if (toolCalls != null && toolCalls.isNotEmpty) {
      return ParsedDelta.delta(
        StreamDelta(
          usage: usageJson == null ? null : ChatUsage.fromJson(usageJson),
          toolCalls: toolCalls,
        ),
      );
    }
    if (usageJson != null) {
      return ParsedDelta.delta(StreamDelta(usage: ChatUsage.fromJson(usageJson)));
    }
    // 合法空块（role-only delta / 空内容）：不缓存
    return const ParsedDelta.none();
  }

  /// 提取流式 tool_calls 增量分片（OpenAI delta 按 index 分片到达）。
  static List<ToolCallDelta>? _extractToolCalls(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final result = <ToolCallDelta>[];
    for (final tc in raw) {
      if (tc is! Map<String, dynamic>) continue;
      final index = tc['index'] as int? ?? 0;
      final fn = tc['function'] as Map<String, dynamic>?;
      result.add(
        ToolCallDelta(
          index: index,
          id: tc['id'] as String?,
          name: fn?['name'] as String?,
          arguments: fn?['arguments'] as String?,
        ),
      );
    }
    return result;
  }

  @override
  (String, ChatUsage?)? parseNonStream(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) return null;
    final message =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>?;
    final content = message?['content'] ?? message?['reasoning_content'];
    if (content == null) return null;
    final usageJson = json['usage'] as Map<String, dynamic>?;
    return (
      content as String,
      usageJson == null ? null : ChatUsage.fromJson(usageJson),
    );
  }
}

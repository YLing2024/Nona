import 'dart:convert';

import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../chat_service.dart' show ChatUsage;
import 'protocol_adapter.dart';
import 'protocol_factory.dart' show ProviderKind;

/// Anthropic Messages 协议。
class AnthropicAdapter implements ProtocolAdapter {
  AnthropicAdapter();

  static const String anthropicVersion = '2023-06-01';

  @override
  ProviderKind get kind => ProviderKind.anthropic;

  @override
  Uri uriFor(String baseUrl, String model) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/messages');
  }

  @override
  Map<String, String> headersFor(String apiKey) => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
    'anthropic-version': anthropicVersion,
  };

  @override
  Map<String, dynamic> buildBody(
    String model,
    ChatOptions options,
    List<ChatMessage> apiMessages,
    List<Map<String, dynamic>>? tools,
  ) {
    final system = <String>[
      for (final m in apiMessages)
        if (m.role == 'system' && m.content.trim().isNotEmpty) m.content.trim(),
    ].join('\n\n');

    // Anthropic 角色仅 user/assistant；消息需连续角色合并
    final messages = <Map<String, dynamic>>[];
    for (final m in apiMessages) {
      if (m.role == 'system') continue;
      final role = m.role == 'assistant' ? 'assistant' : 'user';
      final content = _content(m);
      final last = messages.isNotEmpty ? messages.last : null;
      if (last != null && last['role'] == role) {
        (last['content'] as List).addAll(content);
      } else {
        messages.add({'role': role, 'content': content});
      }
    }
    return {
      'model': model,
      'max_tokens': options.maxTokens ?? 4096,
      if (system.isNotEmpty) 'system': system,
      'messages': messages,
      'stream': options.stream,
      'temperature': options.temperature,
      'top_p': options.topP,
      if (options.stop.isNotEmpty) 'stop_sequences': options.stop,
      if (tools != null && tools.isNotEmpty) 'tools': _toolsBody(tools),
      if (tools != null && tools.isNotEmpty)
        'tool_choice': {'type': 'auto'},
    };
  }

  /// OpenAI function 定义 → Anthropic tools 格式。
  static List<Map<String, dynamic>> _toolsBody(
    List<Map<String, dynamic>> tools,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final t in tools) {
      final fn = t['function'] as Map<String, dynamic>?;
      if (fn == null) continue;
      final name = fn['name'] as String?;
      if (name == null || name.isEmpty) continue;
      result.add({
        'name': name,
        'description': fn['description'] as String? ?? '',
        if (fn['parameters'] != null) 'input_schema': fn['parameters'],
      });
    }
    return result;
  }

  List<Map<String, dynamic>> _content(ChatMessage m) {
    // 工具调用消息：toolCallsJson（OpenAI 格式）→ tool_use 块
    final parts = <Map<String, dynamic>>[];
    if (m.toolCallsJson != null) {
      if (m.content.trim().isNotEmpty) {
        parts.add({'type': 'text', 'text': m.content});
      }
      try {
        final calls = jsonDecode(m.toolCallsJson!) as List<dynamic>;
        for (final c in calls) {
          if (c is! Map<String, dynamic>) continue;
          final fn = c['function'] as Map<String, dynamic>? ?? const {};
          final rawArgs = fn['arguments'] as String? ?? '{}';
          Object? input;
          try {
            input = jsonDecode(rawArgs);
          } catch (_) {
            input = rawArgs;
          }
          parts.add({
            'type': 'tool_use',
            'id': c['id'] as String? ?? '',
            'name': fn['name'] as String? ?? '',
            'input': input ?? {},
          });
        }
      } catch (_) {
        // toolCallsJson 损坏：忽略工具块
      }
      return parts;
    }
    // 工具结果消息（role=tool）→ tool_result 块
    if (m.role == 'tool' && m.toolCallId != null) {
      parts.add({
        'type': 'tool_result',
        'tool_use_id': m.toolCallId,
        'content': [{'type': 'text', 'text': m.content}],
      });
      return parts;
    }
    if (m.content.trim().isNotEmpty) {
      parts.add({'type': 'text', 'text': m.content});
    }
    for (final img in m.images) {
      if (!img.isDataUrl) {
        parts.add({
          'type': 'image',
          'source': {'type': 'url', 'url': img.url},
        });
        continue;
      }
      final comma = img.url.indexOf(',');
      if (comma > 0) {
        parts.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': img.mimeType,
            'data': img.url.substring(comma + 1),
          },
        });
      }
    }
    return parts;
  }

  /// 流式 tool_use 块缓冲：content_block_start 起按块索引暂存，
  /// content_block_stop 组装为完整 ToolCallDelta 返回。
  final Map<int, _ToolUseBlock> _toolUseBlocks = {};

  @override
  ParsedDelta parseDelta(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'content_block_start':
        final block = json['content_block'] as Map<String, dynamic>?;
        if (block?['type'] == 'tool_use') {
          final index = json['index'] as int? ?? 0;
          _toolUseBlocks[index] = _ToolUseBlock(
            id: block!['id'] as String? ?? '',
            name: block['name'] as String? ?? '',
          );
          return const ParsedDelta.none();
        }
        // 非 tool_use 的块起始（text 等）：无操作
        return const ParsedDelta.none();
      case 'content_block_delta':
        final delta = json['delta'] as Map<String, dynamic>?;
        if (delta == null) return const ParsedDelta.none();
        final deltaType = delta['type'] as String?;
        if (deltaType == 'text_delta') {
          final text = delta['text'] as String?;
          return text == null || text.isEmpty
              ? const ParsedDelta.none()
              : ParsedDelta.delta(StreamDelta(content: text));
        }
        if (deltaType == 'thinking_delta') {
          final thinking = delta['thinking'] as String?;
          return thinking == null || thinking.isEmpty
              ? const ParsedDelta.none()
              : ParsedDelta.delta(StreamDelta(reasoning: thinking));
        }
        if (deltaType == 'input_json_delta') {
          final index = json['index'] as int? ?? 0;
          final partial = delta['partial_json'] as String? ?? '';
          _toolUseBlocks[index]?.argsBuf.write(partial);
          return const ParsedDelta.none();
        }
        return const ParsedDelta.unrecognized();
      case 'content_block_stop':
        final index = json['index'] as int? ?? 0;
        final block = _toolUseBlocks.remove(index);
        if (block != null && block.id.isNotEmpty && block.name.isNotEmpty) {
          var args = block.argsBuf.toString().trim();
          if (args.isEmpty) args = '{}';
          return ParsedDelta.delta(
            StreamDelta(
              toolCalls: [
                ToolCallDelta(
                  index: index,
                  id: block.id,
                  name: block.name,
                  arguments: args,
                ),
              ],
            ),
          );
        }
        return const ParsedDelta.none();
      case 'message_start':
        final message = json['message'] as Map<String, dynamic>?;
        final usage = message?['usage'] as Map<String, dynamic>?;
        if (usage == null) return const ParsedDelta.none();
        return ParsedDelta.delta(StreamDelta(usage: _usage(usage, null)));
      case 'message_delta':
        final usage = json['usage'] as Map<String, dynamic>?;
        if (usage == null) return const ParsedDelta.none();
        return ParsedDelta.delta(StreamDelta(usage: _usage(null, usage)));
      case 'message_stop':
        return const ParsedDelta.delta(StreamDelta(done: true));
      default:
        return const ParsedDelta.unrecognized();
    }
  }

  ChatUsage _usage(
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
  ) {
    return ChatUsage(
      promptTokens: input?['input_tokens'] as int? ?? 0,
      completionTokens: output?['output_tokens'] as int? ?? 0,
    );
  }

  @override
  (String, ChatUsage?)? parseNonStream(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? const [];
    final sb = StringBuffer();
    // 非流式响应中的 tool_use 块：直接组装工具调用（无 id 时用索引占位）
    var toolIndex = 0;
    for (final c in content) {
      if (c is! Map<String, dynamic>) continue;
      final cType = c['type'];
      if (cType == 'text') {
        sb.write(c['text'] ?? '');
      } else if (cType == 'tool_use') {
        final id = c['id'] as String? ?? 'call_$toolIndex';
        final name = c['name'] as String? ?? '';
        if (name.isNotEmpty) {
          _nonStreamToolCalls ??= [];
          _nonStreamToolCalls!.add(
            ToolCallDelta(
              index: toolIndex,
              id: id,
              name: name,
              arguments: jsonEncode(c['input'] ?? const {}),
            ),
          );
          toolIndex++;
        }
      }
    }
    if (sb.isEmpty && _nonStreamToolCalls == null) return null;
    return (
      sb.toString(),
      _usage(json['usage'] as Map<String, dynamic>?, null),
    );
  }

  /// 非流式整包 JSON 兜底解析时收集的工具调用（parseNonStream 调用期间有效）。
  List<ToolCallDelta>? _nonStreamToolCalls;
}

/// 流式 tool_use 块缓冲。
class _ToolUseBlock {
  final String id;
  final String name;
  final StringBuffer argsBuf;

  _ToolUseBlock({required this.id, required this.name})
      : argsBuf = StringBuffer();
}

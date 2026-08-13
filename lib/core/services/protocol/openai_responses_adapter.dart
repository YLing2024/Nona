import 'dart:convert';

import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../chat_service.dart' show ChatUsage;
import 'protocol_adapter.dart';
import 'protocol_factory.dart' show ProviderKind;

/// C-01：OpenAI Responses API 适配器（/responses）。
///
/// 适用于 o1/o3/o4/gpt-5 系列：事件流分发
/// `response.output_text.delta` / `response.reasoning_summary_text.delta` /
/// `response.output_item.done` / `response.function_call_arguments.delta` /
/// `response.completed`；工具格式展平为 `{type,name,description,parameters}`。
class OpenAiResponsesAdapter implements ProtocolAdapter {
  const OpenAiResponsesAdapter();

  @override
  ProviderKind get kind => ProviderKind.openai;

  @override
  Uri uriFor(String baseUrl, String model) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/responses');
  }

  @override
  Map<String, String> headersFor(String apiKey) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  /// 将 ChatMessage 历史转换为 Responses input 块。
  static List<Map<String, dynamic>> messagesToInput(List<ChatMessage> msgs) {
    final input = <Map<String, dynamic>>[];
    for (final m in msgs) {
      final role = m.role;
      if (role == 'user') {
        if (m.images.isNotEmpty) {
          // 多模态：input_image + input_text 块
          for (final img in m.images) {
            if (img.isNetwork) {
              input.add({
                'type': 'input_image',
                'image_url': img.url,
              });
            } else if (img.isDataUrl) {
              input.add({
                'type': 'input_image',
                'image_url': img.url,
              });
            }
          }
          if (m.content.trim().isNotEmpty) {
            input.add({
              'type': 'input_text',
              'text': m.content,
            });
          }
        } else {
          input.add({
            'type': 'input_text',
            'text': m.content,
          });
        }
      } else if (role == 'assistant') {
        if (m.toolCallsJson != null && m.toolCallsJson!.isNotEmpty) {
          // 工具调用轮：function_call 块
          final calls = _parseToolCalls(m.toolCallsJson!);
          for (final c in calls) {
            input.add({
              'type': 'function_call',
              'call_id': c['id'],
              'name': c['name'],
              'arguments': c['arguments'],
            });
          }
        }
        if (m.content.trim().isNotEmpty) {
          input.add({
            'type': 'message',
            'role': 'assistant',
            'status': 'completed',
            'content': [
              {'type': 'output_text', 'text': m.content},
            ],
          });
        }
      } else if (role == 'tool') {
        // 工具结果：function_call_output（兼容 toolCallId 字段名）
        input.add({
          'type': 'function_call_output',
          'call_id': m.toolCallId ?? '',
          'output': m.content,
        });
      }
    }
    return input;
  }

  static List<Map<String, String>> _parseToolCalls(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(
              (c) => {
                'id': c['id']?.toString() ?? '',
                'name': (c['function'] as Map<String, dynamic>?)?['name']
                        ?.toString() ??
                    c['name']?.toString() ??
                    '',
                'arguments': (c['function'] as Map<String, dynamic>?)
                            ?['arguments']
                            ?.toString() ??
                        c['arguments']?.toString() ??
                        '{}',
              },
            )
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// 工具定义展平：{type,name,description,parameters}。
  static List<Map<String, dynamic>> flattenTools(
    List<Map<String, dynamic>> tools,
  ) {
    return [
      for (final t in tools)
        if (t['type'] == 'function' && t['function'] is Map<String, dynamic>)
          {
            'type': 'function',
            'name': (t['function'] as Map<String, dynamic>)['name'],
            'description': (t['function'] as Map<String, dynamic>)['description'],
            'parameters':
                (t['function'] as Map<String, dynamic>)['parameters'],
          },
    ];
  }

  @override
  Map<String, dynamic> buildBody(
    String model,
    ChatOptions options,
    List<ChatMessage> apiMessages,
    List<Map<String, dynamic>>? tools,
  ) {
    // system 提示词抽到顶层 instructions；其余消息转 input 块
    final instructions = <String>[];
    final nonSystem = <ChatMessage>[];
    for (final m in apiMessages) {
      if (m.role == 'system' && m.content.trim().isNotEmpty) {
        instructions.add(m.content.trim());
      } else {
        nonSystem.add(m);
      }
    }
    final body = <String, dynamic>{
      'model': model,
      'instructions': instructions.join('\n\n'),
      'input': messagesToInput(nonSystem),
      if (options.maxTokens != null) 'max_output_tokens': options.maxTokens,
      if (options.stop.isNotEmpty) 'stop': options.stop,
      if (options.reasoningEffort != null)
        'reasoning': {'effort': options.reasoningEffort},
      if (options.temperature >= 0)
        'temperature': options.temperature,
    };
    if (options.stream) body['stream'] = true;
    final flatTools = tools == null || tools.isEmpty
        ? const <Map<String, dynamic>>[]
        : flattenTools(tools);
    if (flatTools.isNotEmpty) {
      body['tools'] = flatTools;
      body['tool_choice'] = 'auto';
    }
    return body;
  }

  @override
  ParsedDelta parseDelta(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return const ParsedDelta.unrecognized();
    switch (type) {
      case 'response.output_text.delta':
        final delta = json['delta'] as String?;
        if (delta == null || delta.isEmpty) return const ParsedDelta.none();
        return ParsedDelta.delta(StreamDelta(content: delta));
      case 'response.reasoning_summary_text.delta':
        final delta = json['delta'] as String?;
        if (delta == null || delta.isEmpty) return const ParsedDelta.none();
        return ParsedDelta.delta(StreamDelta(reasoning: delta));
      case 'response.function_call_arguments.delta':
        final args = json['delta'] as String?;
        if (args == null || args.isEmpty) return const ParsedDelta.none();
        return ParsedDelta.delta(
          StreamDelta(
            toolCalls: [
              ToolCallDelta(index: 0, arguments: args),
            ],
          ),
        );
      case 'response.output_item.added':
      case 'response.output_item.done':
        final item = json['item'] as Map<String, dynamic>?;
        if (item == null) return const ParsedDelta.none();
        final itemType = item['type'] as String?;
        if (itemType == 'function_call') {
          return ParsedDelta.delta(
            StreamDelta(
              toolCalls: [
                ToolCallDelta(
                  index: 0,
                  id: item['call_id'] as String? ?? item['id'] as String?,
                  name: item['name'] as String?,
                  arguments: item['arguments'] as String?,
                ),
              ],
            ),
          );
        }
        return const ParsedDelta.none();
      case 'response.completed':
        final response = json['response'] as Map<String, dynamic>?;
        final usageJson = response?['usage'] as Map<String, dynamic>?;
        return ParsedDelta.delta(
          StreamDelta(
            usage: usageJson == null ? null : ChatUsage.fromJson(usageJson),
            done: true,
          ),
        );
      case 'response.failed':
      case 'response.incomplete':
        // 带内错误：交给上层按失败处理（抛解析异常，防截断持久化）
        final err = json['error'] as Map<String, dynamic>?;
        throw FormatException(
          'Responses API error: ${err?['message'] ?? type}',
        );
      case 'error':
        final err = json['error'] as Map<String, dynamic>?;
        throw FormatException(
          'Responses API error: ${err?['message'] ?? json['message']}',
        );
      default:
        return const ParsedDelta.none();
    }
  }

  @override
  (String, ChatUsage?)? parseNonStream(Map<String, dynamic> json) {
    final output = json['output'] as List<dynamic>?;
    if (output == null) return null;
    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, dynamic>) continue;
      final content = item['content'];
      if (content is List) {
        for (final part in content) {
          if (part is Map<String, dynamic>) {
            final text = part['text'] as String?;
            if (text != null && text.isNotEmpty) buffer.write(text);
          }
        }
      }
    }
    if (buffer.isEmpty) return null;
    final usageJson = json['usage'] as Map<String, dynamic>?;
    return (
      buffer.toString(),
      usageJson == null ? null : ChatUsage.fromJson(usageJson),
    );
  }
}

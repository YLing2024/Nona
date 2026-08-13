import 'dart:convert';

import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../chat_service.dart' show ChatUsage;
import 'protocol_adapter.dart';
import 'protocol_factory.dart' show ProviderKind;

/// Google Gemini 协议（streamGenerateContent / generateContent）。
///
/// C-02：Vertex 模式（[vertexProject]/[vertexRegion] 非空）时
/// 拼 aiplatform 端点并用 Bearer 令牌（[accessTokenOverride]，
/// 由 RequestRunner 预取注入）。
class GeminiAdapter implements ProtocolAdapter {
  GeminiAdapter({this.vertexProject, this.vertexRegion});

  /// C-02：Vertex 项目 id（非空时启用 Vertex 端点）。
  final String? vertexProject;

  /// C-02：Vertex 区域，默认 us-central1。
  final String? vertexRegion;

  /// C-02：预取的 access token（RequestRunner 在请求前注入）。
  String? accessTokenOverride;

  bool get _isVertex => vertexProject != null && vertexProject!.isNotEmpty;

  @override
  ProviderKind get kind => ProviderKind.gemini;

  /// 流式走 streamGenerateContent；非流式走 generateContent（无 alt=sse）。
  /// Vertex 模式拼 aiplatform v1 端点。
  @override
  Uri uriFor(String baseUrl, String model, {bool streaming = true}) {
    if (_isVertex) {
      final region = (vertexRegion == null || vertexRegion!.isEmpty)
          ? 'us-central1'
          : vertexRegion!;
      final m = Uri.encodeComponent(model);
      final base = 'https://aiplatform.googleapis.com/v1/projects/'
          '$vertexProject/locations/$region/publishers/google/models';
      return streaming
          ? Uri.parse('$base/$m:streamGenerateContent?alt=sse')
          : Uri.parse('$base/$m:generateContent');
    }
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final m = Uri.encodeComponent(model);
    return streaming
        ? Uri.parse('$base/models/$m:streamGenerateContent?alt=sse')
        : Uri.parse('$base/models/$m:generateContent');
  }

  @override
  Map<String, String> headersFor(String apiKey) {
    if (_isVertex) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${accessTokenOverride ?? apiKey}',
      };
    }
    return {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };
  }

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
    final contents = <Map<String, dynamic>>[];
    for (final m in apiMessages) {
      if (m.role == 'system') continue;
      final role = m.role == 'assistant' ? 'model' : 'user';
      final parts = _contentParts(m);
      if (parts.isEmpty) continue;
      // Gemini 要求相邻同角色内容合并
      final last = contents.isNotEmpty ? contents.last : null;
      if (last != null && last['role'] == role) {
        (last['parts'] as List).addAll(parts);
      } else {
        contents.add({'role': role, 'parts': parts});
      }
    }
    return {
      'contents': contents,
      if (system.isNotEmpty)
        'system_instruction': {'parts': [{'text': system}]},
      'generationConfig': {
        'temperature': options.temperature,
        'topP': options.topP,
        if (options.maxTokens != null)
          'maxOutputTokens': options.maxTokens,
        if (options.stop.isNotEmpty) 'stopSequences': options.stop,
      },
      if (tools != null && tools.isNotEmpty) 'tools': _toolsBody(tools),
    };
  }

  /// 单条消息 → Gemini parts。
  List<Map<String, dynamic>> _contentParts(ChatMessage m) {
    final parts = <Map<String, dynamic>>[];
    // 工具调用消息（toolCallsJson）→ functionCall part
    if (m.toolCallsJson != null) {
      if (m.content.trim().isNotEmpty) {
        parts.add({'text': m.content});
      }
      try {
        final calls = jsonDecode(m.toolCallsJson!) as List<dynamic>;
        for (final c in calls) {
          if (c is! Map<String, dynamic>) continue;
          final fn = c['function'] as Map<String, dynamic>? ?? const {};
          final name = fn['name'] as String?;
          if (name == null || name.isEmpty) continue;
          Object? args;
          final rawArgs = fn['arguments'] as String? ?? '{}';
          try {
            args = jsonDecode(rawArgs);
          } catch (_) {
            args = rawArgs;
          }
          parts.add({
            'functionCall': {'name': name, 'args': args ?? {}},
          });
        }
      } catch (_) {}
      return parts;
    }
    // 工具结果消息（role=tool）→ functionResponse part
    if (m.role == 'tool' && m.toolCallId != null) {
      // 从 toolCallId 反查函数名：toolCallId 格式 `gemini_<name>` 或原 id
      var name = m.toolCallId!;
      if (name.startsWith('gemini_')) {
        name = name.substring('gemini_'.length);
      }
      parts.add({
        'functionResponse': {
          'name': name,
          'response': {'result': m.content},
        },
      });
      return parts;
    }
    if (m.content.trim().isNotEmpty) {
      parts.add({'text': m.content});
    }
    for (final img in m.images) {
      if (!img.isDataUrl) {
        parts.add({'fileData': {'fileUri': img.url}});
        continue;
      }
      final comma = img.url.indexOf(',');
      if (comma > 0) {
        parts.add({
          'inline_data': {
            'mime_type': img.mimeType,
            'data': img.url.substring(comma + 1),
          },
        });
      }
    }
    return parts;
  }

  /// OpenAI function 定义 → Gemini tools 格式。
  static List<Map<String, dynamic>> _toolsBody(
    List<Map<String, dynamic>> tools,
  ) {
    final declarations = <Map<String, dynamic>>[];
    for (final t in tools) {
      final fn = t['function'] as Map<String, dynamic>?;
      if (fn == null) continue;
      final name = fn['name'] as String?;
      if (name == null || name.isEmpty) continue;
      declarations.add({
        'name': name,
        'description': fn['description'] as String? ?? '',
        if (fn['parameters'] != null) 'parameters': fn['parameters'],
      });
    }
    return [
      {'functionDeclarations': declarations},
    ];
  }

  ChatUsage _usage(Map<String, dynamic> json) {
    return ChatUsage(
      promptTokens: (json['promptTokenCount'] as num?)?.toInt() ?? 0,
      completionTokens:
          (json['candidatesTokenCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  ParsedDelta parseDelta(Map<String, dynamic> json) {
    final usageJson = json['usageMetadata'] as Map<String, dynamic>?;
    ChatUsage? parsedUsage;
    if (usageJson != null) {
      parsedUsage = _usage(usageJson);
    }
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // 空 candidates 是 Gemini 合法结束块；无用量时不缓存
      if (parsedUsage == null) return const ParsedDelta.none();
      return ParsedDelta.delta(StreamDelta(usage: parsedUsage));
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      if (parsedUsage == null) return const ParsedDelta.none();
      return ParsedDelta.delta(StreamDelta(usage: parsedUsage));
    }
    final sb = StringBuffer();
    final reasoning = StringBuffer();
    final toolCalls = <ToolCallDelta>[];
    var callIndex = 0;
    for (final p in parts) {
      if (p is! Map<String, dynamic>) continue;
      // functionCall part：整体到达（非分片）
      final fnCall = p['functionCall'] as Map<String, dynamic>?;
      if (fnCall != null) {
        final name = fnCall['name'] as String?;
        if (name != null && name.isNotEmpty) {
          toolCalls.add(
            ToolCallDelta(
              index: callIndex,
              // Gemini 无调用 id：用 `gemini_<name>` 合成，回传时反查函数名
              id: 'gemini_$name',
              name: name,
              arguments: jsonEncode(fnCall['args'] ?? const {}),
            ),
          );
          callIndex++;
        }
        continue;
      }
      final text = p['text'] as String?;
      if (text == null || text.isEmpty) continue;
      if (p['thought'] == true) {
        reasoning.write(text);
      } else {
        sb.write(text);
      }
    }
    if (sb.isEmpty && reasoning.isEmpty && toolCalls.isEmpty) {
      if (parsedUsage == null) return const ParsedDelta.none();
      return ParsedDelta.delta(StreamDelta(usage: parsedUsage));
    }
    return ParsedDelta.delta(
      StreamDelta(
        content: sb.isEmpty ? null : sb.toString(),
        reasoning: reasoning.isEmpty ? null : reasoning.toString(),
        usage: parsedUsage,
        toolCalls: toolCalls.isEmpty ? null : toolCalls,
      ),
    );
  }

  @override
  (String, ChatUsage?)? parseNonStream(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) return null;
    final parts = (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final sb = StringBuffer();
    for (final p in (parts['parts'] as List<dynamic>? ?? const [])) {
      if (p is Map<String, dynamic>) sb.write(p['text'] ?? '');
    }
    if (sb.isEmpty) return null;
    final usageJson = json['usageMetadata'] as Map<String, dynamic>?;
    return (
      sb.toString(),
      usageJson == null ? null : _usage(usageJson),
    );
  }
}

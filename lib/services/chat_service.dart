import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/chat_options.dart';
import 'settings_service.dart';

/// 调用 OpenAI 格式的 chat/completions 接口。
class ChatService {
  /// 发送对话历史，返回助手的完整回复文本。
  ///
  /// [onPartial]：流式输出时逐块回调正文增量（非流式不回调）。
  /// [onReasoning]：流式输出时逐块回调思考内容增量。
  Future<String> sendChat({
    required AppSettings settings,
    required List<ChatMessage> messages,
    ChatOptions options = const ChatOptions(),
    void Function(String delta)? onPartial,
    void Function(String delta)? onReasoning,
  }) async {
    final baseUrl = settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/chat/completions');

    // 过滤空内容消息（流式占位等），并前置系统提示词。
    final apiMessages = [
      if (options.systemPrompt.trim().isNotEmpty)
        ChatMessage(role: 'system', content: options.systemPrompt.trim()),
      ...messages.where((m) => m.content.isNotEmpty),
    ];

    final body = jsonEncode({
      'model': settings.model,
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
    });

    if (!options.stream) {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.apiKey}',
        },
        body: body,
      );
      if (response.statusCode != 200) {
        throw ChatException(
          '请求失败 (HTTP ${response.statusCode})：${_extractError(response.body)}',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) {
        throw const ChatException('接口返回中没有内容 (choices 为空)');
      }
      final content =
          (choices.first['message'] as Map<String, dynamic>?)?['content'];
      if (content == null) {
        throw const ChatException('接口返回中缺少 message.content');
      }
      return content as String;
    }

    // 流式输出：解析 SSE 的 data 事件
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${settings.apiKey}'
      ..body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw ChatException(
          '请求失败 (HTTP ${response.statusCode})：${_extractError(errBody)}',
        );
      }

      final full = StringBuffer();
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices.first as Map<String, dynamic>)['delta']
                  as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            full.write(content);
            onPartial?.call(content);
          }
          // 兼容 reasoning_content / reasoning 两种字段名
          final reasoning =
              (delta?['reasoning_content'] ?? delta?['reasoning']) as String?;
          if (reasoning != null && reasoning.isNotEmpty) {
            onReasoning?.call(reasoning);
          }
        } catch (_) {
          // 忽略无法解析的行
        }
      }
      return full.toString();
    } finally {
      client.close();
    }
  }

  /// 从错误响应体中提取可读的错误信息。
  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'] as String;
      }
    } catch (_) {
      // 忽略解析失败，返回原始内容
    }
    return body;
  }
}

/// 聊天请求异常。
class ChatException implements Exception {
  final String message;

  const ChatException(this.message);

  @override
  String toString() => message;
}

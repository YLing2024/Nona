import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/chat_options.dart';
import 'network_log_service.dart';
import 'settings_service.dart';

/// 一次回复的 token 用量。
class ChatUsage {
  final int promptTokens;
  final int completionTokens;
  final int? totalTokens;

  const ChatUsage({
    required this.promptTokens,
    required this.completionTokens,
    this.totalTokens,
  });

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt(),
    );
  }
}

/// 一次聊天请求的完整结果。
class ChatResult {
  final String content;
  final ChatUsage? usage;
  final int elapsedMs;

  const ChatResult({
    required this.content,
    this.usage,
    required this.elapsedMs,
  });
}

/// 可取消的聊天请求句柄。
///
/// 调用方持有句柄后可在任意时刻调用 [cancel] 中止生成。
class ChatRequestHandle {
  final Future<ChatResult> result;
  final Future<void> Function() _cancelFn;

  ChatRequestHandle._({
    required this.result,
    required Future<void> Function() cancelFn,
  }) : _cancelFn = cancelFn;

  bool _cancelled = false;

  /// 是否已被取消。
  bool get isCancelled => _cancelled;

  /// 取消生成；取消后 [result] 会以 [ChatCancelledException] 结束。
  Future<void> cancel() {
    _cancelled = true;
    return _cancelFn();
  }
}

/// 调用 OpenAI 格式的 chat/completions 接口。
class ChatService {
  /// 连接超时（建立连接阶段）。
  static const Duration kConnectTimeout = Duration(seconds: 60);

  /// 流式空闲超时（两次数据块之间无数据视为超时）。
  static const Duration kIdleTimeout = Duration(seconds: 120);

  /// 发送对话历史，返回助手的完整回复。
  ///
  /// [onPartial]：流式输出时逐块回调正文增量（非流式不回调）。
  /// [onReasoning]：流式输出时逐块回调思考内容增量。
  /// 返回句柄：[handle.result] 正常完成时携带完整回复与用量；
  /// 用户调用 [handle.cancel] 后以 [ChatCancelledException] 结束。
  ChatRequestHandle sendChat({
    required AppSettings settings,
    required List<ChatMessage> messages,
    ChatOptions options = const ChatOptions(),
    void Function(String delta)? onPartial,
    void Function(String delta)? onReasoning,
  }) {
    return _ChatRequestRunner(
      settings: settings,
      messages: messages,
      options: options,
      onPartial: onPartial,
      onReasoning: onReasoning,
    ).start();
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

/// 单个请求的执行器：持有本次请求独立的缓冲/定时器状态。
class _ChatRequestRunner {
  final AppSettings settings;
  final List<ChatMessage> messages;
  final ChatOptions options;
  final void Function(String delta)? onPartial;
  final void Function(String delta)? onReasoning;

  final StringBuffer _full = StringBuffer();
  final List<String> _rawBuffer = [];
  ChatUsage? _usage;
  Timer? _idleTimer;
  void Function()? _idleReset;
  StreamSubscription<String>? _sub;
  http.Client? _client;
  var _cancelled = false;
  late final Completer<ChatResult> _completer;
  late final DateTime _started;

  /// 网络日志记录器（启用日志时非空）。
  NetworkLogBuilder? _logBuilder;
  bool _logEnded = false;
  int? _responseStatus;
  Map<String, String>? _responseHeaders;
  final StringBuffer _logBody = StringBuffer();

  /// 日志原始响应流暂存上限，超出即停止追加（防止超大流撑爆内存）。
  static const int _logBodyCap = 200000;

  _ChatRequestRunner({
    required this.settings,
    required this.messages,
    required this.options,
    this.onPartial,
    this.onReasoning,
  });

  ChatRequestHandle start() {
    _started = DateTime.now();
    _completer = Completer<ChatResult>();
    final handle = ChatRequestHandle._(
      result: _completer.future,
      cancelFn: cancel,
    );
    unawaited(_run(handle));
    return handle;
  }

  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    _idleTimer?.cancel();
    await _sub?.cancel();
    _client?.close();
    _endLog(error: '用户取消');
    if (!_completer.isCompleted) {
      _completer.completeError(const ChatCancelledException());
    }
  }

  /// 结束网络日志（成功/失败/取消均只记录一次）。
  void _endLog({String? body, String? error}) {
    if (_logBuilder == null || _logEnded) return;
    _logEnded = true;
    _logBuilder!.end(
      statusCode: _responseStatus,
      responseHeaders: _responseHeaders,
      responseBody: body ?? _logBody.toString(),
      error: error,
    );
  }

  void _fail(Object error) {
    if (_cancelled || _completer.isCompleted) return;
    _endLog(error: error.toString());
    _completer.completeError(error);
  }

  void _done() {
    if (_cancelled || _completer.isCompleted) return;
    final elapsed = DateTime.now().difference(_started).inMilliseconds;
    _endLog();
    _completer.complete(
      ChatResult(content: _full.toString(), usage: _usage, elapsedMs: elapsed),
    );
  }

  Future<void> _run(ChatRequestHandle handle) async {
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

    final client = http.Client();
    _client = client;
    _logBuilder = NetworkLogService.begin(
      method: 'POST',
      url: uri.toString(),
      requestHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.apiKey}',
      },
      requestBody: body,
      type: NetworkLogType.chat,
    );
    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer ${settings.apiKey}'
        ..body = body;

      final response = await client.send(request).timeout(
        ChatService.kConnectTimeout,
      );
      if (_cancelled) return;
      _responseStatus = response.statusCode;
      _responseHeaders = Map.of(response.headers);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        _endLog(body: errBody, error: 'HTTP ${response.statusCode}');
        throw ChatException(
          '请求失败 (HTTP ${response.statusCode})：'
          '${ChatService()._extractError(errBody)}',
        );
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      void resetIdleTimer() {
        _idleTimer?.cancel();
        _idleTimer = Timer(ChatService.kIdleTimeout, () {
          _fail(const ChatTimeoutException('请求超时：长时间未收到服务端响应'));
          unawaited(cancel());
        });
      }

      _idleReset = resetIdleTimer;

      final sub = lines.listen(
        _handleLine,
        onError: (e) => _fail(ChatException('读取响应流失败：$e')),
        onDone: _handleDone,
        cancelOnError: true,
      );
      _sub = sub;
      resetIdleTimer();
    } catch (e) {
      if (_cancelled) return;
      if (e is ChatException || e is ChatTimeoutException) {
        _fail(e);
      } else {
        _fail(ChatException('网络请求失败：$e'));
      }
    }
  }

  void _handleLine(String line) {
    _idleReset?.call();
    if (_cancelled) return;
    // 启用网络日志时暂存原始响应流（限量），用于日志详情展示
    if (_logBuilder != null &&
        !_logEnded &&
        _logBody.length < _logBodyCap) {
      _logBody.write(line);
      _logBody.write('\n');
    }
    if (!line.startsWith('data:')) {
      // 整包 JSON 可能分多行到达（非流式，或服务端忽略 stream 参数的兜底）：
      // 从首个 `{` 起暂存，供 _handleDone 合并解析。
      // 流式 SSE 的空白行/注释行不会以 `{` 开头，不会被误收集。
      if (line.trimLeft().startsWith('{') || _rawBuffer.isNotEmpty) {
        _rawBuffer.add(line);
      }
      return;
    }
    final data = line.substring(5).trim();
    if (data.isEmpty || data == '[DONE]') return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final usageJson = json['usage'] as Map<String, dynamic>?;
      if (usageJson != null) {
        _usage = ChatUsage.fromJson(usageJson);
      }
      if (options.stream) {
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) return;
        final delta =
            (choices.first as Map<String, dynamic>)['delta']
                as Map<String, dynamic>?;
        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          _full.write(content);
          onPartial?.call(content);
        }
        final reasoning =
            (delta?['reasoning_content'] ?? delta?['reasoning']) as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          onReasoning?.call(reasoning);
        }
      } else {
        // 非流式模式：服务端仍可能走 SSE 包装，直接取首个 choice
        final choices = json['choices'] as List<dynamic>? ?? [];
        if (choices.isNotEmpty) {
          final message =
              (choices.first as Map<String, dynamic>)['message']
                  as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null) _full.write(content);
        }
      }
    } catch (_) {
      // 非流式下 SSE 包装的多行 JSON：首行 `data: {` 无法单独解析，
      // 去掉前缀后暂存，等待 _handleDone 与后续行合并解析。
      if (!options.stream) _rawBuffer.add(data);
    }
  }

  void _handleDone() {
    _idleTimer?.cancel();
    if (_cancelled) return;
    if (_full.isEmpty && _rawBuffer.isNotEmpty) {
      // 逐行没解析到内容（非流式整包 JSON，或服务端忽略 stream 参数返回整包 JSON）：
      // 把暂存的行合并后整体解析
      final raw = _rawBuffer.join('\n').trim();
      if (raw.isNotEmpty) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final usageJson = data['usage'] as Map<String, dynamic>?;
          if (usageJson != null) {
            _usage = ChatUsage.fromJson(usageJson);
          }
          final choices = data['choices'] as List<dynamic>? ?? [];
          if (choices.isEmpty) {
            _fail(const ChatException('接口返回中没有内容 (choices 为空)'));
            return;
          }
          final message =
              (choices.first as Map<String, dynamic>)['message']
                  as Map<String, dynamic>?;
          final content = message?['content'] ?? message?['reasoning_content'];
          if (content == null) {
            _fail(const ChatException('接口返回中缺少 message.content'));
            return;
          }
          _full.write(content as String);
        } catch (_) {
          _fail(const ChatException('接口返回格式无法解析'));
          return;
        }
      } else {
        _fail(const ChatException('接口返回中没有内容'));
        return;
      }
    }
    _done();
  }
}

/// 聊天请求异常。
class ChatException implements Exception {
  final String message;

  const ChatException(this.message);

  @override
  String toString() => message;
}

/// 请求被用户主动取消。
class ChatCancelledException implements Exception {
  const ChatCancelledException();
}

/// 请求超时。
class ChatTimeoutException implements Exception {
  final String message;

  const ChatTimeoutException(this.message);

  @override
  String toString() => message;
}

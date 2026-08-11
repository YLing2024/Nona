import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../app_http_client.dart';
import '../chat_protocol.dart' show ProtocolAdapter, ProtocolFactory;
import '../chat_service.dart' show ChatResult, ChatService;
import '../network_log_service.dart';
import '../settings_service.dart';
import 'chat_exceptions.dart';
import 'chat_request_handle.dart';
import 'sse_parser.dart';

/// 单个聊天请求的执行器：连接 / 重试 / 超时 / idle 定时器与流式帧处理。
///
/// 持有本次请求独立的缓冲/定时器状态；响应行解析委托 [SseStreamParser]。
class RequestRunner {
  final AppSettings settings;
  final List<ChatMessage> messages;
  final ChatOptions options;
  final void Function(String delta)? onPartial;
  final void Function(String delta)? onReasoning;

  /// 工具定义（OpenAI function calling 格式）；仅 OpenAI 协议发送。
  final List<Map<String, dynamic>>? tools;

  /// 自定义请求头/请求体（Provider 级配置，发送时合并）。
  final Map<String, String>? customHeaders;
  final Map<String, dynamic>? customBody;

  /// 多 Key 轮换池（F2-3）：非空时每次请求轮换选取。
  final List<String>? apiKeys;

  /// 单次请求实际使用的 key（供失败标记回写）。
  String? usedApiKey;

  /// 按设置选定的协议适配器（auto 时按 Base URL 探测）。
  late final ProtocolAdapter _protocol = ProtocolFactory.resolve(
    settings.providerKind,
    settings.baseUrl,
  );

  /// 响应流解析器（逐行状态机）。
  late final SseStreamParser _parser = SseStreamParser(
    protocol: _protocol,
    streaming: options.stream,
    isCancelled: () => _cancelled,
    onRawLine: _onRawLine,
    onContent: onPartial,
    onReasoning: onReasoning,
  );

  Timer? _idleTimer;
  void Function()? _idleReset;
  StreamSubscription<String>? _sub;
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

  RequestRunner({
    required this.settings,
    required this.messages,
    required this.options,
    this.onPartial,
    this.onReasoning,
    this.tools,
    this.customHeaders,
    this.customBody,
    this.apiKeys,
  });

  ChatRequestHandle start() {
    _started = DateTime.now();
    _completer = Completer<ChatResult>();
    final handle = ChatRequestHandle(
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
    _endLog(error: 'user cancelled');
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
      ChatResult(
        content: _parser.content.toString(),
        usage: _parser.usage,
        elapsedMs: elapsed,
        toolCalls: _parser.hasToolCalls ? _parser.collectedToolCalls : null,
      ),
    );
  }

  Future<void> _run(ChatRequestHandle handle) async {
    // URI/请求体/请求头的构建也可能抛异常（Uri.parse 格式错误、
    // jsonEncode 遇 NaN 等），必须纳入错误处理，否则 handle.result
    // 永未完成 → 调用方挂起。
    try {
      final baseUrl = settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = _protocol.uriFor(baseUrl, settings.model);

      // 过滤空内容消息（流式占位等），并前置系统提示词。
      // 图片消息即使正文为空也要保留（多模态输入）。
      final apiMessages = [
        if (options.systemPrompt.trim().isNotEmpty)
          ChatMessage(role: 'system', content: options.systemPrompt.trim()),
        ...messages.where((m) => m.hasSendableContent),
      ];

      final bodyMap = _protocol.buildBody(
        settings.model,
        options,
        apiMessages,
        tools,
      );
      // 自定义请求体合并（Provider 级配置覆盖默认）
      if (customBody != null && customBody!.isNotEmpty) {
        bodyMap.addAll(customBody!);
      }
      final body = jsonEncode(bodyMap);
      final headers = _protocol.headersFor(settings.apiKey);
      // 自定义请求头合并（Provider 级配置追加）
      if (customHeaders != null && customHeaders!.isNotEmpty) {
        headers.addAll(customHeaders!);
      }
      await _sendWithRetry(handle, uri, headers, body);
    } catch (e) {
      _endLog(error: e.toString());
      _fail(e is ChatException
          ? e
          : ChatException('$e', code: ChatException.networkFailed));
    }
  }

  Future<void> _sendWithRetry(
    ChatRequestHandle handle,
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    // 统一重试循环：连接失败 / 429 / 5xx 时指数退避重试（设置可关闭）。
    // 每次尝试独立记录网络日志；取消可随时中止（含退避等待期间）。
    final attempts = settings.chatAutoRetry ? AppHttpClient.maxAttempts : 1;
    late http.StreamedResponse response;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      if (_cancelled) return;
      _logBuilder = NetworkLogService.begin(
        method: 'POST',
        url: uri.toString(),
        requestHeaders: headers,
        requestBody: body,
        type: NetworkLogType.chat,
      );
      _logEnded = false;
      try {
        response = await AppHttpClient.instance.sendStreamed(
          method: 'POST',
          uri: uri,
          headers: headers,
          body: body,
          isCancelled: () => _cancelled,
        );
      } catch (e) {
        if (_cancelled) return;
        final retryable = e is TimeoutException || e is http.ClientException;
        if (retryable && attempt < attempts) {
          _endLog(error: 'retrying: $e (attempt $attempt)');
          await Future.delayed(AppHttpClient.backoffFor(attempt));
          continue;
        }
        _endLog(error: e.toString());
        _fail(ChatException('$e', code: ChatException.networkFailed));
        return;
      }
      if (_cancelled) return;
      _responseStatus = response.statusCode;
      _responseHeaders = Map.of(response.headers);
      if (response.statusCode == 200) break;
      final errBody = await response.stream.bytesToString();
      if (AppHttpClient.isRetryableStatus(response.statusCode) &&
          attempt < attempts) {
        _endLog(
          body: errBody,
          error: 'HTTP ${response.statusCode} (retry attempt $attempt)',
        );
        await Future.delayed(AppHttpClient.backoffFor(attempt));
        continue;
      }
      _endLog(body: errBody, error: 'HTTP ${response.statusCode}');
      _fail(ChatException(
        'Request failed (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(errBody)}',
      ));
      return;
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    void resetIdleTimer() {
      _idleTimer?.cancel();
      _idleTimer = Timer(ChatService.kIdleTimeout, () {
        _fail(const ChatTimeoutException('Request timeout: no response from server for a long time'));
        unawaited(cancel());
      });
    }

    _idleReset = resetIdleTimer;

    final sub = lines.listen(
      _parser.handleLine,
      onError: (e) => _fail(ChatException('$e', code: ChatException.streamFailed)),
      onDone: _onDone,
      cancelOnError: true,
    );
    _sub = sub;
    resetIdleTimer();
  }

  /// 每行到达前的回调：重置 idle 定时器并暂存网络日志原始流。
  void _onRawLine(String line) {
    _idleReset?.call();
    if (_logBuilder != null && !_logEnded && _logBody.length < _logBodyCap) {
      _logBody.write(line);
      _logBody.write('\n');
    }
  }

  void _onDone() {
    _idleTimer?.cancel();
    if (_cancelled) return;
    _parser.handleDone();
    if (_parser.error != null) {
      _fail(_parser.error!);
      return;
    }
    _done();
  }
}

/// 聊天请求异常。
///
/// [code] 为机器可读错误码，UI 层据此显示本地化文案；
/// [message] 保留原始描述（写入网络日志 / 兜底展示），不再硬编码中文于 UI 文案。
class ChatException implements Exception {
  /// 服务端未返回任何内容。
  static const String emptyResponse = 'empty_response';

  /// 返回格式无法解析。
  static const String invalidFormat = 'invalid_format';

  /// 返回中缺少 message.content。
  static const String missingContent = 'missing_content';

  /// HTTP 非 2xx（message 携带状态码与服务端错误）。
  static const String httpError = 'http_error';

  /// 网络层失败（连接失败/超时等）。
  static const String networkFailed = 'network_failed';

  /// 读取响应流失败。
  static const String streamFailed = 'stream_failed';

  final String code;
  final String message;

  const ChatException(this.message, {this.code = ChatException.httpError});

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

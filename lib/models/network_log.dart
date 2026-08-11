/// 网络日志类型，用于列表分组与展示。
enum NetworkLogType {
  chat('chat'),
  test('test'),
  models('models'),
  capability('capability'),
  other('other');

  const NetworkLogType(this.label);

  final String label;
}

/// 一条网络请求日志（含请求/响应头与正文，正文按需截断）。
class NetworkLog {
  final String id;
  final DateTime time;
  final String method;
  final String url;

  /// 响应状态码；网络层失败时为 null。
  final int? statusCode;

  /// 请求总耗时（毫秒）。
  final int durationMs;

  /// 请求/响应正文的字节数。
  final int requestBytes;
  final int responseBytes;
  final Map<String, String> requestHeaders;
  final String requestBody;
  final Map<String, String> responseHeaders;
  final String responseBody;

  /// 错误描述；请求成功时为 null。
  final String? error;
  final NetworkLogType type;

  const NetworkLog({
    required this.id,
    required this.time,
    required this.method,
    required this.url,
    required this.statusCode,
    required this.durationMs,
    required this.requestBytes,
    required this.responseBytes,
    required this.requestHeaders,
    required this.requestBody,
    required this.responseHeaders,
    required this.responseBody,
    this.error,
    required this.type,
  });

  /// 是否成功（无网络层错误且状态码为 2xx/3xx）。
  bool get isSuccess =>
      error == null &&
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 400;

  factory NetworkLog.fromJson(Map<String, dynamic> json) {
    return NetworkLog(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      method: json['method'] as String,
      url: json['url'] as String,
      statusCode: json['statusCode'] as int?,
      durationMs: json['durationMs'] as int? ?? 0,
      requestBytes: json['requestBytes'] as int? ?? 0,
      responseBytes: json['responseBytes'] as int? ?? 0,
      requestHeaders: _stringMap(json['requestHeaders']),
      requestBody: json['requestBody'] as String? ?? '',
      responseHeaders: _stringMap(json['responseHeaders']),
      responseBody: json['responseBody'] as String? ?? '',
      error: json['error'] as String?,
      type: NetworkLogType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NetworkLogType.other,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toIso8601String(),
    'method': method,
    'url': url,
    'statusCode': statusCode,
    'durationMs': durationMs,
    'requestBytes': requestBytes,
    'responseBytes': responseBytes,
    'requestHeaders': requestHeaders,
    'requestBody': requestBody,
    'responseHeaders': responseHeaders,
    'responseBody': responseBody,
    'error': error,
    'type': type.name,
  };

  static Map<String, String> _stringMap(Object? v) {
    if (v is! Map) return const {};
    return {
      for (final e in v.entries) e.key.toString(): e.value.toString(),
    };
  }
}

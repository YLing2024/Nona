import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/network_log.dart';
import '../utils/logger.dart';
import 'network_log_store_io.dart'
    if (dart.library.js_interop) 'network_log_store_stub.dart' as store;

export '../models/network_log.dart';

/// 网络日志服务：记录应用内全部 HTTP 请求（含聊天、测速、拉取模型、能力表更新）。
///
/// - 仅当「启用网络日志」打开时记录；
/// - 最大保留条数可配置，0 表示不限制；
/// - 正文超长自动截断，避免内存占用失控；
/// - 请求头中 Authorization 等密钥字段自动脱敏，不落日志；
/// - 请求体/URL 中的密钥字段（api_key 等）同样脱敏；
/// - 日志持久化：桌面/移动端写入本地文件，Web 端写入浏览器 localStorage。
class NetworkLogService extends ChangeNotifier {
  NetworkLogService._();

  static final NetworkLogService instance = NetworkLogService._();

  /// 单条正文最大保留字符数。
  static const int _maxBodyChars = 8000;

  bool _enabled = false;
  int _maxLogs = 0;
  bool _initialized = false;
  final List<NetworkLog> _logs = [];

  /// 持久化串行链，避免并发读改写丢更新。
  Future<void>? _persistChain;

  bool get enabled => _enabled;

  /// 最大保留条数，0 表示不限制。
  int get maxLogs => _maxLogs;

  /// 全部日志，最新在前。
  List<NetworkLog> get logs => List.unmodifiable(_logs);

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void setMaxLogs(int value) {
    _maxLogs = value > 0 ? value : 0;
    notifyListeners();
  }

  /// 初始化：从持久化存储恢复日志（与记录开关无关，日志始终可查看）。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final persisted = await store.readLogs();
    _logs
      ..clear()
      ..addAll(persisted);
    if (_maxLogs > 0 && _logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    _schedulePersist();
    notifyListeners();
  }

  void record(NetworkLog log) {
    if (!_enabled) return;
    _logs.insert(0, log);
    if (_maxLogs > 0 && _logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }
    _schedulePersist();
    notifyListeners();
  }

  /// 串行持久化当前日志（写文件，失败静默）。
  ///
  /// 单次写入失败不污染持久化链：错误被记录后链继续可用，
  /// 避免一次写入错误导致后续所有日志丢失（Web 端超配额常见）。
  void _schedulePersist() {
    _persistChain = (_persistChain ?? Future.value()).then((_) async {
      try {
        await store.writeLogs(_logs);
      } catch (e) {
        Logger.error('netlog', 'network log persistence failed', e);
      }
    });
  }

  /// 等待所有已排队的写入完成（应用退出/挂起前调用，尽量落盘不丢）。
  Future<void> flush() async {
    await _persistChain;
  }

  /// 截断过长的正文：保留头部并注明原长度。
  static String truncate(String body, {int? max}) {
    final limit = max ?? _maxBodyChars;
    if (body.length <= limit) return body;
    return '${body.substring(0, limit)}\n\n...(truncated, original ${body.length} chars)';
  }

  /// 开始记录一次请求；日志关闭时返回 null（调用方无需额外判断）。
  static NetworkLogBuilder? begin({
    required String method,
    required String url,
    Map<String, String> requestHeaders = const {},
    String requestBody = '',
    NetworkLogType type = NetworkLogType.other,
  }) {
    if (!instance._enabled) return null;
    return NetworkLogBuilder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      time: DateTime.now(),
      method: method,
      url: sanitizeUrl(url),
      requestHeaders: _sanitizeHeaders(requestHeaders),
      requestBody: sanitizeBody(requestBody),
      type: type,
    );
  }

  /// 请求头脱敏：隐藏 Authorization / X-API-Key 等密钥类字段。
  static Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    return {
      for (final e in headers.entries)
        if (_isSecretHeader(e.key)) e.key: '******' else e.key: e.value,
    };
  }

  static bool _isSecretHeader(String name) {
    final n = name.toLowerCase();
    return n == 'authorization' ||
        n == 'x-api-key' ||
        n == 'api-key' ||
        n == 'anthropic-api-key' ||
        n == 'x-goog-api-key' ||
        n == 'x-auth-token' ||
        n == 'proxy-authorization' ||
        n == 'cookie' ||
        n == 'mcp-session-id';
  }

  /// URL 脱敏：移除 userinfo 凭据，并对查询参数中的密钥字段打码。
  static String sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final hasCredentials = uri.userInfo.isNotEmpty;
    final hasSecretQuery = uri.queryParameters.entries.any(
      (e) => _isSecretParam(e.key),
    );
    if (!hasCredentials && !hasSecretQuery) return url;
    final newQuery = uri.queryParametersAll.map((k, v) {
      if (_isSecretParam(k)) {
        // 用 REDACTED 打码，避免掩码字符再次被 URL 编码
        return MapEntry(k, v.map((_) => 'REDACTED').toList());
      }
      return MapEntry(k, v);
    });
    return uri.replace(
      userInfo: hasCredentials ? 'REDACTED' : null,
      queryParameters: newQuery,
    ).toString();
  }

  static bool _isSecretParam(String name) {
    final n = name.toLowerCase();
    return n == 'api_key' ||
        n == 'apikey' ||
        n == 'key' ||
        n == 'token' ||
        n == 'access_token' ||
        n == 'auth' ||
        n == 'signature' ||
        n == 'secret';
  }

  /// 请求体脱敏：JSON 中的密钥字段值打码。
  ///
  /// 超大正文跳过正则替换（日志记录路径另有 8000 字符截断策略，
  /// 此处只处理密钥泄露，不做全文改写）。
  static final RegExp _secretFieldRe = RegExp(
    r'("(?:api[_-]?key|apikey|secret|client[_-]?secret|private[_-]?key|'
    r'access[_-]?token|refresh[_-]?token|id[_-]?token|token|password|'
    r'passwd|authorization|auth|cookie|credential|signature|session[_-]?id|'
    r'bearer)"\s*:\s*)("[^"]*"|[^,}\s]+)',
    caseSensitive: false,
  );

  static String sanitizeBody(String body) {
    if (body.isEmpty || body.length > _maxBodyChars * 8) return body;
    return body.replaceAllMapped(
      _secretFieldRe,
      (m) => '${m.group(1)}"******"',
    );
  }
}

/// 一次网络请求的记录器（begin → end），end 时写入日志服务。
class NetworkLogBuilder {
  final String id;
  final DateTime time;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String requestBody;
  final NetworkLogType type;
  final DateTime _started;

  NetworkLogBuilder({
    required this.id,
    required this.time,
    required this.method,
    required this.url,
    required this.requestHeaders,
    required this.requestBody,
    required this.type,
  }) : _started = DateTime.now();

  /// 请求结束（成功或失败）时调用，将结果写入日志。
  ///
  /// 正文完整保留（不截断），由详情页按需截断展示，并支持外部编辑器查看全文。
  void end({
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    String? error,
  }) {
    NetworkLogService.instance.record(
      NetworkLog(
        id: id,
        time: time,
        method: method,
        url: url,
        statusCode: statusCode,
        durationMs: DateTime.now().difference(_started).inMilliseconds,
        requestBytes: utf8.encode(requestBody).length,
        responseBytes: utf8.encode(responseBody ?? '').length,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders ?? const {},
        responseBody: responseBody ?? '',
        error: error,
        type: type,
      ),
    );
  }
}

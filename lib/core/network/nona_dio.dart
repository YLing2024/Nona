import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:socks5_proxy/socks.dart' show ProxySettings, SocksTCPClient;

import '../services/network_log_service.dart';
import '../services/settings_service.dart';

/// A-04：统一网络出口（dio 5.x）。
///
/// - 懒加载单例（[NonaDio.instance]），共享连接池；
/// - [NonaLogInterceptor]：复用 NetworkLogService.begin/end（脱敏保留）；
/// - [NonaRetryInterceptor]：429/5xx 指数退避 ×3（尊重 chatAutoRetry）；
/// - 代理：读 [AppSettings] 的 proxy* 字段，http/https 用 findProxy，
///   socks5 用 SocksTCPClient 包装 HttpClient。
class NonaDio {
  NonaDio._();

  static Dio? _instance;

  /// 全局 dio 实例。
  static Dio get instance => _instance ??= _build();

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    dio.interceptors.add(NonaLogInterceptor());
    dio.interceptors.add(NonaRetryInterceptor());
    _applyAdapter(dio, _currentSettings);
    return dio;
  }

  static void _applyAdapter(Dio dio, AppSettings? s) {
    if (s != null && s.proxyEnabled && s.proxyType == 'socks5') {
      dio.httpClientAdapter = _socks5Adapter(s);
    } else {
      dio.httpClientAdapter = _httpProxyAdapter(s);
    }
  }

  static AppSettings? _currentSettings;

  /// 设置快照（由 SettingsService 在加载/保存时刷新；null=不启用代理）。
  static void updateSettings(AppSettings? settings) {
    _currentSettings = settings;
    if (_instance != null) {
      _applyAdapter(_instance!, settings);
    }
  }

  /// http/https 代理（findProxy 规则注入）。
  static HttpClientAdapter _httpProxyAdapter(AppSettings? s) {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) => _proxyRule(s, uri);
        return client;
      },
    );
  }

  static String _proxyRule(AppSettings? s, Uri uri) {
    if (s == null || !s.proxyEnabled || s.proxyHost.isEmpty) return 'DIRECT';
    final bypass = <String>{
      'localhost',
      '127.0.0.1',
      ...s.proxyBypass
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
    };
    if (bypass.contains(uri.host)) return 'DIRECT';
    final port = s.proxyPort > 0 ? s.proxyPort : 8080;
    final auth =
        s.proxyUser.isNotEmpty ? '${s.proxyUser}:${s.proxyPassword}@' : '';
    return 'PROXY $auth${s.proxyHost}:$port; DIRECT';
  }

  /// socks5 代理（connectionFactory 包装）。
  static HttpClientAdapter _socks5Adapter(AppSettings s) {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        final port = s.proxyPort > 0 ? s.proxyPort : 1080;
        SocksTCPClient.assignToHttpClient(
          client,
          [
            ProxySettings(
              InternetAddress(s.proxyHost),
              port,
              username: s.proxyUser.isEmpty ? null : s.proxyUser,
              password: s.proxyPassword.isEmpty ? null : s.proxyPassword,
            ),
          ],
        );
        return client;
      },
    );
  }
}

/// 网络日志拦截器：复用 NetworkLogService 记录（含脱敏）。
class NonaLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = options.data is String
        ? options.data as String
        : options.data?.toString() ?? '';
    final log = NetworkLogService.begin(
      method: options.method,
      url: options.uri.toString(),
      requestHeaders: Map<String, String>.from(options.headers),
      requestBody: body,
      type: options.extra['nona_log_type'] is NetworkLogType
          ? options.extra['nona_log_type'] as NetworkLogType
          : NetworkLogType.other,
    );
    options.extra['nona_log'] = log;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final log = response.requestOptions.extra['nona_log'] as NetworkLogBuilder?;
    log?.end(
      statusCode: response.statusCode,
      responseHeaders: _flatten(response.headers),
      responseBody: response.data?.toString(),
      error: response.statusCode == 200 ? null : 'HTTP ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final log = err.requestOptions.extra['nona_log'] as NetworkLogBuilder?;
    log?.end(
      statusCode: err.response?.statusCode,
      responseHeaders: err.response == null ? null : _flatten(err.response!.headers),
      responseBody: err.response?.data?.toString(),
      error: err.message ?? err.type.toString(),
    );
    handler.next(err);
  }

  static Map<String, String>? _flatten(Headers headers) {
    if (headers.isEmpty) return null;
    return {
      for (final e in headers.map.entries)
        e.key: e.value.isEmpty ? '' : e.value.join('; '),
    };
  }
}

/// 重试拦截器：429/5xx 指数退避（最多 3 次），尊重 chatAutoRetry。
class NonaRetryInterceptor extends Interceptor {
  static const int maxAttempts = 3;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final attempts = err.requestOptions.extra['nona_attempt'] as int? ?? 1;
    if (err.requestOptions.extra['nona_no_retry'] == true) {
      handler.next(err);
      return;
    }
    if (!_isRetryable(err) || attempts >= maxAttempts) {
      handler.next(err);
      return;
    }
    err.requestOptions.extra['nona_attempt'] = attempts + 1;
    final dio = err.requestOptions.extra['nona_dio'] as Dio?;
    if (dio == null) {
      handler.next(err);
      return;
    }
    Future<void>.delayed(Duration(seconds: attempts)).then((_) {
      dio.fetch(err.requestOptions).then(handler.resolve, onError: handler.next);
    });
  }

  bool _isRetryable(DioException err) {
    final status = err.response?.statusCode;
    if (status == 429) return true;
    if (status != null && status >= 500 && status < 600) return true;
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}

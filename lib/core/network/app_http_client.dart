import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../services/chat_service.dart' show ChatCancelledException;
import '../services/network_log_service.dart';
import 'nona_dio.dart';

/// 统一网络客户端（A-04：底层基于 dio 5.x，对外 API 不变）。
///
/// - [send]：请求并读取完整响应，自动记录网络日志，对 429/5xx 与
///   连接阶段失败按指数退避重试（可关闭）；用于 /models、测速、能力表更新等。
/// - [sendStreamed]：流式请求（聊天 SSE）。仅在「建立连接」阶段失败时重试，
///   响应一旦到达即不再重试（避免流式中途重发产生重复内容）；
///   网络日志由调用方自行记录（聊天场景需要捕获流式正文与取消语义）。
class AppHttpClient {
  AppHttpClient();

  static AppHttpClient _instance = AppHttpClient();

  /// 全局默认实例（18 处调用点保持 `AppHttpClient.instance` 不变）。
  static AppHttpClient get instance => _instance;

  /// 测试替换钩子：注入 fake 客户端（override [send]/[sendStreamed]）。
  static void overrideForTesting(AppHttpClient client) {
    _instance = client;
  }

  /// 总尝试次数（含首次）：连接阶段最多重试 2 次。
  static const int maxAttempts = 3;

  /// 重试退避基数：第 n 次重试前等待 base * n。
  static const Duration backoffBase = Duration(seconds: 1);

  /// 默认连接超时。
  static const Duration defaultConnectTimeout = Duration(seconds: 60);

  /// 构造 JSON 请求头；[bearer] 为空时省略 Authorization 头。
  static Map<String, String> jsonHeaders({String bearer = ''}) => {
        'Content-Type': 'application/json',
        if (bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
      };

  /// 从错误响应体中提取服务端返回的可读错误信息。
  ///
  /// 兼容常见格式：`{error: {message}}` / `{error: "..."}`；
  /// 解析失败时原样返回正文。
  static String extractApiError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          return error['message'] as String;
        }
        if (error is String && error.isNotEmpty) return error;
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // 忽略解析失败，返回原始内容
    }
    return body;
  }

  /// 发送请求并读取完整响应体。
  ///
  /// 自动完成：网络日志记录（请求/响应头脱敏、正文截断）、
  /// 超时保护、429/5xx 与连接失败时的指数退避重试。
  ///
  /// 抛出 [TimeoutException] / [http.ClientException]（重试耗尽后）。
  Future<http.Response> send({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    List<int>? bodyBytes,
    NetworkLogType type = NetworkLogType.other,
    Duration? timeout,
    bool retry = true,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final log = NetworkLogService.begin(
        method: method,
        url: uri.toString(),
        requestHeaders: headers,
        requestBody: bodyBytes != null ? '<binary ${bodyBytes.length} bytes>' : body,
        type: type,
      );
      try {
        final response = await _fetch(
          method: method,
          uri: uri,
          headers: headers,
          body: bodyBytes ?? utf8.encode(body),
          timeout: timeout,
        );
        log?.end(
          statusCode: response.statusCode,
          responseHeaders: response.headers.isEmpty
              ? null
              : Map.of(response.headers),
          responseBody: response.body,
          error: response.statusCode == 200 ? null : 'HTTP ${response.statusCode}',
        );
        if (retry &&
            attempt < maxAttempts &&
            isRetryableStatus(response.statusCode)) {
          await _backoff(attempt);
          continue;
        }
        return response;
      } on TimeoutException {
        log?.end(error: 'timeout');
        if (retry && attempt < maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        rethrow;
      } on http.ClientException {
        log?.end(error: 'connect error');
        if (retry && attempt < maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        rethrow;
      } catch (e) {
        log?.end(error: e.toString());
        rethrow;
      }
    }
    throw http.ClientException('Request failed');
  }

  /// 发送流式请求并返回响应流（不读取正文，单次尝试）。
  ///
  /// 重试策略由调用方统一处理（聊天场景的重试需要感知取消与
  /// 429/5xx 状态码，见 ChatService）。
  /// 发起前若 [isCancelled] 返回 true，直接以 [ChatCancelledException] 终止。
  Future<http.StreamedResponse> sendStreamed({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    Duration? connectTimeout,
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) {
      throw const ChatCancelledException();
    }
    try {
      final response = await NonaDio.instance.fetch<ResponseBody>(
        Options(
          method: method,
          headers: headers,
          responseType: ResponseType.stream,
          validateStatus: (_) => true, // 状态码交上层处理（重试/错误提取）
          sendTimeout: connectTimeout,
          receiveTimeout: connectTimeout,
          // 请求级禁用拦截器重试：聊天管线自行管理重试/取消
          extra: {
            'nona_no_retry': true,
            'nona_dio': NonaDio.instance,
          },
        ).compose(
          NonaDio.instance.options,
          uri.toString(),
          data: utf8.encode(body),
        ),
      );
      final statusCode = response.statusCode ?? 0;
      final responseHeaders = <String, String>{
        for (final e in response.headers.map.entries)
          e.key: e.value.isEmpty ? '' : e.value.join('; '),
      };
      return http.StreamedResponse(
        http.ByteStream(response.data!.stream),
        statusCode,
        headers: responseHeaders,
      );
    } on DioException catch (e) {
      throw _toHttpError(e);
    }
  }

  /// 单次请求（无重试），返回完整响应。
  Future<http.Response> _fetch({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required List<int> body,
    Duration? timeout,
  }) async {
    try {
      final response = await NonaDio.instance.fetch<dynamic>(
        Options(
          method: method,
          headers: headers,
          responseType: ResponseType.plain,
          validateStatus: (_) => true, // 状态码交上层处理（重试/错误提取）
          sendTimeout: timeout,
          receiveTimeout: timeout,
          // 请求级禁用拦截器重试：AppHttpClient 自行管理退避
          extra: {'nona_no_retry': true, 'nona_dio': NonaDio.instance},
        ).compose(
          NonaDio.instance.options,
          uri.toString(),
          data: body.isEmpty ? null : body,
        ),
      );
      return http.Response(
        response.data?.toString() ?? '',
        response.statusCode ?? 0,
        headers: {
          for (final e in response.headers.map.entries)
            e.key: e.value.isEmpty ? '' : e.value.join('; '),
        },
      );
    } on DioException catch (e) {
      throw _toHttpError(e);
    }
  }

  /// dio 异常 → http 层异常契约（TimeoutException / ClientException）。
  Object _toHttpError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(e.message ?? 'timeout');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        return http.ClientException(
          'HTTP $status: ${e.response?.data ?? e.message}',
        );
      default:
        return http.ClientException(e.message ?? e.type.toString());
    }
  }

  /// 关闭底层连接池（应用退出时调用）。
  void close() {}

  static bool isRetryableStatus(int status) =>
      status == 429 || (status >= 500 && status < 600);

  /// 第 [attempt] 次失败后的退避等待时长。
  ///
  /// 测试可通过 [overrideBackoff] 注入零退避，避免慢机 flake。
  static Duration Function(int attempt) backoffFor = _defaultBackoff;

  static Duration _defaultBackoff(int attempt) => backoffBase * attempt;

  /// 测试钩子：替换退避函数（传零退避可加速重试路径测试）。
  static void overrideBackoff(Duration Function(int attempt)? fn) {
    backoffFor = fn ?? _defaultBackoff;
  }

  static Future<void> _backoff(int attempt) =>
      Future.delayed(backoffFor(attempt));
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_provider.dart';
import '../app_http_client.dart';
import '../network_log_service.dart';

/// 余额查询结果。
class BalanceResult {
  final double? value;
  final String? error;

  const BalanceResult({this.value, this.error});

  bool get ok => value != null;
}

/// 余额查询服务（F2-4，对齐 Kelivo provider_balance_service）。
///
/// - 路径：服务商配置 `balancePath`（默认 `{base}/credits`）+
///   `balanceResultPath` JSON 路径表达式；
/// - 默认值：OpenRouter `data.total_credits - data.total_usage`；
///   OpenAI 系 `data.total_usage`；
/// - 5 分钟缓存（prefs），下拉刷新强制。
class BalanceService {
  static const String _kCachePrefix = 'balance_cache_';
  static const Duration cacheTtl = Duration(minutes: 5);

  /// 查询余额。
  Future<BalanceResult> fetch(ChatProvider provider,
      {bool force = false}) async {
    if (provider.apiKey.isEmpty) {
      return const BalanceResult(error: 'no api key');
    }
    if (!force) {
      final cached = await _readCache(provider.id);
      if (cached != null) return cached;
    }
    final base = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = provider.balancePath.trim().isEmpty
        ? '/credits'
        : provider.balancePath.startsWith('/')
            ? provider.balancePath
            : '/${provider.balancePath}';
    final uri = Uri.parse('$base$path');
    try {
      final response = await AppHttpClient.instance.send(
        method: 'GET',
        uri: uri,
        headers: AppHttpClient.jsonHeaders(bearer: provider.apiKey),
        type: NetworkLogType.other,
        timeout: const Duration(seconds: 15),
        retry: false,
      );
      if (response.statusCode != 200) {
        return BalanceResult(
          error: 'HTTP ${response.statusCode}',
        );
      }
      final data = jsonDecode(response.body);
      final value = extractBalance(data, provider);
      if (value == null) {
        return const BalanceResult(error: 'cannot parse balance');
      }
      final result = BalanceResult(value: value);
      await _writeCache(provider.id, result);
      return result;
    } catch (e) {
      return BalanceResult(error: e.toString());
    }
  }

  /// 按 JSON 路径表达式提取余额。
  ///
  /// 表达式示例：`data.total_usage`、`data.credits[0].balance`、
  /// `data.total_credits - data.total_usage`。
  static double? extractBalance(Object? json, ChatProvider provider) {
    final expr = provider.balanceResultPath.trim();
    if (expr.isEmpty) {
      // 默认值：OpenRouter 形状
      final openRouter = _evalPath(json, 'data.total_credits') != null &&
          _evalPath(json, 'data.total_usage') != null;
      if (openRouter) {
        return (_evalPath(json, 'data.total_credits') ?? 0) -
            (_evalPath(json, 'data.total_usage') ?? 0);
      }
      // OpenAI 系 / 其他：total_usage / balance / credits 兜底
      final usage = _evalPath(json, 'data.total_usage') ??
          _evalPath(json, 'total_usage');
      if (usage != null) return usage;
      final balance = _evalPath(json, 'data.balance') ??
          _evalPath(json, 'balance') ??
          _evalPath(json, 'data.credits') ??
          _evalPath(json, 'credits');
      return balance;
    }
    // 减法表达式
    final minus = expr.split('-');
    if (minus.length == 2) {
      final a = _evalPath(json, minus[0].trim());
      final b = _evalPath(json, minus[1].trim());
      if (a != null && b != null) return a - b;
      return null;
    }
    return _evalPath(json, expr);
  }

  /// 求值 JSON 路径：`a.b.c[0].d`。
  static double? _evalPath(Object? json, String path) {
    if (json == null || path.isEmpty) return null;
    Object? current = json;
    // 逐段解析：标识符 或 [index]
    final re = RegExp(r'([^.\[\]]+)|\[(\d+)\]');
    for (final m in re.allMatches(path)) {
      final name = m.group(1);
      final index = m.group(2);
      if (name != null) {
        if (current is! Map<String, dynamic>) return null;
        current = current[name];
      } else if (index != null) {
        if (current is! List) return null;
        final i = int.parse(index);
        if (i >= current.length) return null;
        current = current[i];
      }
    }
    if (current is num) return current.toDouble();
    return null;
  }

  Future<BalanceResult?> _readCache(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_kCachePrefix$providerId');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = data['cachedAt'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - cachedAt >
          cacheTtl.inMilliseconds) {
        return null;
      }
      final value = data['value'];
      if (value is num) return BalanceResult(value: value.toDouble());
    } catch (_) {}
    return null;
  }

  Future<void> _writeCache(String providerId, BalanceResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_kCachePrefix$providerId',
        jsonEncode({
          'value': result.value,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {}
  }

  /// 清除某服务商缓存（配置变更后）。
  Future<void> invalidate(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_kCachePrefix$providerId');
    } catch (_) {}
  }
}

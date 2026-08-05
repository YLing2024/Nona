import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import 'network_log_service.dart';

/// 模型能力映射表服务：内置静态表（离线兜底）+ 联网更新缓存。
///
/// 映射表用于在服务商 /models 接口未提供能力信息时，
/// 按模型 id 自动填充「多模态 / 推理」配置。
class ModelCapabilityService {
  static const _kCacheKey = 'model_capabilities';
  static const _kAssetPath = 'assets/model_capabilities.json';

  /// 网络更新源：LiteLLM 模型目录（含 supports_vision / supports_reasoning）。
  static const kDefaultSourceUrl =
      'https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json';

  Map<String, ModelConfig>? _cache;
  String? _version;

  /// 当前数据来源是否为联网更新后的本地缓存（否则为内置表）。
  bool _fromNetwork = false;

  /// 加载映射表：优先使用联网更新后的本地缓存，否则读内置静态表。
  Future<Map<String, ModelConfig>> load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _cache = _parseCompact(data['models']);
        _version = data['version'] as String?;
        _fromNetwork = true;
        return _cache!;
      } catch (_) {
        // 缓存损坏时回退到内置表
      }
    }
    try {
      final asset = await rootBundle.loadString(_kAssetPath);
      final data = jsonDecode(asset) as Map<String, dynamic>;
      _cache = _parseCompact(data['models']);
      _version = data['version'] as String?;
      _fromNetwork = false;
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  /// 当前映射表版本与数据来源。
  Future<({String? version, bool fromNetwork})> info() async {
    await load();
    return (version: _version, fromNetwork: _fromNetwork);
  }

  /// 查询模型能力；精确匹配 → 去 provider 前缀匹配。
  ModelConfig? lookup(String modelId, [Map<String, ModelConfig>? map]) {
    final m = map ?? _cache;
    if (m == null) return null;
    return m[modelId] ?? m[modelId.split('/').last];
  }

  /// 从网络更新映射表（默认 LiteLLM 目录），解析后缓存到本地。
  /// 返回更新日期版本号；失败时抛出异常。
  Future<String> updateFromNetwork({String? url}) async {
    final uri = Uri.parse(url ?? kDefaultSourceUrl);
    final log = NetworkLogService.begin(
      method: 'GET',
      url: uri.toString(),
      type: NetworkLogType.capability,
    );
    final http.Response resp;
    try {
      resp = await http.get(uri).timeout(const Duration(seconds: 60));
    } catch (e) {
      log?.end(error: e.toString());
      rethrow;
    }
    log?.end(
      statusCode: resp.statusCode,
      responseHeaders: Map.of(resp.headers),
      responseBody: resp.body,
      error: resp.statusCode != 200 ? 'HTTP ${resp.statusCode}' : null,
    );
    if (resp.statusCode != 200) {
      throw Exception('获取模型目录失败 (HTTP ${resp.statusCode})');
    }
    final raw = jsonDecode(resp.body) as Map<String, dynamic>;
    final models = _parseLiteLlm(raw);
    final version = _formatTimestamp(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCacheKey,
      jsonEncode({'version': version, 'models': models}),
    );
    _cache = models;
    _version = version;
    _fromNetwork = true;
    return version;
  }

  /// 格式化为「yyyy-MM-dd HH:mm:ss」，精确到秒，用作更新版本号/更新时间。
  static String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  /// 解析紧凑格式（内置表 / 本地缓存）：
  /// {id: {multimodal, reasoning, aliases?}}，aliases 展开为同配置的键。
  static Map<String, ModelConfig> _parseCompact(dynamic models) {
    final result = <String, ModelConfig>{};
    if (models is! Map) return result;
    models.forEach((id, v) {
      if (v is! Map<String, dynamic>) return;
      final config = ModelConfig(
        multimodal: v['multimodal'] == true,
        reasoning: v['reasoning'] == true,
      );
      result[id] = config;
      final aliases = v['aliases'];
      if (aliases is List) {
        for (final a in aliases) {
          result[a.toString()] = config;
        }
      }
    });
    return result;
  }

  /// 解析 LiteLLM 目录：{id: {mode, supports_vision, supports_reasoning, ...}}。
  /// 只保留对话模型，并补充去 provider 前缀的键（如 openai/gpt-4o → gpt-4o）。
  static Map<String, ModelConfig> _parseLiteLlm(Map<String, dynamic> raw) {
    final result = <String, ModelConfig>{};
    raw.forEach((id, v) {
      if (v is! Map<String, dynamic>) return;
      if (v['mode'] != 'chat') return;
      final config = ModelConfig(
        multimodal: v['supports_vision'] == true,
        reasoning: v['supports_reasoning'] == true,
      );
      result[id] = config;
      final slash = id.indexOf('/');
      if (slash > 0) {
        result[id.substring(slash + 1)] = config;
      }
    });
    return result;
  }
}

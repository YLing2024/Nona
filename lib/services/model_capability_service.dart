import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import '../models/network_log.dart';
import '../utils/logger.dart';
import 'app_http_client.dart';

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
      } catch (e) {
        // 缓存损坏时回退到内置表
        Logger.warn('capability', 'capability cache corrupt, fallback to builtin');
        Logger.error('capability', 'cache parse failed', e);
      }
    }
    try {
      final asset = await rootBundle.loadString(_kAssetPath);
      final data = jsonDecode(asset) as Map<String, dynamic>;
      _cache = _parseCompact(data['models']);
      _version = data['version'] as String?;
      _fromNetwork = false;
    } catch (e) {
      Logger.error('capability', 'builtin capability table load failed', e);
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

  /// 查询模型上下文窗口大小（tokens）。
  ///
  /// 优先级：能力映射表（联网 LiteLLM 目录 / 内置表）→ 内置已知模型表。
  /// 未知模型返回 null。
  int? contextWindowFor(String modelId, [Map<String, ModelConfig>? map]) {
    final config = lookup(modelId, map);
    if (config?.contextWindow != null) return config!.contextWindow;
    return knownContextWindow(modelId);
  }

  /// 内置已知模型上下文窗口表（离线兜底，按前缀匹配）。
  ///
  /// 注意：条目按「最长 key 优先」匹配，避免 `gpt-4o` 误匹配 `gpt-4o-mini`。
  static const Map<String, int> _knownWindows = {
    // OpenAI 新编码（o200k）模型
    'gpt-5': 400000,
    'gpt-5-mini': 400000,
    'gpt-4.1': 1000000,
    'gpt-4.1-mini': 1000000,
    'gpt-4.1-nano': 1000000,
    'gpt-4.5': 128000,
    'gpt-4o': 128000,
    'gpt-4o-mini': 128000,
    'o1': 200000,
    'o1-mini': 128000,
    'o3': 200000,
    'o3-mini': 200000,
    'o4-mini': 200000,
    // OpenAI 旧编码（cl100k）模型
    'gpt-4-turbo': 128000,
    'gpt-4': 8192,
    'gpt-3.5-turbo': 16385,
    // Anthropic
    'claude-opus-4': 200000,
    'claude-sonnet-4': 200000,
    'claude-3-7-sonnet': 200000,
    'claude-3-5-sonnet': 200000,
    'claude-3-5-haiku': 200000,
    'claude-3-opus': 200000,
    'claude-3-haiku': 200000,
    // Google
    'gemini-3': 1000000,
    'gemini-2.5': 1000000,
    'gemini-2.0': 1000000,
    'gemini-1.5': 1000000,
    'gemini-1.0': 32768,
    // 国内模型
    'deepseek-chat': 64000,
    'deepseek-reasoner': 64000,
    'deepseek-v3': 64000,
    'deepseek-r1': 64000,
    'glm-4': 128000,
    'glm-4v': 8192,
    'glm-4.5': 128000,
    'qwen3': 131072,
    'qwen2.5': 131072,
    'qwen2': 131072,
    'qwen': 32768,
    'kimi': 128000,
    'moonshot': 128000,
    'ernie': 8192,
    'hunyuan': 32768,
    // 开源模型
    'llama-3.3': 128000,
    'llama-3.1': 128000,
    'llama-3': 8192,
    'llama-2': 4096,
    'mistral-large': 128000,
    'mistral-small': 32768,
    'mixtral': 32768,
    'codestral': 256000,
    'command-r': 128000,
  };

  /// 内置已知模型窗口匹配：先精确匹配，再按最长前缀（`key-`）匹配。
  static int? knownContextWindow(String modelId) {
    if (modelId.isEmpty) return null;
    final exact = _knownWindows[modelId];
    if (exact != null) return exact;
    // 前缀匹配：按 key 长度降序，命中首个 `id.startsWith(key + '-')`
    final keys = _knownWindows.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      if (modelId.startsWith('$key-') || modelId.startsWith('$key/')) {
        return _knownWindows[key];
      }
    }
    return null;
  }

  /// 从网络更新映射表（默认 LiteLLM 目录），解析后缓存到本地。
  /// 返回更新日期版本号；失败时抛出异常。
  Future<String> updateFromNetwork({String? url}) async {
    final uri = Uri.parse(url ?? kDefaultSourceUrl);
    final resp = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      type: NetworkLogType.capability,
      timeout: const Duration(seconds: 60),
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch model catalog (HTTP ${resp.statusCode})',
      );
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
  /// {id: {multimodal, reasoning, contextWindow?, aliases?}}，
  /// aliases 展开为同配置的键。
  static Map<String, ModelConfig> _parseCompact(dynamic models) {
    final result = <String, ModelConfig>{};
    if (models is! Map) return result;
    models.forEach((id, v) {
      if (v is! Map<String, dynamic>) return;
      final config = ModelConfig(
        multimodal: v['multimodal'] == true,
        reasoning: v['reasoning'] == true,
        contextWindow: v['contextWindow'] as int?,
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

  /// 解析 LiteLLM 目录：
  /// {id: {mode, supports_vision, supports_reasoning, max_input_tokens, ...}}。
  /// 只保留对话模型，并补充去 provider 前缀的键（如 openai/gpt-4o → gpt-4o）。
  static Map<String, ModelConfig> _parseLiteLlm(Map<String, dynamic> raw) {
    final result = <String, ModelConfig>{};
    raw.forEach((id, v) {
      if (v is! Map<String, dynamic>) return;
      if (v['mode'] != 'chat') return;
      final config = ModelConfig(
        multimodal: v['supports_vision'] == true,
        reasoning: v['supports_reasoning'] == true,
        contextWindow: _toInt(v['max_input_tokens']),
      );
      result[id] = config;
      final slash = id.indexOf('/');
      if (slash > 0) {
        result[id.substring(slash + 1)] = config;
      }
    });
    return result;
  }

  /// 宽松转 int：LiteLLM 目录中可能出现 null / 字符串数字。
  static int? _toInt(Object? v) {
    if (v is int) return v > 0 ? v : null;
    if (v is num) return v.toInt() > 0 ? v.toInt() : null;
    if (v is String) {
      final parsed = int.tryParse(v);
      return (parsed != null && parsed > 0) ? parsed : null;
    }
    return null;
  }
}

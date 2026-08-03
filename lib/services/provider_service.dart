import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import 'settings_service.dart';

/// 服务商配置持久化服务。
class ProviderService {
  static const _kProviders = 'providers';
  static const _kInitialized = 'providers_initialized';

  /// 调试服务商（仅非 release 构建注入，release 构建完全不出现）。
  static const debugProviderId = 'provider-debug';

  /// 调试服务商环境变量名（.env 文件，见项目根 .env.example）。
  static const debugEnvApiKey = 'NONA_DEBUG_API_KEY';
  static const debugEnvBaseUrl = 'NONA_DEBUG_BASE_URL';

  /// 调试服务商默认地址（URL 非敏感信息，Key 必须由 .env 注入）。
  static const debugDefaultBaseUrl = 'https://opencode.ai/zen/go/v1';

  /// 调试服务商勾选的模型（单独存储，避免污染正式配置）。
  static const _kDebugModels = 'debug_provider_models';

  static bool get _debugEnabled => !kReleaseMode;

  Future<List<ChatProvider>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 首次使用：迁移旧的单一配置；无配置则内置一个空的 OpenAI。
    if (!(prefs.getBool(_kInitialized) ?? false)) {
      final old = await SettingsService().load();
      final List<ChatProvider> providers;
      if (old.apiKey.isEmpty) {
        providers = [ChatProvider(id: 'provider-openai', name: 'OpenAI')];
      } else {
        providers = [
          ChatProvider(
            id: 'provider-openai',
            name: 'OpenAI',
            baseUrl: old.baseUrl,
            apiKey: old.apiKey,
            modelIds: [if (old.model.isNotEmpty) old.model],
          ),
        ];
      }
      await prefs.setString(
        _kProviders,
        jsonEncode(providers.map((p) => p.toJson()).toList()),
      );
      await prefs.setBool(_kInitialized, true);
      return _withDebugProvider(providers);
    }

    final raw = prefs.getString(_kProviders);
    if (raw == null || raw.isEmpty) return _withDebugProvider([]);
    final list = jsonDecode(raw) as List<dynamic>;
    final providers = list
        .map((e) => ChatProvider.fromJson(e as Map<String, dynamic>))
        .toList();
    return _withDebugProvider(providers);
  }

  /// 非 release 构建下注入调试服务商（不写入正式配置）。
  ///
  /// API Key 从 .env 的 [debugEnvApiKey] 读取（main 中已加载）；
  /// 未配置时跳过注入，避免密钥出现在代码与仓库中。
  Future<List<ChatProvider>> _withDebugProvider(
    List<ChatProvider> providers,
  ) async {
    if (!_debugEnabled) return providers;
    final apiKey = _dotEnvValue(debugEnvApiKey).trim();
    if (apiKey.isEmpty) return providers;
    final envBaseUrl = _dotEnvValue(debugEnvBaseUrl).trim();
    final baseUrl = envBaseUrl.isNotEmpty ? envBaseUrl : debugDefaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    final models = prefs.getStringList(_kDebugModels) ?? const [];
    return [
      ...providers,
      ChatProvider(
        id: debugProviderId,
        name: 'Debug · opencode',
        baseUrl: baseUrl,
        apiKey: apiKey,
        modelIds: models,
      ),
    ];
  }

  /// 安全读取 .env 值：dotenv 未加载（如测试环境）时视为空。
  static String _dotEnvValue(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> save(List<ChatProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    // 调试服务商不持久化，仅保存其勾选的模型列表
    final debug = providers.where((p) => p.id == debugProviderId).firstOrNull;
    if (debug != null) {
      await prefs.setStringList(_kDebugModels, debug.modelIds);
    }
    final toSave = providers.where((p) => p.id != debugProviderId).toList();
    await prefs.setString(
      _kProviders,
      jsonEncode(toSave.map((p) => p.toJson()).toList()),
    );
    await prefs.setBool(_kInitialized, true);
  }

  /// 调用 OpenAI 格式的 /models 接口，获取可用模型 id 列表。
  Future<List<String>> fetchModels(ChatProvider provider) async {
    final baseUrl = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/models');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${provider.apiKey}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        '获取模型失败 (HTTP ${response.statusCode})：${_extractError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  String _extractError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'] as String;
      }
    } catch (_) {
      // 忽略解析失败
    }
    return body;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import '../models/network_log.dart';
import '../utils/logger.dart';
import 'app_http_client.dart';
import 'chat_protocol.dart' show ProviderKind, detectProviderKind;
import 'model_capability_service.dart';
import 'protocol/anthropic_adapter.dart';
import 'secure_credentials_service.dart';
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

  /// 调试服务商的模型级配置（多模态/推理等），同样单独持久化。
  static const _kDebugModelConfigs = 'debug_provider_model_configs';

  static bool get _debugEnabled => !kReleaseMode;

  /// 凭据安全存储键：`provider_api_key_{id}`。
  static String _apiKeyKey(String providerId) => 'provider_api_key_$providerId';

  Future<List<ChatProvider>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 首次使用：迁移旧的单一配置；无配置则内置一个空的 OpenAI。
    if (!(prefs.getBool(_kInitialized) ?? false)) {
      // 若已有正式配置但初始化标记丢失（迁移途中崩溃），不重复覆盖
      final existingRaw = prefs.getString(_kProviders);
      if (existingRaw != null && existingRaw.isNotEmpty) {
        final existing = _parse(raw: existingRaw);
        if (existing.isNotEmpty) {
          await prefs.setBool(_kInitialized, true);
          await _restoreKeysFromSecure(existing);
          return _withDebugProvider(existing);
        }
      }
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
      await _restoreKeysFromSecure(providers);
      return _withDebugProvider(providers);
    }

    final providers = _parse(raw: prefs.getString(_kProviders));
    await _restoreKeysFromSecure(providers);
    return _withDebugProvider(providers);
  }

  /// F7-1 凭据恢复与迁移：
  /// - secure 有值 → 覆盖 JSON 中的明文（旧明文键随后清理）；
  /// - JSON 有明文且 secure 无值 → 迁入 secure 并清空 JSON 明文
  ///   （Web 端 secure 不可用则保留 JSON 明文，UI 提示风险）。
  Future<void> _restoreKeysFromSecure(List<ChatProvider> providers) async {
    final secure = SecureCredentialsService.instance;
    var migrated = false;
    for (final p in providers) {
      final key = _apiKeyKey(p.id);
      final secureValue = await secure.read(key);
      if (secureValue.isNotEmpty) {
        if (p.apiKey != secureValue) {
          p.apiKey = secureValue;
          migrated = true;
        }
        continue;
      }
      if (p.apiKey.isNotEmpty && secure.available) {
        await secure.write(key, p.apiKey);
        p.apiKey = '';
        migrated = true;
      }
    }
    if (migrated) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _kProviders,
          jsonEncode(
            providers.where((p) => p.id != debugProviderId).map((p) => p.toJson()).toList(),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> save(List<ChatProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    // 调试服务商不写入正式配置，仅单独保存其勾选模型与模型级配置
    final debug = providers.where((p) => p.id == debugProviderId).firstOrNull;
    if (debug != null) {
      await prefs.setStringList(_kDebugModels, debug.modelIds);
      await prefs.setString(
        _kDebugModelConfigs,
        jsonEncode(
          debug.modelConfigs.map((k, v) => MapEntry(k, v.toJson())),
        ),
      );
    }
    final toSave = providers.where((p) => p.id != debugProviderId).toList();
    // F7-1：API Key 写入 secure storage，JSON 存空（Web 回退明文）
    final secure = SecureCredentialsService.instance;
    for (final p in toSave) {
      if (p.apiKey.isEmpty) continue;
      final key = _apiKeyKey(p.id);
      final stored = await secure.read(key);
      if (stored != p.apiKey) {
        await secure.write(key, p.apiKey);
      }
      if (secure.available) {
        p.apiKey = '';
      }
    }
    await prefs.setString(
      _kProviders,
      jsonEncode(toSave.map((p) => p.toJson()).toList()),
    );
    await prefs.setBool(_kInitialized, true);
  }

  /// 解析存储的服务商 JSON；损坏时跳过坏条目并自愈（覆写为可解析数据），
  /// 保证个别坏值不至于让整个应用启动崩溃。
  List<ChatProvider> _parse({String? raw}) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final result = <ChatProvider>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        try {
          result.add(ChatProvider.fromJson(e));
        } catch (_) {
          // 单条损坏跳过，不影响其余配置
        }
      }
      return result;
    } catch (e) {
      Logger.warn('provider', 'provider config corrupt, reset to empty list');
      Logger.error('provider', 'load parse failed', e);
      unawaited(_heal());
      return [];
    }
  }

  /// 损坏数据自愈：覆写为空列表，避免每次启动都崩溃。
  Future<void> _heal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProviders, '[]');
      await prefs.setBool(_kInitialized, true);
    } catch (_) {}
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
    final configsRaw = prefs.getString(_kDebugModelConfigs);
    Map<String, ModelConfig> modelConfigs = {};
    if (configsRaw != null && configsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(configsRaw) as Map<String, dynamic>;
        modelConfigs = decoded.map(
          (k, v) => MapEntry(
            k,
            ModelConfig.fromJson(v as Map<String, dynamic>),
          ),
        );
      } catch (_) {
        modelConfigs = {};
      }
    }
    return [
      ...providers.where((p) => p.id != debugProviderId),
      ChatProvider(
        id: debugProviderId,
        name: 'Debug · opencode',
        baseUrl: baseUrl,
        apiKey: apiKey,
        modelIds: models,
        modelConfigs: modelConfigs,
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

  /// 联动清理：模型/服务商被删除后，清除指向已不存在模型的全局默认配置
  /// （聊天默认模型、Agent 默认模型、标题模型、翻译模型），避免默认模型悬空。
  Future<void> clearStaleDefaultModels() async {
    final providers = await load();
    final valid = <String>{
      for (final p in providers) ...p.modelIds,
    };
    final settings = await SettingsService().load();
    final chatModel = settings.chatModel.isNotEmpty &&
            !valid.contains(settings.chatModel)
        ? ''
        : settings.chatModel;
    final agentModel = settings.defaultAgentModel.isNotEmpty &&
            !valid.contains(settings.defaultAgentModel)
        ? ''
        : settings.defaultAgentModel;
    final titleModel = settings.titleModel.isNotEmpty &&
            !valid.contains(settings.titleModel)
        ? ''
        : settings.titleModel;
    final translatorModel = settings.translatorModel.isNotEmpty &&
            !valid.contains(settings.translatorModel)
        ? ''
        : settings.translatorModel;
    if (chatModel == settings.chatModel &&
        agentModel == settings.defaultAgentModel &&
        titleModel == settings.titleModel &&
        translatorModel == settings.translatorModel) {
      return;
    }
    await SettingsService().save(
      settings.copyWith(
        chatModel: chatModel,
        defaultAgentModel: agentModel,
        titleModel: titleModel,
        translatorModel: translatorModel,
      ),
    );
  }

  /// 解析服务商实际协议（auto 时按 Base URL 探测）。
  static ProviderKind _effectiveKind(ChatProvider provider) {
    final kind = provider.kind;
    if (kind != ProviderKind.auto) return kind;
    return detectProviderKind(provider.baseUrl);
  }

  /// 拉取模型列表：按协议分派（OpenAI `/models` / Anthropic `/models` /
  /// Gemini `/models?key=`），返回模型 id 及能力配置。
  Future<List<(String, ModelConfig)>> fetchModels(ChatProvider provider) async {
    final baseUrl = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final kind = _effectiveKind(provider);
    final mapping = await ModelCapabilityService().load();
    switch (kind) {
      case ProviderKind.anthropic:
        return _fetchModelsAnthropic(baseUrl, provider.apiKey, mapping);
      case ProviderKind.gemini:
        return _fetchModelsGemini(baseUrl, provider.apiKey, mapping);
      case ProviderKind.openai:
      case ProviderKind.auto:
        return _fetchModelsOpenAi(baseUrl, provider.apiKey, mapping);
    }
  }

  Future<List<(String, ModelConfig)>> _fetchModelsOpenAi(
    String baseUrl,
    String apiKey,
    Map<String, ModelConfig> mapping,
  ) async {
    final uri = Uri.parse('$baseUrl/models');
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: AppHttpClient.jsonHeaders(bearer: apiKey),
      type: NetworkLogType.models,
      timeout: const Duration(seconds: 30),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic> && e['id'] is String)
          (e['id'] as String, _resolveConfig(e, mapping)),
    ];
  }

  Future<List<(String, ModelConfig)>> _fetchModelsAnthropic(
    String baseUrl,
    String apiKey,
    Map<String, ModelConfig> mapping,
  ) async {
    final uri = Uri.parse('$baseUrl/models');
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': AnthropicAdapter.anthropicVersion,
      },
      type: NetworkLogType.models,
      timeout: const Duration(seconds: 30),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic> && e['id'] is String)
          (e['id'] as String, _resolveConfig(e, mapping)),
    ];
  }

  Future<List<(String, ModelConfig)>> _fetchModelsGemini(
    String baseUrl,
    String apiKey,
    Map<String, ModelConfig> mapping,
  ) async {
    final uri = Uri.parse('$baseUrl/models?key=$apiKey');
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: {'x-goog-api-key': apiKey},
      type: NetworkLogType.models,
      timeout: const Duration(seconds: 30),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch models (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['models'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic> && e['name'] is String)
          // Gemini 模型 id 为 `models/gemini-x` 前缀格式，取末段
          (
            (e['name'] as String).split('/').last,
            _resolveConfig(e, mapping),
          ),
    ];
  }

  /// 合并能力信息：接口明确声明时以接口为准，
  /// 否则回退到内置/联网更新的模型能力映射表。
  static ModelConfig _resolveConfig(
    Map<String, dynamic> json,
    Map<String, ModelConfig> mapping,
  ) {
    final parsed = _parseModelConfig(json);
    if (parsed.multimodal || parsed.reasoning) return parsed;
    // Gemini 模型无 `id` 字段（用 `name`），两者都试
    final id = (json['id'] ?? json['name']).toString().split('/').last;
    return ModelCapabilityService().lookup(id, mapping) ?? parsed;
  }

  /// 从 /models 返回的模型对象中解析能力配置。
  ///
  /// 兼容常见字段：OpenAI 的 supported_features / modalities，
  /// 以及部分兼容服务商的 capabilities 对象。
  static ModelConfig _parseModelConfig(Map<String, dynamic> json) {
    var multimodal = false;
    var reasoning = false;

    final features = json['supported_features'];
    if (features is List) {
      final set = features.map((f) => f.toString().toLowerCase()).toSet();
      if (set.contains('vision') ||
          set.contains('image') ||
          set.contains('images')) {
        multimodal = true;
      }
      if (set.contains('reasoning')) reasoning = true;
    }

    final caps = json['capabilities'];
    if (caps is Map) {
      if (caps['vision'] == true ||
          caps['image'] == true ||
          caps['images'] == true) {
        multimodal = true;
      }
      if (caps['reasoning'] == true) reasoning = true;
    }

    final modalities = json['modalities'];
    if (modalities is List &&
        modalities.any((m) => m.toString().toLowerCase() == 'image')) {
      multimodal = true;
    }

    return ModelConfig(multimodal: multimodal, reasoning: reasoning);
  }

  /// 连通性测试结果。
  Future<ModelTestResult> testModel(
    ChatProvider provider,
    String modelId, {
    String prompt = 'ping',
  }) async {
    final baseUrl = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final kind = _effectiveKind(provider);
    final started = DateTime.now();
    final (uri, headers, body) = switch (kind) {
      ProviderKind.anthropic => (
        Uri.parse('$baseUrl/messages'),
        {
          'Content-Type': 'application/json',
          'x-api-key': provider.apiKey,
          'anthropic-version': AnthropicAdapter.anthropicVersion,
        },
        jsonEncode({
          'model': modelId,
          'max_tokens': 16,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      ),
      ProviderKind.gemini => (
        Uri.parse(
          '$baseUrl/models/${Uri.encodeComponent(modelId)}'
          ':streamGenerateContent?alt=sse',
        ),
        {
          'Content-Type': 'application/json',
          'x-goog-api-key': provider.apiKey,
        },
        jsonEncode({
          'contents': [
            {'role': 'user', 'parts': [{'text': prompt}]},
          ],
          'generationConfig': {'maxOutputTokens': 1},
        }),
      ),
      ProviderKind.openai || ProviderKind.auto => (
        Uri.parse('$baseUrl/chat/completions'),
        AppHttpClient.jsonHeaders(bearer: provider.apiKey),
        jsonEncode({
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1,
          'stream': false,
        }),
      ),
    };
    try {
      // retry: false —— 测速需要真实延迟，重试会污染测量结果
      final response = await AppHttpClient.instance.send(
        method: 'POST',
        uri: uri,
        headers: headers,
        body: body,
        type: NetworkLogType.test,
        timeout: const Duration(seconds: 30),
        retry: false,
      );
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      if (response.statusCode == 200) {
        return ModelTestResult(success: true, elapsedMs: elapsedMs);
      }
      return ModelTestResult(
        success: false,
        elapsedMs: elapsedMs,
        error: AppHttpClient.extractApiError(response.body),
      );
    } catch (e) {
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      return ModelTestResult(
        success: false,
        elapsedMs: elapsedMs,
        error: e.toString(),
      );
    }
  }
}

/// 单一模型连通性测试结果。
class ModelTestResult {
  final bool success;
  final int elapsedMs;
  final String? error;

  const ModelTestResult({
    required this.success,
    required this.elapsedMs,
    this.error,
  });

  String get displayLabel {
    if (success) return '${elapsedMs}ms';
    return error ?? 'Failed';
  }

  factory ModelTestResult.fromJson(Map<String, dynamic> json) {
    return ModelTestResult(
      success: json['success'] as bool? ?? false,
      elapsedMs: json['elapsedMs'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'elapsedMs': elapsedMs,
    if (error != null) 'error': error,
  };
}

/// 连通性测试结果持久化（按服务商存储）。
class TestResultStorage {
  static String _key(String providerId) => 'test_results_$providerId';

  static Future<void> save(
    String providerId,
    Map<String, ModelTestResult?> results,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final entry in results.entries) {
      if (entry.value != null) {
        data[entry.key] = entry.value!.toJson();
      }
    }
    await prefs.setString(_key(providerId), jsonEncode(data));
  }

  static Future<Map<String, ModelTestResult?>> load(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(providerId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, ModelTestResult.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }
}

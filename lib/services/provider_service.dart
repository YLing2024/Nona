import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import 'model_capability_service.dart';
import 'network_log_service.dart';
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
      ...providers,
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
    await prefs.setString(
      _kProviders,
      jsonEncode(toSave.map((p) => p.toJson()).toList()),
    );
    await prefs.setBool(_kInitialized, true);
  }

  /// 联动清理：模型/服务商被删除后，清除指向已不存在模型的全局默认配置
  /// （聊天默认模型、Agent 默认模型），避免默认模型悬空。
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
    if (chatModel == settings.chatModel &&
        agentModel == settings.defaultAgentModel) {
      return;
    }
    await SettingsService().save(
      settings.copyWith(chatModel: chatModel, defaultAgentModel: agentModel),
    );
  }

  /// 调用 OpenAI 格式的 /models 接口，获取可用模型 id 及能力配置。
  Future<List<(String, ModelConfig)>> fetchModels(ChatProvider provider) async {
    final baseUrl = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/models');
    final log = NetworkLogService.begin(
      method: 'GET',
      url: uri.toString(),
      requestHeaders: {
        'Authorization': 'Bearer ${provider.apiKey}',
        'Content-Type': 'application/json',
      },
      type: NetworkLogType.models,
    );
    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {
            'Authorization': 'Bearer ${provider.apiKey}',
            'Content-Type': 'application/json',
          })
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      log?.end(error: e.toString());
      rethrow;
    }
    log?.end(
      statusCode: response.statusCode,
      responseHeaders: Map.of(response.headers),
      responseBody: response.body,
      error: response.statusCode != 200 ? _extractError(response.body) : null,
    );
    if (response.statusCode != 200) {
      throw Exception(
        '获取模型失败 (HTTP ${response.statusCode})：${_extractError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    final mapping = await ModelCapabilityService().load();
    return [
      for (final e in list)
        if (e is Map<String, dynamic> && e['id'] is String)
          (e['id'] as String, _resolveConfig(e, mapping)),
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
    return ModelCapabilityService().lookup(json['id'] as String, mapping) ??
        parsed;
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
    final uri = Uri.parse('$baseUrl/chat/completions');
    final started = DateTime.now();
    final body = jsonEncode({
      'model': modelId,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 1,
      'stream': false,
    });
    final log = NetworkLogService.begin(
      method: 'POST',
      url: uri.toString(),
      requestHeaders: {
        'Authorization': 'Bearer ${provider.apiKey}',
        'Content-Type': 'application/json',
      },
      requestBody: body,
      type: NetworkLogType.test,
    );
    try {
      final response = await http
          .post(uri, headers: {
            'Authorization': 'Bearer ${provider.apiKey}',
            'Content-Type': 'application/json',
          }, body: body)
          .timeout(const Duration(seconds: 30));
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      log?.end(
        statusCode: response.statusCode,
        responseHeaders: Map.of(response.headers),
        responseBody: response.body,
        error: response.statusCode != 200 ? _extractError(response.body) : null,
      );
      if (response.statusCode == 200) {
        return ModelTestResult(success: true, elapsedMs: elapsedMs);
      }
      return ModelTestResult(
        success: false,
        elapsedMs: elapsedMs,
        error: _extractError(response.body),
      );
    } catch (e) {
      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      log?.end(error: e.toString());
      return ModelTestResult(
        success: false,
        elapsedMs: elapsedMs,
        error: e.toString(),
      );
    }
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
    return error ?? '失败';
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

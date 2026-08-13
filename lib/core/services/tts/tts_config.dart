import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// E-01：网络 TTS 服务商配置。
class TtsServiceConfig {
  final String id;
  final String name;

  /// kind：openai / gemini / minimax / qwen / groq / xai / elevenlabs / mimo。
  final String kind;

  /// 服务地址（OpenAI 兼容端点，如 https://api.openai.com/v1）。
  final String baseUrl;

  final String apiKey;

  /// 音色。
  final String voice;

  /// 语速（0.5~2.0）。
  final double rate;

  /// 模型 id（部分服务商需要）。
  final String model;

  /// 是否启用。
  final bool enabled;

  const TtsServiceConfig({
    required this.id,
    required this.name,
    required this.kind,
    required this.baseUrl,
    required this.apiKey,
    this.voice = '',
    this.rate = 1.0,
    this.model = '',
    this.enabled = true,
  });

  factory TtsServiceConfig.fromJson(Map<String, dynamic> json) =>
      TtsServiceConfig(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'openai',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        voice: json['voice'] as String? ?? '',
        rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
        model: json['model'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'voice': voice,
    'rate': rate,
    'model': model,
    'enabled': enabled,
  };
}

/// E-01：TTS 服务配置存储（prefs `tts_services` + `tts_selected`）。
class TtsConfigStore {
  static const _kServices = 'tts_services';
  static const _kSelected = 'tts_selected';

  static Future<List<TtsServiceConfig>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kServices);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) TtsServiceConfig.fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<TtsServiceConfig> services) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kServices,
      jsonEncode(services.map((s) => s.toJson()).toList()),
    );
  }

  static Future<String?> selectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelected);
  }

  static Future<void> setSelected(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kSelected);
    } else {
      await prefs.setString(_kSelected, id);
    }
  }

  /// 当前启用的网络 TTS（null = 用系统 TTS）。
  static Future<TtsServiceConfig?> effective() async {
    final services = await load();
    if (services.isEmpty) return null;
    final selected = await selectedId();
    final picked =
        services.where((s) => s.id == selected && s.enabled).firstOrNull ??
            services.where((s) => s.enabled).firstOrNull;
    if (picked == null) return null;
    if (picked.apiKey.isEmpty) return null;
    return picked;
  }
}

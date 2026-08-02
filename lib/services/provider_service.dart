import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import 'settings_service.dart';

/// 服务商配置持久化服务。
class ProviderService {
  static const _kProviders = 'providers';
  static const _kInitialized = 'providers_initialized';

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
      return providers;
    }

    final raw = prefs.getString(_kProviders);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChatProvider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<ChatProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProviders,
      jsonEncode(providers.map((p) => p.toJson()).toList()),
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

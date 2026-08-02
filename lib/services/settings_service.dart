import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置（API Key / Base URL / 模型名 / 主题模式），本地持久化。
class AppSettings {
  final String apiKey;
  final String baseUrl;
  final String model;

  /// 主题模式：system / light / dark。
  final String themeMode;

  const AppSettings({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.themeMode = 'system',
  });

  AppSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? themeMode,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// 负责读取/保存应用配置。
class SettingsService {
  static const _kApiKey = 'api_key';
  static const _kBaseUrl = 'base_url';
  static const _kModel = 'model';
  static const _kThemeMode = 'theme_mode';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiKey: prefs.getString(_kApiKey) ?? '',
      baseUrl: prefs.getString(_kBaseUrl) ?? 'https://api.openai.com/v1',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, settings.apiKey);
    await prefs.setString(_kBaseUrl, settings.baseUrl);
    await prefs.setString(_kModel, settings.model);
    await prefs.setString(_kThemeMode, settings.themeMode);
  }
}

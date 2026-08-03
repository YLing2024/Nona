import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置（API Key / Base URL / 模型名 / 主题模式 / 偏好），本地持久化。
class AppSettings {
  final String apiKey;
  final String baseUrl;
  final String model;

  /// 主题模式：system / light / dark。
  final String themeMode;

  /// 输入框按 Enter 是否发送消息。
  /// 开：Enter 发送、Shift+Enter 换行；
  /// 关：Enter 换行、Ctrl+Enter 发送。
  final bool sendOnEnter;

  const AppSettings({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.themeMode = 'system',
    this.sendOnEnter = false,
  });

  AppSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? themeMode,
    bool? sendOnEnter,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      themeMode: themeMode ?? this.themeMode,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
    );
  }
}

/// 负责读取/保存应用配置。
class SettingsService {
  static const _kApiKey = 'api_key';
  static const _kBaseUrl = 'base_url';
  static const _kModel = 'model';
  static const _kThemeMode = 'theme_mode';
  static const _kSendOnEnter = 'send_on_enter';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiKey: prefs.getString(_kApiKey) ?? '',
      baseUrl: prefs.getString(_kBaseUrl) ?? 'https://api.openai.com/v1',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      sendOnEnter: prefs.getBool(_kSendOnEnter) ?? false,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, settings.apiKey);
    await prefs.setString(_kBaseUrl, settings.baseUrl);
    await prefs.setString(_kModel, settings.model);
    await prefs.setString(_kThemeMode, settings.themeMode);
    await prefs.setBool(_kSendOnEnter, settings.sendOnEnter);
  }
}

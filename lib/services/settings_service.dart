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

  /// 模型连通性测试的提示词（服务商设置页「测试」时发送给模型的最小请求内容）。
  final String testPrompt;

  /// 新建 Agent 时的默认模型 ID。
  final String defaultAgentModel;

  /// 默认聊天模型 ID（用于新建会话），空字符串表示无默认值（需手动选择）。
  final String chatModel;

  /// 开发者模式：开启后设置页显示「开发者选项」高级设置入口。
  final bool developerMode;

  /// 开发者选项：启动时自动联网更新模型能力映射表。
  final bool autoUpdateModelCapabilities;

  /// 开发者选项：启用网络日志记录。
  final bool networkLogEnabled;

  /// 开发者选项：网络日志最大保留条数，0 表示不限制。
  final int networkLogMaxLogs;

  const AppSettings({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.themeMode = 'system',
    this.sendOnEnter = false,
    this.testPrompt = 'ping',
    this.defaultAgentModel = '',
    this.chatModel = '',
    this.developerMode = false,
    this.autoUpdateModelCapabilities = false,
    this.networkLogEnabled = false,
    this.networkLogMaxLogs = 0,
  });

  AppSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? themeMode,
    bool? sendOnEnter,
    String? testPrompt,
    String? defaultAgentModel,
    String? chatModel,
    bool? developerMode,
    bool? autoUpdateModelCapabilities,
    bool? networkLogEnabled,
    int? networkLogMaxLogs,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      themeMode: themeMode ?? this.themeMode,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
      testPrompt: testPrompt ?? this.testPrompt,
      defaultAgentModel: defaultAgentModel ?? this.defaultAgentModel,
      chatModel: chatModel ?? this.chatModel,
      developerMode: developerMode ?? this.developerMode,
      autoUpdateModelCapabilities:
          autoUpdateModelCapabilities ?? this.autoUpdateModelCapabilities,
      networkLogEnabled: networkLogEnabled ?? this.networkLogEnabled,
      networkLogMaxLogs: networkLogMaxLogs ?? this.networkLogMaxLogs,
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
  static const _kTestPrompt = 'test_prompt';
  static const _kDefaultAgentModel = 'default_agent_model';
  static const _kChatModel = 'chat_model';
  static const _kDeveloperMode = 'developer_mode';
  static const _kAutoUpdateModelCapabilities = 'auto_update_model_capabilities';
  static const _kNetworkLogEnabled = 'network_log_enabled';
  static const _kNetworkLogMaxLogs = 'network_log_max_logs';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      apiKey: prefs.getString(_kApiKey) ?? '',
      baseUrl: prefs.getString(_kBaseUrl) ?? 'https://api.openai.com/v1',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      sendOnEnter: prefs.getBool(_kSendOnEnter) ?? false,
      testPrompt: prefs.getString(_kTestPrompt) ?? 'ping',
      defaultAgentModel: prefs.getString(_kDefaultAgentModel) ?? '',
      chatModel: prefs.getString(_kChatModel) ?? '',
      developerMode: prefs.getBool(_kDeveloperMode) ?? false,
      autoUpdateModelCapabilities:
          prefs.getBool(_kAutoUpdateModelCapabilities) ?? false,
      networkLogEnabled: prefs.getBool(_kNetworkLogEnabled) ?? false,
      networkLogMaxLogs: prefs.getInt(_kNetworkLogMaxLogs) ?? 0,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, settings.apiKey);
    await prefs.setString(_kBaseUrl, settings.baseUrl);
    await prefs.setString(_kModel, settings.model);
    await prefs.setString(_kThemeMode, settings.themeMode);
    await prefs.setBool(_kSendOnEnter, settings.sendOnEnter);
    await prefs.setString(_kTestPrompt, settings.testPrompt);
    await prefs.setString(_kDefaultAgentModel, settings.defaultAgentModel);
    await prefs.setString(_kChatModel, settings.chatModel);
    await prefs.setBool(_kDeveloperMode, settings.developerMode);
    await prefs.setBool(
      _kAutoUpdateModelCapabilities,
      settings.autoUpdateModelCapabilities,
    );
    await prefs.setBool(_kNetworkLogEnabled, settings.networkLogEnabled);
    await prefs.setInt(_kNetworkLogMaxLogs, settings.networkLogMaxLogs);
  }
}

import 'model_router_service.dart';
import '../network/nona_dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置（API Key / Base URL / 模型名 / 主题模式 / 偏好），本地持久化。
class AppSettings {
  /// 请求载体：单次聊天/测速等请求使用的 API Key（由调用方按服务商填充）。
  ///
  /// 同时兼容旧版持久化：老版本将单一服务商配置存于本键，现版本仅用于
  /// 首次启动迁移到「服务商」配置（见 ProviderService），此后不再从设置读取。
  final String apiKey;

  /// 请求载体：接口基础地址，例如 https://api.openai.com/v1（同 [apiKey] 说明）。
  final String baseUrl;

  /// 请求载体：模型 id（同 [apiKey] 说明）。
  final String model;

  /// 主题模式：system / light / dark。
  final String themeMode;

  /// 界面语言：system（跟随系统）/ zh / en。
  final String locale;

  /// 主题强调色（ARGB 色值，0 表示未设置使用默认靛蓝）。
  final int accentColor;

  /// 深色模式下是否使用 OLED 纯黑背景。
  final bool oledDark;

  /// 输入框按 Enter 是否发送消息。
  /// 开：Enter 发送、Shift+Enter 换行；
  /// 关：Enter 换行、Ctrl+Enter 发送。
  final bool sendOnEnter;

  /// 流式生成期间是否实时渲染 Markdown 格式。
  /// 开：生成多少渲染多少（正文实时 Markdown 解析）；
  /// 关：生成期间显示纯文本，生成完成后再渲染 Markdown。
  final bool streamMarkdownRender;

  /// 文本文档阈值：超过该字符数的消息折叠为「文本文档」入口，
  /// 点击进入详情页查看全文；0 表示不折叠（直接渲染）。
  final int documentThreshold;

  /// 模型连通性测试的提示词（服务商设置页「测试」时发送给模型的最小请求内容）。
  final String testPrompt;

  /// 新建 Agent 时的默认模型 ID。
  final String defaultAgentModel;

  /// 默认聊天模型 ID（用于新建会话），空字符串表示无默认值（需手动选择）。
  final String chatModel;

  /// 自动生成会话标题使用的模型 ID，空字符串表示未配置（维持截取首条消息逻辑）。
  final String titleModel;

  /// AI 翻译使用的模型 ID，空字符串表示未配置（回退使用 [chatModel]）。
  final String translatorModel;

  /// 开发者模式：开启后设置页显示「开发者选项」高级设置入口。
  final bool developerMode;

  /// 开发者选项：启动时自动联网更新模型能力映射表。
  final bool autoUpdateModelCapabilities;

  /// 开发者选项：启用网络日志记录。
  final bool networkLogEnabled;

  /// 开发者选项：网络日志最大保留条数，0 表示不限制。
  final int networkLogMaxLogs;

  /// 聊天请求自动重试：连接失败 / 429 / 5xx 时指数退避重试（最多 3 次尝试）。
  final bool chatAutoRetry;

  /// TTS 朗读语速（系统 TTS 参数，0~1，默认 0.5）。
  final double ttsRate;

  /// TTS 朗读语言（系统 TTS 语言代码，如 zh-CN / en-US）。
  final String ttsLanguage;

  /// 服务商协议类型（auto/openai/anthropic/gemini），请求时按此分发。
  final String providerKind;

  /// A-04：全局网络代理开关（设置 → 网络）。
  final bool proxyEnabled;

  /// A-04：代理类型 http / https / socks5。
  final String proxyType;

  /// A-04：代理主机。
  final String proxyHost;

  /// A-04：代理端口。
  final int proxyPort;

  /// A-04：代理用户名（可选）。
  final String proxyUser;

  /// X-02：启用智能模型路由（任务槽自动选模型）。
  final bool autoModelRouting;

  /// J-02：启动时检查更新（默认关）。
  final bool checkUpdatesOnStart;

  /// J-02：自定义更新检查源（GitHub Releases API JSON；空用默认仓库）。
  final String updateSource;

  /// A-04：代理密码（可选）。
  final String proxyPassword;

  /// A-04：绕过代理的主机列表（逗号分隔；默认含 localhost/127.0.0.1）。
  final String proxyBypass;
  /// 是否启用网络搜索（发送前自动搜索并注入上下文）。
  final bool webSearchEnabled;

  /// 搜索引擎（bing/duckduckgo/tavily/searxng）。
  final String webSearchEngine;

  /// Tavily API Key。
  final String webSearchApiKey;

  /// SearXNG 自托管地址。
  final String webSearchBaseUrl;

  const AppSettings({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.themeMode = 'system',
    this.locale = 'system',
    this.accentColor = 0,
    this.oledDark = false,
    this.sendOnEnter = false,
    this.streamMarkdownRender = true,
    this.documentThreshold = 40000,
    this.testPrompt = 'ping',
    this.defaultAgentModel = '',
    this.chatModel = '',
    this.titleModel = '',
    this.translatorModel = '',
    this.developerMode = false,
    this.autoUpdateModelCapabilities = false,
    this.networkLogEnabled = false,
    this.networkLogMaxLogs = 0,
    this.chatAutoRetry = true,
    this.ttsRate = 0.5,
    this.ttsLanguage = 'zh-CN',
    this.providerKind = 'auto',
    this.autoModelRouting = false,
    this.checkUpdatesOnStart = false,
    this.updateSource = '',
    this.proxyEnabled = false,
    this.proxyType = 'http',
    this.proxyHost = '',
    this.proxyPort = 0,
    this.proxyUser = '',
    this.proxyPassword = '',
    this.proxyBypass = '',
    this.webSearchEnabled = false,
    this.webSearchEngine = 'bing',
    this.webSearchApiKey = '',
    this.webSearchBaseUrl = '',
  });

  AppSettings copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? themeMode,
    String? locale,
    int? accentColor,
    bool? oledDark,
    bool? sendOnEnter,
    bool? streamMarkdownRender,
    int? documentThreshold,
    String? testPrompt,
    String? defaultAgentModel,
    String? chatModel,
    String? titleModel,
    String? translatorModel,
    bool? developerMode,
    bool? autoUpdateModelCapabilities,
    bool? networkLogEnabled,
    int? networkLogMaxLogs,
    bool? chatAutoRetry,
    double? ttsRate,
    String? ttsLanguage,
    String? providerKind,
    bool? autoModelRouting,
    bool? checkUpdatesOnStart,
    String? updateSource,
    bool? proxyEnabled,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    String? proxyUser,
    String? proxyPassword,
    String? proxyBypass,
    bool? webSearchEnabled,
    String? webSearchEngine,
    String? webSearchApiKey,
    String? webSearchBaseUrl,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      accentColor: accentColor ?? this.accentColor,
      oledDark: oledDark ?? this.oledDark,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
      streamMarkdownRender: streamMarkdownRender ?? this.streamMarkdownRender,
      documentThreshold: documentThreshold ?? this.documentThreshold,
      testPrompt: testPrompt ?? this.testPrompt,
      defaultAgentModel: defaultAgentModel ?? this.defaultAgentModel,
      chatModel: chatModel ?? this.chatModel,
      titleModel: titleModel ?? this.titleModel,
      translatorModel: translatorModel ?? this.translatorModel,
      developerMode: developerMode ?? this.developerMode,
      autoUpdateModelCapabilities:
          autoUpdateModelCapabilities ?? this.autoUpdateModelCapabilities,
      networkLogEnabled: networkLogEnabled ?? this.networkLogEnabled,
      networkLogMaxLogs: networkLogMaxLogs ?? this.networkLogMaxLogs,
      chatAutoRetry: chatAutoRetry ?? this.chatAutoRetry,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      providerKind: providerKind ?? this.providerKind,
      autoModelRouting: autoModelRouting ?? this.autoModelRouting,
      checkUpdatesOnStart: checkUpdatesOnStart ?? this.checkUpdatesOnStart,
      updateSource: updateSource ?? this.updateSource,
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      proxyUser: proxyUser ?? this.proxyUser,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      proxyBypass: proxyBypass ?? this.proxyBypass,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      webSearchEngine: webSearchEngine ?? this.webSearchEngine,
      webSearchApiKey: webSearchApiKey ?? this.webSearchApiKey,
      webSearchBaseUrl: webSearchBaseUrl ?? this.webSearchBaseUrl,
    );
  }
}

/// 负责读取/保存应用配置。
class SettingsService {
  static const _kApiKey = 'api_key';
  static const _kBaseUrl = 'base_url';
  static const _kModel = 'model';
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kAccentColor = 'accent_color';
  static const _kOledDark = 'oled_dark';
  static const _kSendOnEnter = 'send_on_enter';
  static const _kStreamMarkdownRender = 'stream_markdown_render';
  static const _kDocumentThreshold = 'document_threshold';
  static const _kTestPrompt = 'test_prompt';
  static const _kDefaultAgentModel = 'default_agent_model';
  static const _kChatModel = 'chat_model';
  static const _kTitleModel = 'title_model';
  static const _kTranslatorModel = 'translator_model';
  static const _kDeveloperMode = 'developer_mode';
  static const _kAutoUpdateModelCapabilities = 'auto_update_model_capabilities';
  static const _kNetworkLogEnabled = 'network_log_enabled';
  static const _kNetworkLogMaxLogs = 'network_log_max_logs';
  static const _kChatAutoRetry = 'chat_auto_retry';
  static const _kTtsRate = 'tts_rate';
  static const _kTtsLanguage = 'tts_language';
  static const _kProviderKind = 'provider_kind';
  static const _kWebSearchEnabled = 'web_search_enabled';
  static const _kAutoModelRouting = 'auto_model_routing';
  static const _kCheckUpdatesOnStart = 'check_updates_on_start';
  static const _kUpdateSource = 'update_source';
  static const _kProxyEnabled = 'proxy_enabled';
  static const _kProxyType = 'proxy_type';
  static const _kProxyHost = 'proxy_host';
  static const _kProxyPort = 'proxy_port';
  static const _kProxyUser = 'proxy_user';
  static const _kProxyPassword = 'proxy_password';
  static const _kProxyBypass = 'proxy_bypass';
  static const _kWebSearchEngine = 'web_search_engine';
  static const _kWebSearchApiKey = 'web_search_api_key';
  static const _kWebSearchBaseUrl = 'web_search_base_url';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      apiKey: prefs.getString(_kApiKey) ?? '',
      baseUrl: prefs.getString(_kBaseUrl) ?? 'https://api.openai.com/v1',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      locale: prefs.getString(_kLocale) ?? 'system',
      accentColor: prefs.getInt(_kAccentColor) ?? 0,
      oledDark: prefs.getBool(_kOledDark) ?? false,
      // 未显式设置过时按平台给默认值：PC/Web 回车发送，移动端回车换行
      // （getBool 对损坏/异类型值返回 null，不能直接 `!` 解包）
      sendOnEnter: prefs.getBool(_kSendOnEnter) ?? _defaultSendOnEnter(),
      streamMarkdownRender: prefs.getBool(_kStreamMarkdownRender) ?? true,
      documentThreshold: prefs.getInt(_kDocumentThreshold) ?? 40000,
      testPrompt: prefs.getString(_kTestPrompt) ?? 'ping',
      defaultAgentModel: prefs.getString(_kDefaultAgentModel) ?? '',
      chatModel: prefs.getString(_kChatModel) ?? '',
      titleModel: prefs.getString(_kTitleModel) ?? '',
      translatorModel: prefs.getString(_kTranslatorModel) ?? '',
      developerMode: prefs.getBool(_kDeveloperMode) ?? false,
      autoUpdateModelCapabilities:
          prefs.getBool(_kAutoUpdateModelCapabilities) ?? false,
      networkLogEnabled: prefs.getBool(_kNetworkLogEnabled) ?? false,
      networkLogMaxLogs: prefs.getInt(_kNetworkLogMaxLogs) ?? 0,
      // 未显式设置时默认开启自动重试
      chatAutoRetry: prefs.getBool(_kChatAutoRetry) ?? true,
      ttsRate: prefs.getDouble(_kTtsRate) ?? 0.5,
      ttsLanguage: prefs.getString(_kTtsLanguage) ?? 'zh-CN',
      providerKind: prefs.getString(_kProviderKind) ?? 'auto',
      autoModelRouting: prefs.getBool(_kAutoModelRouting) ?? false,
      checkUpdatesOnStart: prefs.getBool(_kCheckUpdatesOnStart) ?? false,
      updateSource: prefs.getString(_kUpdateSource) ?? '',
      proxyEnabled: prefs.getBool(_kProxyEnabled) ?? false,
      proxyType: prefs.getString(_kProxyType) ?? 'http',
      proxyHost: prefs.getString(_kProxyHost) ?? '',
      proxyPort: prefs.getInt(_kProxyPort) ?? 0,
      proxyUser: prefs.getString(_kProxyUser) ?? '',
      proxyPassword: prefs.getString(_kProxyPassword) ?? '',
      proxyBypass: prefs.getString(_kProxyBypass) ?? '',
      webSearchEnabled: prefs.getBool(_kWebSearchEnabled) ?? false,
      webSearchEngine: prefs.getString(_kWebSearchEngine) ?? 'bing',
      webSearchApiKey: prefs.getString(_kWebSearchApiKey) ?? '',
      webSearchBaseUrl: prefs.getString(_kWebSearchBaseUrl) ?? '',
    );
    _syncProxy(settings);
    _syncRouter(settings);
    return settings;
  }

  /// PC（Windows/macOS/Linux）与 Web 默认回车发送，移动端默认回车换行。
  static bool _defaultSendOnEnter() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, settings.apiKey);
    await prefs.setString(_kBaseUrl, settings.baseUrl);
    await prefs.setString(_kModel, settings.model);
    await prefs.setString(_kThemeMode, settings.themeMode);
    await prefs.setString(_kLocale, settings.locale);
    await prefs.setInt(_kAccentColor, settings.accentColor);
    await prefs.setBool(_kOledDark, settings.oledDark);
    await prefs.setBool(_kSendOnEnter, settings.sendOnEnter);
    await prefs.setBool(_kStreamMarkdownRender, settings.streamMarkdownRender);
    await prefs.setInt(_kDocumentThreshold, settings.documentThreshold);
    await prefs.setString(_kTestPrompt, settings.testPrompt);
    await prefs.setString(_kDefaultAgentModel, settings.defaultAgentModel);
    await prefs.setString(_kChatModel, settings.chatModel);
    await prefs.setString(_kTitleModel, settings.titleModel);
    await prefs.setString(_kTranslatorModel, settings.translatorModel);
    await prefs.setBool(_kDeveloperMode, settings.developerMode);
    await prefs.setBool(
      _kAutoUpdateModelCapabilities,
      settings.autoUpdateModelCapabilities,
    );
    await prefs.setBool(_kNetworkLogEnabled, settings.networkLogEnabled);
    await prefs.setInt(_kNetworkLogMaxLogs, settings.networkLogMaxLogs);
    await prefs.setBool(_kChatAutoRetry, settings.chatAutoRetry);
    await prefs.setDouble(_kTtsRate, settings.ttsRate);
    await prefs.setString(_kTtsLanguage, settings.ttsLanguage);
    await prefs.setString(_kProviderKind, settings.providerKind);
    await prefs.setBool(_kAutoModelRouting, settings.autoModelRouting);
    await prefs.setBool(_kCheckUpdatesOnStart, settings.checkUpdatesOnStart);
    await prefs.setString(_kUpdateSource, settings.updateSource);
    await prefs.setBool(_kProxyEnabled, settings.proxyEnabled);
    await prefs.setString(_kProxyType, settings.proxyType);
    await prefs.setString(_kProxyHost, settings.proxyHost);
    await prefs.setInt(_kProxyPort, settings.proxyPort);
    await prefs.setString(_kProxyUser, settings.proxyUser);
    await prefs.setString(_kProxyPassword, settings.proxyPassword);
    await prefs.setString(_kProxyBypass, settings.proxyBypass);
    await prefs.setBool(_kWebSearchEnabled, settings.webSearchEnabled);
    await prefs.setString(_kWebSearchEngine, settings.webSearchEngine);
    await prefs.setString(_kWebSearchApiKey, settings.webSearchApiKey);
    await prefs.setString(_kWebSearchBaseUrl, settings.webSearchBaseUrl);
    _syncProxy(settings);
    _syncRouter(settings);
  }

  /// X-02：把路由开关同步到 ModelRouterService。
  void _syncRouter(AppSettings settings) {
    ModelRouterService().autoRoutingEnabled = settings.autoModelRouting;
  }

  /// A-04：把代理设置同步到 NonaDio（http/https findProxy / socks5 adapter）。
  void _syncProxy([AppSettings? settings]) {
    NonaDio.updateSettings(settings);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @aboutCopyright.
  ///
  /// In zh, this message translates to:
  /// **'Copyright © 2026 Yunling Zhang · 本地优先，所有数据仅保存在本机'**
  String get aboutCopyright;

  /// No description provided for @aboutDeveloperMode.
  ///
  /// In zh, this message translates to:
  /// **'开发者模式'**
  String get aboutDeveloperMode;

  /// No description provided for @aboutDeveloperModeHint.
  ///
  /// In zh, this message translates to:
  /// **'启用后，设置页将显示「开发者选项」高级设置'**
  String get aboutDeveloperModeHint;

  /// No description provided for @aboutDeveloperSection.
  ///
  /// In zh, this message translates to:
  /// **'开发者'**
  String get aboutDeveloperSection;

  /// No description provided for @aboutGithub.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库'**
  String get aboutGithub;

  /// No description provided for @aboutLicense.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get aboutLicense;

  /// No description provided for @aboutPlatform.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get aboutPlatform;

  /// No description provided for @aboutTagline.
  ///
  /// In zh, this message translates to:
  /// **'一款简洁高效的 AI 聊天客户端，兼容 OpenAI 格式接口'**
  String get aboutTagline;

  /// No description provided for @aboutTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get aboutVersion;

  /// No description provided for @accentIndigo.
  ///
  /// In zh, this message translates to:
  /// **'靛蓝'**
  String get accentIndigo;

  /// No description provided for @accentOrange.
  ///
  /// In zh, this message translates to:
  /// **'橙'**
  String get accentOrange;

  /// No description provided for @accentRed.
  ///
  /// In zh, this message translates to:
  /// **'赤红'**
  String get accentRed;

  /// No description provided for @accentRose.
  ///
  /// In zh, this message translates to:
  /// **'玫红'**
  String get accentRose;

  /// No description provided for @accentSky.
  ///
  /// In zh, this message translates to:
  /// **'天蓝'**
  String get accentSky;

  /// No description provided for @accentSlate.
  ///
  /// In zh, this message translates to:
  /// **'青灰'**
  String get accentSlate;

  /// No description provided for @accentTeal.
  ///
  /// In zh, this message translates to:
  /// **'青绿'**
  String get accentTeal;

  /// No description provided for @accentViolet.
  ///
  /// In zh, this message translates to:
  /// **'紫罗兰'**
  String get accentViolet;

  /// No description provided for @addModelApiKeyRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写 API Key'**
  String get addModelApiKeyRequired;

  /// No description provided for @addModelExample.
  ///
  /// In zh, this message translates to:
  /// **'例如：gpt-4o'**
  String get addModelExample;

  /// No description provided for @addModelFetch.
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表'**
  String get addModelFetch;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表失败：{detail}'**
  String addModelFetchFailed(String detail);

  /// No description provided for @addModelFetchFromList.
  ///
  /// In zh, this message translates to:
  /// **'从列表获取'**
  String get addModelFetchFromList;

  /// No description provided for @addModelFetchHint.
  ///
  /// In zh, this message translates to:
  /// **'调用 /models 接口获取可用模型\\n获取前请先填写 API Key'**
  String get addModelFetchHint;

  /// No description provided for @addModelManual.
  ///
  /// In zh, this message translates to:
  /// **'手动输入'**
  String get addModelManual;

  /// No description provided for @addModelManualHint.
  ///
  /// In zh, this message translates to:
  /// **'填写一个模型 ID'**
  String get addModelManualHint;

  /// No description provided for @addModelNoModels.
  ///
  /// In zh, this message translates to:
  /// **'该接口未返回任何模型'**
  String get addModelNoModels;

  /// No description provided for @addModelReasoningHint.
  ///
  /// In zh, this message translates to:
  /// **'推理模型支持思考模式'**
  String get addModelReasoningHint;

  /// No description provided for @addModelTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get addModelTitle;

  /// No description provided for @agentAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加 Agent'**
  String get agentAdd;

  /// No description provided for @agentConfigTitle.
  ///
  /// In zh, this message translates to:
  /// **'Agent 配置'**
  String get agentConfigTitle;

  /// No description provided for @agentDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get agentDefault;

  /// No description provided for @agentDefaultHint.
  ///
  /// In zh, this message translates to:
  /// **'单击「新建会话」时自动套用该配置'**
  String get agentDefaultHint;

  /// No description provided for @agentDefaultParams.
  ///
  /// In zh, this message translates to:
  /// **'默认参数'**
  String get agentDefaultParams;

  /// No description provided for @agentDefaultSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'你是 Nona，一款简洁高效的 AI 聊天助手。请用简体中文、以清晰友好的语气回应用户，回答问题力求准确、有条理；当需求不明确时可以适当追问，但不要过度。除非用户特别要求，否则默认使用中文回答。'**
  String get agentDefaultSystemPrompt;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'删除 Agent「{name}」？'**
  String agentDeleteConfirm(String name);

  /// No description provided for @agentDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 Agent'**
  String get agentDeleteTitle;

  /// No description provided for @agentEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑 Agent'**
  String get agentEdit;

  /// No description provided for @agentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无 Agent，点右上角添加'**
  String get agentEmpty;

  /// No description provided for @agentMemories.
  ///
  /// In zh, this message translates to:
  /// **'长期记忆（每行一条）'**
  String get agentMemories;

  /// No description provided for @agentMemoriesHint.
  ///
  /// In zh, this message translates to:
  /// **'例：用户偏好简洁的回答风格'**
  String get agentMemoriesHint;

  /// No description provided for @agentName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get agentName;

  /// No description provided for @agentNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：代码助手、翻译官等'**
  String get agentNameHint;

  /// No description provided for @agentNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写 Agent 名称'**
  String get agentNameRequired;

  /// No description provided for @agentNew.
  ///
  /// In zh, this message translates to:
  /// **'新建 Agent'**
  String get agentNew;

  /// No description provided for @agentSetDefault.
  ///
  /// In zh, this message translates to:
  /// **'设为默认 Agent'**
  String get agentSetDefault;

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Nona'**
  String get appTitle;

  /// No description provided for @chatClearInput.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get chatClearInput;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'上下文 {tokens}'**
  String chatContextUsage(String tokens);

  /// No description provided for @chatCopyMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'复制为 Markdown'**
  String get chatCopyMarkdown;

  /// No description provided for @chatDeleteSession.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get chatDeleteSession;

  /// No description provided for @chatDeleteSelectedTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除所选消息'**
  String get chatDeleteSelectedTitle;

  /// No description provided for @chatDeleteSelectedBody.
  ///
  /// In zh, this message translates to:
  /// **'将删除所选 {count} 条消息及其后的所有消息，且不可恢复。确定继续吗？'**
  String chatDeleteSelectedBody(int count);

  /// No description provided for @chatDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get chatDelete;

  /// No description provided for @chatDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 条消息'**
  String chatDeleted(int count);

  /// No description provided for @tokenDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'Token 明细'**
  String get tokenDetailTitle;

  /// No description provided for @tokenDetailInput.
  ///
  /// In zh, this message translates to:
  /// **'输入（接口）'**
  String get tokenDetailInput;

  /// No description provided for @tokenDetailOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出（接口）'**
  String get tokenDetailOutput;

  /// No description provided for @tokenDetailElapsed.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get tokenDetailElapsed;

  /// No description provided for @tokenDetailModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get tokenDetailModel;

  /// No description provided for @tokenDetailEstimated.
  ///
  /// In zh, this message translates to:
  /// **'本地估算（正文）'**
  String get tokenDetailEstimated;

  /// No description provided for @tokenDetailCost.
  ///
  /// In zh, this message translates to:
  /// **'成本'**
  String get tokenDetailCost;

  /// No description provided for @tokenDetailUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'—'**
  String get tokenDetailUnavailable;

  /// No description provided for @tokenDetailNoPrice.
  ///
  /// In zh, this message translates to:
  /// **'价格未收录'**
  String get tokenDetailNoPrice;

  /// No description provided for @tokenDetailHint.
  ///
  /// In zh, this message translates to:
  /// **'本地估算为回复正文的 tiktoken 精确计数（不含提示词）。'**
  String get tokenDetailHint;

  /// No description provided for @quickPhrasesTitle.
  ///
  /// In zh, this message translates to:
  /// **'快捷短语'**
  String get quickPhrasesTitle;

  /// No description provided for @quickPhrasesAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增短语'**
  String get quickPhrasesAdd;

  /// No description provided for @quickPhrasesEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑短语'**
  String get quickPhrasesEdit;

  /// No description provided for @quickPhrasesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有快捷短语，点击右下角新增'**
  String get quickPhrasesEmpty;

  /// No description provided for @quickPhrasesContent.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get quickPhrasesContent;

  /// No description provided for @quickPhrasesGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局可用（所有会话）'**
  String get quickPhrasesGlobal;

  /// No description provided for @settingsQuickPhrasesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'输入框输入 / 快速插入'**
  String get settingsQuickPhrasesSubtitle;

  /// No description provided for @quickPhrasesDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除快捷短语'**
  String get quickPhrasesDeleteTitle;

  /// No description provided for @quickPhrasesDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'将删除「{title}」。确定继续吗？'**
  String quickPhrasesDeleteBody(String title);

  /// No description provided for @quickPhrasesDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get quickPhrasesDeleted;

  /// No description provided for @iiTitle.
  ///
  /// In zh, this message translates to:
  /// **'指令注入'**
  String get iiTitle;

  /// No description provided for @iiAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增指令'**
  String get iiAdd;

  /// No description provided for @iiEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑指令'**
  String get iiEdit;

  /// No description provided for @iiEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有指令，点击右下角新增（勾选即激活）'**
  String get iiEmpty;

  /// No description provided for @iiPrompt.
  ///
  /// In zh, this message translates to:
  /// **'指令内容'**
  String get iiPrompt;

  /// No description provided for @iiGroup.
  ///
  /// In zh, this message translates to:
  /// **'分组（可选）'**
  String get iiGroup;

  /// No description provided for @iiDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除指令'**
  String get iiDeleteTitle;

  /// No description provided for @iiDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'将删除「{title}」。确定继续吗？'**
  String iiDeleteBody(String title);

  /// No description provided for @settingsIiSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义提示词片段，随请求注入'**
  String get settingsIiSubtitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get updateAvailableTitle;

  /// No description provided for @updateVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get updateVersion;

  /// No description provided for @updateDownload.
  ///
  /// In zh, this message translates to:
  /// **'前往下载'**
  String get updateDownload;

  /// No description provided for @settingsUpdateCheck.
  ///
  /// In zh, this message translates to:
  /// **'启动时检查更新'**
  String get settingsUpdateCheck;

  /// No description provided for @settingsUpdateSource.
  ///
  /// In zh, this message translates to:
  /// **'更新源（GitHub Releases URL）'**
  String get settingsUpdateSource;

  /// No description provided for @devCrashReporting.
  ///
  /// In zh, this message translates to:
  /// **'崩溃上报（Sentry）'**
  String get devCrashReporting;

  /// No description provided for @devCrashReportingHint.
  ///
  /// In zh, this message translates to:
  /// **'启用后异常自动上报（需构建时配置 SENTRY_DSN）；默认关闭'**
  String get devCrashReportingHint;

  /// No description provided for @wfTitle.
  ///
  /// In zh, this message translates to:
  /// **'自动化工作流'**
  String get wfTitle;

  /// No description provided for @wfAdd.
  ///
  /// In zh, this message translates to:
  /// **'新建工作流'**
  String get wfAdd;

  /// No description provided for @wfEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑工作流'**
  String get wfEdit;

  /// No description provided for @wfName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get wfName;

  /// No description provided for @wfActionText.
  ///
  /// In zh, this message translates to:
  /// **'动作（当前仅 send_message 文本；支持 cur_date 变量）'**
  String get wfActionText;

  /// No description provided for @wfDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除工作流'**
  String get wfDeleteTitle;

  /// No description provided for @wfDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'将删除「{name}」。确定继续吗？'**
  String wfDeleteBody(String name);

  /// No description provided for @wfRunSuccess.
  ///
  /// In zh, this message translates to:
  /// **'工作流执行完成'**
  String get wfRunSuccess;

  /// No description provided for @wfRunFailed.
  ///
  /// In zh, this message translates to:
  /// **'工作流执行失败，见运行历史'**
  String get wfRunFailed;

  /// No description provided for @wfEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有工作流，点击右下角新建'**
  String get wfEmpty;

  /// No description provided for @wfListTitle.
  ///
  /// In zh, this message translates to:
  /// **'工作流'**
  String get wfListTitle;

  /// No description provided for @wfRun.
  ///
  /// In zh, this message translates to:
  /// **'试运行'**
  String get wfRun;

  /// No description provided for @wfHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'运行历史'**
  String get wfHistoryTitle;

  /// No description provided for @routerTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型路由'**
  String get routerTitle;

  /// No description provided for @routerEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用智能模型路由'**
  String get routerEnable;

  /// No description provided for @routerEnableHint.
  ///
  /// In zh, this message translates to:
  /// **'标题/摘要等任务自动按成本与速度选模型（优先低成本）'**
  String get routerEnableHint;

  /// No description provided for @routerNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无路由记录——启用后运行任务会在这里展示统计'**
  String get routerNoData;

  /// No description provided for @routerRecentStats.
  ///
  /// In zh, this message translates to:
  /// **'最近 30 天路由统计'**
  String get routerRecentStats;

  /// No description provided for @settingsRouterSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'按成本与速度自动选模型'**
  String get settingsRouterSubtitle;

  /// No description provided for @syncIncrementalTitle.
  ///
  /// In zh, this message translates to:
  /// **'多设备增量同步'**
  String get syncIncrementalTitle;

  /// No description provided for @syncIncrementalHint.
  ///
  /// In zh, this message translates to:
  /// **'推送本地变更并拉取其他设备的变更'**
  String get syncIncrementalHint;

  /// No description provided for @syncIncrementalNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get syncIncrementalNow;

  /// No description provided for @syncIncrementalDone.
  ///
  /// In zh, this message translates to:
  /// **'已推送 {pushed} 条、拉取 {pulled} 条变更'**
  String syncIncrementalDone(int pushed, int pulled);

  /// No description provided for @syncLastAt.
  ///
  /// In zh, this message translates to:
  /// **'上次同步：{at}'**
  String syncLastAt(String at);

  /// No description provided for @syncConflicts.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个冲突待处理（本地较新的变更已保留）'**
  String syncConflicts(int n);

  /// No description provided for @privacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'隐私与离线'**
  String get privacyTitle;

  /// No description provided for @offlineMode.
  ///
  /// In zh, this message translates to:
  /// **'离线模式'**
  String get offlineMode;

  /// No description provided for @offlineModeHint.
  ///
  /// In zh, this message translates to:
  /// **'嵌入走本地、不发起网络请求；适合飞行模式或隐私场景'**
  String get offlineModeHint;

  /// No description provided for @offlineCapabilities.
  ///
  /// In zh, this message translates to:
  /// **'能力离线状态'**
  String get offlineCapabilities;

  /// No description provided for @offlineCapEmbedding.
  ///
  /// In zh, this message translates to:
  /// **'文本嵌入'**
  String get offlineCapEmbedding;

  /// No description provided for @offlineCapKbSearch.
  ///
  /// In zh, this message translates to:
  /// **'知识库检索'**
  String get offlineCapKbSearch;

  /// No description provided for @offlineCapWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'网络搜索'**
  String get offlineCapWebSearch;

  /// No description provided for @offlineCapTts.
  ///
  /// In zh, this message translates to:
  /// **'语音朗读'**
  String get offlineCapTts;

  /// No description provided for @offlineCapAsr.
  ///
  /// In zh, this message translates to:
  /// **'语音输入（本地）'**
  String get offlineCapAsr;

  /// No description provided for @offlineStatusLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地可用'**
  String get offlineStatusLocal;

  /// No description provided for @offlineStatusCloud.
  ///
  /// In zh, this message translates to:
  /// **'云端'**
  String get offlineStatusCloud;

  /// No description provided for @offlineStatusOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get offlineStatusOff;

  /// No description provided for @offlineStatusSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get offlineStatusSystem;

  /// No description provided for @offlineStatusNeedsDownload.
  ///
  /// In zh, this message translates to:
  /// **'需下载模型'**
  String get offlineStatusNeedsDownload;

  /// No description provided for @offlineNote.
  ///
  /// In zh, this message translates to:
  /// **'本地嵌入为确定性哈希向量（384 维），完全离线；接入 ONNX 语义模型后自动升级。语音输入本地模型见语音设置。'**
  String get offlineNote;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'离线模式与本地能力'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsWfSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'定时 / 事件触发自动执行动作'**
  String get settingsWfSubtitle;

  /// No description provided for @chatDocument.
  ///
  /// In zh, this message translates to:
  /// **'文档'**
  String get chatDocument;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文档解析失败'**
  String chatDocumentFailed(int count);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 字'**
  String chatDocumentSubtitle(int count);

  /// No description provided for @chatDocumentTitle.
  ///
  /// In zh, this message translates to:
  /// **'文本文档'**
  String get chatDocumentTitle;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除该消息及其后的所有消息？'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatEffortAuto.
  ///
  /// In zh, this message translates to:
  /// **'思考：自动'**
  String get chatEffortAuto;

  /// No description provided for @chatEffortAutoShort.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get chatEffortAutoShort;

  /// No description provided for @chatEffortHigh.
  ///
  /// In zh, this message translates to:
  /// **'思考：高'**
  String get chatEffortHigh;

  /// No description provided for @chatEffortHighShort.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get chatEffortHighShort;

  /// No description provided for @chatEffortLow.
  ///
  /// In zh, this message translates to:
  /// **'思考：低'**
  String get chatEffortLow;

  /// No description provided for @chatEffortLowShort.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get chatEffortLowShort;

  /// No description provided for @chatEffortMedium.
  ///
  /// In zh, this message translates to:
  /// **'思考：中'**
  String get chatEffortMedium;

  /// No description provided for @chatEffortMediumShort.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get chatEffortMediumShort;

  /// No description provided for @chatErrorEmpty.
  ///
  /// In zh, this message translates to:
  /// **'接口没有返回任何内容，请重试'**
  String get chatErrorEmpty;

  /// No description provided for @chatErrorInvalidFormat.
  ///
  /// In zh, this message translates to:
  /// **'接口返回格式无法解析'**
  String get chatErrorInvalidFormat;

  /// No description provided for @chatErrorMissingContent.
  ///
  /// In zh, this message translates to:
  /// **'接口返回中缺少回复内容'**
  String get chatErrorMissingContent;

  /// No description provided for @chatErrorStream.
  ///
  /// In zh, this message translates to:
  /// **'读取响应流失败'**
  String get chatErrorStream;

  /// No description provided for @chatExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get chatExport;

  /// No description provided for @chatExportHtml.
  ///
  /// In zh, this message translates to:
  /// **'导出为 HTML'**
  String get chatExportHtml;

  /// No description provided for @chatExportJson.
  ///
  /// In zh, this message translates to:
  /// **'导出为 JSON'**
  String get chatExportJson;

  /// No description provided for @chatExportMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'导出为 Markdown'**
  String get chatExportMarkdown;

  /// No description provided for @chatExportPdf.
  ///
  /// In zh, this message translates to:
  /// **'导出为 PDF'**
  String get chatExportPdf;

  /// No description provided for @chatGenerating.
  ///
  /// In zh, this message translates to:
  /// **'正在生成…'**
  String get chatGenerating;

  /// No description provided for @chatGenerationFailed.
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get chatGenerationFailed;

  /// No description provided for @chatHelloSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'支持多服务商、多模型，开启一段新的对话吧'**
  String get chatHelloSubtitle;

  /// No description provided for @chatHelloTitle.
  ///
  /// In zh, this message translates to:
  /// **'你好，我是 Nona'**
  String get chatHelloTitle;

  /// No description provided for @chatImage.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get chatImage;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败：{uri}'**
  String chatImageLoadFailed(Object uri);

  /// No description provided for @chatInputHintEnterNewline.
  ///
  /// In zh, this message translates to:
  /// **'输入消息，Enter 换行，Ctrl+Enter 发送'**
  String get chatInputHintEnterNewline;

  /// No description provided for @chatInputHintEnterSend.
  ///
  /// In zh, this message translates to:
  /// **'输入消息，Enter 发送，Shift+Enter 换行'**
  String get chatInputHintEnterSend;

  /// No description provided for @chatMermaidUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'Mermaid 语法暂不支持，以下为源码'**
  String get chatMermaidUnsupported;

  /// No description provided for @chatNewSession.
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get chatNewSession;

  /// No description provided for @chatNoModel.
  ///
  /// In zh, this message translates to:
  /// **'未配置模型'**
  String get chatNoModel;

  /// No description provided for @chatNoProvider.
  ///
  /// In zh, this message translates to:
  /// **'未配置服务商'**
  String get chatNoProvider;

  /// No description provided for @chatOverLimit.
  ///
  /// In zh, this message translates to:
  /// **'超出上限，发送时将裁剪'**
  String get chatOverLimit;

  /// No description provided for @chatRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get chatRegenerate;

  /// No description provided for @chatRollback.
  ///
  /// In zh, this message translates to:
  /// **'回滚到此处'**
  String get chatRollback;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'回退到上一版（共 {count} 版）'**
  String chatRollbackVersion(int count);

  /// No description provided for @chatSelectModel.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get chatSelectModel;

  /// No description provided for @chatSessionContext.
  ///
  /// In zh, this message translates to:
  /// **'会话上下文'**
  String get chatSessionContext;

  /// No description provided for @chatSessionCopySuffix.
  ///
  /// In zh, this message translates to:
  /// **'（副本）'**
  String get chatSessionCopySuffix;

  /// No description provided for @chatSessionList.
  ///
  /// In zh, this message translates to:
  /// **'会话列表'**
  String get chatSessionList;

  /// No description provided for @assistantDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'Nona'**
  String get assistantDisplayName;

  /// No description provided for @citationSourcesTitle.
  ///
  /// In zh, this message translates to:
  /// **'引用来源'**
  String get citationSourcesTitle;

  /// No description provided for @chatSelectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 条'**
  String chatSelectionTitle(int count);

  /// No description provided for @chatSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get chatSelectAll;

  /// No description provided for @chatEnterSelection.
  ///
  /// In zh, this message translates to:
  /// **'选择消息'**
  String get chatEnterSelection;

  /// No description provided for @dropBackupUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'拖入的备份文件暂不支持恢复'**
  String get dropBackupUnsupported;

  /// No description provided for @dropUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持的文件类型'**
  String get dropUnsupported;

  /// No description provided for @dropFailed.
  ///
  /// In zh, this message translates to:
  /// **'文件处理失败'**
  String get dropFailed;

  /// No description provided for @dropImageTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片超过 8MB，已跳过'**
  String get dropImageTooLarge;

  /// No description provided for @dropExtractFailed.
  ///
  /// In zh, this message translates to:
  /// **'文档内容提取失败'**
  String get dropExtractFailed;

  /// No description provided for @dropRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份'**
  String get dropRestoreTitle;

  /// No description provided for @dropRestoreBody.
  ///
  /// In zh, this message translates to:
  /// **'将把 {file} 中的会话合并导入当前数据（跳过重复）。确定继续吗？'**
  String dropRestoreBody(String file);

  /// No description provided for @dropRestoreConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get dropRestoreConfirm;

  /// No description provided for @dropRestoreDone.
  ///
  /// In zh, this message translates to:
  /// **'已恢复 {count} 个会话'**
  String dropRestoreDone(int count);

  /// No description provided for @chatInvertSelection.
  ///
  /// In zh, this message translates to:
  /// **'反选'**
  String get chatInvertSelection;

  /// No description provided for @chatDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选（{count}）'**
  String chatDeleteSelected(int count);

  /// No description provided for @importSelectSessions.
  ///
  /// In zh, this message translates to:
  /// **'选择要导入的会话'**
  String get importSelectSessions;

  /// No description provided for @importToggleAll.
  ///
  /// In zh, this message translates to:
  /// **'全选/全不选'**
  String get importToggleAll;

  /// 消息头服务商与模型标注
  ///
  /// In zh, this message translates to:
  /// **'（{provider} · {model}）'**
  String messageProviderBadge(String provider, String model);

  /// No description provided for @chatSessionNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get chatSessionNewTitle;

  /// 注入 Agent 长期记忆的提示词模板
  ///
  /// In zh, this message translates to:
  /// **'以下是关于用户与该助手的长期记忆，请参考这些信息作答：\n{content}'**
  String orchestratorMemoryPrompt(String content);

  /// 注入知识库检索结果的提示词模板
  ///
  /// In zh, this message translates to:
  /// **'以下是知识库中的相关内容，回答时请优先参考：\n{content}'**
  String orchestratorKbPrompt(String content);

  /// 网络搜索失败时的引导文案
  ///
  /// In zh, this message translates to:
  /// **'网络搜索失败：免费引擎在部分环境不可用，请在设置中改用 Tavily / Bocha（需 API Key）或自建 SearXNG 服务器'**
  String get orchestratorSearchFailed;

  /// 工具审批对话框标题
  ///
  /// In zh, this message translates to:
  /// **'是否允许模型调用工具「{toolName}」？'**
  String toolApprovalTitle(String toolName);

  /// 工具审批「允许本次」
  ///
  /// In zh, this message translates to:
  /// **'允许本次'**
  String get toolApprovalAllowOnce;

  /// 工具审批「记住并允许」
  ///
  /// In zh, this message translates to:
  /// **'记住并允许'**
  String get toolApprovalAllowRemember;

  /// 工具审批「拒绝」
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get toolApprovalDeny;

  /// 工具审批风险提示
  ///
  /// In zh, this message translates to:
  /// **'该工具来自外部服务器，可读取或修改你的数据，请确认参数后决定。'**
  String get toolApprovalRiskHint;

  /// 工具审批来源服务
  ///
  /// In zh, this message translates to:
  /// **'来源：{serverName}'**
  String toolApprovalServer(String serverName);

  /// 工具审批参数标题
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get toolApprovalArguments;

  /// 工具审批对话框标题（已记住工具自动放行提示）
  ///
  /// In zh, this message translates to:
  /// **'已记住该工具的授权，后续调用将自动放行（可在 MCP 设置中撤销）。'**
  String get toolApprovalAutoHint;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'查看全文（{count} 字）'**
  String chatShowFull(int count);

  /// No description provided for @chatSpeak.
  ///
  /// In zh, this message translates to:
  /// **'朗读'**
  String get chatSpeak;

  /// No description provided for @chatStopSpeaking.
  ///
  /// In zh, this message translates to:
  /// **'停止朗读'**
  String get chatStopSpeaking;

  /// No description provided for @chatStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止生成'**
  String get chatStopped;

  /// No description provided for @chatStream.
  ///
  /// In zh, this message translates to:
  /// **'流式'**
  String get chatStream;

  /// No description provided for @chatThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get chatThinking;

  /// No description provided for @chatTokensDown.
  ///
  /// In zh, this message translates to:
  /// **'下行 Token（累计生成）'**
  String get chatTokensDown;

  /// No description provided for @chatTokensUp.
  ///
  /// In zh, this message translates to:
  /// **'上行 Token（累计发送）'**
  String get chatTokensUp;

  /// No description provided for @commonAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonDiscard.
  ///
  /// In zh, this message translates to:
  /// **'仍要返回'**
  String get commonDiscard;

  /// No description provided for @commonWarning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get commonWarning;

  /// No description provided for @commonClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get commonClear;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// No description provided for @commonCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get commonCopied;

  /// No description provided for @commonCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commonCopy;

  /// No description provided for @commonDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get commonDefault;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get commonDeleted;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get commonFailed;

  /// No description provided for @commonFailedTest.
  ///
  /// In zh, this message translates to:
  /// **'测试失败'**
  String get commonFailedTest;

  /// No description provided for @commonImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get commonImport;

  /// No description provided for @commonMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get commonMe;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get commonNone;

  /// No description provided for @commonNotSpecified.
  ///
  /// In zh, this message translates to:
  /// **'不指定'**
  String get commonNotSpecified;

  /// No description provided for @commonNotTested.
  ///
  /// In zh, this message translates to:
  /// **'未测试'**
  String get commonNotTested;

  /// No description provided for @commonOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get commonOff;

  /// No description provided for @commonRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get commonRefresh;

  /// No description provided for @commonRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get commonRemove;

  /// No description provided for @commonReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get commonReset;

  /// No description provided for @commonRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get commonRestore;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @loadFailedBanner.
  ///
  /// In zh, this message translates to:
  /// **'数据加载失败，已尝试恢复'**
  String get loadFailedBanner;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get commonSend;

  /// No description provided for @commonSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试'**
  String get commonSaveFailed;

  /// No description provided for @commonSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get commonSaved;

  /// No description provided for @commonStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get commonStop;

  /// No description provided for @commonUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get commonUnknownError;

  /// No description provided for @commonUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'不限制'**
  String get commonUnlimited;

  /// No description provided for @commonUntested.
  ///
  /// In zh, this message translates to:
  /// **'尚未测试'**
  String get commonUntested;

  /// No description provided for @compareEmpty.
  ///
  /// In zh, this message translates to:
  /// **'选择至少一个模型并输入问题'**
  String get compareEmpty;

  /// No description provided for @compareFailed.
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get compareFailed;

  /// No description provided for @compareHint.
  ///
  /// In zh, this message translates to:
  /// **'输入问题，选择多个模型后开始对比…'**
  String get compareHint;

  /// No description provided for @compareRunning.
  ///
  /// In zh, this message translates to:
  /// **'对比中…'**
  String get compareRunning;

  /// No description provided for @compareStart.
  ///
  /// In zh, this message translates to:
  /// **'开始对比'**
  String get compareStart;

  /// No description provided for @compareTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型对比'**
  String get compareTitle;

  /// No description provided for @compareWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待响应…'**
  String get compareWaiting;

  /// No description provided for @contextAutoTrim.
  ///
  /// In zh, this message translates to:
  /// **'自动裁剪早期消息'**
  String get contextAutoTrim;

  /// No description provided for @contextAutoTrimHint.
  ///
  /// In zh, this message translates to:
  /// **'超出上限时自动移除最早的对话记录'**
  String get contextAutoTrimHint;

  /// No description provided for @contextCommaSeparated.
  ///
  /// In zh, this message translates to:
  /// **'多个用英文逗号分隔'**
  String get contextCommaSeparated;

  /// No description provided for @contextCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义（手动配置）'**
  String get contextCustom;

  /// No description provided for @contextFrequencyPenalty.
  ///
  /// In zh, this message translates to:
  /// **'Frequency Penalty 频率惩罚'**
  String get contextFrequencyPenalty;

  /// No description provided for @contextFrequencyPenaltyTip.
  ///
  /// In zh, this message translates to:
  /// **'对 token 在文本中出现频率施加惩罚，取值范围 -2~2。\\n\\n值越大，越能抑制整段重复与套话。'**
  String get contextFrequencyPenaltyTip;

  /// No description provided for @contextInfoGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get contextInfoGotIt;

  /// No description provided for @contextInfoTitle.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get contextInfoTitle;

  /// No description provided for @contextMaxContext.
  ///
  /// In zh, this message translates to:
  /// **'上下文窗口管理'**
  String get contextMaxContext;

  /// No description provided for @contextMaxContextHint.
  ///
  /// In zh, this message translates to:
  /// **'≤32000，留空表示不限制'**
  String get contextMaxContextHint;

  /// No description provided for @contextMaxContextTip.
  ///
  /// In zh, this message translates to:
  /// **'控制发送给模型的对话历史长度：\\n\\n· 最大上下文：超出该 token 数时按策略处理，留空表示不限制\\n· 自动裁剪：发送前估算对话长度，超限时自动移除最早的消息\\n\\n可避免长对话超出发送方的上下文窗口上限，节省费用并防止报错。'**
  String get contextMaxContextTip;

  /// No description provided for @contextMaxTokens.
  ///
  /// In zh, this message translates to:
  /// **'Max Tokens 最大输出长度'**
  String get contextMaxTokens;

  /// No description provided for @contextMaxTokensHint.
  ///
  /// In zh, this message translates to:
  /// **'留空由服务端决定'**
  String get contextMaxTokensHint;

  /// No description provided for @contextMaxTokensTip.
  ///
  /// In zh, this message translates to:
  /// **'单次回复最多生成的 token 数，超出部分会被截断。\\n\\n留空表示由服务端按模型上限决定。'**
  String get contextMaxTokensTip;

  /// No description provided for @contextN.
  ///
  /// In zh, this message translates to:
  /// **'N 候选数量'**
  String get contextN;

  /// No description provided for @contextNHint.
  ///
  /// In zh, this message translates to:
  /// **'留空使用默认值 1'**
  String get contextNHint;

  /// No description provided for @contextNTip.
  ///
  /// In zh, this message translates to:
  /// **'一次请求生成几条候选回复，默认 1。\\n\\n大于 1 时接口会返回多条，由你自行选择使用哪一条，会增加 token 消耗。'**
  String get contextNTip;

  /// No description provided for @contextNoAgent.
  ///
  /// In zh, this message translates to:
  /// **'还没有 Agent，可到「设置 → Agent 配置」中创建预设，方便快速套用。'**
  String get contextNoAgent;

  /// No description provided for @contextPresencePenalty.
  ///
  /// In zh, this message translates to:
  /// **'Presence Penalty 话题新鲜度惩罚'**
  String get contextPresencePenalty;

  /// No description provided for @contextPresencePenaltyTip.
  ///
  /// In zh, this message translates to:
  /// **'对已出现过的 token 施加惩罚，取值范围 -2~2。\\n\\n值越大，越鼓励模型讨论新话题、避免简单重复已有内容。'**
  String get contextPresencePenaltyTip;

  /// No description provided for @contextQuickConfig.
  ///
  /// In zh, this message translates to:
  /// **'快捷配置'**
  String get contextQuickConfig;

  /// No description provided for @contextResponseFormat.
  ///
  /// In zh, this message translates to:
  /// **'Response Format 响应格式'**
  String get contextResponseFormat;

  /// No description provided for @contextResponseFormatJson.
  ///
  /// In zh, this message translates to:
  /// **'JSON (json_object)'**
  String get contextResponseFormatJson;

  /// No description provided for @contextResponseFormatJsonShort.
  ///
  /// In zh, this message translates to:
  /// **'JSON'**
  String get contextResponseFormatJsonShort;

  /// No description provided for @contextResponseFormatText.
  ///
  /// In zh, this message translates to:
  /// **'文本 (text)'**
  String get contextResponseFormatText;

  /// No description provided for @contextResponseFormatTextShort.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get contextResponseFormatTextShort;

  /// No description provided for @contextResponseFormatTip.
  ///
  /// In zh, this message translates to:
  /// **'期望模型输出的格式：\\n\\n· 不指定：默认文本\\n· 文本 (text)：普通文本\\n· JSON (json_object)：模型只输出合法 JSON，方便程序解析\\n\\n部分模型不支持 JSON 模式，请以服务商文档为准。'**
  String get contextResponseFormatTip;

  /// No description provided for @contextSavedNote.
  ///
  /// In zh, this message translates to:
  /// **'参数随会话保存，仅对当前会话生效。'**
  String get contextSavedNote;

  /// No description provided for @contextSeed.
  ///
  /// In zh, this message translates to:
  /// **'Seed 随机种子'**
  String get contextSeed;

  /// No description provided for @contextSeedHint.
  ///
  /// In zh, this message translates to:
  /// **'留空表示随机'**
  String get contextSeedHint;

  /// No description provided for @contextSeedTip.
  ///
  /// In zh, this message translates to:
  /// **'设置随机种子后，相同种子与相同输入在多数服务端可复现出相似的结果，方便调试与对比。\\n\\n留空表示随机。'**
  String get contextSeedTip;

  /// No description provided for @contextStop.
  ///
  /// In zh, this message translates to:
  /// **'Stop 停止序列'**
  String get contextStop;

  /// No description provided for @contextStopTip.
  ///
  /// In zh, this message translates to:
  /// **'模型生成到该字符串时会立即停止输出。\\n\\n多个序列用英文逗号分隔，例如：\\n\\n,。！？\\n\\n留空表示不使用停止序列。'**
  String get contextStopTip;

  /// No description provided for @contextSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示词'**
  String get contextSystemPrompt;

  /// No description provided for @contextSystemPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'可选，设定助手的角色与行为'**
  String get contextSystemPromptHint;

  /// No description provided for @contextSystemPromptTip.
  ///
  /// In zh, this message translates to:
  /// **'设定助手的角色、风格与行为准则，会作为 system 消息放在对话最前面，影响整个会话的回复基调。'**
  String get contextSystemPromptTip;

  /// No description provided for @contextTemperature.
  ///
  /// In zh, this message translates to:
  /// **'Temperature 采样温度'**
  String get contextTemperature;

  /// No description provided for @contextTemperatureHint.
  ///
  /// In zh, this message translates to:
  /// **'留空使用默认值 1'**
  String get contextTemperatureHint;

  /// No description provided for @contextTemperatureTip.
  ///
  /// In zh, this message translates to:
  /// **'控制输出的随机程度，取值范围 0~2。\\n\\n值越高，输出越发散、更有创造力；值越低，输出越稳定、保守、可预测。需要稳定的回答建议调低。'**
  String get contextTemperatureTip;

  /// No description provided for @contextTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话上下文'**
  String get contextTitle;

  /// No description provided for @contextTopP.
  ///
  /// In zh, this message translates to:
  /// **'Top P 核采样'**
  String get contextTopP;

  /// No description provided for @contextTopPHint.
  ///
  /// In zh, this message translates to:
  /// **'留空使用默认值 1'**
  String get contextTopPHint;

  /// No description provided for @contextTopPTip.
  ///
  /// In zh, this message translates to:
  /// **'只从累计概率达到该值的 token 集合中采样，取值范围 0~1。\\n\\n与 Temperature 二选一调整即可，一般不建议同时大幅调整两者。'**
  String get contextTopPTip;

  /// No description provided for @devAutoUpdate.
  ///
  /// In zh, this message translates to:
  /// **'启动时自动更新'**
  String get devAutoUpdate;

  /// No description provided for @devAutoUpdateHint.
  ///
  /// In zh, this message translates to:
  /// **'应用启动时静默从网络更新映射表，失败不影响使用'**
  String get devAutoUpdateHint;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'内置版本 {version}'**
  String devBuiltinVersion(String version);

  /// No description provided for @devCapabilityDesc.
  ///
  /// In zh, this message translates to:
  /// **'内置静态表（离线兜底）+ 联网更新缓存，用于按模型 id 自动填充「多模态 / 推理」配置'**
  String get devCapabilityDesc;

  /// No description provided for @devCapabilitySection.
  ///
  /// In zh, this message translates to:
  /// **'模型能力映射表'**
  String get devCapabilitySection;

  /// No description provided for @devCapabilityTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型能力映射表'**
  String get devCapabilityTitle;

  /// No description provided for @devConnectivitySection.
  ///
  /// In zh, this message translates to:
  /// **'连通性设置'**
  String get devConnectivitySection;

  /// No description provided for @devMaxLogs.
  ///
  /// In zh, this message translates to:
  /// **'最大保留条数'**
  String get devMaxLogs;

  /// No description provided for @devMaxLogsExample.
  ///
  /// In zh, this message translates to:
  /// **'例如：1000'**
  String get devMaxLogsExample;

  /// No description provided for @devMaxLogsInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入非负整数'**
  String get devMaxLogsInvalid;

  /// No description provided for @devMaxLogsLabel.
  ///
  /// In zh, this message translates to:
  /// **'条数（留空为无限）'**
  String get devMaxLogsLabel;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'最多保留 {count} 条（0 为不限）'**
  String devMaxLogsSubtitle(int count);

  /// No description provided for @devMaxLogsTitle.
  ///
  /// In zh, this message translates to:
  /// **'最大保留条数'**
  String get devMaxLogsTitle;

  /// No description provided for @devMaxLogsUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'无限，全部记录保留'**
  String get devMaxLogsUnlimited;

  /// No description provided for @devNetworkLog.
  ///
  /// In zh, this message translates to:
  /// **'网络日志'**
  String get devNetworkLog;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已记录 {count} 条'**
  String devNetworkLogCount(int count);

  /// No description provided for @devNetworkLogDisabled.
  ///
  /// In zh, this message translates to:
  /// **'未启用记录，开启后自动捕获请求'**
  String get devNetworkLogDisabled;

  /// No description provided for @devNetworkLogEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用网络日志'**
  String get devNetworkLogEnable;

  /// No description provided for @devNetworkLogEnableHint.
  ///
  /// In zh, this message translates to:
  /// **'记录应用内全部网络请求（含聊天、测速、拉取模型等）'**
  String get devNetworkLogEnableHint;

  /// No description provided for @devNetworkLogSection.
  ///
  /// In zh, this message translates to:
  /// **'网络日志'**
  String get devNetworkLogSection;

  /// No description provided for @devNoBuiltinTable.
  ///
  /// In zh, this message translates to:
  /// **'无内置映射表'**
  String get devNoBuiltinTable;

  /// No description provided for @devTestPrompt.
  ///
  /// In zh, this message translates to:
  /// **'连通性测试提示词'**
  String get devTestPrompt;

  /// No description provided for @devTestPromptExample.
  ///
  /// In zh, this message translates to:
  /// **'例如：ping'**
  String get devTestPromptExample;

  /// No description provided for @devTestPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'模型连通性测试时发送给模型的最小请求内容'**
  String get devTestPromptHint;

  /// No description provided for @devTitle.
  ///
  /// In zh, this message translates to:
  /// **'开发者选项'**
  String get devTitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'更新失败：{error}'**
  String devUpdateFailed(Object error);

  /// No description provided for @devUpdateFromNetwork.
  ///
  /// In zh, this message translates to:
  /// **'从网络更新'**
  String get devUpdateFromNetwork;

  /// No description provided for @devUpdated.
  ///
  /// In zh, this message translates to:
  /// **'模型能力表更新完成'**
  String get devUpdated;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'更新时间 {time}'**
  String devUpdatedAt(String time);

  /// No description provided for @devUpdating.
  ///
  /// In zh, this message translates to:
  /// **'正在更新…'**
  String get devUpdating;

  /// No description provided for @devUpdatingShort.
  ///
  /// In zh, this message translates to:
  /// **'更新中'**
  String get devUpdatingShort;

  /// No description provided for @devWarning.
  ///
  /// In zh, this message translates to:
  /// **'开发者选项包含高风险设置，仅建议高级用户使用，请谨慎修改。'**
  String get devWarning;

  /// No description provided for @homeAnonymousSession.
  ///
  /// In zh, this message translates to:
  /// **'匿名会话'**
  String get homeAnonymousSession;

  /// No description provided for @homeCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get homeCopied;

  /// No description provided for @homeCopiedMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'已复制为 Markdown'**
  String get homeCopiedMarkdown;

  /// No description provided for @homeCopiedSession.
  ///
  /// In zh, this message translates to:
  /// **'已复制会话'**
  String get homeCopiedSession;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'确定删除会话「{title}」？'**
  String homeDeleteSessionConfirm(String title);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已导出到 {path}'**
  String homeExportedTo(String path);

  /// No description provided for @homeImageTooLargeSkippedAll.
  ///
  /// In zh, this message translates to:
  /// **'图片超过 8MB，已跳过'**
  String get homeImageTooLargeSkippedAll;

  /// No description provided for @homeImageTooLargeSkippedSome.
  ///
  /// In zh, this message translates to:
  /// **'部分图片超过 8MB，已跳过'**
  String get homeImageTooLargeSkippedSome;

  /// No description provided for @homeModelMismatch.
  ///
  /// In zh, this message translates to:
  /// **'当前服务商不包含该模型，请到设置中检查'**
  String get homeModelMismatch;

  /// No description provided for @homeNetworkError.
  ///
  /// In zh, this message translates to:
  /// **'网络请求失败，请检查网络或配置'**
  String get homeNetworkError;

  /// No description provided for @homeNoApiKey.
  ///
  /// In zh, this message translates to:
  /// **'请先完善服务商的 API Key'**
  String get homeNoApiKey;

  /// No description provided for @homeNoModel.
  ///
  /// In zh, this message translates to:
  /// **'请先选择模型'**
  String get homeNoModel;

  /// No description provided for @homeNoProvider.
  ///
  /// In zh, this message translates to:
  /// **'请先在设置中配置服务商'**
  String get homeNoProvider;

  /// No description provided for @homeRenameSession.
  ///
  /// In zh, this message translates to:
  /// **'重命名会话'**
  String get homeRenameSession;

  /// No description provided for @homeRollbackConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定回滚'**
  String get homeRollbackConfirm;

  /// No description provided for @homeRollbackContent.
  ///
  /// In zh, this message translates to:
  /// **'将删除该消息及其之后的所有消息，并把内容回填到输入框，以便修改后重新发送。确定继续吗？'**
  String get homeRollbackContent;

  /// No description provided for @homeRollbackTitle.
  ///
  /// In zh, this message translates to:
  /// **'回滚到此处'**
  String get homeRollbackTitle;

  /// No description provided for @homeSessionNameHint.
  ///
  /// In zh, this message translates to:
  /// **'会话名称'**
  String get homeSessionNameHint;

  /// No description provided for @homeTitlePrompt.
  ///
  /// In zh, this message translates to:
  /// **'为用户的对话生成一个简洁的标题（不超过 20 个字，不要引号，不要解释，直接输出标题）'**
  String get homeTitlePrompt;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'上下文超限，已自动移除最早 {count} 条消息'**
  String homeTrimmed(int count);

  /// No description provided for @homeCompacted.
  ///
  /// In zh, this message translates to:
  /// **'上下文超限，已压缩最早 {count} 条消息为摘要（可点击消息列表顶部的压缩条查看）'**
  String homeCompacted(Object count);

  /// No description provided for @summaryCompressed.
  ///
  /// In zh, this message translates to:
  /// **'已压缩 {count} 条消息为摘要'**
  String summaryCompressed(Object count);

  /// No description provided for @summaryCompressedMessages.
  ///
  /// In zh, this message translates to:
  /// **'被压缩的原始消息（{count} 条）：'**
  String summaryCompressedMessages(Object count);

  /// No description provided for @summaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话摘要（注入到每次请求的上下文中）'**
  String get summaryTitle;

  /// No description provided for @summaryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'（摘要为空）'**
  String get summaryEmpty;

  /// No description provided for @summaryEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑摘要'**
  String get summaryEdit;

  /// No description provided for @summaryEditHint.
  ///
  /// In zh, this message translates to:
  /// **'修改后的摘要将替代被压缩消息注入后续请求'**
  String get summaryEditHint;

  /// No description provided for @summaryClear.
  ///
  /// In zh, this message translates to:
  /// **'清空压缩记录'**
  String get summaryClear;

  /// No description provided for @kbAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加文档'**
  String get kbAdd;

  /// No description provided for @kbAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'没有可添加的内容'**
  String get kbAddFailed;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已添加 {count} 个文档'**
  String kbAdded(int count);

  /// No description provided for @kbEmpty.
  ///
  /// In zh, this message translates to:
  /// **'知识库为空'**
  String get kbEmpty;

  /// No description provided for @kbEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 添加文本文件（txt/md/json 等）'**
  String get kbEmptyHint;

  /// No description provided for @kbHint.
  ///
  /// In zh, this message translates to:
  /// **'对话时会自动检索知识库中相关内容并注入上下文（Agent 可在编辑页绑定知识库）'**
  String get kbHint;

  /// No description provided for @kbCreateLibrary.
  ///
  /// In zh, this message translates to:
  /// **'新建知识库'**
  String get kbCreateLibrary;

  /// No description provided for @kbLibraryNameHint.
  ///
  /// In zh, this message translates to:
  /// **'知识库名称'**
  String get kbLibraryNameHint;

  /// No description provided for @kbRenameLibrary.
  ///
  /// In zh, this message translates to:
  /// **'重命名知识库'**
  String get kbRenameLibrary;

  /// No description provided for @kbDeleteLibrary.
  ///
  /// In zh, this message translates to:
  /// **'删除知识库'**
  String get kbDeleteLibrary;

  /// No description provided for @kbDeleteLibraryConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除知识库「{name}」将同时删除其中全部文档，是否继续？'**
  String kbDeleteLibraryConfirm(Object name);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'删除文档「{name}」？'**
  String kbDeleteConfirm(String name);

  /// No description provided for @kbTitle.
  ///
  /// In zh, this message translates to:
  /// **'知识库'**
  String get kbTitle;

  /// No description provided for @mcpAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加服务'**
  String get mcpAdd;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'删除服务「{name}」及其工具配置？'**
  String mcpDeleteConfirm(String name);

  /// No description provided for @mcpEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑服务'**
  String get mcpEdit;

  /// No description provided for @mcpEmpty.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置 MCP 服务'**
  String get mcpEmpty;

  /// No description provided for @mcpEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 添加（需支持 MCP 协议的服务器地址）'**
  String get mcpEmptyHint;

  /// No description provided for @mcpHeaders.
  ///
  /// In zh, this message translates to:
  /// **'请求头（每行一个，Key: Value）'**
  String get mcpHeaders;

  /// No description provided for @mcpHint.
  ///
  /// In zh, this message translates to:
  /// **'MCP（Model Context Protocol）让模型调用外部工具。支持的服务器：streamable HTTP / SSE。'**
  String get mcpHint;

  /// No description provided for @mcpName.
  ///
  /// In zh, this message translates to:
  /// **'服务名称'**
  String get mcpName;

  /// No description provided for @mcpFieldsRequired.
  ///
  /// In zh, this message translates to:
  /// **'名称和地址不能为空'**
  String get mcpFieldsRequired;

  /// No description provided for @mcpNeedsApproval.
  ///
  /// In zh, this message translates to:
  /// **'工具调用需人工确认'**
  String get mcpNeedsApproval;

  /// No description provided for @mcpNeedsApprovalHint.
  ///
  /// In zh, this message translates to:
  /// **'开启后执行工具前会弹出确认'**
  String get mcpNeedsApprovalHint;

  /// No description provided for @mcpTitle.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务'**
  String get mcpTitle;

  /// No description provided for @mcpUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务地址'**
  String get mcpUrl;

  /// No description provided for @messageEditAssistantHint.
  ///
  /// In zh, this message translates to:
  /// **'修改回复内容…'**
  String get messageEditAssistantHint;

  /// No description provided for @messageScrollToBottom.
  ///
  /// In zh, this message translates to:
  /// **'滚动到底部'**
  String get messageScrollToBottom;

  /// No description provided for @messageEditAssistantLabel.
  ///
  /// In zh, this message translates to:
  /// **'回复内容'**
  String get messageEditAssistantLabel;

  /// No description provided for @messageEditAssistantTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑助手回复'**
  String get messageEditAssistantTitle;

  /// No description provided for @messageEditNote.
  ///
  /// In zh, this message translates to:
  /// **'修改后将在后续对话中生效'**
  String get messageEditNote;

  /// No description provided for @messageEditReasoningHint.
  ///
  /// In zh, this message translates to:
  /// **'修改模型生成时的思考过程…'**
  String get messageEditReasoningHint;

  /// No description provided for @messageEditReasoningLabel.
  ///
  /// In zh, this message translates to:
  /// **'思考内容'**
  String get messageEditReasoningLabel;

  /// No description provided for @messageEditReasoningNote.
  ///
  /// In zh, this message translates to:
  /// **'思考内容与回复内容均可修改，修改后将用于后续对话上下文'**
  String get messageEditReasoningNote;

  /// No description provided for @messageEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑消息'**
  String get messageEditTitle;

  /// No description provided for @messageEditUserHint.
  ///
  /// In zh, this message translates to:
  /// **'修改消息内容…'**
  String get messageEditUserHint;

  /// No description provided for @messageEditUserLabel.
  ///
  /// In zh, this message translates to:
  /// **'消息内容'**
  String get messageEditUserLabel;

  /// No description provided for @modelConfigChatModel.
  ///
  /// In zh, this message translates to:
  /// **'聊天模型'**
  String get modelConfigChatModel;

  /// No description provided for @modelConfigChatModelDesc.
  ///
  /// In zh, this message translates to:
  /// **'每次新建会话时默认使用此模型。重置后新建会话需手动选择。'**
  String get modelConfigChatModelDesc;

  /// No description provided for @modelConfigNoModels.
  ///
  /// In zh, this message translates to:
  /// **'暂无已配置的模型，请先在服务商中添加'**
  String get modelConfigNoModels;

  /// No description provided for @modelConfigPickChat.
  ///
  /// In zh, this message translates to:
  /// **'选择聊天模型'**
  String get modelConfigPickChat;

  /// No description provided for @modelConfigPickTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择标题生成模型'**
  String get modelConfigPickTitle;

  /// No description provided for @modelConfigPickTranslator.
  ///
  /// In zh, this message translates to:
  /// **'选择翻译模型'**
  String get modelConfigPickTranslator;

  /// No description provided for @modelConfigResetChatContent.
  ///
  /// In zh, this message translates to:
  /// **'重置后，新建会话将不再自动选择模型，每次需手动选择。确定继续吗？'**
  String get modelConfigResetChatContent;

  /// No description provided for @modelConfigResetChatTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置聊天默认模型'**
  String get modelConfigResetChatTitle;

  /// No description provided for @modelConfigResetTitleContent.
  ///
  /// In zh, this message translates to:
  /// **'重置后，会话标题将维持「取首条消息」的默认逻辑。确定继续吗？'**
  String get modelConfigResetTitleContent;

  /// No description provided for @modelConfigResetTitleTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置标题生成模型'**
  String get modelConfigResetTitleTitle;

  /// No description provided for @modelConfigResetTranslatorContent.
  ///
  /// In zh, this message translates to:
  /// **'重置后，AI 翻译将使用聊天模型进行翻译。确定继续吗？'**
  String get modelConfigResetTranslatorContent;

  /// No description provided for @modelConfigResetTranslatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置翻译模型'**
  String get modelConfigResetTranslatorTitle;

  /// No description provided for @modelConfigSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get modelConfigSaved;

  /// No description provided for @modelConfigTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型配置'**
  String get modelConfigTitle;

  /// No description provided for @modelConfigTitleModel.
  ///
  /// In zh, this message translates to:
  /// **'标题生成模型'**
  String get modelConfigTitleModel;

  /// No description provided for @modelConfigTitleModelDesc.
  ///
  /// In zh, this message translates to:
  /// **'配置后，会话标题将由该模型根据首条消息自动生成；未配置则维持现有「截取首条消息」逻辑。'**
  String get modelConfigTitleModelDesc;

  /// No description provided for @modelConfigTranslatorModel.
  ///
  /// In zh, this message translates to:
  /// **'翻译模型'**
  String get modelConfigTranslatorModel;

  /// No description provided for @modelConfigTranslatorModelDesc.
  ///
  /// In zh, this message translates to:
  /// **'配置后，AI 翻译页将使用此模型；未配置则回退使用聊天模型。'**
  String get modelConfigTranslatorModelDesc;

  /// No description provided for @modelConfigUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get modelConfigUnset;

  /// No description provided for @networkLogBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get networkLogBasic;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{bytes} · {lines} 行'**
  String networkLogBodyMeta(String bytes, int lines);

  /// No description provided for @networkLogClear.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get networkLogClear;

  /// No description provided for @networkLogClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将删除全部已记录的网络日志，确定继续吗？'**
  String get networkLogClearConfirm;

  /// No description provided for @networkLogClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空网络日志'**
  String get networkLogClearTitle;

  /// No description provided for @networkLogCopiedFull.
  ///
  /// In zh, this message translates to:
  /// **'已复制全文'**
  String get networkLogCopiedFull;

  /// No description provided for @networkLogCopyFull.
  ///
  /// In zh, this message translates to:
  /// **'复制全文'**
  String get networkLogCopyFull;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条记录 · 最多保留 {max} 条'**
  String networkLogCountLimited(int count, int max);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条记录 · 无限保留'**
  String networkLogCountUnlimited(int count);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月{day}日'**
  String networkLogDateFull(int year, int month, int day);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日'**
  String networkLogDateToday(int month, int day);

  /// No description provided for @networkLogDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'日志详情'**
  String get networkLogDetailTitle;

  /// No description provided for @networkLogDuration.
  ///
  /// In zh, this message translates to:
  /// **'耗时'**
  String get networkLogDuration;

  /// No description provided for @networkLogEditorUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台暂不支持在外部编辑器中打开'**
  String get networkLogEditorUnsupported;

  /// No description provided for @networkLogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无网络日志'**
  String get networkLogEmpty;

  /// No description provided for @networkLogEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'回到开发者选项开启「启用网络日志」后自动记录'**
  String get networkLogEmptyHint;

  /// No description provided for @networkLogExport.
  ///
  /// In zh, this message translates to:
  /// **'导出日志'**
  String get networkLogExport;

  /// No description provided for @networkLogExported.
  ///
  /// In zh, this message translates to:
  /// **'日志已导出'**
  String get networkLogExported;

  /// No description provided for @networkLogExternalEditor.
  ///
  /// In zh, this message translates to:
  /// **'外部编辑器'**
  String get networkLogExternalEditor;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'请求失败：{error}'**
  String networkLogFailed(String error);

  /// No description provided for @networkLogFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get networkLogFilterAll;

  /// No description provided for @networkLogFilterFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get networkLogFilterFailed;

  /// No description provided for @networkLogFilterSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get networkLogFilterSuccess;

  /// No description provided for @networkLogFormatJson.
  ///
  /// In zh, this message translates to:
  /// **'格式化 JSON'**
  String get networkLogFormatJson;

  /// No description provided for @networkLogFormatted.
  ///
  /// In zh, this message translates to:
  /// **' · 已格式化'**
  String get networkLogFormatted;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{label}全文'**
  String networkLogFullTitle(String label);

  /// No description provided for @networkLogInvalidJson.
  ///
  /// In zh, this message translates to:
  /// **'内容不是有效的 JSON，无法格式化'**
  String get networkLogInvalidJson;

  /// No description provided for @networkLogMethod.
  ///
  /// In zh, this message translates to:
  /// **'方法'**
  String get networkLogMethod;

  /// No description provided for @networkLogRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求'**
  String get networkLogRequest;

  /// No description provided for @networkLogRequestBody.
  ///
  /// In zh, this message translates to:
  /// **'请求 Body'**
  String get networkLogRequestBody;

  /// No description provided for @networkLogRequestHeaders.
  ///
  /// In zh, this message translates to:
  /// **'请求 Headers'**
  String get networkLogRequestHeaders;

  /// No description provided for @networkLogRequestSize.
  ///
  /// In zh, this message translates to:
  /// **'请求大小'**
  String get networkLogRequestSize;

  /// No description provided for @networkLogResponse.
  ///
  /// In zh, this message translates to:
  /// **'响应'**
  String get networkLogResponse;

  /// No description provided for @networkLogResponseBody.
  ///
  /// In zh, this message translates to:
  /// **'响应 Body'**
  String get networkLogResponseBody;

  /// No description provided for @networkLogResponseHeaders.
  ///
  /// In zh, this message translates to:
  /// **'响应 Headers'**
  String get networkLogResponseHeaders;

  /// No description provided for @networkLogResponseSize.
  ///
  /// In zh, this message translates to:
  /// **'响应大小'**
  String get networkLogResponseSize;

  /// No description provided for @networkLogShowRaw.
  ///
  /// In zh, this message translates to:
  /// **'显示原文'**
  String get networkLogShowRaw;

  /// No description provided for @networkLogStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态码'**
  String get networkLogStatus;

  /// No description provided for @networkLogTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get networkLogTime;

  /// No description provided for @networkLogTitle.
  ///
  /// In zh, this message translates to:
  /// **'网络日志'**
  String get networkLogTitle;

  /// No description provided for @networkLogToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get networkLogToday;

  /// No description provided for @networkLogType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get networkLogType;

  /// No description provided for @networkLogTypeCapability.
  ///
  /// In zh, this message translates to:
  /// **'能力表'**
  String get networkLogTypeCapability;

  /// No description provided for @networkLogTypeChat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get networkLogTypeChat;

  /// No description provided for @networkLogTypeModels.
  ///
  /// In zh, this message translates to:
  /// **'模型列表'**
  String get networkLogTypeModels;

  /// No description provided for @networkLogTypeOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get networkLogTypeOther;

  /// No description provided for @networkLogTypeTest.
  ///
  /// In zh, this message translates to:
  /// **'测速'**
  String get networkLogTypeTest;

  /// No description provided for @networkLogUrl.
  ///
  /// In zh, this message translates to:
  /// **'地址'**
  String get networkLogUrl;

  /// No description provided for @networkLogViewFull.
  ///
  /// In zh, this message translates to:
  /// **'查看全文'**
  String get networkLogViewFull;

  /// No description provided for @networkLogYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get networkLogYesterday;

  /// No description provided for @preferencesAutoRetry.
  ///
  /// In zh, this message translates to:
  /// **'自动重试失败请求'**
  String get preferencesAutoRetry;

  /// No description provided for @preferencesAutoRetryHint.
  ///
  /// In zh, this message translates to:
  /// **'连接失败、限流或服务端错误时自动重试（指数退避，最多 3 次尝试）'**
  String get preferencesAutoRetryHint;

  /// No description provided for @preferencesDocumentThreshold.
  ///
  /// In zh, this message translates to:
  /// **'文本文档阈值'**
  String get preferencesDocumentThreshold;

  /// No description provided for @preferencesDocumentThresholdExample.
  ///
  /// In zh, this message translates to:
  /// **'例如：40000，0 表示关闭'**
  String get preferencesDocumentThresholdExample;

  /// No description provided for @preferencesDocumentThresholdInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入不小于 0 的数字'**
  String get preferencesDocumentThresholdInvalid;

  /// No description provided for @preferencesDocumentThresholdLabel.
  ///
  /// In zh, this message translates to:
  /// **'阈值（字）'**
  String get preferencesDocumentThresholdLabel;

  /// No description provided for @preferencesDocumentThresholdOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭（直接渲染）'**
  String get preferencesDocumentThresholdOff;

  /// No description provided for @preferencesDocumentThresholdTitle.
  ///
  /// In zh, this message translates to:
  /// **'文本文档阈值'**
  String get preferencesDocumentThresholdTitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'超过 {count} 字的消息显示为文本文档'**
  String preferencesDocumentThresholdValue(int count);

  /// No description provided for @preferencesEnterSend.
  ///
  /// In zh, this message translates to:
  /// **'Enter 发送消息'**
  String get preferencesEnterSend;

  /// No description provided for @preferencesEnterSendHint.
  ///
  /// In zh, this message translates to:
  /// **'关闭后，输入法右下角的「换行」键将插入换行，而不会直接发送消息。'**
  String get preferencesEnterSendHint;

  /// No description provided for @preferencesEnterSendOff.
  ///
  /// In zh, this message translates to:
  /// **'按 Enter 换行，Ctrl+Enter 发送'**
  String get preferencesEnterSendOff;

  /// No description provided for @preferencesEnterSendOn.
  ///
  /// In zh, this message translates to:
  /// **'按 Enter 发送，Shift+Enter 换行'**
  String get preferencesEnterSendOn;

  /// No description provided for @preferencesLanguage.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get preferencesLanguage;

  /// No description provided for @preferencesLanguageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get preferencesLanguageEn;

  /// No description provided for @preferencesLanguageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get preferencesLanguageSystem;

  /// No description provided for @preferencesLanguageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get preferencesLanguageZh;

  /// No description provided for @preferencesStreamMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'流式渲染 Markdown'**
  String get preferencesStreamMarkdown;

  /// No description provided for @preferencesStreamMarkdownHint.
  ///
  /// In zh, this message translates to:
  /// **'生成过程中实时渲染 Markdown 格式；关闭后生成完成再渲染（超长回复时更流畅）'**
  String get preferencesStreamMarkdownHint;

  /// No description provided for @preferencesTitle.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferencesTitle;

  /// No description provided for @preferencesTtsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'朗读语言'**
  String get preferencesTtsLanguage;

  /// No description provided for @preferencesTtsLanguageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get preferencesTtsLanguageEn;

  /// No description provided for @preferencesTtsLanguageJa.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get preferencesTtsLanguageJa;

  /// No description provided for @preferencesTtsLanguageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get preferencesTtsLanguageZh;

  /// No description provided for @preferencesTtsRate.
  ///
  /// In zh, this message translates to:
  /// **'朗读语速'**
  String get preferencesTtsRate;

  /// No description provided for @preferencesWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'网络搜索'**
  String get preferencesWebSearch;

  /// No description provided for @preferencesWebSearchApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get preferencesWebSearchApiKey;

  /// No description provided for @preferencesWebSearchApiKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'未配置（点此填写）'**
  String get preferencesWebSearchApiKeyHint;

  /// No description provided for @searchEngineBing.
  ///
  /// In zh, this message translates to:
  /// **'Bing（免费）'**
  String get searchEngineBing;

  /// No description provided for @searchEngineDuckduckgo.
  ///
  /// In zh, this message translates to:
  /// **'DuckDuckGo（免费）'**
  String get searchEngineDuckduckgo;

  /// No description provided for @searchEngineTavily.
  ///
  /// In zh, this message translates to:
  /// **'Tavily（需 API Key）'**
  String get searchEngineTavily;

  /// No description provided for @searchEngineBocha.
  ///
  /// In zh, this message translates to:
  /// **'博查搜搜（需 API Key）'**
  String get searchEngineBocha;

  /// No description provided for @searchEngineSearxng.
  ///
  /// In zh, this message translates to:
  /// **'SearXNG（自托管）'**
  String get searchEngineSearxng;

  /// No description provided for @preferencesWebSearchBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'SearXNG 地址'**
  String get preferencesWebSearchBaseUrl;

  /// No description provided for @preferencesWebSearchBaseUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'未配置（点此填写）'**
  String get preferencesWebSearchBaseUrlHint;

  /// No description provided for @preferencesWebSearchEngine.
  ///
  /// In zh, this message translates to:
  /// **'搜索引擎'**
  String get preferencesWebSearchEngine;

  /// No description provided for @preferencesWebSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'发送前自动联网搜索，结果注入上下文供模型引用'**
  String get preferencesWebSearchHint;

  /// No description provided for @providerAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加服务商'**
  String get providerAdd;

  /// No description provided for @providerAddModel.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get providerAddModel;

  /// No description provided for @providerAdvancedSettings.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get providerAdvancedSettings;

  /// No description provided for @providerBaseSettings.
  ///
  /// In zh, this message translates to:
  /// **'基础设置'**
  String get providerBaseSettings;

  /// No description provided for @providerClickRetest.
  ///
  /// In zh, this message translates to:
  /// **'点击重新测试'**
  String get providerClickRetest;

  /// No description provided for @providerClickTest.
  ///
  /// In zh, this message translates to:
  /// **'点击测试'**
  String get providerClickTest;

  /// No description provided for @providerCustomBody.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求体（JSON，合并进请求）'**
  String get providerCustomBody;

  /// No description provided for @providerCustomBodyInvalid.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求体不是合法的 JSON，返回后该内容将丢失'**
  String get providerCustomBodyInvalid;

  /// No description provided for @providerCustomHeaders.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头（每行一个 Key: Value）'**
  String get providerCustomHeaders;

  /// No description provided for @providerCustomHeadersInvalid.
  ///
  /// In zh, this message translates to:
  /// **'自定义请求头存在缺少冒号的行，返回后这些行将丢失'**
  String get providerCustomHeadersInvalid;

  /// No description provided for @providerDebug.
  ///
  /// In zh, this message translates to:
  /// **'调试'**
  String get providerDebug;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'删除服务商「{name}」？'**
  String providerDeleteConfirm(String name);

  /// No description provided for @providerDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除服务商'**
  String get providerDeleteTitle;

  /// No description provided for @providerEdit.
  ///
  /// In zh, this message translates to:
  /// **'服务商设置'**
  String get providerEdit;

  /// No description provided for @providerEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无服务商，点右上角添加'**
  String get providerEmpty;

  /// No description provided for @providerImportHint.
  ///
  /// In zh, this message translates to:
  /// **'粘贴分享的服务商文本…'**
  String get providerImportHint;

  /// No description provided for @providerImportInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无法解析该文本，请检查是否完整'**
  String get providerImportInvalid;

  /// No description provided for @providerImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入服务商'**
  String get providerImportTitle;

  /// No description provided for @providerLatencyExcellent.
  ///
  /// In zh, this message translates to:
  /// **'优秀'**
  String get providerLatencyExcellent;

  /// No description provided for @providerLatencyGood.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get providerLatencyGood;

  /// No description provided for @providerLatencyRecord.
  ///
  /// In zh, this message translates to:
  /// **'延迟记录'**
  String get providerLatencyRecord;

  /// No description provided for @providerLatencySlow.
  ///
  /// In zh, this message translates to:
  /// **'较慢'**
  String get providerLatencySlow;

  /// No description provided for @providerModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get providerModel;

  /// No description provided for @providerModelSettings.
  ///
  /// In zh, this message translates to:
  /// **'模型设置'**
  String get providerModelSettings;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个模型'**
  String providerModelsCount(int count);

  /// No description provided for @providerModelsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'尚未添加模型，点击「添加模型」\\n可手动填写模型 ID 或从 /models 列表获取'**
  String get providerModelsEmpty;

  /// No description provided for @providerMultimodal.
  ///
  /// In zh, this message translates to:
  /// **'多模态'**
  String get providerMultimodal;

  /// No description provided for @providerMultimodalHint.
  ///
  /// In zh, this message translates to:
  /// **'支持图片、文件等非文本输入'**
  String get providerMultimodalHint;

  /// No description provided for @providerName.
  ///
  /// In zh, this message translates to:
  /// **'服务商名称'**
  String get providerName;

  /// No description provided for @providerNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：OpenAI'**
  String get providerNameHint;

  /// No description provided for @providerBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'接口地址'**
  String get providerBaseUrl;

  /// No description provided for @providerSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试'**
  String get providerSaveFailed;

  /// No description provided for @providerBaseUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：https://api.openai.com/v1'**
  String get providerBaseUrlHint;

  /// No description provided for @providerApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API 密钥'**
  String get providerApiKey;

  /// No description provided for @providerApiKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'sk-…'**
  String get providerApiKeyHint;

  /// No description provided for @providerProtocol.
  ///
  /// In zh, this message translates to:
  /// **'协议类型'**
  String get providerProtocol;

  /// No description provided for @providerProtocolAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动（按地址识别）'**
  String get providerProtocolAuto;

  /// No description provided for @providerReasoning.
  ///
  /// In zh, this message translates to:
  /// **'推理'**
  String get providerReasoning;

  /// No description provided for @providerReasoningHint.
  ///
  /// In zh, this message translates to:
  /// **'启用深度推理能力（如 o1、o3 系列）'**
  String get providerReasoningHint;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'移除模型「{id}」？'**
  String providerRemoveModelConfirm(String id);

  /// No description provided for @providerRemoveModelTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除模型'**
  String get providerRemoveModelTitle;

  /// No description provided for @providerShareHint.
  ///
  /// In zh, this message translates to:
  /// **'复制以下文本即可分享服务商配置（含 API Key，请注意保管）：'**
  String get providerShareHint;

  /// No description provided for @providerShareTitle.
  ///
  /// In zh, this message translates to:
  /// **'分享服务商'**
  String get providerShareTitle;

  /// No description provided for @providerTest.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get providerTest;

  /// No description provided for @providerTestAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新测试'**
  String get providerTestAgain;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'测试失败: {error}'**
  String providerTestFailedDetail(String error);

  /// No description provided for @providerTesting.
  ///
  /// In zh, this message translates to:
  /// **'测试中…'**
  String get providerTesting;

  /// No description provided for @providerTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get providerTitle;

  /// No description provided for @providerUnconfiguredModel.
  ///
  /// In zh, this message translates to:
  /// **'未配置模型'**
  String get providerUnconfiguredModel;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词，搜索全部会话'**
  String get searchHint;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'没有找到与「{query}」相关的消息'**
  String searchNoResult(String query);

  /// No description provided for @searchTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索会话标题与消息内容…'**
  String get searchTitle;

  /// No description provided for @searchTitleHit.
  ///
  /// In zh, this message translates to:
  /// **'标题命中'**
  String get searchTitleHit;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于 Nona'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'版本 / GitHub 仓库 / 开源许可'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAgents.
  ///
  /// In zh, this message translates to:
  /// **'Agent 配置'**
  String get settingsAgents;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个 Agent'**
  String settingsAgentsSubtitle(int count);

  /// No description provided for @settingsAllExist.
  ///
  /// In zh, this message translates to:
  /// **'所有会话已存在，无新增'**
  String get settingsAllExist;

  /// No description provided for @settingsClearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空全部会话'**
  String get settingsClearAll;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'将删除全部 {count} 个会话'**
  String settingsClearAllSubtitle(int count);

  /// No description provided for @settingsClearAllSubtitleEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前没有保存的会话'**
  String get settingsClearAllSubtitleEmpty;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'将删除全部 {count} 个会话，此操作不可恢复。'**
  String settingsClearConfirmContent(int count);

  /// No description provided for @settingsClearConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空全部会话'**
  String get settingsClearConfirmTitle;

  /// No description provided for @settingsCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清空全部会话'**
  String get settingsCleared;

  /// No description provided for @settingsCompareSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'同一问题对比多个模型'**
  String get settingsCompareSubtitle;

  /// No description provided for @settingsDevOptions.
  ///
  /// In zh, this message translates to:
  /// **'开发者选项'**
  String get settingsDevOptions;

  /// No description provided for @settingsDevOptionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'连通性高级设置 / 模型能力映射表'**
  String get settingsDevOptionsSubtitle;

  /// No description provided for @settingsExportAll.
  ///
  /// In zh, this message translates to:
  /// **'导出全部会话'**
  String get settingsExportAll;

  /// No description provided for @settingsExportAllSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'备份为 JSON 文件，可随时恢复'**
  String get settingsExportAllSubtitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String settingsExportFailed(Object error);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已导出全部数据到 {path}'**
  String settingsExportedAll(String path);

  /// No description provided for @settingsFooter.
  ///
  /// In zh, this message translates to:
  /// **'Nona · 本地优先，所有数据仅保存在本机'**
  String get settingsFooter;

  /// No description provided for @settingsImport.
  ///
  /// In zh, this message translates to:
  /// **'导入会话'**
  String get settingsImport;

  /// No description provided for @settingsImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：文件格式不正确'**
  String get settingsImportFailed;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从 Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo 导入'**
  String get settingsImportSubtitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 个会话'**
  String settingsImported(int count);

  /// No description provided for @settingsKbSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本地知识库，对话自动检索'**
  String get settingsKbSubtitle;

  /// No description provided for @settingsMcpSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'MCP 工具服务管理'**
  String get settingsMcpSubtitle;

  /// No description provided for @settingsModelConfig.
  ///
  /// In zh, this message translates to:
  /// **'模型配置'**
  String get settingsModelConfig;

  /// No description provided for @settingsModelConfigSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'聊天默认模型 · 标题生成模型'**
  String get settingsModelConfigSubtitle;

  /// No description provided for @settingsNoExportable.
  ///
  /// In zh, this message translates to:
  /// **'还没有可导出的会话'**
  String get settingsNoExportable;

  /// No description provided for @settingsPreferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get settingsPreferences;

  /// No description provided for @settingsPreferencesEnterNewline.
  ///
  /// In zh, this message translates to:
  /// **'Enter 换行，Ctrl+Enter 发送'**
  String get settingsPreferencesEnterNewline;

  /// No description provided for @settingsPreferencesEnterSend.
  ///
  /// In zh, this message translates to:
  /// **'Enter 发送，Shift+Enter 换行'**
  String get settingsPreferencesEnterSend;

  /// No description provided for @settingsProviders.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get settingsProviders;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{providers} 个服务商 · {models} 个模型'**
  String settingsProvidersSubtitle(int providers, int models);

  /// No description provided for @settingsProvidersSubtitleEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未配置，添加服务商并获取模型'**
  String get settingsProvidersSubtitleEmpty;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsSectionAbout;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionIntegrations.
  ///
  /// In zh, this message translates to:
  /// **'集成与同步'**
  String get settingsSectionIntegrations;

  /// No description provided for @settingsSectionMemory.
  ///
  /// In zh, this message translates to:
  /// **'记忆与上下文'**
  String get settingsSectionMemory;

  /// No description provided for @settingsSectionModels.
  ///
  /// In zh, this message translates to:
  /// **'模型与智能体'**
  String get settingsSectionModels;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionTools.
  ///
  /// In zh, this message translates to:
  /// **'工具与增强'**
  String get settingsSectionTools;

  /// No description provided for @settingsSyncSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV / S3 备份同步'**
  String get settingsSyncSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsTranslatorSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'调用 AI 模型进行翻译'**
  String get settingsTranslatorSubtitle;

  /// No description provided for @sidebarAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'匿名会话（不保存）'**
  String get sidebarAnonymous;

  /// No description provided for @sidebarAnonymousActive.
  ///
  /// In zh, this message translates to:
  /// **'匿名会话进行中'**
  String get sidebarAnonymousActive;

  /// No description provided for @sidebarAnonymousHint.
  ///
  /// In zh, this message translates to:
  /// **'对话内容仅保存在内存中，\\n关闭应用后不会留下记录'**
  String get sidebarAnonymousHint;

  /// No description provided for @sidebarBrandSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 聊天助手'**
  String get sidebarBrandSubtitle;

  /// No description provided for @sidebarDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'复制会话'**
  String get sidebarDuplicate;

  /// No description provided for @sidebarEarlier.
  ///
  /// In zh, this message translates to:
  /// **'更早'**
  String get sidebarEarlier;

  /// No description provided for @sidebarExitAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'退出匿名'**
  String get sidebarExitAnonymous;

  /// No description provided for @sidebarExitAnonymousConfirm.
  ///
  /// In zh, this message translates to:
  /// **'退出匿名会话'**
  String get sidebarExitAnonymousConfirm;

  /// No description provided for @sidebarNewSessionAgent.
  ///
  /// In zh, this message translates to:
  /// **'新建会话 / 选择 Agent'**
  String get sidebarNewSessionAgent;

  /// No description provided for @sidebarNewWithAgent.
  ///
  /// In zh, this message translates to:
  /// **'用 Agent 新建会话'**
  String get sidebarNewWithAgent;

  /// No description provided for @sidebarNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的会话'**
  String get sidebarNoMatch;

  /// No description provided for @sidebarNoSessions.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话'**
  String get sidebarNoSessions;

  /// No description provided for @sidebarPin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get sidebarPin;

  /// No description provided for @sidebarRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get sidebarRename;

  /// No description provided for @sidebarSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索会话与消息…'**
  String get sidebarSearchHint;

  /// No description provided for @sidebarSessionActions.
  ///
  /// In zh, this message translates to:
  /// **'会话操作'**
  String get sidebarSessionActions;

  /// No description provided for @sidebarToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get sidebarToday;

  /// No description provided for @sidebarUnpin.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get sidebarUnpin;

  /// No description provided for @sidebarYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get sidebarYesterday;

  /// No description provided for @syncBackupList.
  ///
  /// In zh, this message translates to:
  /// **'云端备份'**
  String get syncBackupList;

  /// No description provided for @syncEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无备份，点击「上传备份」创建'**
  String get syncEmpty;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'将合并恢复备份「{name}」中的会话与服务商配置？'**
  String syncRestoreConfirm(String name);

  /// No description provided for @syncRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份'**
  String get syncRestoreTitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已恢复 {count} 个新会话'**
  String syncRestored(int count);

  /// No description provided for @syncS3Access.
  ///
  /// In zh, this message translates to:
  /// **'Access Key'**
  String get syncS3Access;

  /// No description provided for @syncS3Bucket.
  ///
  /// In zh, this message translates to:
  /// **'Bucket'**
  String get syncS3Bucket;

  /// No description provided for @syncS3Endpoint.
  ///
  /// In zh, this message translates to:
  /// **'S3 端点'**
  String get syncS3Endpoint;

  /// No description provided for @syncS3Region.
  ///
  /// In zh, this message translates to:
  /// **'Region'**
  String get syncS3Region;

  /// No description provided for @syncS3Secret.
  ///
  /// In zh, this message translates to:
  /// **'Secret Key'**
  String get syncS3Secret;

  /// No description provided for @syncTitle.
  ///
  /// In zh, this message translates to:
  /// **'云同步'**
  String get syncTitle;

  /// No description provided for @statsTitle.
  ///
  /// In zh, this message translates to:
  /// **'统计看板'**
  String get statsTitle;

  /// No description provided for @settingsStatsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Token 用量、模型排行与成本统计'**
  String get settingsStatsSubtitle;

  /// No description provided for @memoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'记忆'**
  String get memoryTitle;

  /// No description provided for @settingsMemorySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自动提取与管理的长期记忆'**
  String get settingsMemorySubtitle;

  /// No description provided for @memoryAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加记忆'**
  String get memoryAdd;

  /// No description provided for @memoryContentHint.
  ///
  /// In zh, this message translates to:
  /// **'输入想长期记住的内容'**
  String get memoryContentHint;

  /// No description provided for @memoryEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑记忆'**
  String get memoryEdit;

  /// No description provided for @memoryDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除该记忆？'**
  String get memoryDeleteConfirm;

  /// No description provided for @memoryScopeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get memoryScopeGlobal;

  /// No description provided for @memoryScopeAgent.
  ///
  /// In zh, this message translates to:
  /// **'Agent'**
  String get memoryScopeAgent;

  /// No description provided for @memoryScopeSession.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get memoryScopeSession;

  /// No description provided for @memoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无记忆，对话满 10 轮后会自动提取'**
  String get memoryEmpty;

  /// No description provided for @memoryPin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get memoryPin;

  /// No description provided for @settingsWbSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'世界书：关键词触发的角色设定注入'**
  String get settingsWbSubtitle;

  /// No description provided for @importTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get importTitle;

  /// No description provided for @imgGenTitle.
  ///
  /// In zh, this message translates to:
  /// **'图片生成'**
  String get imgGenTitle;

  /// No description provided for @settingsImgGenSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用 AI 生成图片（需支持图片生成的服务商）'**
  String get settingsImgGenSubtitle;

  /// No description provided for @ocrAction.
  ///
  /// In zh, this message translates to:
  /// **'转为文字'**
  String get ocrAction;

  /// No description provided for @ocrProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在识别图片文字…'**
  String get ocrProcessing;

  /// No description provided for @ocrNoVisionModel.
  ///
  /// In zh, this message translates to:
  /// **'当前服务商没有可用的多模态（视觉）模型，无法识别图片文字'**
  String get ocrNoVisionModel;

  /// No description provided for @ocrDone.
  ///
  /// In zh, this message translates to:
  /// **'已识别图片文字并替换为文本消息'**
  String get ocrDone;

  /// No description provided for @ocrFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片文字识别失败：{error}'**
  String ocrFailed(Object error);

  /// No description provided for @imgGenProvider.
  ///
  /// In zh, this message translates to:
  /// **'服务商（需支持图片生成）'**
  String get imgGenProvider;

  /// No description provided for @imgGenPrompt.
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get imgGenPrompt;

  /// No description provided for @imgGenPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'描述你想生成的图片'**
  String get imgGenPromptHint;

  /// No description provided for @imgGenSize.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get imgGenSize;

  /// No description provided for @imgGenCount.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get imgGenCount;

  /// No description provided for @imgGenGenerate.
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get imgGenGenerate;

  /// No description provided for @imgGenGenerating.
  ///
  /// In zh, this message translates to:
  /// **'生成中…'**
  String get imgGenGenerating;

  /// No description provided for @imgGenEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史，输入提示词开始生成'**
  String get imgGenEmpty;

  /// No description provided for @importPickHint.
  ///
  /// In zh, this message translates to:
  /// **'选择备份文件（Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo）'**
  String get importPickHint;

  /// No description provided for @importPick.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get importPick;

  /// No description provided for @importConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get importConfirm;

  /// No description provided for @importFormat.
  ///
  /// In zh, this message translates to:
  /// **'识别格式：{format}'**
  String importFormat(Object format);

  /// No description provided for @importPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览：{sessions} 个会话，{messages} 条消息'**
  String importPreview(Object messages, Object sessions);

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败，请检查文件格式'**
  String get importFailed;

  /// No description provided for @importResultOk.
  ///
  /// In zh, this message translates to:
  /// **'导入成功：新增 {count} 个会话'**
  String importResultOk(Object count);

  /// No description provided for @importResultPartial.
  ///
  /// In zh, this message translates to:
  /// **'导入完成：新增 {count} 个会话，{failed} 条记录失败（已跳过）'**
  String importResultPartial(Object count, Object failed);

  /// No description provided for @wbTitle.
  ///
  /// In zh, this message translates to:
  /// **'世界书'**
  String get wbTitle;

  /// No description provided for @wbAdd.
  ///
  /// In zh, this message translates to:
  /// **'新建条目'**
  String get wbAdd;

  /// No description provided for @wbEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑条目'**
  String get wbEdit;

  /// No description provided for @wbImport.
  ///
  /// In zh, this message translates to:
  /// **'导入 JSON'**
  String get wbImport;

  /// No description provided for @wbExport.
  ///
  /// In zh, this message translates to:
  /// **'导出 JSON'**
  String get wbExport;

  /// No description provided for @wbEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无条目，点击右上角新建'**
  String get wbEmpty;

  /// No description provided for @wbDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除世界书条目「{title}」？'**
  String wbDeleteConfirm(Object title);

  /// No description provided for @wbImported.
  ///
  /// In zh, this message translates to:
  /// **'导入 {count} 条条目'**
  String wbImported(Object count);

  /// No description provided for @wbImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：JSON 格式不正确'**
  String get wbImportFailed;

  /// No description provided for @wbTitleField.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get wbTitleField;

  /// No description provided for @wbKeywordsField.
  ///
  /// In zh, this message translates to:
  /// **'触发关键词'**
  String get wbKeywordsField;

  /// No description provided for @wbKeywordsHint.
  ///
  /// In zh, this message translates to:
  /// **'逗号分隔，消息中包含任一关键词即触发'**
  String get wbKeywordsHint;

  /// No description provided for @wbContentField.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get wbContentField;

  /// No description provided for @wbPriorityField.
  ///
  /// In zh, this message translates to:
  /// **'优先级'**
  String get wbPriorityField;

  /// No description provided for @wbScanDepthField.
  ///
  /// In zh, this message translates to:
  /// **'扫描深度'**
  String get wbScanDepthField;

  /// No description provided for @wbPositionField.
  ///
  /// In zh, this message translates to:
  /// **'注入位置'**
  String get wbPositionField;

  /// No description provided for @wbCaseSensitive.
  ///
  /// In zh, this message translates to:
  /// **'关键词区分大小写'**
  String get wbCaseSensitive;

  /// No description provided for @wbConstantActive.
  ///
  /// In zh, this message translates to:
  /// **'常驻激活（始终注入）'**
  String get wbConstantActive;

  /// No description provided for @wbUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名条目'**
  String get wbUntitled;

  /// No description provided for @statsBudgetWarning.
  ///
  /// In zh, this message translates to:
  /// **'本月已使用预算的 {percent}%，请注意控制用量'**
  String statsBudgetWarning(Object percent);

  /// No description provided for @statsBudgetBlocked.
  ///
  /// In zh, this message translates to:
  /// **'已超出本月预算，发送被拦截（可在统计看板调整预算）'**
  String get statsBudgetBlocked;

  /// No description provided for @statsBudgetWarningTitle.
  ///
  /// In zh, this message translates to:
  /// **'本月预算已用完'**
  String get statsBudgetWarningTitle;

  /// No description provided for @statsBudgetWarningBody.
  ///
  /// In zh, this message translates to:
  /// **'继续发送将超出本月预算，是否继续？'**
  String get statsBudgetWarningBody;

  /// No description provided for @statsBudgetOverride.
  ///
  /// In zh, this message translates to:
  /// **'仍然发送'**
  String get statsBudgetOverride;

  /// No description provided for @statsRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get statsRefresh;

  /// No description provided for @statsDailyTokens.
  ///
  /// In zh, this message translates to:
  /// **'每日 Token（下:输入 / 上:输出）'**
  String get statsDailyTokens;

  /// No description provided for @statsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get statsEmpty;

  /// No description provided for @statsCostTrend.
  ///
  /// In zh, this message translates to:
  /// **'Token 趋势'**
  String get statsCostTrend;

  /// No description provided for @statsTopModels.
  ///
  /// In zh, this message translates to:
  /// **'模型 Top 10'**
  String get statsTopModels;

  /// No description provided for @statsTopSessions.
  ///
  /// In zh, this message translates to:
  /// **'会话 Top 10'**
  String get statsTopSessions;

  /// No description provided for @statsTotalTokens.
  ///
  /// In zh, this message translates to:
  /// **'累计 Token'**
  String get statsTotalTokens;

  /// No description provided for @statsTotalCost.
  ///
  /// In zh, this message translates to:
  /// **'累计花费（美元）'**
  String get statsTotalCost;

  /// No description provided for @syncTypeS3.
  ///
  /// In zh, this message translates to:
  /// **'S3'**
  String get syncTypeS3;

  /// No description provided for @syncTypeWebDav.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV'**
  String get syncTypeWebDav;

  /// No description provided for @syncErrorAuth.
  ///
  /// In zh, this message translates to:
  /// **'认证失败，请检查账号或密钥'**
  String get syncErrorAuth;

  /// No description provided for @syncErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络后重试'**
  String get syncErrorNetwork;

  /// No description provided for @syncErrorStorage.
  ///
  /// In zh, this message translates to:
  /// **'存储服务错误，请检查配置'**
  String get syncErrorStorage;

  /// No description provided for @syncUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传备份'**
  String get syncUpload;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已上传备份：{name}'**
  String syncUploaded(String name);

  /// No description provided for @syncWebDavPass.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get syncWebDavPass;

  /// No description provided for @syncWebDavUrl.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 地址'**
  String get syncWebDavUrl;

  /// No description provided for @syncWebDavUser.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get syncWebDavUser;

  /// No description provided for @themeAccentSection.
  ///
  /// In zh, this message translates to:
  /// **'强调色'**
  String get themeAccentSection;

  /// No description provided for @themeCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get themeCustom;

  /// No description provided for @themeCustomColor.
  ///
  /// In zh, this message translates to:
  /// **'自定义颜色'**
  String get themeCustomColor;

  /// No description provided for @themeCustomTitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义强调色'**
  String get themeCustomTitle;

  /// No description provided for @themeDarkSection.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeDarkSection;

  /// No description provided for @themeHue.
  ///
  /// In zh, this message translates to:
  /// **'色相'**
  String get themeHue;

  /// No description provided for @themeModeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeModeDark;

  /// No description provided for @themeModeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeModeLight;

  /// No description provided for @themeModeSection.
  ///
  /// In zh, this message translates to:
  /// **'外观模式'**
  String get themeModeSection;

  /// No description provided for @themeModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeModeSystem;

  /// No description provided for @themeOledSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'深色模式下使用纯黑背景，适合 OLED 屏幕，更省电'**
  String get themeOledSubtitle;

  /// No description provided for @themeOledTitle.
  ///
  /// In zh, this message translates to:
  /// **'OLED 纯黑背景'**
  String get themeOledTitle;

  /// No description provided for @themeSaturation.
  ///
  /// In zh, this message translates to:
  /// **'饱和度'**
  String get themeSaturation;

  /// No description provided for @themeTitle.
  ///
  /// In zh, this message translates to:
  /// **'主题配置'**
  String get themeTitle;

  /// No description provided for @themeValue.
  ///
  /// In zh, this message translates to:
  /// **'明度'**
  String get themeValue;

  /// No description provided for @translatorFailed.
  ///
  /// In zh, this message translates to:
  /// **'翻译失败，请重试'**
  String get translatorFailed;

  /// No description provided for @translatorNoModel.
  ///
  /// In zh, this message translates to:
  /// **'请先在「模型配置」中设置默认聊天模型'**
  String get translatorNoModel;

  /// No description provided for @translatorResult.
  ///
  /// In zh, this message translates to:
  /// **'译文'**
  String get translatorResult;

  /// No description provided for @translatorSourceHint.
  ///
  /// In zh, this message translates to:
  /// **'输入需要翻译的内容…'**
  String get translatorSourceHint;

  /// No description provided for @translatorTarget.
  ///
  /// In zh, this message translates to:
  /// **'目标语言'**
  String get translatorTarget;

  /// No description provided for @unitsMb.
  ///
  /// In zh, this message translates to:
  /// **'MB'**
  String get unitsMb;

  /// No description provided for @unitsKb.
  ///
  /// In zh, this message translates to:
  /// **'KB'**
  String get unitsKb;

  /// No description provided for @unitsB.
  ///
  /// In zh, this message translates to:
  /// **'B'**
  String get unitsB;

  /// No description provided for @translatorLangEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get translatorLangEn;

  /// No description provided for @translatorLangZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get translatorLangZh;

  /// No description provided for @translatorLangJa.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get translatorLangJa;

  /// No description provided for @translatorLangKo.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get translatorLangKo;

  /// No description provided for @translatorLangFr.
  ///
  /// In zh, this message translates to:
  /// **'Français'**
  String get translatorLangFr;

  /// No description provided for @translatorLangDe.
  ///
  /// In zh, this message translates to:
  /// **'Deutsch'**
  String get translatorLangDe;

  /// No description provided for @translatorLangEs.
  ///
  /// In zh, this message translates to:
  /// **'Español'**
  String get translatorLangEs;

  /// No description provided for @translatorLangRu.
  ///
  /// In zh, this message translates to:
  /// **'Русский'**
  String get translatorLangRu;

  /// 翻译提示词模板
  ///
  /// In zh, this message translates to:
  /// **'请将以下内容翻译成{target}，只输出译文：\n\n{source}'**
  String translatorPrompt(String target, String source);

  /// No description provided for @translatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 翻译'**
  String get translatorTitle;

  /// No description provided for @translatorTranslate.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get translatorTranslate;

  /// No description provided for @translatorTranslating.
  ///
  /// In zh, this message translates to:
  /// **'翻译中…'**
  String get translatorTranslating;

  /// No description provided for @chatSuggestionTitle.
  ///
  /// In zh, this message translates to:
  /// **'你可以这样开始'**
  String get chatSuggestionTitle;

  /// No description provided for @chatSuggestionStart.
  ///
  /// In zh, this message translates to:
  /// **'介绍你自己，包括能力和限制'**
  String get chatSuggestionStart;

  /// No description provided for @chatSuggestionFiles.
  ///
  /// In zh, this message translates to:
  /// **'如何上传文档并获得摘要？'**
  String get chatSuggestionFiles;

  /// No description provided for @chatSuggestionMcp.
  ///
  /// In zh, this message translates to:
  /// **'连接外部工具需要什么配置？'**
  String get chatSuggestionMcp;

  /// No description provided for @chatMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get chatMoreActions;

  /// No description provided for @chatSelectCopy.
  ///
  /// In zh, this message translates to:
  /// **'选择复制'**
  String get chatSelectCopy;

  /// No description provided for @chatExportImage.
  ///
  /// In zh, this message translates to:
  /// **'导出图片'**
  String get chatExportImage;

  /// No description provided for @chatExportSelectedImage.
  ///
  /// In zh, this message translates to:
  /// **'导出长图'**
  String get chatExportSelectedImage;

  /// No description provided for @chatExportJsonl.
  ///
  /// In zh, this message translates to:
  /// **'导出 JSONL'**
  String get chatExportJsonl;

  /// No description provided for @chatLongImageCapturing.
  ///
  /// In zh, this message translates to:
  /// **'正在生成长图…'**
  String get chatLongImageCapturing;

  /// No description provided for @chatLongImageDone.
  ///
  /// In zh, this message translates to:
  /// **'长图已导出'**
  String get chatLongImageDone;

  /// No description provided for @chatSelectCopyHint.
  ///
  /// In zh, this message translates to:
  /// **'长按或拖选文本后复制；可附带上下文发送'**
  String get chatSelectCopyHint;

  /// No description provided for @chatCopyWithContext.
  ///
  /// In zh, this message translates to:
  /// **'附带上下文发送'**
  String get chatCopyWithContext;

  /// No description provided for @chatNoSelection.
  ///
  /// In zh, this message translates to:
  /// **'未选择文本'**
  String get chatNoSelection;

  /// No description provided for @contextManageTitle.
  ///
  /// In zh, this message translates to:
  /// **'上下文管理'**
  String get contextManageTitle;

  /// No description provided for @contextSegments.
  ///
  /// In zh, this message translates to:
  /// **'注入分段'**
  String get contextSegments;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{tokens} tokens'**
  String contextSegmentTokens(String tokens);

  /// No description provided for @contextSegmentSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统提示词'**
  String get contextSegmentSystem;

  /// No description provided for @contextSegmentMemory.
  ///
  /// In zh, this message translates to:
  /// **'记忆'**
  String get contextSegmentMemory;

  /// No description provided for @contextSegmentKnowledge.
  ///
  /// In zh, this message translates to:
  /// **'知识库'**
  String get contextSegmentKnowledge;

  /// No description provided for @contextSegmentSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get contextSegmentSearch;

  /// No description provided for @contextSegmentWorldBook.
  ///
  /// In zh, this message translates to:
  /// **'世界书'**
  String get contextSegmentWorldBook;

  /// No description provided for @contextSegmentHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史消息'**
  String get contextSegmentHistory;

  /// No description provided for @contextSegmentSummary.
  ///
  /// In zh, this message translates to:
  /// **'会话摘要'**
  String get contextSegmentSummary;

  /// No description provided for @contextSegmentInjection.
  ///
  /// In zh, this message translates to:
  /// **'指令注入'**
  String get contextSegmentInjection;

  /// No description provided for @contextSegmentAgent.
  ///
  /// In zh, this message translates to:
  /// **'Agent 提示词'**
  String get contextSegmentAgent;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已用 {used} / 上限 {limit}'**
  String contextUsedTokens(String limit, String used);

  /// No description provided for @contextNoLimit.
  ///
  /// In zh, this message translates to:
  /// **'未设置上限'**
  String get contextNoLimit;

  /// No description provided for @contextCompress.
  ///
  /// In zh, this message translates to:
  /// **'压缩上下文'**
  String get contextCompress;

  /// No description provided for @contextCompressHint.
  ///
  /// In zh, this message translates to:
  /// **'生成摘要并折叠历史消息'**
  String get contextCompressHint;

  /// No description provided for @contextClear.
  ///
  /// In zh, this message translates to:
  /// **'清除上下文'**
  String get contextClear;

  /// No description provided for @contextClearHint.
  ///
  /// In zh, this message translates to:
  /// **'标记截断点，历史可恢复'**
  String get contextClearHint;

  /// No description provided for @contextRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复被清除的上下文'**
  String get contextRestore;

  /// No description provided for @contextCompressing.
  ///
  /// In zh, this message translates to:
  /// **'正在压缩…'**
  String get contextCompressing;

  /// No description provided for @contextCompressDone.
  ///
  /// In zh, this message translates to:
  /// **'上下文已压缩，新会话以摘要开头'**
  String get contextCompressDone;

  /// No description provided for @contextToggleOffHint.
  ///
  /// In zh, this message translates to:
  /// **'已停用该分段（仅本次请求生效）'**
  String get contextToggleOffHint;

  /// No description provided for @contextEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get contextEnabled;

  /// No description provided for @contextDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get contextDisabled;

  /// No description provided for @providerUseResponseApi.
  ///
  /// In zh, this message translates to:
  /// **'使用 Responses API'**
  String get providerUseResponseApi;

  /// No description provided for @providerUseResponseApiHint.
  ///
  /// In zh, this message translates to:
  /// **'面向 o1/o3/o4/gpt-5 系列；ChatCompletions 兼容服务商请勿开启'**
  String get providerUseResponseApiHint;

  /// No description provided for @providerAuthMode.
  ///
  /// In zh, this message translates to:
  /// **'认证方式'**
  String get providerAuthMode;

  /// No description provided for @providerAuthApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get providerAuthApiKey;

  /// No description provided for @providerAuthServiceAccount.
  ///
  /// In zh, this message translates to:
  /// **'Service Account（Vertex）'**
  String get providerAuthServiceAccount;

  /// No description provided for @providerSaProjectId.
  ///
  /// In zh, this message translates to:
  /// **'Project ID'**
  String get providerSaProjectId;

  /// No description provided for @providerSaRegion.
  ///
  /// In zh, this message translates to:
  /// **'区域（Region）'**
  String get providerSaRegion;

  /// No description provided for @providerSaEmail.
  ///
  /// In zh, this message translates to:
  /// **'Service Account 邮箱'**
  String get providerSaEmail;

  /// No description provided for @providerSaKeyFile.
  ///
  /// In zh, this message translates to:
  /// **'选择 SA JSON 密钥文件'**
  String get providerSaKeyFile;

  /// No description provided for @providerSaKeyPaste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 SA JSON'**
  String get providerSaKeyPaste;

  /// No description provided for @providerSaInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无效的 SA JSON：缺少 client_email/private_key/project_id'**
  String get providerSaInvalid;

  /// No description provided for @providerVertexHint.
  ///
  /// In zh, this message translates to:
  /// **'baseUrl 含 aiplatform 时使用 Bearer 令牌访问 Vertex 端点'**
  String get providerVertexHint;

  /// No description provided for @providerGroupUngrouped.
  ///
  /// In zh, this message translates to:
  /// **'未分组'**
  String get providerGroupUngrouped;

  /// No description provided for @providerGroupAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get providerGroupAll;

  /// No description provided for @providerGroupAdd.
  ///
  /// In zh, this message translates to:
  /// **'新建分组'**
  String get providerGroupAdd;

  /// No description provided for @providerGroupName.
  ///
  /// In zh, this message translates to:
  /// **'分组名称'**
  String get providerGroupName;

  /// No description provided for @providerGroupRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get providerGroupRename;

  /// No description provided for @providerGroupDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除分组'**
  String get providerGroupDelete;

  /// No description provided for @providerGroupEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无分组'**
  String get providerGroupEmpty;

  /// No description provided for @providerKeysTitle.
  ///
  /// In zh, this message translates to:
  /// **'API Key 管理'**
  String get providerKeysTitle;

  /// No description provided for @providerKeysBatchAdd.
  ///
  /// In zh, this message translates to:
  /// **'批量添加 Key（每行一个）'**
  String get providerKeysBatchAdd;

  /// No description provided for @providerKeysTest.
  ///
  /// In zh, this message translates to:
  /// **'测活'**
  String get providerKeysTest;

  /// No description provided for @providerKeysTesting.
  ///
  /// In zh, this message translates to:
  /// **'测活中…'**
  String get providerKeysTesting;

  /// No description provided for @providerKeysStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get providerKeysStatusActive;

  /// No description provided for @providerKeysStatusCooling.
  ///
  /// In zh, this message translates to:
  /// **'冷却中'**
  String get providerKeysStatusCooling;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'失败 {count} 次'**
  String providerKeysStatusError(String count);

  /// No description provided for @providerKeysStatusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已停用（连续失败）'**
  String get providerKeysStatusDisabled;

  /// No description provided for @providerKeysEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get providerKeysEnable;

  /// No description provided for @providerKeysDisable.
  ///
  /// In zh, this message translates to:
  /// **'停用'**
  String get providerKeysDisable;

  /// No description provided for @providerKeysNone.
  ///
  /// In zh, this message translates to:
  /// **'暂无 Key'**
  String get providerKeysNone;

  /// No description provided for @providerKeysCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制（可能被剪贴板暴露，请谨慎）'**
  String get providerKeysCopied;

  /// No description provided for @providerKeysTestOk.
  ///
  /// In zh, this message translates to:
  /// **'测活通过'**
  String get providerKeysTestOk;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'测活失败：{detail}'**
  String providerKeysTestFail(String detail);

  /// No description provided for @providerKeysRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已删除 Key'**
  String get providerKeysRemoved;

  /// No description provided for @imggenSize.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get imggenSize;

  /// No description provided for @imggenQuality.
  ///
  /// In zh, this message translates to:
  /// **'质量'**
  String get imggenQuality;

  /// No description provided for @imggenCount.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get imggenCount;

  /// No description provided for @imggenSendToChat.
  ///
  /// In zh, this message translates to:
  /// **'发送到对话'**
  String get imggenSendToChat;

  /// No description provided for @imggenHistory.
  ///
  /// In zh, this message translates to:
  /// **'生成历史'**
  String get imggenHistory;

  /// No description provided for @imggenHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无生成记录'**
  String get imggenHistoryEmpty;

  /// No description provided for @modelSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索模型'**
  String get modelSearch;

  /// No description provided for @modelFilterMultimodal.
  ///
  /// In zh, this message translates to:
  /// **'多模态'**
  String get modelFilterMultimodal;

  /// No description provided for @modelFilterReasoning.
  ///
  /// In zh, this message translates to:
  /// **'推理'**
  String get modelFilterReasoning;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'上下文 {window}'**
  String modelContextWindow(String window);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'¥{price}/M'**
  String modelPrice(String price);

  /// No description provided for @modelNoCapability.
  ///
  /// In zh, this message translates to:
  /// **'能力未知'**
  String get modelNoCapability;

  /// No description provided for @searchServicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索服务'**
  String get searchServicesTitle;

  /// No description provided for @searchServiceEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get searchServiceEnabled;

  /// No description provided for @searchServiceKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get searchServiceKey;

  /// No description provided for @searchServiceTest.
  ///
  /// In zh, this message translates to:
  /// **'测活'**
  String get searchServiceTest;

  /// No description provided for @searchServiceTesting.
  ///
  /// In zh, this message translates to:
  /// **'测活中…'**
  String get searchServiceTesting;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'返回 {count} 条结果'**
  String searchServiceTestOk(String count);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'测活失败：{detail}'**
  String searchServiceTestFail(String detail);

  /// No description provided for @searchServiceNeedKey.
  ///
  /// In zh, this message translates to:
  /// **'需要 API Key'**
  String get searchServiceNeedKey;

  /// No description provided for @searchServiceNoKey.
  ///
  /// In zh, this message translates to:
  /// **'无需 Key'**
  String get searchServiceNoKey;

  /// No description provided for @searchServiceSelected.
  ///
  /// In zh, this message translates to:
  /// **'当前使用'**
  String get searchServiceSelected;

  /// No description provided for @searchServiceUsageTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索用量'**
  String get searchServiceUsageTitle;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{count} 次调用'**
  String searchServiceCalls(String count);

  /// No description provided for @searchNoKeyFallback.
  ///
  /// In zh, this message translates to:
  /// **'未配置 Key，回退 Bing 免费引擎'**
  String get searchNoKeyFallback;

  /// No description provided for @searchFilterTime.
  ///
  /// In zh, this message translates to:
  /// **'时间范围'**
  String get searchFilterTime;

  /// No description provided for @searchFilterProvider.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get searchFilterProvider;

  /// No description provided for @searchFilterModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get searchFilterModel;

  /// No description provided for @searchFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get searchFilterAll;

  /// No description provided for @searchFilterToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get searchFilterToday;

  /// No description provided for @searchFilterWeek.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天'**
  String get searchFilterWeek;

  /// No description provided for @searchFilterMonth.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get searchFilterMonth;

  /// No description provided for @searchFilterYear.
  ///
  /// In zh, this message translates to:
  /// **'近一年'**
  String get searchFilterYear;

  /// No description provided for @searchExportResults.
  ///
  /// In zh, this message translates to:
  /// **'导出结果'**
  String get searchExportResults;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 条结果'**
  String searchExported(String count);

  /// No description provided for @kbDebugTitle.
  ///
  /// In zh, this message translates to:
  /// **'检索测试台'**
  String get kbDebugTitle;

  /// No description provided for @kbDebugQuery.
  ///
  /// In zh, this message translates to:
  /// **'检索词'**
  String get kbDebugQuery;

  /// No description provided for @kbDebugTopK.
  ///
  /// In zh, this message translates to:
  /// **'返回条数'**
  String get kbDebugTopK;

  /// No description provided for @kbDebugSimilarity.
  ///
  /// In zh, this message translates to:
  /// **'相似度阈值'**
  String get kbDebugSimilarity;

  /// No description provided for @kbDebugChunkSize.
  ///
  /// In zh, this message translates to:
  /// **'分块大小（覆盖，不落库）'**
  String get kbDebugChunkSize;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'向量命中 {count}'**
  String kbDebugVectorHits(String count);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'关键词命中 {count}'**
  String kbDebugBigramHits(String count);

  /// No description provided for @kbDebugNoHits.
  ///
  /// In zh, this message translates to:
  /// **'无命中'**
  String get kbDebugNoHits;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'分数 {score}'**
  String kbDebugScore(String score);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'来源：{source}'**
  String kbDebugSource(String source);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'文档 {id}'**
  String kbDebugDocId(String id);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'第 {rank} 位'**
  String kbDebugRank(String rank);

  /// No description provided for @worldBookNewBook.
  ///
  /// In zh, this message translates to:
  /// **'新建世界书'**
  String get worldBookNewBook;

  /// No description provided for @worldBookName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get worldBookName;

  /// No description provided for @worldBookDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get worldBookDescription;

  /// No description provided for @worldBookActive.
  ///
  /// In zh, this message translates to:
  /// **'激活'**
  String get worldBookActive;

  /// No description provided for @worldBookActivateForAgent.
  ///
  /// In zh, this message translates to:
  /// **'为 Agent 激活'**
  String get worldBookActivateForAgent;

  /// No description provided for @worldBookHitTest.
  ///
  /// In zh, this message translates to:
  /// **'命中测试'**
  String get worldBookHitTest;

  /// No description provided for @worldBookHitTestInput.
  ///
  /// In zh, this message translates to:
  /// **'输入文本来测试匹配'**
  String get worldBookHitTestInput;

  /// No description provided for @worldBookHitTestNoHit.
  ///
  /// In zh, this message translates to:
  /// **'无命中条目'**
  String get worldBookHitTestNoHit;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'命中 {count} 条，注入 {chars} 字符'**
  String worldBookHitTestHit(String chars, String count);

  /// No description provided for @worldBookGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get worldBookGlobal;

  /// No description provided for @voiceServicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'语音服务'**
  String get voiceServicesTitle;

  /// No description provided for @voiceTtsSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统 TTS'**
  String get voiceTtsSystem;

  /// No description provided for @voiceTtsProviders.
  ///
  /// In zh, this message translates to:
  /// **'网络 TTS'**
  String get voiceTtsProviders;

  /// No description provided for @voiceTtsProviderName.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get voiceTtsProviderName;

  /// No description provided for @voiceTtsVoice.
  ///
  /// In zh, this message translates to:
  /// **'音色'**
  String get voiceTtsVoice;

  /// No description provided for @voiceTtsRate.
  ///
  /// In zh, this message translates to:
  /// **'语速'**
  String get voiceTtsRate;

  /// No description provided for @voiceTtsModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get voiceTtsModel;

  /// No description provided for @voiceTtsPreview.
  ///
  /// In zh, this message translates to:
  /// **'试听'**
  String get voiceTtsPreview;

  /// No description provided for @voiceTtsPreviewing.
  ///
  /// In zh, this message translates to:
  /// **'试听中…'**
  String get voiceTtsPreviewing;

  /// No description provided for @voiceTtsAddProvider.
  ///
  /// In zh, this message translates to:
  /// **'添加 TTS 服务'**
  String get voiceTtsAddProvider;

  /// No description provided for @voiceTtsTestOk.
  ///
  /// In zh, this message translates to:
  /// **'试听完成'**
  String get voiceTtsTestOk;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'试听失败：{detail}'**
  String voiceTtsTestFail(String detail);

  /// No description provided for @voiceTtsFallbackSystem.
  ///
  /// In zh, this message translates to:
  /// **'未配置网络 TTS，回退系统朗读'**
  String get voiceTtsFallbackSystem;

  /// No description provided for @voiceAsrTitle.
  ///
  /// In zh, this message translates to:
  /// **'语音输入（ASR）'**
  String get voiceAsrTitle;

  /// No description provided for @voiceAsrSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统语音识别'**
  String get voiceAsrSystem;

  /// No description provided for @voiceAsrCloud.
  ///
  /// In zh, this message translates to:
  /// **'云端识别'**
  String get voiceAsrCloud;

  /// No description provided for @voiceAsrLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地离线识别'**
  String get voiceAsrLocal;

  /// No description provided for @voiceAsrListening.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听…'**
  String get voiceAsrListening;

  /// No description provided for @voiceAsrDone.
  ///
  /// In zh, this message translates to:
  /// **'识别完成'**
  String get voiceAsrDone;

  /// No description provided for @voiceAsrCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get voiceAsrCancelled;

  /// No description provided for @voiceAsrNoPermission.
  ///
  /// In zh, this message translates to:
  /// **'没有麦克风权限'**
  String get voiceAsrNoPermission;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'识别失败：{detail}'**
  String voiceAsrError(String detail);

  /// No description provided for @voiceAsrUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不支持语音输入'**
  String get voiceAsrUnavailable;

  /// No description provided for @voiceAsrTapToSpeak.
  ///
  /// In zh, this message translates to:
  /// **'点击开始说话'**
  String get voiceAsrTapToSpeak;

  /// No description provided for @voiceModelDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载模型'**
  String get voiceModelDownload;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'下载中 {percent}%'**
  String voiceModelDownloading(String percent);

  /// No description provided for @voiceModelInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get voiceModelInstalled;

  /// No description provided for @voiceModelDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除模型'**
  String get voiceModelDelete;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{size}'**
  String voiceModelSize(String size);

  /// No description provided for @mcpTransport.
  ///
  /// In zh, this message translates to:
  /// **'传输方式'**
  String get mcpTransport;

  /// No description provided for @mcpTransportHttp.
  ///
  /// In zh, this message translates to:
  /// **'Streamable HTTP'**
  String get mcpTransportHttp;

  /// No description provided for @mcpTransportSse.
  ///
  /// In zh, this message translates to:
  /// **'SSE'**
  String get mcpTransportSse;

  /// No description provided for @mcpTransportStdio.
  ///
  /// In zh, this message translates to:
  /// **'STDIO（本地进程）'**
  String get mcpTransportStdio;

  /// No description provided for @mcpStdioCommand.
  ///
  /// In zh, this message translates to:
  /// **'命令'**
  String get mcpStdioCommand;

  /// No description provided for @mcpStdioArgs.
  ///
  /// In zh, this message translates to:
  /// **'参数（每行一个）'**
  String get mcpStdioArgs;

  /// No description provided for @mcpStdioEnv.
  ///
  /// In zh, this message translates to:
  /// **'环境变量（KEY=VALUE，每行一个）'**
  String get mcpStdioEnv;

  /// No description provided for @mcpStdioCwd.
  ///
  /// In zh, this message translates to:
  /// **'工作目录（可选）'**
  String get mcpStdioCwd;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'找不到命令 {command}，请检查 PATH'**
  String mcpCommandNotFound(String command);

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'stderr：{line}'**
  String mcpStdioStderr(String line);

  /// No description provided for @mcpAuthorize.
  ///
  /// In zh, this message translates to:
  /// **'授权'**
  String get mcpAuthorize;

  /// No description provided for @mcpReauthorize.
  ///
  /// In zh, this message translates to:
  /// **'重新授权'**
  String get mcpReauthorize;

  /// No description provided for @mcpAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'已授权'**
  String get mcpAuthorized;

  /// No description provided for @mcpNotAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get mcpNotAuthorized;

  /// No description provided for @mcpOAuthInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在打开授权页面…'**
  String get mcpOAuthInProgress;

  /// No description provided for @mcpOAuthDone.
  ///
  /// In zh, this message translates to:
  /// **'授权成功'**
  String get mcpOAuthDone;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'授权失败：{detail}'**
  String mcpOAuthFailed(String detail);

  /// No description provided for @mcpOAuthServerFound.
  ///
  /// In zh, this message translates to:
  /// **'发现授权服务器'**
  String get mcpOAuthServerFound;

  /// No description provided for @mcpOAuthTokenRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'令牌已刷新'**
  String get mcpOAuthTokenRefreshed;

  /// No description provided for @approvalWhitelist.
  ///
  /// In zh, this message translates to:
  /// **'免审批白名单（工具名，每行一个）'**
  String get approvalWhitelist;

  /// No description provided for @approvalBlacklist.
  ///
  /// In zh, this message translates to:
  /// **'强制审批黑名单（工具名，每行一个）'**
  String get approvalBlacklist;

  /// No description provided for @approvalTimeout.
  ///
  /// In zh, this message translates to:
  /// **'审批超时（秒）'**
  String get approvalTimeout;

  /// No description provided for @approvalRememberSession.
  ///
  /// In zh, this message translates to:
  /// **'本次会话记住'**
  String get approvalRememberSession;

  /// No description provided for @toolExecuting.
  ///
  /// In zh, this message translates to:
  /// **'执行中'**
  String get toolExecuting;

  /// No description provided for @toolDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get toolDone;

  /// No description provided for @toolError.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get toolError;

  /// No description provided for @toolDetail.
  ///
  /// In zh, this message translates to:
  /// **'工具详情'**
  String get toolDetail;

  /// No description provided for @toolArguments.
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get toolArguments;

  /// No description provided for @toolResult.
  ///
  /// In zh, this message translates to:
  /// **'结果'**
  String get toolResult;

  /// No description provided for @toolResultTruncated.
  ///
  /// In zh, this message translates to:
  /// **'（结果过长已截断）'**
  String get toolResultTruncated;

  /// No description provided for @toolApprove.
  ///
  /// In zh, this message translates to:
  /// **'同意'**
  String get toolApprove;

  /// No description provided for @toolReject.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get toolReject;

  /// No description provided for @toolWaitingApproval.
  ///
  /// In zh, this message translates to:
  /// **'等待审批'**
  String get toolWaitingApproval;

  /// No description provided for @toolShowDetail.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get toolShowDetail;

  /// No description provided for @toolHideDetail.
  ///
  /// In zh, this message translates to:
  /// **'收起详情'**
  String get toolHideDetail;

  /// No description provided for @restoreModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复模式'**
  String get restoreModeTitle;

  /// No description provided for @restoreModeOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'整体覆盖（推荐）'**
  String get restoreModeOverwrite;

  /// No description provided for @restoreModeMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并（保留现有数据）'**
  String get restoreModeMerge;

  /// No description provided for @restoreModeHint.
  ///
  /// In zh, this message translates to:
  /// **'覆盖模式将替换全部本地数据；合并模式保留现有会话与服务商'**
  String get restoreModeHint;

  /// No description provided for @restorePreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复…'**
  String get restorePreparing;

  /// No description provided for @restoreDone.
  ///
  /// In zh, this message translates to:
  /// **'恢复完成'**
  String get restoreDone;

  /// No description provided for @restoreRolledBack.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败，已回滚到原数据'**
  String get restoreRolledBack;

  /// No description provided for @restoreCorrupt.
  ///
  /// In zh, this message translates to:
  /// **'备份包损坏或校验失败'**
  String get restoreCorrupt;

  /// No description provided for @restoreResume.
  ///
  /// In zh, this message translates to:
  /// **'检测到未完成的恢复，正在收敛…'**
  String get restoreResume;

  /// No description provided for @shareQrTab.
  ///
  /// In zh, this message translates to:
  /// **'二维码'**
  String get shareQrTab;

  /// No description provided for @scanQrTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫码导入'**
  String get scanQrTitle;

  /// No description provided for @scanQrCameraPermission.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限以扫描二维码'**
  String get scanQrCameraPermission;

  /// No description provided for @scanQrInvalid.
  ///
  /// In zh, this message translates to:
  /// **'无法识别的二维码内容'**
  String get scanQrInvalid;

  /// No description provided for @scanQrProviderImported.
  ///
  /// In zh, this message translates to:
  /// **'服务商导入成功'**
  String get scanQrProviderImported;

  /// No description provided for @tagsTitle.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get tagsTitle;

  /// No description provided for @tagsAdd.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get tagsAdd;

  /// No description provided for @tagsName.
  ///
  /// In zh, this message translates to:
  /// **'标签名'**
  String get tagsName;

  /// No description provided for @tagsColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get tagsColor;

  /// No description provided for @tagsApply.
  ///
  /// In zh, this message translates to:
  /// **'打标签'**
  String get tagsApply;

  /// No description provided for @tagsFilter.
  ///
  /// In zh, this message translates to:
  /// **'按标签筛选'**
  String get tagsFilter;

  /// No description provided for @tagsNone.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get tagsNone;

  /// No description provided for @tagsManage.
  ///
  /// In zh, this message translates to:
  /// **'管理标签'**
  String get tagsManage;

  /// No description provided for @statsHeatmapTitle.
  ///
  /// In zh, this message translates to:
  /// **'活跃热力图'**
  String get statsHeatmapTitle;

  /// No description provided for @statsHeatmapLegend.
  ///
  /// In zh, this message translates to:
  /// **'少 → 多'**
  String get statsHeatmapLegend;

  /// No description provided for @statsTrendTitle.
  ///
  /// In zh, this message translates to:
  /// **'趋势'**
  String get statsTrendTitle;

  /// No description provided for @statsRankProviders.
  ///
  /// In zh, this message translates to:
  /// **'服务商排行'**
  String get statsRankProviders;

  /// No description provided for @statsRankModels.
  ///
  /// In zh, this message translates to:
  /// **'模型排行'**
  String get statsRankModels;

  /// No description provided for @statsRankSessions.
  ///
  /// In zh, this message translates to:
  /// **'会话排行'**
  String get statsRankSessions;

  /// No description provided for @statsViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get statsViewAll;

  /// No description provided for @statsRangeAllTime.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get statsRangeAllTime;

  /// No description provided for @statsRangeLast30.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get statsRangeLast30;

  /// No description provided for @statsRangePrevMonth.
  ///
  /// In zh, this message translates to:
  /// **'上一月'**
  String get statsRangePrevMonth;

  /// No description provided for @statsRangeCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get statsRangeCustom;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'{count} 条消息'**
  String statsMessages(String count);

  /// No description provided for @displayFontFamily.
  ///
  /// In zh, this message translates to:
  /// **'界面字体'**
  String get displayFontFamily;

  /// No description provided for @displayFontSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get displayFontSystem;

  /// No description provided for @displayCodeFont.
  ///
  /// In zh, this message translates to:
  /// **'代码字体'**
  String get displayCodeFont;

  /// No description provided for @displayUiDensity.
  ///
  /// In zh, this message translates to:
  /// **'界面密度'**
  String get displayUiDensity;

  /// No description provided for @densityCompact.
  ///
  /// In zh, this message translates to:
  /// **'紧凑'**
  String get densityCompact;

  /// No description provided for @densityStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get densityStandard;

  /// No description provided for @densityComfortable.
  ///
  /// In zh, this message translates to:
  /// **'宽松'**
  String get densityComfortable;

  /// No description provided for @displayChatFontScale.
  ///
  /// In zh, this message translates to:
  /// **'聊天字号'**
  String get displayChatFontScale;

  /// No description provided for @fontImportLocal.
  ///
  /// In zh, this message translates to:
  /// **'导入本地字体文件'**
  String get fontImportLocal;

  /// No description provided for @fontImported.
  ///
  /// In zh, this message translates to:
  /// **'字体已导入'**
  String get fontImported;

  /// No description provided for @androidBackgroundMode.
  ///
  /// In zh, this message translates to:
  /// **'后台生成'**
  String get androidBackgroundMode;

  /// No description provided for @androidBackgroundOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get androidBackgroundOff;

  /// No description provided for @androidBackgroundOn.
  ///
  /// In zh, this message translates to:
  /// **'开启'**
  String get androidBackgroundOn;

  /// No description provided for @androidBackgroundOnNotify.
  ///
  /// In zh, this message translates to:
  /// **'开启并通知'**
  String get androidBackgroundOnNotify;

  /// No description provided for @androidBackgroundHint.
  ///
  /// In zh, this message translates to:
  /// **'开启后锁屏/退后台时保持生成不中断'**
  String get androidBackgroundHint;

  /// No description provided for @notificationChatCompleted.
  ///
  /// In zh, this message translates to:
  /// **'生成完成'**
  String get notificationChatCompleted;

  /// No description provided for @notificationChatFailed.
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get notificationChatFailed;

  /// No description provided for @desktopAutostart.
  ///
  /// In zh, this message translates to:
  /// **'开机自启'**
  String get desktopAutostart;

  /// No description provided for @desktopAutostartHint.
  ///
  /// In zh, this message translates to:
  /// **'登录系统时自动启动 Nona'**
  String get desktopAutostartHint;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'设置自启失败：{detail}'**
  String desktopAutostartError(String detail);

  /// No description provided for @deeplinkChatTitle.
  ///
  /// In zh, this message translates to:
  /// **'来自外部链接'**
  String get deeplinkChatTitle;

  /// No description provided for @devColdStartTiming.
  ///
  /// In zh, this message translates to:
  /// **'冷启动耗时（毫秒）'**
  String get devColdStartTiming;

  /// No description provided for @chatOpenDocument.
  ///
  /// In zh, this message translates to:
  /// **'打开文本文档'**
  String get chatOpenDocument;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'请用简洁的中文总结以下对话的要点，保留关键结论、决定与待办，不超过 300 字：\n\n{source}'**
  String contextSummaryPrompt(String source);

  /// No description provided for @providerAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'已导入（认证信息已加密保存）'**
  String get providerAuthorized;

  /// No description provided for @commonAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get commonAuto;

  /// placeholder
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个分块'**
  String kbChunkCount(String count);

  /// No description provided for @ttsSpeakSelection.
  ///
  /// In zh, this message translates to:
  /// **'朗读所选'**
  String get ttsSpeakSelection;

  /// No description provided for @ttsFloatingPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get ttsFloatingPaused;

  /// No description provided for @ttsFloatingSpeaking.
  ///
  /// In zh, this message translates to:
  /// **'朗读中'**
  String get ttsFloatingSpeaking;

  /// No description provided for @ttsFloatingPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get ttsFloatingPause;

  /// No description provided for @ttsFloatingResume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get ttsFloatingResume;

  /// No description provided for @ttsFloatingStop.
  ///
  /// In zh, this message translates to:
  /// **'停止朗读'**
  String get ttsFloatingStop;

  /// No description provided for @ttsFloatingSpeed.
  ///
  /// In zh, this message translates to:
  /// **'速度'**
  String get ttsFloatingSpeed;

  /// No description provided for @offlineBadge.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get offlineBadge;

  /// No description provided for @voiceSherpaSelected.
  ///
  /// In zh, this message translates to:
  /// **'当前使用'**
  String get voiceSherpaSelected;

  /// No description provided for @voiceSherpaUse.
  ///
  /// In zh, this message translates to:
  /// **'设为默认'**
  String get voiceSherpaUse;

  /// No description provided for @voiceSherpaNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装（需下载模型）'**
  String get voiceSherpaNotInstalled;

  /// No description provided for @voiceSherpaHint.
  ///
  /// In zh, this message translates to:
  /// **'下载模型后完全离线可用：识别走本地 ONNX 推理，不发送任何音频到云端。'**
  String get voiceSherpaHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

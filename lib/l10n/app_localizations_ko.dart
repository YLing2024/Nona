// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutCopyright =>
      'Copyright © 2026 Yunling Zhang · 本地优先，所有数据仅保存在本机';

  @override
  String get aboutDeveloperMode => '开发者模式';

  @override
  String get aboutDeveloperModeHint => '启用后，设置页将显示「开发者选项」高级设置';

  @override
  String get aboutDeveloperSection => '开发者';

  @override
  String get aboutGithub => 'GitHub 仓库';

  @override
  String get aboutLicense => '开源许可';

  @override
  String get aboutPlatform => '系统';

  @override
  String get aboutTagline => '一款简洁高效的 AI 聊天客户端，兼容 OpenAI 格式接口';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutVersion => '版本';

  @override
  String get accentIndigo => '靛蓝';

  @override
  String get accentOrange => '橙';

  @override
  String get accentRed => '赤红';

  @override
  String get accentRose => '玫红';

  @override
  String get accentSky => '天蓝';

  @override
  String get accentSlate => '青灰';

  @override
  String get accentTeal => '青绿';

  @override
  String get accentViolet => '紫罗兰';

  @override
  String get addModelApiKeyRequired => '请先填写 API Key';

  @override
  String get addModelExample => '例如：gpt-4o';

  @override
  String get addModelFetch => '获取模型列表';

  @override
  String addModelFetchFailed(String detail) {
    return '获取模型列表失败：$detail';
  }

  @override
  String get addModelFetchFromList => '从列表获取';

  @override
  String get addModelFetchHint => '调用 /models 接口获取可用模型\\n获取前请先填写 API Key';

  @override
  String get addModelManual => '手动输入';

  @override
  String get addModelManualHint => '填写一个模型 ID';

  @override
  String get addModelNoModels => '该接口未返回任何模型';

  @override
  String get addModelReasoningHint => '推理模型支持思考模式';

  @override
  String get addModelTitle => '添加模型';

  @override
  String get agentAdd => '添加 Agent';

  @override
  String get agentConfigTitle => 'Agent 配置';

  @override
  String get agentDefault => '默认';

  @override
  String get agentDefaultHint => '单击「新建会话」时自动套用该配置';

  @override
  String get agentDefaultParams => '默认参数';

  @override
  String get agentDefaultSystemPrompt =>
      '你是 Nona，一款简洁高效的 AI 聊天助手。请用简体中文、以清晰友好的语气回应用户，回答问题力求准确、有条理；当需求不明确时可以适当追问，但不要过度。除非用户特别要求，否则默认使用中文回答。';

  @override
  String agentDeleteConfirm(String name) {
    return '删除 Agent「$name」？';
  }

  @override
  String get agentDeleteTitle => '删除 Agent';

  @override
  String get agentEdit => '编辑 Agent';

  @override
  String get agentEmpty => '暂无 Agent，点右上角添加';

  @override
  String get agentMemories => '长期记忆（每行一条）';

  @override
  String get agentMemoriesHint => '例：用户偏好简洁的回答风格';

  @override
  String get agentName => '名称';

  @override
  String get agentNameHint => '例如：代码助手、翻译官等';

  @override
  String get agentNameRequired => '请填写 Agent 名称';

  @override
  String get agentNew => '新建 Agent';

  @override
  String get agentSetDefault => '设为默认 Agent';

  @override
  String get appTitle => 'Nona';

  @override
  String get chatClearInput => '清空';

  @override
  String chatContextUsage(String tokens) {
    return '上下文 $tokens';
  }

  @override
  String get chatCopyMarkdown => '复制为 Markdown';

  @override
  String get chatDeleteSession => '删除会话';

  @override
  String get chatDeleteSelectedTitle => '删除所选消息';

  @override
  String chatDeleteSelectedBody(int count) {
    return '将删除所选 $count 条消息及其后的所有消息，且不可恢复。确定继续吗？';
  }

  @override
  String get chatDelete => '删除';

  @override
  String chatDeleted(int count) {
    return '已删除 $count 条消息';
  }

  @override
  String get tokenDetailTitle => 'Token 明细';

  @override
  String get tokenDetailInput => '输入（接口）';

  @override
  String get tokenDetailOutput => '输出（接口）';

  @override
  String get tokenDetailElapsed => '耗时';

  @override
  String get tokenDetailModel => '模型';

  @override
  String get tokenDetailEstimated => '本地估算（正文）';

  @override
  String get tokenDetailCost => '成本';

  @override
  String get tokenDetailUnavailable => '—';

  @override
  String get tokenDetailNoPrice => '价格未收录';

  @override
  String get tokenDetailHint => '本地估算为回复正文的 tiktoken 精确计数（不含提示词）。';

  @override
  String get quickPhrasesTitle => '快捷短语';

  @override
  String get quickPhrasesAdd => '新增短语';

  @override
  String get quickPhrasesEdit => '编辑短语';

  @override
  String get quickPhrasesEmpty => '还没有快捷短语，点击右下角新增';

  @override
  String get quickPhrasesContent => '内容';

  @override
  String get quickPhrasesGlobal => '全局可用（所有会话）';

  @override
  String get settingsQuickPhrasesSubtitle => '输入框输入 / 快速插入';

  @override
  String get quickPhrasesDeleteTitle => '删除快捷短语';

  @override
  String quickPhrasesDeleteBody(String title) {
    return '将删除「$title」。确定继续吗？';
  }

  @override
  String get quickPhrasesDeleted => '已删除';

  @override
  String get iiTitle => '指令注入';

  @override
  String get iiAdd => '新增指令';

  @override
  String get iiEdit => '编辑指令';

  @override
  String get iiEmpty => '还没有指令，点击右下角新增（勾选即激活）';

  @override
  String get iiPrompt => '指令内容';

  @override
  String get iiGroup => '分组（可选）';

  @override
  String get iiDeleteTitle => '删除指令';

  @override
  String iiDeleteBody(String title) {
    return '将删除「$title」。确定继续吗？';
  }

  @override
  String get settingsIiSubtitle => '自定义提示词片段，随请求注入';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String get updateVersion => '版本';

  @override
  String get updateDownload => '前往下载';

  @override
  String get settingsUpdateCheck => '启动时检查更新';

  @override
  String get settingsUpdateSource => '更新源（GitHub Releases URL）';

  @override
  String get devCrashReporting => '崩溃上报（Sentry）';

  @override
  String get devCrashReportingHint => '启用后异常自动上报（需构建时配置 SENTRY_DSN）；默认关闭';

  @override
  String get wfTitle => '自动化工作流';

  @override
  String get wfAdd => '新建工作流';

  @override
  String get wfEdit => '编辑工作流';

  @override
  String get wfName => '名称';

  @override
  String get wfActionText => '动作（当前仅 send_message 文本；支持 cur_date 变量）';

  @override
  String get wfDeleteTitle => '删除工作流';

  @override
  String wfDeleteBody(String name) {
    return '将删除「$name」。确定继续吗？';
  }

  @override
  String get wfRunSuccess => '工作流执行完成';

  @override
  String get wfRunFailed => '工作流执行失败，见运行历史';

  @override
  String get wfEmpty => '还没有工作流，点击右下角新建';

  @override
  String get wfListTitle => '工作流';

  @override
  String get wfRun => '试运行';

  @override
  String get wfHistoryTitle => '运行历史';

  @override
  String get routerTitle => '模型路由';

  @override
  String get routerEnable => '启用智能模型路由';

  @override
  String get routerEnableHint => '标题/摘要等任务自动按成本与速度选模型（优先低成本）';

  @override
  String get routerNoData => '暂无路由记录——启用后运行任务会在这里展示统计';

  @override
  String get routerRecentStats => '最近 30 天路由统计';

  @override
  String get settingsRouterSubtitle => '按成本与速度自动选模型';

  @override
  String get syncIncrementalTitle => '多设备增量同步';

  @override
  String get syncIncrementalHint => '推送本地变更并拉取其他设备的变更';

  @override
  String get syncIncrementalNow => '立即同步';

  @override
  String syncIncrementalDone(int pushed, int pulled) {
    return '已推送 $pushed 条、拉取 $pulled 条变更';
  }

  @override
  String syncLastAt(String at) {
    return '上次同步：$at';
  }

  @override
  String syncConflicts(int n) {
    return '$n 个冲突待处理（本地较新的变更已保留）';
  }

  @override
  String get privacyTitle => '隐私与离线';

  @override
  String get offlineMode => '离线模式';

  @override
  String get offlineModeHint => '嵌入走本地、不发起网络请求；适合飞行模式或隐私场景';

  @override
  String get offlineCapabilities => '能力离线状态';

  @override
  String get offlineCapEmbedding => '文本嵌入';

  @override
  String get offlineCapKbSearch => '知识库检索';

  @override
  String get offlineCapWebSearch => '网络搜索';

  @override
  String get offlineCapTts => '语音朗读';

  @override
  String get offlineCapAsr => '语音输入（本地）';

  @override
  String get offlineStatusLocal => '本地可用';

  @override
  String get offlineStatusCloud => '云端';

  @override
  String get offlineStatusOff => '已关闭';

  @override
  String get offlineStatusSystem => '系统';

  @override
  String get offlineStatusNeedsDownload => '需下载模型';

  @override
  String get offlineNote =>
      '本地嵌入为确定性哈希向量（384 维），完全离线；接入 ONNX 语义模型后自动升级。语音输入本地模型见语音设置。';

  @override
  String get settingsPrivacySubtitle => '离线模式与本地能力';

  @override
  String get settingsWfSubtitle => '定时 / 事件触发自动执行动作';

  @override
  String get chatDocument => '文档';

  @override
  String chatDocumentFailed(int count) {
    return '$count 个文档解析失败';
  }

  @override
  String chatDocumentSubtitle(int count) {
    return '共 $count 字';
  }

  @override
  String get chatDocumentTitle => '文本文档';

  @override
  String get chatDeleteMessageConfirm => '删除该消息及其后的所有消息？';

  @override
  String get chatEffortAuto => '思考：自动';

  @override
  String get chatEffortAutoShort => '自动';

  @override
  String get chatEffortHigh => '思考：高';

  @override
  String get chatEffortHighShort => '高';

  @override
  String get chatEffortLow => '思考：低';

  @override
  String get chatEffortLowShort => '低';

  @override
  String get chatEffortMedium => '思考：中';

  @override
  String get chatEffortMediumShort => '中';

  @override
  String get chatErrorEmpty => '接口没有返回任何内容，请重试';

  @override
  String get chatErrorInvalidFormat => '接口返回格式无法解析';

  @override
  String get chatErrorMissingContent => '接口返回中缺少回复内容';

  @override
  String get chatErrorStream => '读取响应流失败';

  @override
  String get chatExport => '导出';

  @override
  String get chatExportHtml => '导出为 HTML';

  @override
  String get chatExportJson => '导出为 JSON';

  @override
  String get chatExportMarkdown => '导出为 Markdown';

  @override
  String get chatExportPdf => '导出为 PDF';

  @override
  String get chatGenerating => '正在生成…';

  @override
  String get chatGenerationFailed => '生成失败';

  @override
  String get chatHelloSubtitle => '支持多服务商、多模型，开启一段新的对话吧';

  @override
  String get chatHelloTitle => '你好，我是 Nona';

  @override
  String get chatImage => '图片';

  @override
  String chatImageLoadFailed(Object uri) {
    return '图片加载失败：$uri';
  }

  @override
  String get chatInputHintEnterNewline => '输入消息，Enter 换行，Ctrl+Enter 发送';

  @override
  String get chatInputHintEnterSend => '输入消息，Enter 发送，Shift+Enter 换行';

  @override
  String get chatMermaidUnsupported => 'Mermaid 语法暂不支持，以下为源码';

  @override
  String get chatNewSession => '新建会话';

  @override
  String get chatNoModel => '未配置模型';

  @override
  String get chatNoProvider => '未配置服务商';

  @override
  String get chatOverLimit => '超出上限，发送时将裁剪';

  @override
  String get chatRegenerate => '重新生成';

  @override
  String get chatRollback => '回滚到此处';

  @override
  String chatRollbackVersion(int count) {
    return '回退到上一版（共 $count 版）';
  }

  @override
  String get chatSelectModel => '选择模型';

  @override
  String get chatSessionContext => '会话上下文';

  @override
  String get chatSessionCopySuffix => '（副本）';

  @override
  String get chatSessionList => '会话列表';

  @override
  String get assistantDisplayName => 'Nona';

  @override
  String get citationSourcesTitle => '引用来源';

  @override
  String chatSelectionTitle(int count) {
    return '已选 $count 条';
  }

  @override
  String get chatSelectAll => '全选';

  @override
  String get chatEnterSelection => '选择消息';

  @override
  String get dropBackupUnsupported => '拖入的备份文件暂不支持恢复';

  @override
  String get dropUnsupported => '不支持的文件类型';

  @override
  String get dropFailed => '文件处理失败';

  @override
  String get dropImageTooLarge => '图片超过 8MB，已跳过';

  @override
  String get dropExtractFailed => '文档内容提取失败';

  @override
  String get dropRestoreTitle => '恢复备份';

  @override
  String dropRestoreBody(String file) {
    return '将把 $file 中的会话合并导入当前数据（跳过重复）。确定继续吗？';
  }

  @override
  String get dropRestoreConfirm => '恢复';

  @override
  String dropRestoreDone(int count) {
    return '已恢复 $count 个会话';
  }

  @override
  String get chatInvertSelection => '反选';

  @override
  String chatDeleteSelected(int count) {
    return '删除所选（$count）';
  }

  @override
  String get importSelectSessions => '选择要导入的会话';

  @override
  String get importToggleAll => '全选/全不选';

  @override
  String messageProviderBadge(String provider, String model) {
    return '（$provider · $model）';
  }

  @override
  String get chatSessionNewTitle => '新对话';

  @override
  String orchestratorMemoryPrompt(String content) {
    return '以下是关于用户与该助手的长期记忆，请参考这些信息作答：\n$content';
  }

  @override
  String orchestratorKbPrompt(String content) {
    return '以下是知识库中的相关内容，回答时请优先参考：\n$content';
  }

  @override
  String get orchestratorSearchFailed =>
      '网络搜索失败：免费引擎在部分环境不可用，请在设置中改用 Tavily / Bocha（需 API Key）或自建 SearXNG 服务器';

  @override
  String toolApprovalTitle(String toolName) {
    return '是否允许模型调用工具「$toolName」？';
  }

  @override
  String get toolApprovalAllowOnce => '允许本次';

  @override
  String get toolApprovalAllowRemember => '记住并允许';

  @override
  String get toolApprovalDeny => '拒绝';

  @override
  String get toolApprovalRiskHint => '该工具来自外部服务器，可读取或修改你的数据，请确认参数后决定。';

  @override
  String toolApprovalServer(String serverName) {
    return '来源：$serverName';
  }

  @override
  String get toolApprovalArguments => '参数';

  @override
  String get toolApprovalAutoHint => '已记住该工具的授权，后续调用将自动放行（可在 MCP 设置中撤销）。';

  @override
  String chatShowFull(int count) {
    return '查看全文（$count 字）';
  }

  @override
  String get chatSpeak => '朗读';

  @override
  String get chatStopSpeaking => '停止朗读';

  @override
  String get chatStopped => '已停止生成';

  @override
  String get chatStream => '流式';

  @override
  String get chatThinking => '思考过程';

  @override
  String get chatTokensDown => '下行 Token（累计生成）';

  @override
  String get chatTokensUp => '上行 Token（累计发送）';

  @override
  String get commonAdd => '添加';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDiscard => '仍要返回';

  @override
  String get commonWarning => '警告';

  @override
  String get commonClear => '清空';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonCopy => '复制';

  @override
  String get commonDefault => '默认';

  @override
  String get commonDelete => '删除';

  @override
  String get commonDeleted => '已删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonFailed => '失败';

  @override
  String get commonFailedTest => '测试失败';

  @override
  String get commonImport => '导入';

  @override
  String get commonMe => '我';

  @override
  String get commonNone => '无';

  @override
  String get commonNotSpecified => '不指定';

  @override
  String get commonNotTested => '未测试';

  @override
  String get commonOff => '已关闭';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonRemove => '移除';

  @override
  String get commonReset => '重置';

  @override
  String get commonRestore => '恢复';

  @override
  String get commonRetry => '重试';

  @override
  String get loadFailedBanner => '数据加载失败，已尝试恢复';

  @override
  String get commonSave => '保存';

  @override
  String get commonSend => '发送';

  @override
  String get commonSaveFailed => '保存失败，请重试';

  @override
  String get commonSaved => '已保存';

  @override
  String get commonStop => '停止';

  @override
  String get commonUnknownError => '未知错误';

  @override
  String get commonUnlimited => '不限制';

  @override
  String get commonUntested => '尚未测试';

  @override
  String get compareEmpty => '选择至少一个模型并输入问题';

  @override
  String get compareFailed => '生成失败';

  @override
  String get compareHint => '输入问题，选择多个模型后开始对比…';

  @override
  String get compareRunning => '对比中…';

  @override
  String get compareStart => '开始对比';

  @override
  String get compareTitle => '模型对比';

  @override
  String get compareWaiting => '等待响应…';

  @override
  String get contextAutoTrim => '自动裁剪早期消息';

  @override
  String get contextAutoTrimHint => '超出上限时自动移除最早的对话记录';

  @override
  String get contextCommaSeparated => '多个用英文逗号分隔';

  @override
  String get contextCustom => '自定义（手动配置）';

  @override
  String get contextFrequencyPenalty => 'Frequency Penalty 频率惩罚';

  @override
  String get contextFrequencyPenaltyTip =>
      '对 token 在文本中出现频率施加惩罚，取值范围 -2~2。\\n\\n值越大，越能抑制整段重复与套话。';

  @override
  String get contextInfoGotIt => '知道了';

  @override
  String get contextInfoTitle => '说明';

  @override
  String get contextMaxContext => '上下文窗口管理';

  @override
  String get contextMaxContextHint => '≤32000，留空表示不限制';

  @override
  String get contextMaxContextTip =>
      '控制发送给模型的对话历史长度：\\n\\n· 最大上下文：超出该 token 数时按策略处理，留空表示不限制\\n· 自动裁剪：发送前估算对话长度，超限时自动移除最早的消息\\n\\n可避免长对话超出发送方的上下文窗口上限，节省费用并防止报错。';

  @override
  String get contextMaxTokens => 'Max Tokens 最大输出长度';

  @override
  String get contextMaxTokensHint => '留空由服务端决定';

  @override
  String get contextMaxTokensTip =>
      '单次回复最多生成的 token 数，超出部分会被截断。\\n\\n留空表示由服务端按模型上限决定。';

  @override
  String get contextN => 'N 候选数量';

  @override
  String get contextNHint => '留空使用默认值 1';

  @override
  String get contextNTip =>
      '一次请求生成几条候选回复，默认 1。\\n\\n大于 1 时接口会返回多条，由你自行选择使用哪一条，会增加 token 消耗。';

  @override
  String get contextNoAgent => '还没有 Agent，可到「设置 → Agent 配置」中创建预设，方便快速套用。';

  @override
  String get contextPresencePenalty => 'Presence Penalty 话题新鲜度惩罚';

  @override
  String get contextPresencePenaltyTip =>
      '对已出现过的 token 施加惩罚，取值范围 -2~2。\\n\\n值越大，越鼓励模型讨论新话题、避免简单重复已有内容。';

  @override
  String get contextQuickConfig => '快捷配置';

  @override
  String get contextResponseFormat => 'Response Format 响应格式';

  @override
  String get contextResponseFormatJson => 'JSON (json_object)';

  @override
  String get contextResponseFormatJsonShort => 'JSON';

  @override
  String get contextResponseFormatText => '文本 (text)';

  @override
  String get contextResponseFormatTextShort => '文本';

  @override
  String get contextResponseFormatTip =>
      '期望模型输出的格式：\\n\\n· 不指定：默认文本\\n· 文本 (text)：普通文本\\n· JSON (json_object)：模型只输出合法 JSON，方便程序解析\\n\\n部分模型不支持 JSON 模式，请以服务商文档为准。';

  @override
  String get contextSavedNote => '参数随会话保存，仅对当前会话生效。';

  @override
  String get contextSeed => 'Seed 随机种子';

  @override
  String get contextSeedHint => '留空表示随机';

  @override
  String get contextSeedTip =>
      '设置随机种子后，相同种子与相同输入在多数服务端可复现出相似的结果，方便调试与对比。\\n\\n留空表示随机。';

  @override
  String get contextStop => 'Stop 停止序列';

  @override
  String get contextStopTip =>
      '模型生成到该字符串时会立即停止输出。\\n\\n多个序列用英文逗号分隔，例如：\\n\\n,。！？\\n\\n留空表示不使用停止序列。';

  @override
  String get contextSystemPrompt => '系统提示词';

  @override
  String get contextSystemPromptHint => '可选，设定助手的角色与行为';

  @override
  String get contextSystemPromptTip =>
      '设定助手的角色、风格与行为准则，会作为 system 消息放在对话最前面，影响整个会话的回复基调。';

  @override
  String get contextTemperature => 'Temperature 采样温度';

  @override
  String get contextTemperatureHint => '留空使用默认值 1';

  @override
  String get contextTemperatureTip =>
      '控制输出的随机程度，取值范围 0~2。\\n\\n值越高，输出越发散、更有创造力；值越低，输出越稳定、保守、可预测。需要稳定的回答建议调低。';

  @override
  String get contextTitle => '会话上下文';

  @override
  String get contextTopP => 'Top P 核采样';

  @override
  String get contextTopPHint => '留空使用默认值 1';

  @override
  String get contextTopPTip =>
      '只从累计概率达到该值的 token 集合中采样，取值范围 0~1。\\n\\n与 Temperature 二选一调整即可，一般不建议同时大幅调整两者。';

  @override
  String get devAutoUpdate => '启动时自动更新';

  @override
  String get devAutoUpdateHint => '应用启动时静默从网络更新映射表，失败不影响使用';

  @override
  String devBuiltinVersion(String version) {
    return '内置版本 $version';
  }

  @override
  String get devCapabilityDesc =>
      '内置静态表（离线兜底）+ 联网更新缓存，用于按模型 id 自动填充「多模态 / 推理」配置';

  @override
  String get devCapabilitySection => '模型能力映射表';

  @override
  String get devCapabilityTitle => '模型能力映射表';

  @override
  String get devConnectivitySection => '连通性设置';

  @override
  String get devMaxLogs => '最大保留条数';

  @override
  String get devMaxLogsExample => '例如：1000';

  @override
  String get devMaxLogsInvalid => '请输入非负整数';

  @override
  String get devMaxLogsLabel => '条数（留空为无限）';

  @override
  String devMaxLogsSubtitle(int count) {
    return '最多保留 $count 条（0 为不限）';
  }

  @override
  String get devMaxLogsTitle => '最大保留条数';

  @override
  String get devMaxLogsUnlimited => '无限，全部记录保留';

  @override
  String get devNetworkLog => '网络日志';

  @override
  String devNetworkLogCount(int count) {
    return '已记录 $count 条';
  }

  @override
  String get devNetworkLogDisabled => '未启用记录，开启后自动捕获请求';

  @override
  String get devNetworkLogEnable => '启用网络日志';

  @override
  String get devNetworkLogEnableHint => '记录应用内全部网络请求（含聊天、测速、拉取模型等）';

  @override
  String get devNetworkLogSection => '网络日志';

  @override
  String get devNoBuiltinTable => '无内置映射表';

  @override
  String get devTestPrompt => '连通性测试提示词';

  @override
  String get devTestPromptExample => '例如：ping';

  @override
  String get devTestPromptHint => '模型连通性测试时发送给模型的最小请求内容';

  @override
  String get devTitle => '开发者选项';

  @override
  String devUpdateFailed(Object error) {
    return '更新失败：$error';
  }

  @override
  String get devUpdateFromNetwork => '从网络更新';

  @override
  String get devUpdated => '模型能力表更新完成';

  @override
  String devUpdatedAt(String time) {
    return '更新时间 $time';
  }

  @override
  String get devUpdating => '正在更新…';

  @override
  String get devUpdatingShort => '更新中';

  @override
  String get devWarning => '开发者选项包含高风险设置，仅建议高级用户使用，请谨慎修改。';

  @override
  String get homeAnonymousSession => '匿名会话';

  @override
  String get homeCopied => '已复制到剪贴板';

  @override
  String get homeCopiedMarkdown => '已复制为 Markdown';

  @override
  String get homeCopiedSession => '已复制会话';

  @override
  String homeDeleteSessionConfirm(String title) {
    return '确定删除会话「$title」？';
  }

  @override
  String homeExportedTo(String path) {
    return '已导出到 $path';
  }

  @override
  String get homeImageTooLargeSkippedAll => '图片超过 8MB，已跳过';

  @override
  String get homeImageTooLargeSkippedSome => '部分图片超过 8MB，已跳过';

  @override
  String get homeModelMismatch => '当前服务商不包含该模型，请到设置中检查';

  @override
  String get homeNetworkError => '网络请求失败，请检查网络或配置';

  @override
  String get homeNoApiKey => '请先完善服务商的 API Key';

  @override
  String get homeNoModel => '请先选择模型';

  @override
  String get homeNoProvider => '请先在设置中配置服务商';

  @override
  String get homeRenameSession => '重命名会话';

  @override
  String get homeRollbackConfirm => '确定回滚';

  @override
  String get homeRollbackContent =>
      '将删除该消息及其之后的所有消息，并把内容回填到输入框，以便修改后重新发送。确定继续吗？';

  @override
  String get homeRollbackTitle => '回滚到此处';

  @override
  String get homeSessionNameHint => '会话名称';

  @override
  String get homeTitlePrompt => '为用户的对话生成一个简洁的标题（不超过 20 个字，不要引号，不要解释，直接输出标题）';

  @override
  String homeTrimmed(int count) {
    return '上下文超限，已自动移除最早 $count 条消息';
  }

  @override
  String homeCompacted(Object count) {
    return '上下文超限，已压缩最早 $count 条消息为摘要（可点击消息列表顶部的压缩条查看）';
  }

  @override
  String summaryCompressed(Object count) {
    return '已压缩 $count 条消息为摘要';
  }

  @override
  String summaryCompressedMessages(Object count) {
    return '被压缩的原始消息（$count 条）：';
  }

  @override
  String get summaryTitle => '会话摘要（注入到每次请求的上下文中）';

  @override
  String get summaryEmpty => '（摘要为空）';

  @override
  String get summaryEdit => '编辑摘要';

  @override
  String get summaryEditHint => '修改后的摘要将替代被压缩消息注入后续请求';

  @override
  String get summaryClear => '清空压缩记录';

  @override
  String get kbAdd => '添加文档';

  @override
  String get kbAddFailed => '没有可添加的内容';

  @override
  String kbAdded(int count) {
    return '已添加 $count 个文档';
  }

  @override
  String get kbEmpty => '知识库为空';

  @override
  String get kbEmptyHint => '点击右上角 + 添加文本文件（txt/md/json 等）';

  @override
  String get kbHint => '对话时会自动检索知识库中相关内容并注入上下文（Agent 可在编辑页绑定知识库）';

  @override
  String get kbCreateLibrary => '新建知识库';

  @override
  String get kbLibraryNameHint => '知识库名称';

  @override
  String get kbRenameLibrary => '重命名知识库';

  @override
  String get kbDeleteLibrary => '删除知识库';

  @override
  String kbDeleteLibraryConfirm(Object name) {
    return '删除知识库「$name」将同时删除其中全部文档，是否继续？';
  }

  @override
  String kbDeleteConfirm(String name) {
    return '删除文档「$name」？';
  }

  @override
  String get kbTitle => '知识库';

  @override
  String get mcpAdd => '添加服务';

  @override
  String mcpDeleteConfirm(String name) {
    return '删除服务「$name」及其工具配置？';
  }

  @override
  String get mcpEdit => '编辑服务';

  @override
  String get mcpEmpty => '尚未配置 MCP 服务';

  @override
  String get mcpEmptyHint => '点击右上角 + 添加（需支持 MCP 协议的服务器地址）';

  @override
  String get mcpHeaders => '请求头（每行一个，Key: Value）';

  @override
  String get mcpHint =>
      'MCP（Model Context Protocol）让模型调用外部工具。支持的服务器：streamable HTTP / SSE。';

  @override
  String get mcpName => '服务名称';

  @override
  String get mcpFieldsRequired => '名称和地址不能为空';

  @override
  String get mcpNeedsApproval => '工具调用需人工确认';

  @override
  String get mcpNeedsApprovalHint => '开启后执行工具前会弹出确认';

  @override
  String get mcpTitle => 'MCP 服务';

  @override
  String get mcpUrl => '服务地址';

  @override
  String get messageEditAssistantHint => '修改回复内容…';

  @override
  String get messageScrollToBottom => '滚动到底部';

  @override
  String get messageEditAssistantLabel => '回复内容';

  @override
  String get messageEditAssistantTitle => '编辑助手回复';

  @override
  String get messageEditNote => '修改后将在后续对话中生效';

  @override
  String get messageEditReasoningHint => '修改模型生成时的思考过程…';

  @override
  String get messageEditReasoningLabel => '思考内容';

  @override
  String get messageEditReasoningNote => '思考内容与回复内容均可修改，修改后将用于后续对话上下文';

  @override
  String get messageEditTitle => '编辑消息';

  @override
  String get messageEditUserHint => '修改消息内容…';

  @override
  String get messageEditUserLabel => '消息内容';

  @override
  String get modelConfigChatModel => '聊天模型';

  @override
  String get modelConfigChatModelDesc => '每次新建会话时默认使用此模型。重置后新建会话需手动选择。';

  @override
  String get modelConfigNoModels => '暂无已配置的模型，请先在服务商中添加';

  @override
  String get modelConfigPickChat => '选择聊天模型';

  @override
  String get modelConfigPickTitle => '选择标题生成模型';

  @override
  String get modelConfigPickTranslator => '选择翻译模型';

  @override
  String get modelConfigResetChatContent => '重置后，新建会话将不再自动选择模型，每次需手动选择。确定继续吗？';

  @override
  String get modelConfigResetChatTitle => '重置聊天默认模型';

  @override
  String get modelConfigResetTitleContent => '重置后，会话标题将维持「取首条消息」的默认逻辑。确定继续吗？';

  @override
  String get modelConfigResetTitleTitle => '重置标题生成模型';

  @override
  String get modelConfigResetTranslatorContent => '重置后，AI 翻译将使用聊天模型进行翻译。确定继续吗？';

  @override
  String get modelConfigResetTranslatorTitle => '重置翻译模型';

  @override
  String get modelConfigSaved => '已保存';

  @override
  String get modelConfigTitle => '模型配置';

  @override
  String get modelConfigTitleModel => '标题生成模型';

  @override
  String get modelConfigTitleModelDesc =>
      '配置后，会话标题将由该模型根据首条消息自动生成；未配置则维持现有「截取首条消息」逻辑。';

  @override
  String get modelConfigTranslatorModel => '翻译模型';

  @override
  String get modelConfigTranslatorModelDesc => '配置后，AI 翻译页将使用此模型；未配置则回退使用聊天模型。';

  @override
  String get modelConfigUnset => '未设置';

  @override
  String get networkLogBasic => '基本信息';

  @override
  String networkLogBodyMeta(String bytes, int lines) {
    return '$bytes · $lines 行';
  }

  @override
  String get networkLogClear => '清空日志';

  @override
  String get networkLogClearConfirm => '将删除全部已记录的网络日志，确定继续吗？';

  @override
  String get networkLogClearTitle => '清空网络日志';

  @override
  String get networkLogCopiedFull => '已复制全文';

  @override
  String get networkLogCopyFull => '复制全文';

  @override
  String networkLogCountLimited(int count, int max) {
    return '共 $count 条记录 · 最多保留 $max 条';
  }

  @override
  String networkLogCountUnlimited(int count) {
    return '共 $count 条记录 · 无限保留';
  }

  @override
  String networkLogDateFull(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String networkLogDateToday(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get networkLogDetailTitle => '日志详情';

  @override
  String get networkLogDuration => '耗时';

  @override
  String get networkLogEditorUnsupported => '当前平台暂不支持在外部编辑器中打开';

  @override
  String get networkLogEmpty => '暂无网络日志';

  @override
  String get networkLogEmptyHint => '回到开发者选项开启「启用网络日志」后自动记录';

  @override
  String get networkLogExport => '导出日志';

  @override
  String get networkLogExported => '日志已导出';

  @override
  String get networkLogExternalEditor => '外部编辑器';

  @override
  String networkLogFailed(String error) {
    return '请求失败：$error';
  }

  @override
  String get networkLogFilterAll => '全部';

  @override
  String get networkLogFilterFailed => '失败';

  @override
  String get networkLogFilterSuccess => '成功';

  @override
  String get networkLogFormatJson => '格式化 JSON';

  @override
  String get networkLogFormatted => ' · 已格式化';

  @override
  String networkLogFullTitle(String label) {
    return '$label全文';
  }

  @override
  String get networkLogInvalidJson => '内容不是有效的 JSON，无法格式化';

  @override
  String get networkLogMethod => '方法';

  @override
  String get networkLogRequest => '请求';

  @override
  String get networkLogRequestBody => '请求 Body';

  @override
  String get networkLogRequestHeaders => '请求 Headers';

  @override
  String get networkLogRequestSize => '请求大小';

  @override
  String get networkLogResponse => '响应';

  @override
  String get networkLogResponseBody => '响应 Body';

  @override
  String get networkLogResponseHeaders => '响应 Headers';

  @override
  String get networkLogResponseSize => '响应大小';

  @override
  String get networkLogShowRaw => '显示原文';

  @override
  String get networkLogStatus => '状态码';

  @override
  String get networkLogTime => '时间';

  @override
  String get networkLogTitle => '网络日志';

  @override
  String get networkLogToday => '今天';

  @override
  String get networkLogType => '类型';

  @override
  String get networkLogTypeCapability => '能力表';

  @override
  String get networkLogTypeChat => '聊天';

  @override
  String get networkLogTypeModels => '模型列表';

  @override
  String get networkLogTypeOther => '其他';

  @override
  String get networkLogTypeTest => '测速';

  @override
  String get networkLogUrl => '地址';

  @override
  String get networkLogViewFull => '查看全文';

  @override
  String get networkLogYesterday => '昨天';

  @override
  String get preferencesAutoRetry => '自动重试失败请求';

  @override
  String get preferencesAutoRetryHint => '连接失败、限流或服务端错误时自动重试（指数退避，最多 3 次尝试）';

  @override
  String get preferencesDocumentThreshold => '文本文档阈值';

  @override
  String get preferencesDocumentThresholdExample => '例如：40000，0 表示关闭';

  @override
  String get preferencesDocumentThresholdInvalid => '请输入不小于 0 的数字';

  @override
  String get preferencesDocumentThresholdLabel => '阈值（字）';

  @override
  String get preferencesDocumentThresholdOff => '已关闭（直接渲染）';

  @override
  String get preferencesDocumentThresholdTitle => '文本文档阈值';

  @override
  String preferencesDocumentThresholdValue(int count) {
    return '超过 $count 字的消息显示为文本文档';
  }

  @override
  String get preferencesEnterSend => 'Enter 发送消息';

  @override
  String get preferencesEnterSendHint => '关闭后，输入法右下角的「换行」键将插入换行，而不会直接发送消息。';

  @override
  String get preferencesEnterSendOff => '按 Enter 换行，Ctrl+Enter 发送';

  @override
  String get preferencesEnterSendOn => '按 Enter 发送，Shift+Enter 换行';

  @override
  String get preferencesLanguage => '界面语言';

  @override
  String get preferencesLanguageEn => 'English';

  @override
  String get preferencesLanguageSystem => '跟随系统';

  @override
  String get preferencesLanguageZh => '中文';

  @override
  String get preferencesStreamMarkdown => '流式渲染 Markdown';

  @override
  String get preferencesStreamMarkdownHint =>
      '生成过程中实时渲染 Markdown 格式；关闭后生成完成再渲染（超长回复时更流畅）';

  @override
  String get preferencesTitle => '偏好设置';

  @override
  String get preferencesTtsLanguage => '朗读语言';

  @override
  String get preferencesTtsLanguageEn => 'English';

  @override
  String get preferencesTtsLanguageJa => '日本語';

  @override
  String get preferencesTtsLanguageZh => '中文';

  @override
  String get preferencesTtsRate => '朗读语速';

  @override
  String get preferencesWebSearch => '网络搜索';

  @override
  String get preferencesWebSearchApiKey => 'API Key';

  @override
  String get preferencesWebSearchApiKeyHint => '未配置（点此填写）';

  @override
  String get searchEngineBing => 'Bing（免费）';

  @override
  String get searchEngineDuckduckgo => 'DuckDuckGo（免费）';

  @override
  String get searchEngineTavily => 'Tavily（需 API Key）';

  @override
  String get searchEngineBocha => '博查搜搜（需 API Key）';

  @override
  String get searchEngineSearxng => 'SearXNG（自托管）';

  @override
  String get preferencesWebSearchBaseUrl => 'SearXNG 地址';

  @override
  String get preferencesWebSearchBaseUrlHint => '未配置（点此填写）';

  @override
  String get preferencesWebSearchEngine => '搜索引擎';

  @override
  String get preferencesWebSearchHint => '发送前自动联网搜索，结果注入上下文供模型引用';

  @override
  String get providerAdd => '添加服务商';

  @override
  String get providerAddModel => '添加模型';

  @override
  String get providerAdvancedSettings => '高级设置';

  @override
  String get providerBaseSettings => '基础设置';

  @override
  String get providerClickRetest => '点击重新测试';

  @override
  String get providerClickTest => '点击测试';

  @override
  String get providerCustomBody => '自定义请求体（JSON，合并进请求）';

  @override
  String get providerCustomBodyInvalid => '自定义请求体不是合法的 JSON，返回后该内容将丢失';

  @override
  String get providerCustomHeaders => '自定义请求头（每行一个 Key: Value）';

  @override
  String get providerCustomHeadersInvalid => '自定义请求头存在缺少冒号的行，返回后这些行将丢失';

  @override
  String get providerDebug => '调试';

  @override
  String providerDeleteConfirm(String name) {
    return '删除服务商「$name」？';
  }

  @override
  String get providerDeleteTitle => '删除服务商';

  @override
  String get providerEdit => '服务商设置';

  @override
  String get providerEmpty => '暂无服务商，点右上角添加';

  @override
  String get providerImportHint => '粘贴分享的服务商文本…';

  @override
  String get providerImportInvalid => '无法解析该文本，请检查是否完整';

  @override
  String get providerImportTitle => '导入服务商';

  @override
  String get providerLatencyExcellent => '优秀';

  @override
  String get providerLatencyGood => '一般';

  @override
  String get providerLatencyRecord => '延迟记录';

  @override
  String get providerLatencySlow => '较慢';

  @override
  String get providerModel => '模型';

  @override
  String get providerModelSettings => '模型设置';

  @override
  String providerModelsCount(int count) {
    return '共 $count 个模型';
  }

  @override
  String get providerModelsEmpty =>
      '尚未添加模型，点击「添加模型」\\n可手动填写模型 ID 或从 /models 列表获取';

  @override
  String get providerMultimodal => '多模态';

  @override
  String get providerMultimodalHint => '支持图片、文件等非文本输入';

  @override
  String get providerName => '服务商名称';

  @override
  String get providerNameHint => '例如：OpenAI';

  @override
  String get providerBaseUrl => '接口地址';

  @override
  String get providerSaveFailed => '保存失败，请重试';

  @override
  String get providerBaseUrlHint => '例如：https://api.openai.com/v1';

  @override
  String get providerApiKey => 'API 密钥';

  @override
  String get providerApiKeyHint => 'sk-…';

  @override
  String get providerProtocol => '协议类型';

  @override
  String get providerProtocolAuto => '自动（按地址识别）';

  @override
  String get providerReasoning => '推理';

  @override
  String get providerReasoningHint => '启用深度推理能力（如 o1、o3 系列）';

  @override
  String providerRemoveModelConfirm(String id) {
    return '移除模型「$id」？';
  }

  @override
  String get providerRemoveModelTitle => '移除模型';

  @override
  String get providerShareHint => '复制以下文本即可分享服务商配置（含 API Key，请注意保管）：';

  @override
  String get providerShareTitle => '分享服务商';

  @override
  String get providerTest => '测试';

  @override
  String get providerTestAgain => '重新测试';

  @override
  String providerTestFailedDetail(String error) {
    return '测试失败: $error';
  }

  @override
  String get providerTesting => '测试中…';

  @override
  String get providerTitle => '服务商';

  @override
  String get providerUnconfiguredModel => '未配置模型';

  @override
  String get searchHint => '输入关键词，搜索全部会话';

  @override
  String searchNoResult(String query) {
    return '没有找到与「$query」相关的消息';
  }

  @override
  String get searchTitle => '搜索会话标题与消息内容…';

  @override
  String get searchTitleHit => '标题命中';

  @override
  String get settingsAbout => '关于 Nona';

  @override
  String get settingsAboutSubtitle => '版本 / GitHub 仓库 / 开源许可';

  @override
  String get settingsAgents => 'Agent 配置';

  @override
  String settingsAgentsSubtitle(int count) {
    return '共 $count 个 Agent';
  }

  @override
  String get settingsAllExist => '所有会话已存在，无新增';

  @override
  String get settingsClearAll => '清空全部会话';

  @override
  String settingsClearAllSubtitle(int count) {
    return '将删除全部 $count 个会话';
  }

  @override
  String get settingsClearAllSubtitleEmpty => '当前没有保存的会话';

  @override
  String settingsClearConfirmContent(int count) {
    return '将删除全部 $count 个会话，此操作不可恢复。';
  }

  @override
  String get settingsClearConfirmTitle => '清空全部会话';

  @override
  String get settingsCleared => '已清空全部会话';

  @override
  String get settingsCompareSubtitle => '同一问题对比多个模型';

  @override
  String get settingsDevOptions => '开发者选项';

  @override
  String get settingsDevOptionsSubtitle => '连通性高级设置 / 模型能力映射表';

  @override
  String get settingsExportAll => '导出全部会话';

  @override
  String get settingsExportAllSubtitle => '备份为 JSON 文件，可随时恢复';

  @override
  String settingsExportFailed(Object error) {
    return '导出失败：$error';
  }

  @override
  String settingsExportedAll(String path) {
    return '已导出全部数据到 $path';
  }

  @override
  String get settingsFooter => 'Nona · 本地优先，所有数据仅保存在本机';

  @override
  String get settingsImport => '导入会话';

  @override
  String get settingsImportFailed => '导入失败：文件格式不正确';

  @override
  String get settingsImportSubtitle =>
      '从 Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo 导入';

  @override
  String settingsImported(int count) {
    return '已导入 $count 个会话';
  }

  @override
  String get settingsKbSubtitle => '本地知识库，对话自动检索';

  @override
  String get settingsMcpSubtitle => 'MCP 工具服务管理';

  @override
  String get settingsModelConfig => '模型配置';

  @override
  String get settingsModelConfigSubtitle => '聊天默认模型 · 标题生成模型';

  @override
  String get settingsNoExportable => '还没有可导出的会话';

  @override
  String get settingsPreferences => '偏好设置';

  @override
  String get settingsPreferencesEnterNewline => 'Enter 换行，Ctrl+Enter 发送';

  @override
  String get settingsPreferencesEnterSend => 'Enter 发送，Shift+Enter 换行';

  @override
  String get settingsProviders => '服务商';

  @override
  String settingsProvidersSubtitle(int providers, int models) {
    return '$providers 个服务商 · $models 个模型';
  }

  @override
  String get settingsProvidersSubtitleEmpty => '未配置，添加服务商并获取模型';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionData => '数据';

  @override
  String get settingsSectionPreferences => '偏好';

  @override
  String get settingsSectionServices => '服务与内容';

  @override
  String get settingsSyncSubtitle => 'WebDAV / S3 备份同步';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTranslatorSubtitle => '调用 AI 模型进行翻译';

  @override
  String get sidebarAnonymous => '匿名会话（不保存）';

  @override
  String get sidebarAnonymousActive => '匿名会话进行中';

  @override
  String get sidebarAnonymousHint => '对话内容仅保存在内存中，\\n关闭应用后不会留下记录';

  @override
  String get sidebarBrandSubtitle => 'AI 聊天助手';

  @override
  String get sidebarDuplicate => '复制会话';

  @override
  String get sidebarEarlier => '更早';

  @override
  String get sidebarExitAnonymous => '退出匿名';

  @override
  String get sidebarExitAnonymousConfirm => '退出匿名会话';

  @override
  String get sidebarNewSessionAgent => '新建会话 / 选择 Agent';

  @override
  String get sidebarNewWithAgent => '用 Agent 新建会话';

  @override
  String get sidebarNoMatch => '没有匹配的会话';

  @override
  String get sidebarNoSessions => '暂无会话';

  @override
  String get sidebarPin => '置顶';

  @override
  String get sidebarRename => '重命名';

  @override
  String get sidebarSearchHint => '搜索会话与消息…';

  @override
  String get sidebarSessionActions => '会话操作';

  @override
  String get sidebarToday => '今天';

  @override
  String get sidebarUnpin => '取消置顶';

  @override
  String get sidebarYesterday => '昨天';

  @override
  String get syncBackupList => '云端备份';

  @override
  String get syncEmpty => '暂无备份，点击「上传备份」创建';

  @override
  String syncRestoreConfirm(String name) {
    return '将合并恢复备份「$name」中的会话与服务商配置？';
  }

  @override
  String get syncRestoreTitle => '恢复备份';

  @override
  String syncRestored(int count) {
    return '已恢复 $count 个新会话';
  }

  @override
  String get syncS3Access => 'Access Key';

  @override
  String get syncS3Bucket => 'Bucket';

  @override
  String get syncS3Endpoint => 'S3 端点';

  @override
  String get syncS3Region => 'Region';

  @override
  String get syncS3Secret => 'Secret Key';

  @override
  String get syncTitle => '云同步';

  @override
  String get statsTitle => '统计看板';

  @override
  String get settingsStatsSubtitle => 'Token 用量、模型排行与成本统计';

  @override
  String get memoryTitle => '记忆';

  @override
  String get settingsMemorySubtitle => '自动提取与管理的长期记忆';

  @override
  String get memoryAdd => '添加记忆';

  @override
  String get memoryContentHint => '输入想长期记住的内容';

  @override
  String get memoryEdit => '编辑记忆';

  @override
  String get memoryDeleteConfirm => '删除该记忆？';

  @override
  String get memoryScopeGlobal => '全局';

  @override
  String get memoryScopeAgent => 'Agent';

  @override
  String get memoryScopeSession => '会话';

  @override
  String get memoryEmpty => '暂无记忆，对话满 10 轮后会自动提取';

  @override
  String get memoryPin => '置顶';

  @override
  String get settingsWbSubtitle => '世界书：关键词触发的角色设定注入';

  @override
  String get importTitle => '导入数据';

  @override
  String get imgGenTitle => '图片生成';

  @override
  String get settingsImgGenSubtitle => '用 AI 生成图片（需支持图片生成的服务商）';

  @override
  String get ocrAction => '转为文字';

  @override
  String get ocrProcessing => '正在识别图片文字…';

  @override
  String get ocrNoVisionModel => '当前服务商没有可用的多模态（视觉）模型，无法识别图片文字';

  @override
  String get ocrDone => '已识别图片文字并替换为文本消息';

  @override
  String ocrFailed(Object error) {
    return '图片文字识别失败：$error';
  }

  @override
  String get imgGenProvider => '服务商（需支持图片生成）';

  @override
  String get imgGenPrompt => '提示词';

  @override
  String get imgGenPromptHint => '描述你想生成的图片';

  @override
  String get imgGenSize => '尺寸';

  @override
  String get imgGenCount => '数量';

  @override
  String get imgGenGenerate => '生成';

  @override
  String get imgGenGenerating => '生成中…';

  @override
  String get imgGenEmpty => '暂无历史，输入提示词开始生成';

  @override
  String get importPickHint =>
      '选择备份文件（Nona / Chatbox / Cherry / NextChat / ChatGPT / RikkaHub / Kelivo）';

  @override
  String get importPick => '选择文件';

  @override
  String get importConfirm => '确认导入';

  @override
  String importFormat(Object format) {
    return '识别格式：$format';
  }

  @override
  String importPreview(Object messages, Object sessions) {
    return '预览：$sessions 个会话，$messages 条消息';
  }

  @override
  String get importFailed => '导入失败，请检查文件格式';

  @override
  String importResultOk(Object count) {
    return '导入成功：新增 $count 个会话';
  }

  @override
  String importResultPartial(Object count, Object failed) {
    return '导入完成：新增 $count 个会话，$failed 条记录失败（已跳过）';
  }

  @override
  String get wbTitle => '世界书';

  @override
  String get wbAdd => '新建条目';

  @override
  String get wbEdit => '编辑条目';

  @override
  String get wbImport => '导入 JSON';

  @override
  String get wbExport => '导出 JSON';

  @override
  String get wbEmpty => '暂无条目，点击右上角新建';

  @override
  String wbDeleteConfirm(Object title) {
    return '删除世界书条目「$title」？';
  }

  @override
  String wbImported(Object count) {
    return '导入 $count 条条目';
  }

  @override
  String get wbImportFailed => '导入失败：JSON 格式不正确';

  @override
  String get wbTitleField => '标题';

  @override
  String get wbKeywordsField => '触发关键词';

  @override
  String get wbKeywordsHint => '逗号分隔，消息中包含任一关键词即触发';

  @override
  String get wbContentField => '内容';

  @override
  String get wbPriorityField => '优先级';

  @override
  String get wbScanDepthField => '扫描深度';

  @override
  String get wbPositionField => '注入位置';

  @override
  String get wbCaseSensitive => '关键词区分大小写';

  @override
  String get wbConstantActive => '常驻激活（始终注入）';

  @override
  String get wbUntitled => '未命名条目';

  @override
  String statsBudgetWarning(Object percent) {
    return '本月已使用预算的 $percent%，请注意控制用量';
  }

  @override
  String get statsBudgetBlocked => '已超出本月预算，发送被拦截（可在统计看板调整预算）';

  @override
  String get statsBudgetWarningTitle => '本月预算已用完';

  @override
  String get statsBudgetWarningBody => '继续发送将超出本月预算，是否继续？';

  @override
  String get statsBudgetOverride => '仍然发送';

  @override
  String get statsRefresh => '刷新';

  @override
  String get statsDailyTokens => '每日 Token（下:输入 / 上:输出）';

  @override
  String get statsEmpty => '暂无数据';

  @override
  String get statsCostTrend => 'Token 趋势';

  @override
  String get statsTopModels => '模型 Top 10';

  @override
  String get statsTopSessions => '会话 Top 10';

  @override
  String get statsTotalTokens => '累计 Token';

  @override
  String get statsTotalCost => '累计花费（美元）';

  @override
  String get syncTypeS3 => 'S3';

  @override
  String get syncTypeWebDav => 'WebDAV';

  @override
  String get syncErrorAuth => '认证失败，请检查账号或密钥';

  @override
  String get syncErrorNetwork => '网络连接失败，请检查网络后重试';

  @override
  String get syncErrorStorage => '存储服务错误，请检查配置';

  @override
  String get syncUpload => '上传备份';

  @override
  String syncUploaded(String name) {
    return '已上传备份：$name';
  }

  @override
  String get syncWebDavPass => '密码';

  @override
  String get syncWebDavUrl => 'WebDAV 地址';

  @override
  String get syncWebDavUser => '用户名';

  @override
  String get themeAccentSection => '强调色';

  @override
  String get themeCustom => '自定义';

  @override
  String get themeCustomColor => '自定义颜色';

  @override
  String get themeCustomTitle => '自定义强调色';

  @override
  String get themeDarkSection => '深色模式';

  @override
  String get themeHue => '色相';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeSection => '外观模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeOledSubtitle => '深色模式下使用纯黑背景，适合 OLED 屏幕，更省电';

  @override
  String get themeOledTitle => 'OLED 纯黑背景';

  @override
  String get themeSaturation => '饱和度';

  @override
  String get themeTitle => '主题配置';

  @override
  String get themeValue => '明度';

  @override
  String get translatorFailed => '翻译失败，请重试';

  @override
  String get translatorNoModel => '请先在「模型配置」中设置默认聊天模型';

  @override
  String get translatorResult => '译文';

  @override
  String get translatorSourceHint => '输入需要翻译的内容…';

  @override
  String get translatorTarget => '目标语言';

  @override
  String get unitsMb => 'MB';

  @override
  String get unitsKb => 'KB';

  @override
  String get unitsB => 'B';

  @override
  String get translatorLangEn => 'English';

  @override
  String get translatorLangZh => '中文';

  @override
  String get translatorLangJa => '日本語';

  @override
  String get translatorLangKo => '한국어';

  @override
  String get translatorLangFr => 'Français';

  @override
  String get translatorLangDe => 'Deutsch';

  @override
  String get translatorLangEs => 'Español';

  @override
  String get translatorLangRu => 'Русский';

  @override
  String translatorPrompt(String target, String source) {
    return '请将以下内容翻译成$target，只输出译文：\n\n$source';
  }

  @override
  String get translatorTitle => 'AI 翻译';

  @override
  String get translatorTranslate => '翻译';

  @override
  String get translatorTranslating => '翻译中…';

  @override
  String get chatSuggestionTitle => '你可以这样开始';

  @override
  String get chatSuggestionStart => '介绍你自己，包括能力和限制';

  @override
  String get chatSuggestionFiles => '如何上传文档并获得摘要？';

  @override
  String get chatSuggestionMcp => '连接外部工具需要什么配置？';

  @override
  String get chatMoreActions => '更多操作';

  @override
  String get chatSelectCopy => '选择复制';

  @override
  String get chatExportImage => '导出图片';

  @override
  String get chatExportSelectedImage => '导出长图';

  @override
  String get chatExportJsonl => '导出 JSONL';

  @override
  String get chatLongImageCapturing => '正在生成长图…';

  @override
  String get chatLongImageDone => '长图已导出';

  @override
  String get chatSelectCopyHint => '长按或拖选文本后复制；可附带上下文发送';

  @override
  String get chatCopyWithContext => '附带上下文发送';

  @override
  String get chatNoSelection => '未选择文本';

  @override
  String get contextManageTitle => '上下文管理';

  @override
  String get contextSegments => '注入分段';

  @override
  String contextSegmentTokens(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get contextSegmentSystem => '系统提示词';

  @override
  String get contextSegmentMemory => '记忆';

  @override
  String get contextSegmentKnowledge => '知识库';

  @override
  String get contextSegmentSearch => '搜索结果';

  @override
  String get contextSegmentWorldBook => '世界书';

  @override
  String get contextSegmentHistory => '历史消息';

  @override
  String get contextSegmentSummary => '会话摘要';

  @override
  String get contextSegmentInjection => '指令注入';

  @override
  String get contextSegmentAgent => 'Agent 提示词';

  @override
  String contextUsedTokens(String limit, String used) {
    return '已用 $used / 上限 $limit';
  }

  @override
  String get contextNoLimit => '未设置上限';

  @override
  String get contextCompress => '压缩上下文';

  @override
  String get contextCompressHint => '生成摘要并折叠历史消息';

  @override
  String get contextClear => '清除上下文';

  @override
  String get contextClearHint => '标记截断点，历史可恢复';

  @override
  String get contextRestore => '恢复被清除的上下文';

  @override
  String get contextCompressing => '正在压缩…';

  @override
  String get contextCompressDone => '上下文已压缩，新会话以摘要开头';

  @override
  String get contextToggleOffHint => '已停用该分段（仅本次请求生效）';

  @override
  String get contextEnabled => '已启用';

  @override
  String get contextDisabled => '已停用';

  @override
  String get providerUseResponseApi => '使用 Responses API';

  @override
  String get providerUseResponseApiHint =>
      '面向 o1/o3/o4/gpt-5 系列；ChatCompletions 兼容服务商请勿开启';

  @override
  String get providerAuthMode => '认证方式';

  @override
  String get providerAuthApiKey => 'API Key';

  @override
  String get providerAuthServiceAccount => 'Service Account（Vertex）';

  @override
  String get providerSaProjectId => 'Project ID';

  @override
  String get providerSaRegion => '区域（Region）';

  @override
  String get providerSaEmail => 'Service Account 邮箱';

  @override
  String get providerSaKeyFile => '选择 SA JSON 密钥文件';

  @override
  String get providerSaKeyPaste => '粘贴 SA JSON';

  @override
  String get providerSaInvalid =>
      '无效的 SA JSON：缺少 client_email/private_key/project_id';

  @override
  String get providerVertexHint =>
      'baseUrl 含 aiplatform 时使用 Bearer 令牌访问 Vertex 端点';

  @override
  String get providerGroupUngrouped => '未分组';

  @override
  String get providerGroupAll => '全部';

  @override
  String get providerGroupAdd => '新建分组';

  @override
  String get providerGroupName => '分组名称';

  @override
  String get providerGroupRename => '重命名';

  @override
  String get providerGroupDelete => '删除分组';

  @override
  String get providerGroupEmpty => '暂无分组';

  @override
  String get providerKeysTitle => 'API Key 管理';

  @override
  String get providerKeysBatchAdd => '批量添加 Key（每行一个）';

  @override
  String get providerKeysTest => '测活';

  @override
  String get providerKeysTesting => '测活中…';

  @override
  String get providerKeysStatusActive => '正常';

  @override
  String get providerKeysStatusCooling => '冷却中';

  @override
  String providerKeysStatusError(String count) {
    return '失败 $count 次';
  }

  @override
  String get providerKeysStatusDisabled => '已停用（连续失败）';

  @override
  String get providerKeysEnable => '启用';

  @override
  String get providerKeysDisable => '停用';

  @override
  String get providerKeysNone => '暂无 Key';

  @override
  String get providerKeysCopied => '已复制（可能被剪贴板暴露，请谨慎）';

  @override
  String get providerKeysTestOk => '测活通过';

  @override
  String providerKeysTestFail(String detail) {
    return '测活失败：$detail';
  }

  @override
  String get providerKeysRemoved => '已删除 Key';

  @override
  String get imggenSize => '尺寸';

  @override
  String get imggenQuality => '质量';

  @override
  String get imggenCount => '数量';

  @override
  String get imggenSendToChat => '发送到对话';

  @override
  String get imggenHistory => '生成历史';

  @override
  String get imggenHistoryEmpty => '暂无生成记录';

  @override
  String get modelSearch => '搜索模型';

  @override
  String get modelFilterMultimodal => '多模态';

  @override
  String get modelFilterReasoning => '推理';

  @override
  String modelContextWindow(String window) {
    return '上下文 $window';
  }

  @override
  String modelPrice(String price) {
    return '¥$price/M';
  }

  @override
  String get modelNoCapability => '能力未知';

  @override
  String get searchServicesTitle => '搜索服务';

  @override
  String get searchServiceEnabled => '启用';

  @override
  String get searchServiceKey => 'API Key';

  @override
  String get searchServiceTest => '测活';

  @override
  String get searchServiceTesting => '测活中…';

  @override
  String searchServiceTestOk(String count) {
    return '返回 $count 条结果';
  }

  @override
  String searchServiceTestFail(String detail) {
    return '测活失败：$detail';
  }

  @override
  String get searchServiceNeedKey => '需要 API Key';

  @override
  String get searchServiceNoKey => '无需 Key';

  @override
  String get searchServiceSelected => '当前使用';

  @override
  String get searchServiceUsageTitle => '搜索用量';

  @override
  String searchServiceCalls(String count) {
    return '$count 次调用';
  }

  @override
  String get searchNoKeyFallback => '未配置 Key，回退 Bing 免费引擎';

  @override
  String get searchFilterTime => '时间范围';

  @override
  String get searchFilterProvider => '服务商';

  @override
  String get searchFilterModel => '模型';

  @override
  String get searchFilterAll => '全部';

  @override
  String get searchFilterToday => '今天';

  @override
  String get searchFilterWeek => '近 7 天';

  @override
  String get searchFilterMonth => '近 30 天';

  @override
  String get searchFilterYear => '近一年';

  @override
  String get searchExportResults => '导出结果';

  @override
  String searchExported(String count) {
    return '已导出 $count 条结果';
  }

  @override
  String get kbDebugTitle => '检索测试台';

  @override
  String get kbDebugQuery => '检索词';

  @override
  String get kbDebugTopK => '返回条数';

  @override
  String get kbDebugSimilarity => '相似度阈值';

  @override
  String get kbDebugChunkSize => '分块大小（覆盖，不落库）';

  @override
  String kbDebugVectorHits(String count) {
    return '向量命中 $count';
  }

  @override
  String kbDebugBigramHits(String count) {
    return '关键词命中 $count';
  }

  @override
  String get kbDebugNoHits => '无命中';

  @override
  String kbDebugScore(String score) {
    return '分数 $score';
  }

  @override
  String kbDebugSource(String source) {
    return '来源：$source';
  }

  @override
  String kbDebugDocId(String id) {
    return '文档 $id';
  }

  @override
  String kbDebugRank(String rank) {
    return '第 $rank 位';
  }

  @override
  String get worldBookNewBook => '新建世界书';

  @override
  String get worldBookName => '名称';

  @override
  String get worldBookDescription => '描述';

  @override
  String get worldBookActive => '激活';

  @override
  String get worldBookActivateForAgent => '为 Agent 激活';

  @override
  String get worldBookHitTest => '命中测试';

  @override
  String get worldBookHitTestInput => '输入文本来测试匹配';

  @override
  String get worldBookHitTestNoHit => '无命中条目';

  @override
  String worldBookHitTestHit(String chars, String count) {
    return '命中 $count 条，注入 $chars 字符';
  }

  @override
  String get worldBookGlobal => '全局';

  @override
  String get voiceServicesTitle => '语音服务';

  @override
  String get voiceTtsSystem => '系统 TTS';

  @override
  String get voiceTtsProviders => '网络 TTS';

  @override
  String get voiceTtsProviderName => '服务商';

  @override
  String get voiceTtsVoice => '音色';

  @override
  String get voiceTtsRate => '语速';

  @override
  String get voiceTtsModel => '模型';

  @override
  String get voiceTtsPreview => '试听';

  @override
  String get voiceTtsPreviewing => '试听中…';

  @override
  String get voiceTtsAddProvider => '添加 TTS 服务';

  @override
  String get voiceTtsTestOk => '试听完成';

  @override
  String voiceTtsTestFail(String detail) {
    return '试听失败：$detail';
  }

  @override
  String get voiceTtsFallbackSystem => '未配置网络 TTS，回退系统朗读';

  @override
  String get voiceAsrTitle => '语音输入（ASR）';

  @override
  String get voiceAsrSystem => '系统语音识别';

  @override
  String get voiceAsrCloud => '云端识别';

  @override
  String get voiceAsrLocal => '本地离线识别';

  @override
  String get voiceAsrListening => '正在聆听…';

  @override
  String get voiceAsrDone => '识别完成';

  @override
  String get voiceAsrCancelled => '已取消';

  @override
  String get voiceAsrNoPermission => '没有麦克风权限';

  @override
  String voiceAsrError(String detail) {
    return '识别失败：$detail';
  }

  @override
  String get voiceAsrUnavailable => '当前平台不支持语音输入';

  @override
  String get voiceAsrTapToSpeak => '点击开始说话';

  @override
  String get voiceModelDownload => '下载模型';

  @override
  String voiceModelDownloading(String percent) {
    return '下载中 $percent%';
  }

  @override
  String get voiceModelInstalled => '已安装';

  @override
  String get voiceModelDelete => '删除模型';

  @override
  String voiceModelSize(String size) {
    return '$size';
  }

  @override
  String get mcpTransport => '传输方式';

  @override
  String get mcpTransportHttp => 'Streamable HTTP';

  @override
  String get mcpTransportSse => 'SSE';

  @override
  String get mcpTransportStdio => 'STDIO（本地进程）';

  @override
  String get mcpStdioCommand => '命令';

  @override
  String get mcpStdioArgs => '参数（每行一个）';

  @override
  String get mcpStdioEnv => '环境变量（KEY=VALUE，每行一个）';

  @override
  String get mcpStdioCwd => '工作目录（可选）';

  @override
  String mcpCommandNotFound(String command) {
    return '找不到命令 $command，请检查 PATH';
  }

  @override
  String mcpStdioStderr(String line) {
    return 'stderr：$line';
  }

  @override
  String get mcpAuthorize => '授权';

  @override
  String get mcpReauthorize => '重新授权';

  @override
  String get mcpAuthorized => '已授权';

  @override
  String get mcpNotAuthorized => '未授权';

  @override
  String get mcpOAuthInProgress => '正在打开授权页面…';

  @override
  String get mcpOAuthDone => '授权成功';

  @override
  String mcpOAuthFailed(String detail) {
    return '授权失败：$detail';
  }

  @override
  String get mcpOAuthServerFound => '发现授权服务器';

  @override
  String get mcpOAuthTokenRefreshed => '令牌已刷新';

  @override
  String get approvalWhitelist => '免审批白名单（工具名，每行一个）';

  @override
  String get approvalBlacklist => '强制审批黑名单（工具名，每行一个）';

  @override
  String get approvalTimeout => '审批超时（秒）';

  @override
  String get approvalRememberSession => '本次会话记住';

  @override
  String get toolExecuting => '执行中';

  @override
  String get toolDone => '完成';

  @override
  String get toolError => '失败';

  @override
  String get toolDetail => '工具详情';

  @override
  String get toolArguments => '参数';

  @override
  String get toolResult => '结果';

  @override
  String get toolResultTruncated => '（结果过长已截断）';

  @override
  String get toolApprove => '同意';

  @override
  String get toolReject => '拒绝';

  @override
  String get toolWaitingApproval => '等待审批';

  @override
  String get toolShowDetail => '查看详情';

  @override
  String get toolHideDetail => '收起详情';

  @override
  String get restoreModeTitle => '恢复模式';

  @override
  String get restoreModeOverwrite => '整体覆盖（推荐）';

  @override
  String get restoreModeMerge => '合并（保留现有数据）';

  @override
  String get restoreModeHint => '覆盖模式将替换全部本地数据；合并模式保留现有会话与服务商';

  @override
  String get restorePreparing => '正在恢复…';

  @override
  String get restoreDone => '恢复完成';

  @override
  String get restoreRolledBack => '恢复失败，已回滚到原数据';

  @override
  String get restoreCorrupt => '备份包损坏或校验失败';

  @override
  String get restoreResume => '检测到未完成的恢复，正在收敛…';

  @override
  String get shareQrTab => '二维码';

  @override
  String get scanQrTitle => '扫码导入';

  @override
  String get scanQrCameraPermission => '需要相机权限以扫描二维码';

  @override
  String get scanQrInvalid => '无法识别的二维码内容';

  @override
  String get scanQrProviderImported => '服务商导入成功';

  @override
  String get tagsTitle => '标签';

  @override
  String get tagsAdd => '新建标签';

  @override
  String get tagsName => '标签名';

  @override
  String get tagsColor => '颜色';

  @override
  String get tagsApply => '打标签';

  @override
  String get tagsFilter => '按标签筛选';

  @override
  String get tagsNone => '暂无标签';

  @override
  String get tagsManage => '管理标签';

  @override
  String get statsHeatmapTitle => '活跃热力图';

  @override
  String get statsHeatmapLegend => '少 → 多';

  @override
  String get statsTrendTitle => '趋势';

  @override
  String get statsRankProviders => '服务商排行';

  @override
  String get statsRankModels => '模型排行';

  @override
  String get statsRankSessions => '会话排行';

  @override
  String get statsViewAll => '查看全部';

  @override
  String get statsRangeAllTime => '全部时间';

  @override
  String get statsRangeLast30 => '近 30 天';

  @override
  String get statsRangePrevMonth => '上一月';

  @override
  String get statsRangeCustom => '自定义';

  @override
  String statsMessages(String count) {
    return '$count 条消息';
  }

  @override
  String get displayFontFamily => '界面字体';

  @override
  String get displayFontSystem => '跟随系统';

  @override
  String get displayCodeFont => '代码字体';

  @override
  String get displayUiDensity => '界面密度';

  @override
  String get densityCompact => '紧凑';

  @override
  String get densityStandard => '标准';

  @override
  String get densityComfortable => '宽松';

  @override
  String get displayChatFontScale => '聊天字号';

  @override
  String get fontImportLocal => '导入本地字体文件';

  @override
  String get fontImported => '字体已导入';

  @override
  String get androidBackgroundMode => '后台生成';

  @override
  String get androidBackgroundOff => '关闭';

  @override
  String get androidBackgroundOn => '开启';

  @override
  String get androidBackgroundOnNotify => '开启并通知';

  @override
  String get androidBackgroundHint => '开启后锁屏/退后台时保持生成不中断';

  @override
  String get notificationChatCompleted => '生成完成';

  @override
  String get notificationChatFailed => '生成失败';

  @override
  String get desktopAutostart => '开机自启';

  @override
  String get desktopAutostartHint => '登录系统时自动启动 Nona';

  @override
  String desktopAutostartError(String detail) {
    return '设置自启失败：$detail';
  }

  @override
  String get deeplinkChatTitle => '来自外部链接';

  @override
  String get devColdStartTiming => '冷启动耗时（毫秒）';

  @override
  String get chatOpenDocument => '打开文本文档';

  @override
  String contextSummaryPrompt(String source) {
    return '请用简洁的中文总结以下对话的要点，保留关键结论、决定与待办，不超过 300 字：\n\n$source';
  }

  @override
  String get providerAuthorized => '已导入（认证信息已加密保存）';

  @override
  String get commonAuto => '自动';
}

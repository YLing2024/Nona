// 批量向 app_zh.arb / app_en.arb 追加新键（幂等：已存在的键跳过）。
// 用法：dart run tool/add_l10n_keys.dart <zh.json> <en.json>
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final zh = _load(args[0]);
  final en = _load(args[1]);
  var added = 0;
  for (final entry in keys.entries) {
    if (zh.containsKey(entry.key)) continue;
    final zhText = entry.value.zh;
    final enText = entry.value.en;
    zh[entry.key] = zhText;
    en[entry.key] = enText;
    final meta = _autoMeta(zhText, enText);
    if (meta != null) {
      zh['@${entry.key}'] = meta;
      en['@${entry.key}'] = meta;
    }
    added++;
  }
  _save(args[0], zh);
  _save(args[1], en);
  stdout.writeln('added $added keys');
}

/// 从文案中的 {placeholder} 自动生成 gen-l10n 元数据。
Map<String, dynamic>? _autoMeta(String zhText, String enText) {
  final placeholders = <String>{
    ...RegExp(r'\{(\w+)\}').allMatches(zhText).map((m) => m.group(1)!),
    ...RegExp(r'\{(\w+)\}').allMatches(enText).map((m) => m.group(1)!),
  }.toList()..sort();
  if (placeholders.isEmpty) return null;
  return _meta(placeholders);
}

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void _save(String path, Map<String, dynamic> map) {
  const encoder = JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(map)}\n');
}

class _Key {
  final String zh;
  final String en;
  const _Key(this.zh, this.en);
}

/// 新键表：B 域聊天 / C 域模型 / D 域检索 / E 域语音 / F 域 MCP /
/// G 域数据 / H 域个性化 / I 域平台。
const keys = <String, _Key>{
  // ---- B-04 建议气泡 ----
  'chatSuggestionTitle': _Key('你可以这样开始', 'You can start with'),
  'chatSuggestionStart': _Key('介绍你自己，包括能力和限制', 'Introduce yourself, including capabilities and limits'),
  'chatSuggestionFiles': _Key('如何上传文档并获得摘要？', 'How do I upload documents and get summaries?'),
  'chatSuggestionMcp': _Key('连接外部工具需要什么配置？', 'What configuration is needed to connect external tools?'),
  // ---- B-07 统一菜单 ----
  'chatMoreActions': _Key('更多操作', 'More actions'),
  'chatSelectCopy': _Key('选择复制', 'Select & copy'),
  'chatExportImage': _Key('导出图片', 'Export image'),
  'chatExportSelectedImage': _Key('导出长图', 'Export as image'),
  'chatExportJsonl': _Key('导出 JSONL', 'Export JSONL'),
  'chatLongImageCapturing': _Key('正在生成长图…', 'Rendering long image…'),
  'chatLongImageDone': _Key('长图已导出', 'Long image exported'),
  'chatSelectCopyHint': _Key('长按或拖选文本后复制；可附带上下文发送', 'Select text then copy; optionally send with context'),
  'chatCopyWithContext': _Key('附带上下文发送', 'Copy & send with context'),
  'chatNoSelection': _Key('未选择文本', 'No text selected'),
  'chatOpenDocument': _Key('打开文本文档', 'Open document'),
  // ---- B-08 上下文管理面板 ----
  'contextManageTitle': _Key('上下文管理', 'Context management'),
  'contextSegments': _Key('注入分段', 'Injected segments'),
  'contextSegmentTokens': _Key('{tokens} tokens', '{tokens} tokens'),
  'contextSegmentSystem': _Key('系统提示词', 'System prompt'),
  'contextSegmentMemory': _Key('记忆', 'Memory'),
  'contextSegmentKnowledge': _Key('知识库', 'Knowledge base'),
  'contextSegmentSearch': _Key('搜索结果', 'Search results'),
  'contextSegmentWorldBook': _Key('世界书', 'World book'),
  'contextSegmentHistory': _Key('历史消息', 'History'),
  'contextSegmentSummary': _Key('会话摘要', 'Session summary'),
  'contextSegmentInjection': _Key('指令注入', 'Instruction injections'),
  'contextSegmentAgent': _Key('Agent 提示词', 'Agent prompt'),
  'contextUsedTokens': _Key('已用 {used} / 上限 {limit}', 'Used {used} / limit {limit}'),
  'contextNoLimit': _Key('未设置上限', 'No limit set'),
  'contextCompress': _Key('压缩上下文', 'Compress context'),
  'contextCompressHint': _Key('生成摘要并折叠历史消息', 'Summarize and fold history'),
  'contextClear': _Key('清除上下文', 'Clear context'),
  'contextClearHint': _Key('标记截断点，历史可恢复', 'Mark truncation point; history is recoverable'),
  'contextRestore': _Key('恢复被清除的上下文', 'Restore cleared context'),
  'contextCompressing': _Key('正在压缩…', 'Compressing…'),
  'contextCompressDone': _Key('上下文已压缩，新会话以摘要开头', 'Context compressed; new messages start with the summary'),
  'contextToggleOffHint': _Key('已停用该分段（仅本次请求生效）', 'Segment disabled for next request only'),
  'contextEnabled': _Key('已启用', 'Enabled'),
  'contextDisabled': _Key('已停用', 'Disabled'),
  'contextSummaryPrompt': _Key('请用简洁的中文总结以下对话的要点，保留关键结论、决定与待办，不超过 300 字：\n\n{source}', 'Summarize the key points of the following conversation concisely, keeping conclusions, decisions and todos, within 300 words:\n\n{source}'),
  // ---- C-01 Responses API ----
  'providerUseResponseApi': _Key('使用 Responses API', 'Use Responses API'),
  'providerUseResponseApiHint': _Key('面向 o1/o3/o4/gpt-5 系列；ChatCompletions 兼容服务商请勿开启', 'For o1/o3/o4/gpt-5 series; keep off for ChatCompletions-compatible providers'),
  // ---- C-02 Vertex ----
  'providerAuthMode': _Key('认证方式', 'Auth mode'),
  'providerAuthApiKey': _Key('API Key', 'API Key'),
  'providerAuthServiceAccount': _Key('Service Account（Vertex）', 'Service Account (Vertex)'),
  'providerSaProjectId': _Key('Project ID', 'Project ID'),
  'providerSaRegion': _Key('区域（Region）', 'Region'),
  'providerSaEmail': _Key('Service Account 邮箱', 'Service Account email'),
  'providerSaKeyFile': _Key('选择 SA JSON 密钥文件', 'Select SA JSON key file'),
  'providerSaKeyPaste': _Key('粘贴 SA JSON', 'Paste SA JSON'),
  'providerSaInvalid': _Key('无效的 SA JSON：缺少 client_email/private_key/project_id', 'Invalid SA JSON: missing client_email/private_key/project_id'),
  'providerVertexHint': _Key('baseUrl 含 aiplatform 时使用 Bearer 令牌访问 Vertex 端点', 'Bearer token is used when baseUrl contains aiplatform'),
  'providerAuthorized': _Key('已导入（认证信息已加密保存）', 'Imported (credentials stored encrypted)'),
  // ---- C-03 服务商分组 ----
  'providerGroupUngrouped': _Key('未分组', 'Ungrouped'),
  'providerGroupAll': _Key('全部', 'All'),
  'providerGroupAdd': _Key('新建分组', 'New group'),
  'providerGroupName': _Key('分组名称', 'Group name'),
  'providerGroupRename': _Key('重命名', 'Rename'),
  'providerGroupDelete': _Key('删除分组', 'Delete group'),
  'providerGroupEmpty': _Key('暂无分组', 'No groups yet'),
  // ---- C-04 多 Key 管理 ----
  'providerKeysTitle': _Key('API Key 管理', 'API Keys'),
  'providerKeysBatchAdd': _Key('批量添加 Key（每行一个）', 'Add keys (one per line)'),
  'providerKeysTest': _Key('测活', 'Test'),
  'providerKeysTesting': _Key('测活中…', 'Testing…'),
  'providerKeysStatusActive': _Key('正常', 'Active'),
  'providerKeysStatusCooling': _Key('冷却中', 'Cooling down'),
  'providerKeysStatusError': _Key('失败 {count} 次', 'Failed {count} times'),
  'providerKeysStatusDisabled': _Key('已停用（连续失败）', 'Disabled (consecutive failures)'),
  'providerKeysEnable': _Key('启用', 'Enable'),
  'providerKeysDisable': _Key('停用', 'Disable'),
  'providerKeysNone': _Key('暂无 Key', 'No keys yet'),
  'providerKeysCopied': _Key('已复制（可能被剪贴板暴露，请谨慎）', 'Copied (may expose to clipboard)'),
  'providerKeysTestOk': _Key('测活通过', 'Test passed'),
  'providerKeysTestFail': _Key('测活失败：{detail}', 'Test failed: {detail}'),
  'providerKeysRemoved': _Key('已删除 Key', 'Key removed'),
  // ---- C-05 图片生成增强 ----
  'imggenSize': _Key('尺寸', 'Size'),
  'imggenQuality': _Key('质量', 'Quality'),
  'imggenCount': _Key('数量', 'Count'),
  'imggenSendToChat': _Key('发送到对话', 'Send to chat'),
  'imggenHistory': _Key('生成历史', 'History'),
  'imggenHistoryEmpty': _Key('暂无生成记录', 'No generation history'),
  'commonAuto': _Key('自动', 'Auto'),
  // ---- C-06 模型面板 ----
  'modelSearch': _Key('搜索模型', 'Search models'),
  'modelFilterMultimodal': _Key('多模态', 'Multimodal'),
  'modelFilterReasoning': _Key('推理', 'Reasoning'),
  'modelContextWindow': _Key('上下文 {window}', 'Context {window}'),
  'modelPrice': _Key('¥{price}/M', '${r'$'}{price}/M'),
  'modelNoCapability': _Key('能力未知', 'Unknown capabilities'),
  // ---- D-01/D-02 搜索 ----
  'searchServicesTitle': _Key('搜索服务', 'Search services'),
  'searchServiceEnabled': _Key('启用', 'Enabled'),
  'searchServiceKey': _Key('API Key', 'API Key'),
  'searchServiceTest': _Key('测活', 'Test'),
  'searchServiceTesting': _Key('测活中…', 'Testing…'),
  'searchServiceTestOk': _Key('返回 {count} 条结果', 'Got {count} results'),
  'searchServiceTestFail': _Key('测活失败：{detail}', 'Test failed: {detail}'),
  'searchServiceNeedKey': _Key('需要 API Key', 'API key required'),
  'searchServiceNoKey': _Key('无需 Key', 'No key required'),
  'searchServiceSelected': _Key('当前使用', 'In use'),
  'searchServiceUsageTitle': _Key('搜索用量', 'Search usage'),
  'searchServiceCalls': _Key('{count} 次调用', '{count} calls'),
  'searchNoKeyFallback': _Key('未配置 Key，回退 Bing 免费引擎', 'No key configured; falling back to Bing free engine'),
  // ---- D-03 搜索筛选 ----
  'searchFilterTime': _Key('时间范围', 'Time range'),
  'searchFilterProvider': _Key('服务商', 'Provider'),
  'searchFilterModel': _Key('模型', 'Model'),
  'searchFilterAll': _Key('全部', 'All'),
  'searchFilterToday': _Key('今天', 'Today'),
  'searchFilterWeek': _Key('近 7 天', 'Last 7 days'),
  'searchFilterMonth': _Key('近 30 天', 'Last 30 days'),
  'searchFilterYear': _Key('近一年', 'Last year'),
  'searchExportResults': _Key('导出结果', 'Export results'),
  'searchExported': _Key('已导出 {count} 条结果', 'Exported {count} results'),
  // ---- D-04 知识库测试台 ----
  'kbDebugTitle': _Key('检索测试台', 'Retrieval test bench'),
  'kbDebugQuery': _Key('检索词', 'Query'),
  'kbDebugTopK': _Key('返回条数', 'Top K'),
  'kbDebugSimilarity': _Key('相似度阈值', 'Similarity threshold'),
  'kbDebugChunkSize': _Key('分块大小（覆盖，不落库）', 'Chunk size (override, not persisted)'),
  'kbDebugVectorHits': _Key('向量命中 {count}', 'Vector hits {count}'),
  'kbDebugBigramHits': _Key('关键词命中 {count}', 'Bigram hits {count}'),
  'kbDebugNoHits': _Key('无命中', 'No hits'),
  'kbDebugScore': _Key('分数 {score}', 'Score {score}'),
  'kbDebugSource': _Key('来源：{source}', 'Source: {source}'),
  'kbDebugDocId': _Key('文档 {id}', 'Document {id}'),
  'kbDebugRank': _Key('第 {rank} 位', 'Rank #{rank}'),
  // ---- D-06 世界书 ----
  'worldBookNewBook': _Key('新建世界书', 'New world book'),
  'worldBookName': _Key('名称', 'Name'),
  'worldBookDescription': _Key('描述', 'Description'),
  'worldBookActive': _Key('激活', 'Active'),
  'worldBookActivateForAgent': _Key('为 Agent 激活', 'Activate for agent'),
  'worldBookHitTest': _Key('命中测试', 'Hit test'),
  'worldBookHitTestInput': _Key('输入文本来测试匹配', 'Type text to test matching'),
  'worldBookHitTestNoHit': _Key('无命中条目', 'No entries matched'),
  'worldBookHitTestHit': _Key('命中 {count} 条，注入 {chars} 字符', 'Matched {count} entries, {chars} chars injected'),
  'worldBookGlobal': _Key('全局', 'Global'),
  // ---- E-01/E-03 语音 ----
  'voiceServicesTitle': _Key('语音服务', 'Voice services'),
  'voiceTtsSystem': _Key('系统 TTS', 'System TTS'),
  'voiceTtsProviders': _Key('网络 TTS', 'Network TTS'),
  'voiceTtsProviderName': _Key('服务商', 'Provider'),
  'voiceTtsVoice': _Key('音色', 'Voice'),
  'voiceTtsRate': _Key('语速', 'Rate'),
  'voiceTtsModel': _Key('模型', 'Model'),
  'voiceTtsPreview': _Key('试听', 'Preview'),
  'voiceTtsPreviewing': _Key('试听中…', 'Previewing…'),
  'voiceTtsAddProvider': _Key('添加 TTS 服务', 'Add TTS provider'),
  'voiceTtsTestOk': _Key('试听完成', 'Preview finished'),
  'voiceTtsTestFail': _Key('试听失败：{detail}', 'Preview failed: {detail}'),
  'voiceTtsFallbackSystem': _Key('未配置网络 TTS，回退系统朗读', 'Falling back to system TTS'),
  'voiceAsrTitle': _Key('语音输入（ASR）', 'Speech input (ASR)'),
  'voiceAsrSystem': _Key('系统语音识别', 'System speech recognition'),
  'voiceAsrCloud': _Key('云端识别', 'Cloud ASR'),
  'voiceAsrLocal': _Key('本地离线识别', 'Local offline ASR'),
  'voiceAsrListening': _Key('正在聆听…', 'Listening…'),
  'voiceAsrDone': _Key('识别完成', 'Recognition done'),
  'voiceAsrCancelled': _Key('已取消', 'Cancelled'),
  'voiceAsrNoPermission': _Key('没有麦克风权限', 'Microphone permission denied'),
  'voiceAsrError': _Key('识别失败：{detail}', 'Recognition failed: {detail}'),
  'voiceAsrUnavailable': _Key('当前平台不支持语音输入', 'Speech input unavailable on this platform'),
  'voiceAsrTapToSpeak': _Key('点击开始说话', 'Tap to speak'),
  // ---- E-04 模型下载 ----
  'voiceModelDownload': _Key('下载模型', 'Download model'),
  'voiceModelDownloading': _Key('下载中 {percent}%', 'Downloading {percent}%'),
  'voiceModelInstalled': _Key('已安装', 'Installed'),
  'voiceModelDelete': _Key('删除模型', 'Delete model'),
  'voiceModelSize': _Key('{size}', '{size}'),
  // ---- F-01 stdio ----
  'mcpTransport': _Key('传输方式', 'Transport'),
  'mcpTransportHttp': _Key('Streamable HTTP', 'Streamable HTTP'),
  'mcpTransportSse': _Key('SSE', 'SSE'),
  'mcpTransportStdio': _Key('STDIO（本地进程）', 'STDIO (local process)'),
  'mcpStdioCommand': _Key('命令', 'Command'),
  'mcpStdioArgs': _Key('参数（每行一个）', 'Arguments (one per line)'),
  'mcpStdioEnv': _Key('环境变量（KEY=VALUE，每行一个）', 'Environment (KEY=VALUE per line)'),
  'mcpStdioCwd': _Key('工作目录（可选）', 'Working directory (optional)'),
  'mcpCommandNotFound': _Key('找不到命令 {command}，请检查 PATH', 'Command {command} not found. Check PATH'),
  'mcpStdioStderr': _Key('stderr：{line}', 'stderr: {line}'),
  // ---- F-02 OAuth ----
  'mcpAuthorize': _Key('授权', 'Authorize'),
  'mcpReauthorize': _Key('重新授权', 'Re-authorize'),
  'mcpAuthorized': _Key('已授权', 'Authorized'),
  'mcpNotAuthorized': _Key('未授权', 'Not authorized'),
  'mcpOAuthInProgress': _Key('正在打开授权页面…', 'Opening authorization page…'),
  'mcpOAuthDone': _Key('授权成功', 'Authorization succeeded'),
  'mcpOAuthFailed': _Key('授权失败：{detail}', 'Authorization failed: {detail}'),
  'mcpOAuthServerFound': _Key('发现授权服务器', 'Authorization server discovered'),
  'mcpOAuthTokenRefreshed': _Key('令牌已刷新', 'Token refreshed'),
  // ---- F-03 审批 ----
  'approvalWhitelist': _Key('免审批白名单（工具名，每行一个）', 'No-approval whitelist (tool names, one per line)'),
  'approvalBlacklist': _Key('强制审批黑名单（工具名，每行一个）', 'Force-approval blacklist (tool names, one per line)'),
  'approvalTimeout': _Key('审批超时（秒）', 'Approval timeout (seconds)'),
  'approvalRememberSession': _Key('本次会话记住', 'Remember for this session'),
  // ---- F-04 工具 UI ----
  'toolExecuting': _Key('执行中', 'Running'),
  'toolDone': _Key('完成', 'Done'),
  'toolError': _Key('失败', 'Failed'),
  'toolDetail': _Key('工具详情', 'Tool details'),
  'toolArguments': _Key('参数', 'Arguments'),
  'toolResult': _Key('结果', 'Result'),
  'toolResultTruncated': _Key('（结果过长已截断）', '(result truncated)'),
  'toolApprove': _Key('同意', 'Approve'),
  'toolReject': _Key('拒绝', 'Reject'),
  'toolWaitingApproval': _Key('等待审批', 'Awaiting approval'),
  'toolShowDetail': _Key('查看详情', 'View details'),
  'toolHideDetail': _Key('收起详情', 'Hide details'),
  // ---- G-01 备份 ----
  'restoreModeTitle': _Key('恢复模式', 'Restore mode'),
  'restoreModeOverwrite': _Key('整体覆盖（推荐）', 'Overwrite (recommended)'),
  'restoreModeMerge': _Key('合并（保留现有数据）', 'Merge (keep existing)'),
  'restoreModeHint': _Key('覆盖模式将替换全部本地数据；合并模式保留现有会话与服务商', 'Overwrite replaces all local data; merge keeps existing sessions and providers'),
  'restorePreparing': _Key('正在恢复…', 'Restoring…'),
  'restoreDone': _Key('恢复完成', 'Restore completed'),
  'restoreRolledBack': _Key('恢复失败，已回滚到原数据', 'Restore failed; original data restored'),
  'restoreCorrupt': _Key('备份包损坏或校验失败', 'Backup corrupt or verification failed'),
  'restoreResume': _Key('检测到未完成的恢复，正在收敛…', 'Unfinished restore detected; finalizing…'),
  // ---- G-02 二维码 ----
  'shareQrTab': _Key('二维码', 'QR code'),
  'scanQrTitle': _Key('扫码导入', 'Scan QR code'),
  'scanQrCameraPermission': _Key('需要相机权限以扫描二维码', 'Camera permission needed to scan QR codes'),
  'scanQrInvalid': _Key('无法识别的二维码内容', 'Unrecognized QR code content'),
  'scanQrProviderImported': _Key('服务商导入成功', 'Provider imported'),
  // ---- G-06 标签 ----
  'tagsTitle': _Key('标签', 'Tags'),
  'tagsAdd': _Key('新建标签', 'New tag'),
  'tagsName': _Key('标签名', 'Tag name'),
  'tagsColor': _Key('颜色', 'Color'),
  'tagsApply': _Key('打标签', 'Add tag'),
  'tagsFilter': _Key('按标签筛选', 'Filter by tag'),
  'tagsNone': _Key('暂无标签', 'No tags'),
  'tagsManage': _Key('管理标签', 'Manage tags'),
  // ---- H-01 统计 ----
  'statsHeatmapTitle': _Key('活跃热力图', 'Activity heatmap'),
  'statsHeatmapLegend': _Key('少 → 多', 'Less → More'),
  'statsTrendTitle': _Key('趋势', 'Trend'),
  'statsRankProviders': _Key('服务商排行', 'Provider ranking'),
  'statsRankModels': _Key('模型排行', 'Model ranking'),
  'statsRankSessions': _Key('会话排行', 'Session ranking'),
  'statsViewAll': _Key('查看全部', 'View all'),
  'statsRangeAllTime': _Key('全部时间', 'All time'),
  'statsRangeLast30': _Key('近 30 天', 'Last 30 days'),
  'statsRangePrevMonth': _Key('上一月', 'Previous month'),
  'statsRangeCustom': _Key('自定义', 'Custom'),
  'statsMessages': _Key('{count} 条消息', '{count} messages'),
  // ---- H-02/H-03 个性化 ----
  'displayFontFamily': _Key('界面字体', 'UI font'),
  'displayFontSystem': _Key('跟随系统', 'System default'),
  'displayCodeFont': _Key('代码字体', 'Code font'),
  'displayUiDensity': _Key('界面密度', 'UI density'),
  'densityCompact': _Key('紧凑', 'Compact'),
  'densityStandard': _Key('标准', 'Standard'),
  'densityComfortable': _Key('宽松', 'Comfortable'),
  'displayChatFontScale': _Key('聊天字号', 'Chat font size'),
  'fontImportLocal': _Key('导入本地字体文件', 'Import local font file'),
  'fontImported': _Key('字体已导入', 'Font imported'),
  // ---- I-01 后台生成 ----
  'androidBackgroundMode': _Key('后台生成', 'Background generation'),
  'androidBackgroundOff': _Key('关闭', 'Off'),
  'androidBackgroundOn': _Key('开启', 'On'),
  'androidBackgroundOnNotify': _Key('开启并通知', 'On + notify'),
  'androidBackgroundHint': _Key('开启后锁屏/退后台时保持生成不中断', 'Keep generating when screen is locked or app is in background'),
  'notificationChatCompleted': _Key('生成完成', 'Generation finished'),
  'notificationChatFailed': _Key('生成失败', 'Generation failed'),
  // ---- I-03 桌面自启 ----
  'desktopAutostart': _Key('开机自启', 'Launch at startup'),
  'desktopAutostartHint': _Key('登录系统时自动启动 Nona', 'Start Nona when you sign in'),
  'desktopAutostartError': _Key('设置自启失败：{detail}', 'Failed to set autostart: {detail}'),
  // ---- I-06 deep-link ----
  'deeplinkChatTitle': _Key('来自外部链接', 'From external link'),
  // ---- J-04 冷启动 ----
  'devColdStartTiming': _Key('冷启动耗时（毫秒）', 'Cold start timings (ms)'),
};

/// 带占位符键的 meta 元数据（gen-l10n 需要）。
Map<String, dynamic>? _meta(List<String> placeholders) => {
      'description': 'placeholder',
      'placeholders': {
        for (final p in placeholders)
          p: {'type': 'String'}
      },
    };

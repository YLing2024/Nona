import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/app_routes.dart';
import '../../../core/models/agent.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/services/imggen_share.dart';
import '../../settings/screens/context_settings_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../../shared/widgets/desktop_drop_zone.dart';
import '../../../shared/desktop_event_bus.dart';
import '../../../shared/widgets/desktop_window_title_bar.dart';
import '../../../core/services/agent_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/share_text_receiver.dart';
import '../../../core/services/export/restore_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/platform/desktop_launcher.dart';
import '../../../core/services/quick_phrase_service.dart';
import '../../../core/services/knowledge_base_service.dart';
import '../../../core/services/mcp/approval_policy.dart';
import '../../../core/services/mcp/mcp_service.dart';
import '../../../core/services/model_capability_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/network_log_service.dart';
import '../../../core/services/network_monitor.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/storage_io_io.dart'
    if (dart.library.js_interop) '../../../core/services/storage_io_stub.dart'
    as storage_io;
import '../../../core/services/tts_service.dart' show FlutterTtsEngine;
import '../../../core/services/tts/tts_provider.dart';
import '../../../core/services/tts/voice_controller.dart';
import '../../../core/services/web_search/web_search_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../core/utils/logger.dart';
import '../controllers/auto_follow_scroll.dart';
import '../widgets/chat_view.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/session_sidebar.dart';
import '../../../shared/widgets/tag_picker.dart';
import '../widgets/context_management_sheet.dart';
import '../widgets/message_more_sheet.dart';
import '../widgets/voice_input_sheet.dart';
import '../widgets/tool_approval_dialog.dart';

/// 应用主界面：自适应布局（宽屏侧边栏 / 窄屏抽屉）+ UI 组装。
///
/// 会话/聊天领域逻辑位于 [ChatController]；本页负责 UI 交互
/// （对话框、页面跳转、输入框、滚动、TTS、快捷键）并驱动控制器。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  static const double _wideBreakpoint = 900;

  final _inputController = TextEditingController();
  // 初始滚动位置设为极大值：列表首帧即钳制到底部（最新消息），无入场滚动动画
  // B-02：自定义控制器——布局期贴底矫正（零闪烁）
  final _scrollController = AutoFollowScrollController(
    initialScrollOffset: double.maxFinite,
  );
  late final SessionService _sessionService = context.read<SessionService>();
  late final AgentService _agentService = context.read<AgentService>();
  late final ProviderService _providerService =
      context.read<ProviderService>();

  /// 领域控制器：会话/附件/发送/流式/注入逻辑。
  /// 注：宿主持有（服务经 DI 树注入，回调与宿主生命周期绑定），
  /// dispose 由宿主负责。
  late final ChatController controller = ChatController(
    chatService: context.read<ChatService>(),
    sessionService: _sessionService,
    agentService: _agentService,
    providerService: _providerService,
    capabilityService: context.read<ModelCapabilityService>(),
    webSearchService: context.read<WebSearchService>(),
    mcpService: context.read<McpService>(),
    knowledgeBase: context.read<KnowledgeBaseService>(),
    callbacks: ChatUiCallbacks(
      onStateChanged: _onControllerChanged,
      onSnack: (message) => showAppSnack(context, message),
      onScrollToBottom: _scrollToBottom,
      onRestoreInput: _restoreInput,
      requestApproval: ({
        required toolName,
        required serverName,
        required argumentsJson,
      }) =>
          ToolApprovalDialog.show(
        context,
        toolName: toolName,
        serverName: serverName,
        argumentsJson: argumentsJson,
      ).then((d) => d ?? const ApprovalDecision(allowed: false)),
      onBudgetConfirm: () async {
        final l10n = AppLocalizations.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.statsBudgetWarningTitle),
            content: Text(l10n.statsBudgetWarningBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.statsBudgetOverride),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
    ),
    onOpenSettings: _openSettings,
  );

  final _sidebarKey = GlobalKey<SessionSidebarState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// TTS 朗读控制（使用系统 TTS）。
  /// E-01/E-02：语音控制器（网络 TTS 预取优先，回退系统 TTS）。
  /// X-05：离线模式强制走系统 TTS（不发起网络合成请求）。
  late final VoiceController _ttsController;

  /// X-05：离线徽标状态（离线模式开启或网络探测离线）。
  bool _offline = false;

  /// 搜索结果跳转：进入会话后滚动定位到的消息索引（一次性，用后清除）。
  int? _pendingScrollIndex;

  /// 正在朗读的消息标识（identityHashCode）。
  int? get _speakingMessageId => _ttsController.currentId == null
      ? null
      : int.tryParse(_ttsController.currentId!);

  /// 偏好：Enter 是否发送。
  bool _sendOnEnter = false;

  ChatSession? get _currentSession => controller.currentSession;

  bool get _isWide => MediaQuery.sizeOf(context).width >= _wideBreakpoint;

  /// 控制器状态变化 → 刷新界面。
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// 回填/清空输入框（发送后清空；回滚后恢复文本）。
  void _restoreInput(String text) {
    _inputController.text = text;
    _inputController.selection = TextSelection.collapsed(offset: text.length);
  }

  /// F3-1：编辑会话摘要（写回并持久化）。
  void _onSummaryEdited(String summary) {
    final s = _currentSession;
    if (s == null) return;
    s.summary = summary.trim();
    s.summaryTokens = null;
    controller.persist();
    _onControllerChanged();
  }

  /// F3-1：清空压缩记录。
  void _onClearCompaction() {
    final s = _currentSession;
    if (s == null) return;
    controller.clearCompaction(s);
    controller.persist();
    _onControllerChanged();
  }

  /// F1-5：图片消息「转为文字」——用当前会话的视觉模型识别，
  /// 成功替换图片入消息，失败保留原图。
  Future<void> _onOcr(ChatMessage message) async {
    if (message.images.isEmpty) return;
    final session = _currentSession;
    if (session == null) return;
    final l10n = AppLocalizations.of(context);
    final provider = controller.providers
        .where((p) => p.id == session.providerId)
        .firstOrNull ??
        controller.providers
            .where((p) => p.modelIds.isNotEmpty)
            .firstOrNull;
    if (provider == null || provider.apiKey.isEmpty) {
      showAppSnack(context, l10n.ocrNoVisionModel);
      return;
    }
    if (!OcrService.hasVisionModel(provider)) {
      showAppSnack(context, l10n.ocrNoVisionModel);
      return;
    }
    final modelId = session.modelId ?? provider.modelIds.first;
    showAppSnack(context, l10n.ocrProcessing);
    try {
      final text = await _ocrService.extract(
        message.images.first,
        AppSettings(
          apiKey: provider.apiKey,
          baseUrl: provider.baseUrl,
          model: modelId,
          providerKind: provider.kind.name,
        ),
      );
      if (!mounted) return;
      final l10n2 = l10n;
      // 替换图片为文本（保留原消息位置）
      message.content = '${message.content.trim()}\n\n[OCR]\n$text'.trim();
      message.images = [];
      await controller.persist();
      if (!mounted) return;
      _onControllerChanged();
      showAppSnack(context, l10n2.ocrDone);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, l10n.ocrFailed(e.toString()));
    }
  }

  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _ttsController = VoiceController(
      providerResolver: () async {
        if (controller.settings.offlineMode) {
          return SystemTtsProvider(FlutterTtsEngine());
        }
        return TtsProviderRegistry.effective(
          systemEngine: FlutterTtsEngine(),
        );
      },
      legacy: LegacySystemTts(SystemTtsProvider(FlutterTtsEngine())),
    );
    WidgetsBinding.instance.addObserver(this);
    // TTS 朗读开始/结束（含自动播完）时刷新朗读状态图标
    _ttsController.addListener(_onTtsChanged);
    // A-03：桌面托盘/热键动作（新建会话/打开设置等）
    _desktopSub = DesktopEventBus.instance.actions.listen(_onDesktopAction);
    // C-05：图片生成页「发送到对话」投递
    ImggenShare.channel.addListener(_onImggenShared);
    // X-05：网络探测结果变化 → 离线徽标刷新
    _offline = NetworkMonitor.instance.online.value == false;
    NetworkMonitor.instance.online.addListener(_onNetworkChanged);
    _initPlatformEntries();
    _loadData();
  }

  /// X-05：网络状态变化 → 刷新离线徽标。
  void _onNetworkChanged() {
    if (!mounted) return;
    final offline = NetworkMonitor.instance.online.value == false;
    if (offline != _offline) {
      setState(() => _offline = offline);
    }
  }

  /// I-06/I-02/I-03：平台入口初始化（deep-link / 分享文本 / 命令行备份）。
  void _initPlatformEntries() {
    // I-06：deep-link 订阅（热链接；冷启动链接在数据加载完成后处理）
    unawaited(
      DeepLinkService.instance.init(onHandle: (uri) {
        final action = DeepLinkService.parse(uri);
        if (action == null || !mounted) return;
        _handleDeepLinkAction(action);
      }),
    );
    // I-02：Android 系统分享文本 → 新会话预填
    unawaited(
      ShareTextReceiver.instance.init(onText: (text) {
        if (!mounted) return;
        _openSharedText(text);
      }),
    );
    // I-03：首实例唤起（托盘/单实例）
    DesktopLauncher.setFocusHandler(() {
      if (mounted) {
        DesktopEventBus.instance.emit(DesktopAction.toggleAppVisibility);
      }
    });
    // I-03：命令行 .nona 备份文件（双击打开 → 恢复确认）
    unawaited(_handleBackupFileArgs());
  }

  /// I-06：deep-link 动作路由。
  Future<void> _handleDeepLinkAction((String?, String?, String?) action) async {
    final (providerId, modelId, text) = action;
    await controller.newSession();
    if (providerId != null && modelId != null) {
      controller.onModelChanged(providerId, modelId);
    }
    if (text != null && text.isNotEmpty && mounted) {
      _restoreInput(text);
    }
    _onControllerChanged();
  }

  /// I-02：系统分享文本 → 新会话并预填输入框。
  void _openSharedText(String text) {
    unawaited(_handleSharedText(text));
  }

  Future<void> _handleSharedText(String text) async {
    await controller.newSession();
    if (!mounted) return;
    _restoreInput(text);
    _closeDrawer();
    _onControllerChanged();
  }

  /// I-03：处理命令行传入的备份文件（.nona/.zip → 恢复流程）。
  Future<void> _handleBackupFileArgs() async {
    if (kIsWeb) return;
    final path = await DesktopLauncher.backupFileFromArgs(
      Platform.environment['NONA_OPEN_BACKUP'] != null
          ? [Platform.environment['NONA_OPEN_BACKUP']!]
          : const [],
    );
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _onDroppedBackup(bytes, file.uri.pathSegments.last);
  }

  /// C-05：接收图片生成页投递的图片 → 附加到当前输入区。
  void _onImggenShared() {
    final image = ImggenShare.channel.value;
    if (image == null || !mounted) return;
    controller.addImageUrl(image);
    _closeDrawer();
    _onControllerChanged();
  }

  StreamSubscription<DesktopAction>? _desktopSub;

  void _onDesktopAction(DesktopAction action) {
    if (!mounted) return;
    switch (action) {
      case DesktopAction.newTopic:
        _onShortcutNewSession();
      case DesktopAction.openSettings:
        Navigator.of(context).push(AppRoutes.settings());
      case DesktopAction.toggleAppVisibility:
      case DesktopAction.closeWindow:
      case DesktopAction.toggleTray:
        break;
    }
  }

  /// A-03：拖入备份文件 → 事务化恢复确认（G-01）。
  Future<void> _onDroppedBackup(Uint8List bytes, String fileName) async {
    final confirmed = await _confirmDialog(
      title: context.l10n.dropRestoreTitle,
      message: context.l10n.dropRestoreBody(fileName),
      confirmText: context.l10n.dropRestoreConfirm,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      // G-01：staging 校验 → 旧数据快照 → 安装 → 回读校验 → 提交
      final count = await RestoreService.restoreTransactional(
        bytes,
        onInstall: (sessions) async {
          final existing = await SessionService().load();
          final byId = {for (final s in existing) s.id: s};
          for (final s in sessions) {
            if (byId.containsKey(s.id)) continue;
            existing.add(s);
            byId[s.id] = s;
          }
          await SessionService().saveAll(existing);
          return sessions.length;
        },
      );
      if (!mounted) return;
      await controller.loadSessions(
        defaultTitle: context.l10n.chatSessionNewTitle,
        defaultAgentPrompt: context.l10n.agentDefaultSystemPrompt,
      );
      if (!mounted) return;
      showAppSnack(context, context.l10n.dropRestoreDone(count));
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.restoreCorrupt);
    }
  }

  void _onTtsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用挂起/退出前强制落盘：排队中的会话变更与网络日志写入持久化存储
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(controller.flushPersist());
      unawaited(NetworkLogService.instance.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _desktopSub?.cancel();
    _ttsController.removeListener(_onTtsChanged);
    ImggenShare.channel.removeListener(_onImggenShared);
    NetworkMonitor.instance.online.removeListener(_onNetworkChanged);
    _ttsController.dispose();
    controller.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- 数据加载 ----------------

  Future<void> _loadData() async {
    final providers = await loadGuarded<List<ChatProvider>>(
      _providerService.load,
      label: 'home_providers',
    );
    // 首个 await 之后 initState 已完成，可安全访问 context；
    // 首次启动的默认会话标题与默认 Agent 提示词使用本地化文案
    if (!mounted) return;
    final l10n = context.l10n;
    final defaultTitle = l10n.chatSessionNewTitle;
    final defaultAgentPrompt = l10n.agentDefaultSystemPrompt;
    final settings = await loadGuarded<AppSettings>(
      context.read<SettingsService>().load,
      label: 'home_settings',
    );
    controller
      ..l10n = l10n
      ..defaultTitle = defaultTitle
      ..providers = providers ?? []
      ..settings = settings ?? const AppSettings()
      ..sendOnEnter = settings?.sendOnEnter ?? false;
    await controller.loadSessions(
      defaultTitle: defaultTitle,
      defaultAgentPrompt: defaultAgentPrompt,
    );
    if (!mounted) return;
    setState(() => _sendOnEnter = settings?.sendOnEnter ?? false);
    if (settings != null) _applyTtsConfig(settings);
    controller.bumpTokenVersion();
  }

  // ---------------- 会话管理（UI 交互层） ----------------

  Future<void> _newSession({Agent? agent}) => controller.newSession(agent: agent);

  void _switchSession(String id) => controller.switchSession(id);

  Future<void> _deleteSession(ChatSession session) async {
    if (controller.isLoading && session.id == controller.currentSessionId) {
      await controller.stop();
    }
    if (!mounted) return;
    final confirmed = await _confirmDialog(
      title: context.l10n.chatDeleteSession,
      message: context.l10n.homeDeleteSessionConfirm(session.title),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    controller.l10n = context.l10n;
    controller.defaultTitle = context.l10n.chatSessionNewTitle;
    await controller.deleteSession(session);
    _closeDrawer();
  }

  Future<void> _renameSession(ChatSession session) async {
    final nameController = TextEditingController(text: session.title);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.homeRenameSession),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(hintText: context.l10n.homeSessionNameHint),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    session.title = name;
    try {
      await controller.persist();
    } catch (e) {
      Logger.error('home', '重命名后保存失败', e);
      if (mounted) showAppSnack(context, context.l10n.commonSaveFailed);
    }
    setState(() {});
  }

  void _pinSession(ChatSession session) => controller.pinSession(session);

  /// G-06：会话打标签（对话框多选 + 新建，结果写回会话并持久化）。
  Future<void> _tagSession(ChatSession session) async {
    final tags = await showTagPicker(context, session);
    if (!mounted) return;
    session.tags = tags;
    await controller.persist();
    if (mounted) setState(() {});
  }

  Future<void> _duplicateSession(ChatSession session) =>
      controller.duplicateSession(
        session,
        copySuffix: context.l10n.chatSessionCopySuffix,
        snackText: context.l10n.homeCopiedSession,
      );

  void _toggleAnonymous() => controller.toggleAnonymous(
    anonymousTitle: context.l10n.homeAnonymousSession,
  );

  // ---------------- 消息操作（UI 交互层） ----------------

  void _copyMessage(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    showAppSnack(context, context.l10n.homeCopied);
  }

  /// 编辑消息：跳转独立编辑页，就地修改内容（不自动重发）。
  Future<void> _editMessage(ChatMessage message) async {
    if (controller.isLoading) return;
    final session = _currentSession;
    if (session == null) return;
    final result = await Navigator.of(context).push<(String, String)>(
      AppRoutes.messageEdit(message: message),
    );
    if (result == null || !mounted) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    controller.editMessage(
      message,
      session,
      content: result.$1,
      reasoning: result.$2,
    );
  }

  /// 打开超长文本（文本文档）消息详情页：全量渲染 + 该消息全部操作。
  Future<void> _openMessageDocument(ChatMessage message) async {
    await Navigator.of(context).push<bool>(
      AppRoutes.messageDocument(
        message: message,
        speaking: _speakingMessageId == identityHashCode(message),
        onCopy: () async => _copyMessage(message),
        onSpeak: () async => _onMessageSpeak(message),
        onEdit: () => _editMessage(message),
        onRollback: () => _rollbackToMessage(message),
        onRegenerate: () async {
          _regenerateMessage(message);
        },
        onDelete: () => _deleteMessage(message),
      ),
    );
  }

  /// 回滚到此处：确认后删除该条用户消息及其之后的所有消息，
  /// 并把它的内容回填到输入框，便于修改后重新发送。
  Future<void> _rollbackToMessage(ChatMessage message) async {
    final session = _currentSession;
    if (session == null || controller.isLoading) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    final confirmed = await confirmAction(
      context,
      title: context.l10n.homeRollbackTitle,
      message: context.l10n.homeRollbackContent,
      confirmText: context.l10n.homeRollbackConfirm,
    );
    if (!confirmed || !mounted) return;
    await controller.rollbackToMessage(message);
  }

  void _regenerateMessage(ChatMessage message) {
    controller
      ..l10n = context.l10n
      ..defaultTitle = context.l10n.chatSessionNewTitle;
    controller.regenerateMessage(message);
  }

  void _rollbackVersion(ChatMessage message) => controller.rollbackVersion(message);

  Future<void> _deleteMessage(ChatMessage message) => controller.deleteMessage(message);

  // ---------------- B-01：消息多选 ----------------

  /// 批量删除所选消息（含其后所有），二次确认后执行。
  Future<void> _deleteSelectedMessages() async {
    final count = controller.selectedCount;
    if (count == 0 || !mounted) return;
    final confirmed = await _confirmDialog(
      title: context.l10n.chatDeleteSelectedTitle,
      message: context.l10n.chatDeleteSelectedBody(count),
      confirmText: context.l10n.chatDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await controller.deleteSelectedMessages();
    await controller.flushPersist();
    if (!mounted) return;
    showAppSnack(context, context.l10n.chatDeleted(count));
  }

  /// 导出所选消息为 Markdown 文件。
  Future<void> _exportSelectedMarkdown() async {
    final session = controller.currentSession;
    final indices = controller.selectedMessageIndices;
    if (session == null || indices.isEmpty) return;
    final path = await ExportService.exportToFile(
      session,
      messageIndices: indices,
    );
    controller.exitSelection();
    if (!mounted) return;
    if (path != null) {
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } else {
      showAppSnack(context, context.l10n.settingsExportFailed(''));
    }
  }

  // ---------------- B-07：消息「更多」统一菜单 ----------------

  /// 统一菜单分发：复制/编辑/回滚/重生成/删除/朗读/选择复制/导出图片/多选。
  Future<void> _onMessageMore(ChatMessage message) async {
    final session = _currentSession;
    if (session == null || !mounted) return;
    final isLastAssistant = message.role == 'assistant' &&
        session.messages.isNotEmpty &&
        identical(session.messages.last, message);
    final action = await showMessageMoreSheet(
      context,
      message: message,
      isUser: message.role == 'user',
      isLastAssistant: isLastAssistant,
      canRegenerate: !controller.isLoading && isLastAssistant,
      isStreaming: controller.streamingMessage == message,
      longDocument: message.content.length >
          (controller.settings.documentThreshold > 0
              ? controller.settings.documentThreshold
              : 0) ||
          false,
      speaking: _speakingMessageId == identityHashCode(message),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case MessageMoreAction.copy:
        _copyMessage(message);
      case MessageMoreAction.edit:
        await _editMessage(message);
      case MessageMoreAction.rollback:
        await _rollbackToMessage(message);
      case MessageMoreAction.regenerate:
        _regenerateMessage(message);
      case MessageMoreAction.delete:
        await _deleteMessage(message);
      case MessageMoreAction.speak:
        _onMessageSpeak(message);
      case MessageMoreAction.multiSelect:
        controller.enterSelection();
      case MessageMoreAction.ocr:
        await _onOcr(message);
      case MessageMoreAction.openDocument:
        await _openMessageDocument(message);
      case MessageMoreAction.selectCopy:
        await _onSelectCopy(message);
      case MessageMoreAction.exportImage:
        await _onExportMessageImage(message);
    }
  }

  /// 选择复制：弹出可选中文本对话框，复制或附带上下文发送。
  Future<void> _onSelectCopy(ChatMessage message) async {
    final text = message.content.trim();
    if (text.isEmpty) return;
    final result = await showSelectCopySheet(
      context,
      text: text,
      // E-05：选词朗读
      onSpeak: (speech) => _ttsController.speakText(speech),
    );
    if (result == null || !mounted) return;
    await Clipboard.setData(ClipboardData(text: result));
    if (!mounted) return;
    showAppSnack(context, context.l10n.homeCopied);
  }

  /// 导出单条消息为 PNG 图片。
  Future<void> _onExportMessageImage(ChatMessage message) async {
    final bytes = await showMessageExportImageDialog(
      context,
      message: message,
      isUser: message.role == 'user',
    );
    if (bytes == null || !mounted) return;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = await storage_io.saveBytesFile(
      suggestedName: 'message-$ts.png',
      data: bytes,
      extension: 'png',
      mimeType: 'image/png',
    );
    if (!mounted) return;
    showAppSnack(
      context,
      path == null
          ? context.l10n.settingsExportFailed('')
          : context.l10n.homeExportedTo(path),
    );
  }

  // ---------------- B-08：上下文管理 ----------------

  /// 打开上下文管理面板：分段报告 + 压缩/清除。
  Future<void> _onManageContext() async {
    final session = _currentSession;
    if (session == null || !mounted) return;
    await ContextManagementSheet.show(
      context,
      segments: controller.buildContextReport(session),
      usedTokens: controller.estimateTokens(session),
      limitTokens: controller.contextLimitFor(session),
      session: session,
      onCompress: () => controller.compressContext(session),
      onSetTruncated: (clear) =>
          controller.setContextTruncated(session, clear: clear),
    );
  }

  // ---------------- E-03：语音输入 ----------------

  /// 打开语音输入浮层：识别结果填入输入框。
  Future<void> _openVoiceInput() async {
    await showVoiceInputSheet(
      context,
      onResult: (text) {
        if (!mounted) return;
        final existing = _inputController.text;
        final base = existing.trim().isEmpty ? '' : '$existing ';
        _restoreInput('$base$text');
      },
    );
  }

  // ---------------- 发送 ----------------

  Future<void> _send() async {
    controller
      ..l10n = context.l10n
      ..defaultTitle = context.l10n.chatSessionNewTitle
      ..sendOnEnter = _sendOnEnter;
    await controller.send(inputText: _inputController.text);
  }

  Future<void> _stop() => controller.stop();

  // ---------------- 附件 ----------------

  Future<void> _pickImages() async {
    controller.l10n = context.l10n;
    await controller.pickImages();
  }

  Future<void> _pickDocuments() async {
    controller.l10n = context.l10n;
    await controller.pickDocuments();
  }

  void _removePendingDocument(int index) => controller.removePendingDocument(index);

  void _addImageUrl(ChatImage image) => controller.addImageUrl(image);

  void _removePendingImage(int index) => controller.removePendingImage(index);

  // ---------------- TTS 朗读 ----------------

  void _onMessageSpeak(ChatMessage message) {
    unawaited(
      _ttsController.toggle(
        '${identityHashCode(message)}',
        message.content.trim(),
      ),
    );
  }

  /// 将 TTS 语速/语言设置同步到朗读引擎。
  void _applyTtsConfig(AppSettings settings) {
    unawaited(
      _ttsController.updateConfig(
        speechRate: settings.ttsRate,
        language: settings.ttsLanguage,
      ),
    );
  }

  // ---------------- 页面跳转 ----------------

  /// 打开全屏搜索页；点击结果后切换会话并定位到对应消息。
  Future<void> _openSearch() async {
    if (controller.sessions.isEmpty) return;
    final target = await Navigator.of(context).push<SearchTarget>(
      AppRoutes.search(
        sessions: controller.sessions,
        indexedSearch: _sessionService.search,
      ),
    );
    if (target == null || !mounted) return;
    if (controller.isAnonymous) controller.toggleAnonymous();
    controller.switchSession(target.sessionId);
    setState(() => _pendingScrollIndex = target.messageIndex);
    _closeDrawer();
  }

  /// 定位完成后清除一次性跳转状态。
  void _onScrollTargetHandled() {
    if (_pendingScrollIndex == null) return;
    setState(() => _pendingScrollIndex = null);
  }

  Future<void> _openSettings() async {
    final settingsService = context.read<SettingsService>();
    await Navigator.of(context).push(AppRoutes.settings());
    final providers = await _providerService.load();
    final agents = await _agentService.load();
    final sessions = await _sessionService.load();
    final settings = await settingsService.load();
    if (!mounted) return;
    // 设置页里可能删除了服务商/模型，返回后联动清理会话引用
    controller
      ..providers = providers
      ..agents = agents
      ..settings = settings;
    final cleaned = controller.cleanupSessions(sessions, providers);
    if (settings.chatModel.isNotEmpty && sessions.isNotEmpty) {
      for (final s in sessions) {
        if (s.modelId == null) controller.applyDefaultModel(s, settings, providers);
      }
    }
    if (!controller.isAnonymous) {
      controller.sessions = sessions;
    }
    controller.bumpTokenVersion();
    setState(() {
      _sendOnEnter = settings.sendOnEnter;
    });
    _applyTtsConfig(settings);
    if (cleaned && !controller.isAnonymous) {
      await _sessionService.saveAll(controller.sessions);
    }
  }

  Future<void> _openContextSettings() async {
    final session = _currentSession;
    if (session == null) return;
    final result = await Navigator.of(context).push<ContextSettingsResult>(
      AppRoutes.contextSettings(
        initial: session.options,
        initialAgentId: session.agentId,
      ),
    );
    if (result != null && mounted) {
      session.options = result.options;
      session.agentId = result.agentId;
      controller.bumpTokenVersion();
      await controller.persist();
      setState(() {});
    }
  }

  // ---------------- 导出 ----------------

  Future<void> _exportMarkdown() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportToFile(session);
      if (path == null) return;
      if (!mounted) return;
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.settingsExportFailed(e));
    }
  }

  Future<void> _exportJson() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportJsonToFile(session);
      if (path == null) return;
      if (!mounted) return;
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.settingsExportFailed(e));
    }
  }

  /// G-03：导出 JSONL（OpenAI fine-tune 格式）。
  Future<void> _exportJsonl() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportJsonlToFile(session);
      if (path == null) return;
      if (!mounted) return;
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.settingsExportFailed(e));
    }
  }

  Future<void> _exportHtml() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportHtmlToFile(session);
      if (path == null) return;
      if (!mounted) return;
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.settingsExportFailed(e));
    }
  }

  Future<void> _exportPdf() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportPdfToFile(session);
      if (path == null) return;
      if (!mounted) return;
      showAppSnack(context, context.l10n.homeExportedTo(path));
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.settingsExportFailed(e));
    }
  }

  Future<void> _copyMarkdown() async {
    final session = _currentSession;
    if (session == null) return;
    await ExportService.copyAsMarkdown(session);
    if (!mounted) return;
    showAppSnack(context, context.l10n.homeCopiedMarkdown);
  }

  // ---------------- 工具 ----------------


  /// 确认对话框（统一实现见 [confirmAction]）。
  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String? confirmText,
    bool danger = false,
  }) {
    return confirmAction(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      danger: danger,
    );
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (!force && _isNearBottom) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 24;
  }

  // ---------------- 快捷键 ----------------

  void _onShortcutNewSession() {
    if (controller.isLoading) return;
    _newSession();
  }

  void _onShortcutSearch() {
    _openSearch();
  }

  void _onShortcutStop() {
    if (controller.isLoading) _stop();
  }

  // ---------------- 构建 ----------------

  @override
  Widget build(BuildContext context) {
    // 每次构建刷新本地化依赖（发送/自动标题等使用）
    controller
      ..l10n = context.l10n
      ..defaultTitle = context.l10n.chatSessionNewTitle
      ..sendOnEnter = _sendOnEnter;
    final session = _currentSession;
    final streamingIndex = session?.messages
        .indexWhere((m) => identical(m, controller.streamingMessage));

    final sidebar = SessionSidebar(
      key: _sidebarKey,
      sessions: controller.sessions,
      currentSessionId: controller.currentSessionId,
      isAnonymous: controller.isAnonymous,
      agents: controller.agents,
      onNewSession: _newSession,
      onNewSessionWithAgent: (agent) => _newSession(agent: agent),
      onSwitchSession: _switchSession,
      onDeleteSession: _deleteSession,
      onRenameSession: _renameSession,
      onPinSession: _pinSession,
      onDuplicateSession: _duplicateSession,
      // G-06：会话打标签
      onTagSession: _tagSession,
      onToggleAnonymous: _toggleAnonymous,
      onOpenSettings: _openSettings,
    );

    final chatView = ChatView(
      session: session,
      providers: controller.providers,
      isLoading: controller.isLoading,
      streamingIndex: streamingIndex,
      estimatedTokens: session == null ? 0 : controller.estimateTokens(session),
      contextLimit: session == null ? null : controller.contextLimitFor(session),
      sessionUsage: session == null ? (0, 0) : controller.sessionUsage(session),
      sendOnEnter: _sendOnEnter,
      autoSelectModel: controller.settings.chatModel.isNotEmpty,
      scrollController: _scrollController,
      inputController: _inputController,
      showSidebarToggle: !_isWide,
      onToggleSidebar: () => _scaffoldKey.currentState?.openDrawer(),
      onOpenContextSettings: _openContextSettings,
      onRename: () {
        final s = _currentSession;
        if (s != null) _renameSession(s);
      },
      onDelete: () {
        final s = _currentSession;
        if (s != null) _deleteSession(s);
      },
      onExportMarkdown: _exportMarkdown,
      onExportJson: _exportJson,
      onExportHtml: _exportHtml,
      onExportPdf: _exportPdf,
      onCopyMarkdown: _copyMarkdown,
      onNewSession: _newSession,
      onModelChanged: controller.onModelChanged,
      onEffortChanged: controller.onEffortChanged,
      onStreamChanged: controller.onStreamChanged,
      onSend: _send,
      onStop: _stop,
      pendingImages: controller.pendingImages,
      onPickImages: _pickImages,
      pendingDocuments: controller.pendingDocuments,
      onPickDocuments: _pickDocuments,
      onRemoveDocument: _removePendingDocument,
      onAddImageUrl: _addImageUrl,
      onRemoveImage: _removePendingImage,
      speakingMessageId: _speakingMessageId,
      onMessageSpeak: _onMessageSpeak,
      initialScrollIndex: _pendingScrollIndex,
      onScrollTargetHandled: _onScrollTargetHandled,
      onMessageCopy: _copyMessage,
      onMessageEdit: _editMessage,
      onMessageRollback: _rollbackToMessage,
      onMessageRollbackVersion: _rollbackVersion,
      onMessageRegenerate: _regenerateMessage,
      onMessageDelete: _deleteMessage,
      onOpenDocument: (message) => _openMessageDocument(message),
      streamMarkdown: controller.settings.streamMarkdownRender,
      documentThreshold: controller.settings.documentThreshold,
      onSummaryEdited: _onSummaryEdited,
      onClearCompaction: _onClearCompaction,
      onOcr: (message) => _onOcr(message),
      // B-01：消息多选
      selectionActive: controller.selectionActive,
      selectedIndices: controller.selectedMessageIndices,
      selectedCount: controller.selectedCount,
      onEnterSelection: controller.enterSelection,
      onExitSelection: controller.exitSelection,
      onSelectAll: controller.selectAllMessages,
      onInvertSelection: controller.invertSelection,
      onToggleSelect: controller.toggleSelect,
      onRangeSelect: controller.selectRangeTo,
      onDeleteSelected: _deleteSelectedMessages,
      onExportSelectedMarkdown: _exportSelectedMarkdown,
      // G-03：JSONL 导出（OpenAI fine-tune 格式）
      onExportJsonl: _exportJsonl,
      // E-03：语音输入
      onVoiceInput: _openVoiceInput,
      // E-05：批量朗读所选消息
      onSpeakSelected: () {
        final session = _currentSession;
        if (session == null) return;
        final items = <(String, String)>[
          for (final m in session.messages)
            if (controller.selectedMessageIndices.contains(
              session.messages.indexOf(m),
            ))
              ('${identityHashCode(m)}', m.content),
        ];
        unawaited(_ttsController.queueSpeak(items));
      },
      quickPhrasesLoader: (agentId) => QuickPhraseService().list(agentId: agentId),
      agentId: session?.agentId,
      // B-04：空态建议气泡（点击即发送）
      suggestions: null,
      onSuggestionTap: (text) => controller.sendText(text),
      // B-07：统一「更多」菜单
      onMessageMore: _onMessageMore,
      // B-08：上下文管理面板
      onManageContext: _onManageContext,
      // E-05：朗读浮动播放器
      ttsSpeaking: _ttsController.isSpeaking,
      ttsPaused: _ttsController.isPaused,
      ttsSpeed: _ttsController.speed,
      ttsCurrentChunk: _ttsController.currentChunkIndex,
      ttsTotalChunks: _ttsController.totalChunks,
      onTtsTogglePause: () => unawaited(_ttsController.togglePause()),
      onTtsStop: () => unawaited(_ttsController.stop()),
      onTtsSpeed: (rate) => unawaited(_ttsController.setSpeed(rate)),
      // X-05：离线徽标
      offlineBadge: _offline || controller.settings.offlineMode,
    );

    return CallbackShortcuts(
      bindings: {
        if (_isWide)
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              _onShortcutNewSession,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _onShortcutSearch,
        if (controller.isLoading)
          const SingleActivator(LogicalKeyboardKey.escape): _onShortcutStop,
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: _isWide
            ? null
            : Drawer(
                width: 300,
                shape: const RoundedRectangleBorder(),
                child: SafeArea(child: sidebar),
              ),
        // A-03：Windows 无边框自绘标题栏（其余平台无）
        appBar: defaultTargetPlatform == TargetPlatform.windows
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: const DesktopWindowTitleBar(),
              )
            : null,
        // SafeArea 处理状态栏（刘海）与底部手势条，避免内容重叠。
        // A-03：桌面拖放壳层（桌面平台生效；其余平台 no-op）
        body: SafeArea(
          top: !_isWide,
          bottom: !_isWide,
          left: false,
          right: false,
          child: DesktopDropZone(
            attachmentManager: controller.attachmentManager,
            onRestoreBackup: _onDroppedBackup,
            child: _isWide
                ? Row(
                    children: [
                      sidebar,
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(child: chatView),
                    ],
                  )
                : chatView,
          ),
        ),
      ),
    );
  }
}

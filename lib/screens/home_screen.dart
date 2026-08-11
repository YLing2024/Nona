import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../models/agent.dart';
import '../models/chat_message.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import '../screens/context_settings_screen.dart';
import '../screens/search_screen.dart';
import '../services/agent_service.dart';
import '../services/chat_service.dart';
import '../services/export_service.dart';
import '../services/knowledge_base_service.dart';
import '../services/mcp/approval_policy.dart';
import '../services/mcp/mcp_service.dart';
import '../services/model_capability_service.dart';
import '../services/ocr_service.dart';
import '../services/network_log_service.dart';
import '../services/provider_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../services/web_search/web_search_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/l10n_ext.dart';
import '../utils/load_guarded.dart';
import '../utils/logger.dart';
import '../widgets/chat_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/session_sidebar.dart';
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
  final _scrollController =
      ScrollController(initialScrollOffset: double.maxFinite);
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
  final _ttsController = TtsController(FlutterTtsEngine());

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
    WidgetsBinding.instance.addObserver(this);
    // TTS 朗读开始/结束（含自动播完）时刷新朗读状态图标
    _ttsController.addListener(_onTtsChanged);
    _loadData();
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
    _ttsController.removeListener(_onTtsChanged);
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
        // SafeArea 处理状态栏（刘海）与底部手势条，避免内容重叠。
        body: SafeArea(
          top: !_isWide,
          bottom: !_isWide,
          left: false,
          right: false,
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
    );
  }
}

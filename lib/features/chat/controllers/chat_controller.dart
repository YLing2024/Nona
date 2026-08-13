import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/agent.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/services/agent_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/document_extractor.dart';
import '../../../core/services/knowledge_base_service.dart';
import '../../../core/services/mcp/approval_policy.dart';
import '../../../core/services/mcp/mcp_service.dart';
import '../../../core/services/model_capability_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/title_generator.dart';
import '../../../core/services/web_search/web_search_service.dart';
import 'attachment_manager.dart';
import 'chat_run_orchestrator.dart';
import 'context_builder.dart';
import 'message_ops.dart';
import '../../../core/services/session_manager.dart';

/// UI 回调总线：控制器与宿主（界面层）的解耦接口。
///
/// 未来新钩子（审批 / 进度 / 建议气泡 / 恢复横幅）一律以
/// 本类字段形式添加，保持构造参数稳定。
class ChatUiCallbacks {
  /// 通知宿主刷新界面（setState）。
  final VoidCallback? onStateChanged;

  /// 展示提示条。
  final void Function(String message)? onSnack;

  /// 滚动到底部。
  final VoidCallback? onScrollToBottom;

  /// 回填输入框（回滚/删除用户消息后）。
  final void Function(String text)? onRestoreInput;

  /// 工具审批 UI（MCP 外部工具调用前弹出确认）。
  final Future<ApprovalDecision> Function({
    required String toolName,
    required String serverName,
    required String argumentsJson,
  })? requestApproval;

  /// 超预算发送确认（F3-2）。
  final Future<bool> Function()? onBudgetConfirm;

  const ChatUiCallbacks({
    this.onStateChanged,
    this.onSnack,
    this.onScrollToBottom,
    this.onRestoreInput,
    this.requestApproval,
    this.onBudgetConfirm,
  });
}

/// 会话与聊天领域控制器：状态聚合与事件转发。
///
/// 职责按域委托给下列组件（公共 API 保持稳定，内部为搬移 + 委托）：
/// - [SessionManager]：会话 CRUD/切换/置顶/匿名
/// - [MessageOps]：消息编辑/重生成/回滚/版本链
/// - [ContextBuilder]：token 估算/裁剪/上下文上限推断
/// - [ChatRunOrchestrator]：发送管线/流式帧刷新/停止
/// - [AttachmentManager]：待发图片/文档队列
/// - [TitleGenerator]：自动标题与回退
///
/// 不是 ChangeNotifier：状态变化经 [ChatUiCallbacks.onStateChanged] 回调
/// 通知宿主（宿主持有 setState 与生命周期），避免误导性的 listenable API。
class ChatController {
  final ChatService chatService;
  final SessionService sessionService;
  final AgentService agentService;
  final ProviderService providerService;
  final ModelCapabilityService capabilityService;
  final WebSearchService webSearchService;
  final McpService mcpService;
  final KnowledgeBaseService knowledgeBase;

  /// UI 回调总线（由宿主注入）。
  final ChatUiCallbacks callbacks;

  /// 打开设置页。
  final VoidCallback? onOpenSettings;

  // ---------------- 内部组件 ----------------

  late final SessionManager _sessionManager;
  late final ContextBuilder _contextBuilder;
  late final AttachmentManager _attachments;
  late final MessageOps _messageOps;
  late final TitleGenerator _titleGenerator;
  late final ChatRunOrchestrator _orchestrator;

  /// 本地化文案（宿主发送前刷新）。
  AppLocalizations? l10n;

  /// 本地化默认会话标题（宿主每次构建前刷新；见 HomeScreen.build）。
  String defaultTitle = '';

  /// 偏好：Enter 是否发送。
  bool sendOnEnter = false;

  // ---------------- 状态 ----------------

  AppSettings settings = const AppSettings();
  List<ChatProvider> providers = [];
  List<Agent> agents = [];
  bool isLoading = false;
  ChatMessage? streamingMessage;

  /// token 估算缓存版本号（消息变更时递增，ContextBuilder 据此失效缓存）。
  int tokenVersion = 0;

  /// 单张图片体积上限（与 AttachmentManager 一致，兼容旧引用）。
  static const int kMaxImageBytes = AttachmentManager.kMaxImageBytes;

  /// 服务依赖：无默认实例（由 DI 根 / 宿主显式注入），
  /// 便于测试注入 fake 与避免隐式全局单例。
  ChatController({
    required this.chatService,
    required this.sessionService,
    required this.agentService,
    required this.providerService,
    required this.capabilityService,
    required this.webSearchService,
    required this.mcpService,
    required this.knowledgeBase,
    this.callbacks = const ChatUiCallbacks(),
    this.onOpenSettings,
  }) {
    _sessionManager = SessionManager(
      sessionService: sessionService,
      defaultTitle: () => defaultTitle,
      settings: () => settings,
      providers: () => providers,
      isLoading: () => isLoading,
      onStateChanged: callbacks.onStateChanged,
      bumpTokenVersion: bumpTokenVersion,
      onSnack: callbacks.onSnack,
    );
    _contextBuilder = ContextBuilder(capabilityService: capabilityService);
    _attachments = AttachmentManager(
      onStateChanged: callbacks.onStateChanged,
      onSnack: callbacks.onSnack,
      l10n: () => l10n,
    );
    _titleGenerator = TitleGenerator(
      providerService: providerService,
      chatService: chatService,
      settings: () => settings,
      defaultTitle: () => defaultTitle,
      l10n: () => l10n,
      onStateChanged: callbacks.onStateChanged,
      persist: persist,
    );
    _messageOps = MessageOps(
      currentSession: () => _sessionManager.currentSession,
      isLoading: () => isLoading,
      streamingMessage: () => streamingMessage,
      stop: () => _orchestrator.stop(),
      sendText: (text) => _orchestrator.sendText(text),
      onRestoreInput: callbacks.onRestoreInput,
      persist: persist,
      bumpTokenVersion: bumpTokenVersion,
      onStateChanged: callbacks.onStateChanged,
    );
    _orchestrator = ChatRunOrchestrator(
      chatService: chatService,
      providerService: providerService,
      webSearchService: webSearchService,
      mcpService: mcpService,
      knowledgeBase: knowledgeBase,
      sessionManager: _sessionManager,
      contextBuilder: _contextBuilder,
      messageOps: _messageOps,
      titleGenerator: _titleGenerator,
      attachmentManager: _attachments,
      agents: () => agents,
      settings: () => settings,
      providers: () => providers,
      setProviders: (value) => providers = value,
      l10n: () => l10n,
      notify: _notify,
      onSnack: callbacks.onSnack,
      onScrollToBottom: callbacks.onScrollToBottom,
      onRestoreInput: callbacks.onRestoreInput,
      onOpenSettings: onOpenSettings,
      requestApproval: callbacks.requestApproval,
      onBudgetConfirm: callbacks.onBudgetConfirm,
      bumpTokenVersion: bumpTokenVersion,
      isLoading: () => isLoading,
      setIsLoading: (value) => isLoading = value,
      streamingMessage: () => streamingMessage,
      setStreamingMessage: (value) => streamingMessage = value,
    );
  }

  // ---------------- 会话集合（委托 SessionManager） ----------------

  /// 会话列表。
  List<ChatSession> get sessions => _sessionManager.sessions;

  set sessions(List<ChatSession> value) => _sessionManager.sessions = value;

  /// 当前会话 id。
  String? get currentSessionId => _sessionManager.currentSessionId;

  set currentSessionId(String? value) => _sessionManager.currentSessionId = value;

  /// 匿名会话（[isAnonymous] 为 true 时使用，不持久化）。
  ChatSession? get anonymousSession => _sessionManager.anonymousSession;

  set anonymousSession(ChatSession? value) =>
      _sessionManager.anonymousSession = value;

  /// 是否处于匿名模式。
  bool get isAnonymous => _sessionManager.isAnonymous;

  set isAnonymous(bool value) => _sessionManager.isAnonymous = value;

  /// 当前会话（匿名优先）。
  ChatSession? get currentSession => _sessionManager.currentSession;

  // ---------------- 附件队列（委托 AttachmentManager） ----------------

  /// 待发送的图片附件。
  List<ChatImage> get pendingImages => _attachments.images;

  set pendingImages(List<ChatImage> value) => _attachments.images = value;

  /// 待发送的文档附件。
  List<ChatDocument> get pendingDocuments => _attachments.documents;

  set pendingDocuments(List<ChatDocument> value) =>
      _attachments.documents = value;

  void _notify() => callbacks.onStateChanged?.call();

  void bumpTokenVersion() {
    tokenVersion++;
  }

  // ---------------- 会话加载与持久化 ----------------

  /// 加载会话（配合宿主的 providers/agents/settings 加载流程）。
  ///
  /// [defaultTitle]/[defaultAgentPrompt] 为本地化默认值（宿主传入）。
  Future<void> loadSessions({
    required String defaultTitle,
    required String defaultAgentPrompt,
  }) async {
    agents = await agentService.load(defaultSystemPrompt: defaultAgentPrompt);
    await _sessionManager.load(title: defaultTitle);
    _notify();
  }

  /// 联动清理：服务商或模型被删除后，清除会话中指向它们的引用。
  ///
  /// 返回是否有会话被修改，便于调用方决定是否持久化。
  bool cleanupSessions(
    List<ChatSession> sessions,
    List<ChatProvider> providers,
  ) {
    return _sessionManager.cleanupSessions(sessions, providers);
  }

  void applyDefaultModel(
    ChatSession session, [
    AppSettings? settings,
    List<ChatProvider>? providers,
  ]) {
    _sessionManager.applyDefaultModel(session, settings, providers);
  }

  Future<void> persist() => _sessionManager.persist();

  /// 取消防抖并立即落盘（切会话 / 应用挂起 / 退出前）。
  Future<void> flushPersist() => _sessionManager.flushNow();

  // ---------------- 上下文窗口（委托 ContextBuilder） ----------------

  /// 会话上下文窗口上限：显式配置优先，否则按模型能力表/内置库推断。
  int? contextLimitFor(ChatSession session) =>
      _contextBuilder.contextLimitFor(session);

  int estimateTokens(ChatSession session) =>
      _contextBuilder.estimateTokens(session, tokenVersion: tokenVersion);

  /// 会话累计上行/下行 token（由每条已完成的回复用量累加）。
  (int prompt, int completion) sessionUsage(ChatSession session) =>
      _contextBuilder.sessionUsage(session);

  /// 发送前自动裁剪：超出上下文上限时移除最早的消息。
  ///
  /// 上限取「显式配置」或「模型能力表/内置库推断的上下文窗口」。
  int trimContext(ChatSession session) =>
      _contextBuilder.trimContext(session);

  /// F3-1：摘要压缩计划（超限时优先压缩早期消息）。
  CompactionPlan? buildCompactionPlan(ChatSession session) =>
      _contextBuilder.buildPlan(session);

  /// F3-1：落地压缩计划（替换消息、写摘要与压缩记录）。
  void applyCompaction(
    ChatSession session,
    CompactionPlan plan, {
    required String summary,
  }) =>
      _contextBuilder.applyCompaction(session, plan, summary: summary);

  /// F3-1：清空会话摘要与压缩记录。
  void clearCompaction(ChatSession session) =>
      _contextBuilder.clearCompaction(session);

  // ---------------- 会话管理（委托 SessionManager） ----------------

  Future<void> newSession({Agent? agent}) =>
      _sessionManager.newSession(agent: agent);

  void switchSession(String id) => _sessionManager.switchSession(id);

  Future<void> deleteSession(ChatSession session) =>
      _sessionManager.deleteSession(session);

  void pinSession(ChatSession session) => _sessionManager.pinSession(session);

  Future<void> duplicateSession(
    ChatSession session, {
    String? copySuffix,
    String? snackText,
  }) =>
      _sessionManager.duplicateSession(
        session,
        copySuffix: copySuffix,
        snackText: snackText,
      );

  void toggleAnonymous({String? anonymousTitle}) =>
      _sessionManager.toggleAnonymous(anonymousTitle: anonymousTitle);

  // ---------------- 消息操作（委托 MessageOps） ----------------

  /// 就地修改消息内容（编辑页保存后调用）。
  void editMessage(
    ChatMessage message,
    ChatSession session, {
    required String content,
    String? reasoning,
  }) {
    _messageOps.editMessage(
      message,
      session,
      content: content,
      reasoning: reasoning,
    );
  }

  /// 回滚到用户消息：删除该条及其后所有消息，回填输入框。
  Future<void> rollbackToMessage(ChatMessage message) =>
      _messageOps.rollbackToMessage(message);

  void regenerateMessage(ChatMessage message) =>
      _messageOps.regenerateMessage(message);

  /// 回退到上一版回复：与最新历史版本交换内容。
  void rollbackVersion(ChatMessage message) =>
      _messageOps.rollbackVersion(message);

  /// 删除消息（含其后所有）。
  Future<void> deleteMessage(ChatMessage message) =>
      _messageOps.deleteMessage(message);

  // ---------------- 发送 / 停止（委托 ChatRunOrchestrator） ----------------

  /// 发送输入框内容（附件来自待发送队列）。
  Future<void> send({required String inputText}) =>
      _orchestrator.send(inputText: inputText);

  /// 核心发送流程；[text] 为空但带图片时表示纯图片消息，
  /// [text] 为空且无图片表示沿用已有消息（重新生成场景）。
  Future<void> sendText(String text) => _orchestrator.sendText(text);

  Future<void> stop() => _orchestrator.stop();

  /// 将聊天异常映射为本地化文案；未知错误码回退原始描述。
  static String localizeChatError(AppLocalizations l10n, ChatException e) =>
      ChatRunOrchestrator.localizeChatError(l10n, e);

  /// 释放活动请求与防抖定时器（宿主 dispose 时调用）。
  void dispose() {
    _orchestrator.dispose();
    _sessionManager.dispose();
  }

  // ---------------- 模型/参数变更 ----------------

  void onModelChanged(String providerId, String modelId) {
    final session = currentSession;
    if (session == null) return;
    session.providerId = providerId;
    session.modelId = modelId;
    // 非推理模型不支持思考，切换时清空思考强度
    if (!_isReasoningModel(providerId, modelId) &&
        session.options.reasoningEffort != null) {
      session.options = session.options.copyWith(reasoningEffort: null);
    }
    persist();
    _notify();
  }

  /// 指定服务商下的模型是否为推理模型（未标记时视为非推理）。
  bool _isReasoningModel(String providerId, String modelId) {
    for (final p in providers) {
      if (p.id == providerId) {
        return p.modelConfigs[modelId]?.reasoning ?? false;
      }
    }
    return false;
  }

  void onEffortChanged(String? effort) {
    final session = currentSession;
    if (session == null) return;
    session.options = session.options.copyWith(reasoningEffort: effort);
    persist();
    _notify();
  }

  void onStreamChanged(bool stream) {
    final session = currentSession;
    if (session == null) return;
    session.options = session.options.copyWith(stream: stream);
    persist();
    _notify();
  }

  // ---------------- 附件（委托 AttachmentManager） ----------------

  /// 打开系统文件选择器选取图片（多选），转为 Data URL 加入待发送列表。
  Future<void> pickImages() => _attachments.pickImages();

  /// 选择并提取文档附件（PDF/DOCX/TXT），提取失败提示。
  Future<void> pickDocuments() => _attachments.pickDocuments();

  void removePendingDocument(int index) =>
      _attachments.removePendingDocument(index);

  void addImageUrl(ChatImage image) => _attachments.addImageUrl(image);

  void removePendingImage(int index) => _attachments.removePendingImage(index);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/agent.dart';
import '../models/chat_message.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/chat_service.dart';
import '../services/export_service.dart';
import '../services/provider_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../utils/token_counter.dart';
import '../widgets/chat_view.dart';
import '../widgets/session_sidebar.dart';
import 'context_settings_screen.dart';
import 'settings_screen.dart';

/// 应用主界面：自适应布局（宽屏侧边栏 / 窄屏抽屉）+ 会话状态中枢。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideBreakpoint = 900;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _sessionService = SessionService();
  final _agentService = AgentService();
  final _providerService = ProviderService();
  final _sidebarKey = GlobalKey<SessionSidebarState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 偏好：Enter 是否发送。
  bool _sendOnEnter = false;

  List<ChatSession> _sessions = [];
  List<ChatProvider> _providers = [];
  List<Agent> _agents = [];
  String? _currentSessionId;
  bool _isLoading = false;

  /// 当前正在流式生成的消息（跨会话追踪）。
  ChatMessage? _streamingMessage;
  ChatRequestHandle? _activeHandle;

  /// 匿名会话：仅存在于内存，不持久化、不出现在会话列表中。
  ChatSession? _anonymousSession;
  bool _isAnonymous = false;

  /// token 估算缓存（版本号变化时重算，避免流式高频重算）。
  int _tokenVersion = 0;
  int _cachedTokenVersion = -1;
  int _cachedTokens = 0;
  String? _cachedSessionId;

  ChatSession? get _currentSession {
    if (_isAnonymous) return _anonymousSession;
    for (final s in _sessions) {
      if (s.id == _currentSessionId) return s;
    }
    return null;
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= _wideBreakpoint;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- 数据加载与持久化 ----------------

  Future<void> _loadData() async {
    final providers = await _providerService.load();
    final agents = await _agentService.load();
    var sessions = await _sessionService.load();
    if (sessions.isEmpty) {
      final session = ChatSession.create();
      sessions = [session];
      await _sessionService.save(sessions);
    }
    final settings = await SettingsService().load();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _agents = agents;
      _sessions = sessions;
      _currentSessionId = sessions.first.id;
      _sendOnEnter = settings.sendOnEnter;
    });
    _bumpTokenVersion();
  }

  Future<void> _persist() async {
    if (_isAnonymous) return;
    await _sessionService.save(_sessions);
  }

  void _bumpTokenVersion() {
    _tokenVersion++;
  }

  int _estimateTokens(ChatSession session) {
    if (_tokenVersion == _cachedTokenVersion &&
        session.id == _cachedSessionId) {
      return _cachedTokens;
    }
    var total = TokenCounter.estimate(session.options.systemPrompt) + 4;
    for (final m in session.messages) {
      total += TokenCounter.estimateMessage(m.role, m.content);
    }
    _cachedTokenVersion = _tokenVersion;
    _cachedTokens = total;
    _cachedSessionId = session.id;
    return total;
  }

  /// 会话累计上行/下行 token（由每条已完成的回复用量累加）。
  (int prompt, int completion) _sessionUsage(ChatSession session) {
    var prompt = 0;
    var completion = 0;
    for (final m in session.messages) {
      prompt += m.promptTokens ?? 0;
      completion += m.completionTokens ?? 0;
    }
    return (prompt, completion);
  }

  /// 发送前自动裁剪：超出上下文上限时移除最早的消息。
  int _trimContext(ChatSession session) {
    final max = session.options.maxContextTokens;
    if (max == null || !session.options.autoTrim) return 0;
    var total = TokenCounter.estimate(session.options.systemPrompt) + 4;
    for (final m in session.messages) {
      total += TokenCounter.estimateMessage(m.role, m.content);
    }
    var removed = 0;
    while (total > max && session.messages.length > 1) {
      final first = session.messages.removeAt(0);
      total -= TokenCounter.estimateMessage(first.role, first.content);
      removed++;
    }
    return removed;
  }

  // ---------------- 会话管理 ----------------

  Future<void> _newSession({Agent? agent}) async {
    if (_isLoading) return;
    final session = ChatSession.create();
    if (agent != null) {
      session.options = agent.options;
      session.agentId = agent.id;
    }
    setState(() {
      _sessions.insert(0, session);
      _currentSessionId = session.id;
      _isAnonymous = false;
    });
    _bumpTokenVersion();
    await _persist();
    _closeDrawer();
    _scrollToBottom(force: true);
  }

  void _switchSession(String id) {
    if (id == _currentSessionId) return;
    setState(() => _currentSessionId = id);
    _bumpTokenVersion();
    _closeDrawer();
    _scrollToBottom(force: true);
  }

  Future<void> _deleteSession(ChatSession session) async {
    if (_isLoading && session.id == _currentSessionId) {
      await _stop();
    }
    final confirmed = await _confirmDialog(
      title: '删除会话',
      message: '确定删除「${session.title}」吗？删除后不可恢复。',
      confirmText: '删除',
      danger: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
      if (_currentSessionId == session.id) {
        _currentSessionId = _sessions.firstOrNull?.id;
      }
      if (_sessions.isEmpty) {
        final s = ChatSession.create();
        _sessions.add(s);
        _currentSessionId = s.id;
      }
    });
    _bumpTokenVersion();
    await _persist();
    _closeDrawer();
  }

  Future<void> _renameSession(ChatSession session) async {
    final controller = TextEditingController(text: session.title);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: '会话名称'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => session.title = name);
    await _persist();
  }

  void _pinSession(ChatSession session) {
    setState(() => session.pinned = !session.pinned);
    _persist();
  }

  Future<void> _duplicateSession(ChatSession session) async {
    final copy = session.duplicate();
    setState(() => _sessions.insert(0, copy));
    _bumpTokenVersion();
    await _persist();
    _snack('已复制会话');
  }

  void _toggleAnonymous() {
    if (_isLoading) return;
    setState(() {
      _isAnonymous = !_isAnonymous;
      if (_isAnonymous && _anonymousSession == null) {
        _anonymousSession = ChatSession.create()..title = '匿名会话';
      }
    });
    _bumpTokenVersion();
    _scrollToBottom(force: true);
  }

  // ---------------- 消息操作 ----------------

  void _copyMessage(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    _snack('已复制到剪贴板');
  }

  Future<void> _editMessage(ChatMessage message) async {
    if (_isLoading || message.role != 'user') return;
    final controller = TextEditingController(text: message.content);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑并重发'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(hintText: '修改消息内容…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存并重发'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final session = _currentSession;
    if (session == null) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    setState(() {
      message.content = text;
      session.truncateMessagesFrom(idx + 1);
    });
    _bumpTokenVersion();
    await _persist();
    await _sendText('');
  }

  void _regenerateMessage(ChatMessage message) {
    final session = _currentSession;
    if (session == null || _isLoading) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    session.truncateMessagesFrom(idx);
    _bumpTokenVersion();
    _sendText('');
  }

  void _continueMessage(ChatMessage message) {
    final session = _currentSession;
    if (session == null || _isLoading) return;
    session.messages.add(
      ChatMessage(
        role: 'user',
        content: '继续上一条回答，从上次中断的地方接着写，不要重复已经输出的内容。',
      ),
    );
    _bumpTokenVersion();
    _sendText('');
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final session = _currentSession;
    if (session == null) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    if (_isLoading && identical(message, _streamingMessage)) {
      await _stop();
    }
    setState(() {
      session.truncateMessagesFrom(idx);
    });
    _bumpTokenVersion();
    await _persist();
  }

  // ---------------- 发送 / 停止 / 流式 ----------------

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;
    await _sendText(text);
  }

  /// 核心发送流程；[text] 为空表示沿用已有消息（重新生成/继续/编辑场景）。
  Future<void> _sendText(String text) async {
    final session = _currentSession;
    if (_isLoading || session == null) return;
    if (text.trim().isNotEmpty) {
      session.messages.add(ChatMessage(role: 'user', content: text.trim()));
      if (!_isAnonymous) session.updateTitleFromFirstMessage();
      session.updatedAt = DateTime.now();
      _inputController.clear();
    } else if (session.messages.isEmpty) {
      return;
    }

    // 上下文窗口管理：超限时自动裁剪
    final trimmed = _trimContext(session);
    if (trimmed > 0) {
      _snack('上下文超出上限，已自动裁剪最早 $trimmed 条消息');
    }
    session.updatedAt = DateTime.now();
    _bumpTokenVersion();

    final providers = await _providerService.load();
    if (!mounted) return;
    if (providers.isEmpty) {
      _snack('请先在设置中配置服务商');
      await _openSettings();
      return;
    }

    // 解析服务商与模型
    ChatProvider? provider;
    for (final p in providers) {
      if (p.id == session.providerId) {
        provider = p;
        break;
      }
    }
    // 默认选择第一个已配置模型的服务商（跳过空的 OpenAI 占位）
    provider ??= providers
        .where((p) => p.modelIds.isNotEmpty)
        .firstOrNull ?? providers.firstOrNull;
    if (provider == null || provider.apiKey.isEmpty) {
      _snack('请先完善服务商的 API Key');
      await _openSettings();
      return;
    }
    var modelId = session.modelId;
    if (modelId == null || !provider.modelIds.contains(modelId)) {
      modelId = provider.modelIds.firstOrNull;
    }
    if (modelId == null) {
      _snack('该服务商未配置模型，请到设置中添加');
      await _openSettings();
      return;
    }
    setState(() {
      _providers = providers;
      _isLoading = true;
    });

    final effectiveSettings = AppSettings(
      apiKey: provider.apiKey,
      baseUrl: provider.baseUrl,
      model: modelId,
    );

    final assistantMessage = ChatMessage(role: 'assistant', content: '');
    setState(() {
      session.messages.add(assistantMessage);
      _streamingMessage = assistantMessage;
    });
    await _persist();
    _scrollToBottom(force: true);

    final handle = _chatService.sendChat(
      settings: effectiveSettings,
      messages: session.messages,
      options: session.options,
      onPartial: (delta) {
        if (!mounted) return;
        setState(() {
          assistantMessage.content += delta;
          session.updatedAt = DateTime.now();
          _tokenVersion++;
        });
        _scrollToBottom();
      },
      onReasoning: (delta) {
        if (!mounted) return;
        setState(() {
          assistantMessage.reasoningContent += delta;
          session.updatedAt = DateTime.now();
          _tokenVersion++;
        });
        _scrollToBottom();
      },
    );
    _activeHandle = handle;

    try {
      final result = await handle.result;
      if (!mounted) return;
      setState(() {
        assistantMessage.content = result.content;
        assistantMessage.promptTokens = result.usage?.promptTokens;
        assistantMessage.completionTokens = result.usage?.completionTokens;
        assistantMessage.elapsedMs = result.elapsedMs;
        session.updatedAt = DateTime.now();
        _isLoading = false;
        _streamingMessage = null;
        _activeHandle = null;
        _tokenVersion++;
      });
      await _persist();
    } on ChatCancelledException {
      if (!mounted) return;
      setState(() {
        assistantMessage.interrupted = true;
        session.updatedAt = DateTime.now();
        _isLoading = false;
        _streamingMessage = null;
        _activeHandle = null;
        _tokenVersion++;
      });
      await _persist();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        session.updatedAt = DateTime.now();
        _isLoading = false;
        _streamingMessage = null;
        _activeHandle = null;
        _tokenVersion++;
        if (assistantMessage.content.isEmpty &&
            assistantMessage.reasoningContent.isEmpty) {
          session.messages.remove(assistantMessage);
        } else {
          assistantMessage.failed = true;
        }
      });
      await _persist();
      _snack(e.message);
    } on ChatTimeoutException catch (e) {
      if (!mounted) return;
      setState(() {
        session.updatedAt = DateTime.now();
        _isLoading = false;
        _streamingMessage = null;
        _activeHandle = null;
        _tokenVersion++;
        if (assistantMessage.content.isEmpty &&
            assistantMessage.reasoningContent.isEmpty) {
          session.messages.remove(assistantMessage);
        } else {
          assistantMessage.failed = true;
        }
      });
      await _persist();
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        session.updatedAt = DateTime.now();
        _isLoading = false;
        _streamingMessage = null;
        _activeHandle = null;
        _tokenVersion++;
        if (assistantMessage.content.isEmpty &&
            assistantMessage.reasoningContent.isEmpty) {
          session.messages.remove(assistantMessage);
        } else {
          assistantMessage.failed = true;
        }
      });
      await _persist();
      _snack('网络请求失败，请检查网络或配置');
    }
    _scrollToBottom();
  }

  Future<void> _stop() async {
    final handle = _activeHandle;
    _activeHandle = null;
    await handle?.cancel();
  }

  // ---------------- 页面跳转 ----------------

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    final providers = await _providerService.load();
    final agents = await _agentService.load();
    final sessions = await _sessionService.load();
    final settings = await SettingsService().load();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _agents = agents;
      if (!_isAnonymous) _sessions = sessions;
      _sendOnEnter = settings.sendOnEnter;
    });
    _bumpTokenVersion();
  }

  Future<void> _openContextSettings() async {
    final session = _currentSession;
    if (session == null) return;
    final result = await Navigator.of(context).push<ContextSettingsResult>(
      MaterialPageRoute(
        builder: (_) => ContextSettingsScreen(
          initial: session.options,
          initialAgentId: session.agentId,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        session.options = result.options;
        session.agentId = result.agentId;
      });
      _bumpTokenVersion();
      await _persist();
    }
  }

  // ---------------- 导出 ----------------

  Future<void> _exportMarkdown() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportToFile(session);
      if (path != null && mounted) _snack('已导出到 $path');
    } catch (e) {
      _snack('导出失败：$e');
    }
  }

  Future<void> _exportJson() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final path = await ExportService.exportJsonToFile(session);
      if (path != null && mounted) _snack('已导出到 $path');
    } catch (e) {
      _snack('导出失败：$e');
    }
  }

  Future<void> _copyMarkdown() async {
    final session = _currentSession;
    if (session == null) return;
    await ExportService.copyAsMarkdown(session);
    _snack('已复制为 Markdown');
  }

  // ---------------- 工具 ----------------

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    String confirmText = '确定',
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: scheme.error)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
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
    return position.pixels >= position.maxScrollExtent - 100;
  }

  // ---------------- 快捷键 ----------------

  void _onShortcutNewSession() {
    if (_isLoading) return;
    _newSession();
  }

  void _onShortcutSearch() {
    _sidebarKey.currentState?.focusSearch();
  }

  void _onShortcutStop() {
    if (_isLoading) _stop();
  }

  void _onModelChanged(String providerId, String modelId) {
    final session = _currentSession;
    if (session == null) return;
    setState(() {
      session.providerId = providerId;
      session.modelId = modelId;
    });
    _persist();
  }

  void _onEffortChanged(String? effort) {
    final session = _currentSession;
    if (session == null) return;
    setState(() {
      session.options = session.options.copyWith(reasoningEffort: effort);
    });
    _persist();
  }

  void _onStreamChanged(bool stream) {
    final session = _currentSession;
    if (session == null) return;
    setState(() {
      session.options = session.options.copyWith(stream: stream);
    });
    _persist();
  }

  // ---------------- 构建 ----------------

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;
    final streamingIndex = session?.messages
        .indexWhere((m) => identical(m, _streamingMessage));

    final sidebar = SessionSidebar(
      key: _sidebarKey,
      sessions: _sessions,
      currentSessionId: _currentSessionId,
      isAnonymous: _isAnonymous,
      agents: _agents,
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
      providers: _providers,
      isLoading: _isLoading,
      streamingIndex: streamingIndex,
      estimatedTokens:
          session == null ? 0 : _estimateTokens(session),
      sessionUsage:
          session == null ? (0, 0) : _sessionUsage(session),
      sendOnEnter: _sendOnEnter,
      scrollController: _scrollController,
      inputController: _inputController,      showSidebarToggle: !_isWide,
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
      onCopyMarkdown: _copyMarkdown,
      onNewSession: _newSession,
      onOpenSettings: _openSettings,
      onModelChanged: _onModelChanged,
      onEffortChanged: _onEffortChanged,
      onStreamChanged: _onStreamChanged,
      onSend: _send,
      onStop: _stop,
      onMessageCopy: _copyMessage,
      onMessageEdit: _editMessage,
      onMessageRegenerate: _regenerateMessage,
      onMessageContinue: _continueMessage,
      onMessageDelete: _deleteMessage,
    );

    return CallbackShortcuts(
      bindings: {
        if (_isWide)
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              _onShortcutNewSession,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _onShortcutSearch,
        if (_isLoading)
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

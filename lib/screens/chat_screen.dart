import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/agent.dart';
import '../models/chat_message.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/chat_service.dart';
import '../services/provider_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import 'context_settings_screen.dart';
import 'settings_screen.dart';

/// 聊天主界面，左侧 Drawer 承载会话列表。
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _sessionService = SessionService();
  final _agentService = AgentService();
  final _providerService = ProviderService();

  List<ChatSession> _sessions = [];
  List<ChatProvider> _providers = [];
  String? _currentSessionId;
  bool _isLoading = false;

  /// 匿名会话：仅存在于内存，不持久化、不出现在会话列表中。
  ChatSession? _anonymousSession;
  bool _isAnonymous = false;

  ChatSession? get _currentSession {
    if (_isAnonymous) return _anonymousSession;
    for (final s in _sessions) {
      if (s.id == _currentSessionId) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final providers = await _providerService.load();
    var sessions = await _sessionService.load();
    if (sessions.isEmpty) {
      final session = ChatSession.create();
      sessions = [session];
      await _sessionService.save(sessions);
    }
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _sessions = sessions;
      _currentSessionId = sessions.first.id;
    });
  }

  Future<void> _persist() async {
    if (_isAnonymous) return;
    await _sessionService.save(_sessions);
  }

  void _toggleAnonymous() {
    setState(() {
      _isAnonymous = !_isAnonymous;
      if (_isAnonymous && _anonymousSession == null) {
        _anonymousSession = ChatSession.create()..title = '匿名会话';
      }
    });
    _scrollToBottom();
  }

  /// 单击新建会话：若存在默认 Agent 则自动套用其配置，否则为空白配置。
  Future<void> _newSession() async {
    final agents = await _agentService.load();
    Agent? defaultAgent;
    for (final a in agents) {
      if (a.isDefault) {
        defaultAgent = a;
        break;
      }
    }

    final session = ChatSession.create();
    if (defaultAgent != null) {
      session.options = defaultAgent.options;
      session.agentId = defaultAgent.id;
    }
    if (!mounted) return;
    setState(() {
      _sessions.insert(0, session);
      _currentSessionId = session.id;
    });
    await _persist();
    if (!mounted) return;
    Navigator.of(context).pop(); // 关闭 Drawer
  }

  /// 长按新建会话：弹出选择指定 Agent 来创建会话。
  Future<void> _newSessionWithAgent() async {
    final agents = await _agentService.load();
    if (!mounted) return;
    if (agents.isEmpty) {
      await _newSession();
      return;
    }

    final selected = await showDialog<Agent>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择 Agent 新建会话'),
        children: [
          for (final a in agents)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(a),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    color: a.isDefault
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a.name)),
                  if (a.isDefault)
                    Text(
                      '默认',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;

    final session = ChatSession.create();
    session.options = selected.options;
    session.agentId = selected.id;
    setState(() {
      _sessions.insert(0, session);
      _currentSessionId = session.id;
    });
    await _persist();
    if (!mounted) return;
    Navigator.of(context).pop(); // 关闭 Drawer
  }

  void _switchSession(String id) {
    setState(() => _currentSessionId = id);
    Navigator.of(context).pop(); // 关闭 Drawer
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${session.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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
    await _persist();
    if (mounted) Navigator.of(context).pop(); // 关闭 Drawer
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    // 设置页中可能新增/修改了服务商与模型，返回后刷新
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() => _providers = providers);
  }

  Future<void> _openContextSettings() async {
    final session = _currentSession;
    if (session == null) return;
    final result = await Navigator.of(context).push<ContextSettingsResult>(
      MaterialPageRoute(
        builder: (_) => ContextSettingsScreen(
          initial: session.options,
          initialAgentId: session.agentId,
          initialProviderId: session.providerId,
          initialModelId: session.modelId,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        session.options = result.options;
        session.agentId = result.agentId;
        session.providerId = result.providerId;
        session.modelId = result.modelId;
      });
      await _persist();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final session = _currentSession;
    if (text.isEmpty || _isLoading || session == null) return;

    final providers = await _providerService.load();
    if (!mounted) return;
    if (providers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先在设置中配置服务商')));
      await _openSettings();
      return;
    }

    // 解析会话使用的服务商：优先会话记录，否则默认第一个
    ChatProvider? provider;
    for (final p in providers) {
      if (p.id == session.providerId) {
        provider = p;
        break;
      }
    }
    provider ??= providers.firstOrNull;

    if (provider == null || provider.apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先完善服务商的 API Key')));
      await _openSettings();
      return;
    }

    // 解析模型：优先会话记录，否则该服务商第一个启用的模型
    var modelId = session.modelId;
    if (modelId == null || !provider.modelIds.contains(modelId)) {
      modelId = provider.modelIds.firstOrNull;
    }
    if (modelId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该服务商未配置模型，请到设置中添加')));
      await _openSettings();
      return;
    }

    final effectiveSettings = AppSettings(
      apiKey: provider.apiKey,
      baseUrl: provider.baseUrl,
      model: modelId,
    );

    setState(() {
      session.messages.add(ChatMessage(role: 'user', content: text));
      if (!_isAnonymous) session.updateTitleFromFirstMessage();
      session.updatedAt = DateTime.now();
      _isLoading = true;
    });
    _controller.clear();
    await _persist();
    _scrollToBottom(force: true);

    // 占位 assistant 消息，流式输出时逐块填充
    final assistantMessage = ChatMessage(role: 'assistant', content: '');
    setState(() => session.messages.add(assistantMessage));
    _scrollToBottom();

    try {
      final reply = await _chatService.sendChat(
        settings: effectiveSettings,
        messages: session.messages,
        options: session.options,
        onPartial: (delta) {
          if (!mounted) return;
          setState(() {
            assistantMessage.content += delta;
            session.updatedAt = DateTime.now();
          });
          _scrollToBottom();
        },
        onReasoning: (delta) {
          if (!mounted) return;
          setState(() {
            assistantMessage.reasoningContent += delta;
            session.updatedAt = DateTime.now();
          });
          _scrollToBottom();
        },
      );
      if (!mounted) return;
      setState(() {
        assistantMessage.content = reply;
        session.updatedAt = DateTime.now();
        _isLoading = false;
      });
      await _persist();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        session.messages.remove(assistantMessage);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        session.messages.remove(assistantMessage);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('网络请求失败，请检查网络或配置')));
    }
    _scrollToBottom();
  }

  /// 距底部的容差，低于此值视为"在底部"。
  static const double _bottomTolerance = 80;

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - _bottomTolerance;
  }

  /// 滚动到底部；[force] 为 true 时无条件滚动，
  /// 否则仅在用户当前靠近底部时才自动跟随（尊重手动滑动位置）。
  void _scrollToBottom({bool force = false}) {
    if (!force && !_isNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;
    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? 'Nona'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '会话上下文',
            onPressed: _openContextSettings,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: session == null || session.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: session.messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: session.messages[index]);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('生成中…'),
                ],
              ),
            ),
          if (session != null) _buildToolbar(session),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _isAnonymous
                  ? Text('匿名会话', style: Theme.of(context).textTheme.titleMedium)
                  : Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _newSession,
                            onLongPress: _newSessionWithAgent,
                            icon: const Icon(Icons.add_comment_outlined),
                            label: const Text('新建会话'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _toggleAnonymous();
                            Navigator.of(context).pop(); // 收起 Drawer
                          },
                          icon: const Icon(Icons.person_off, size: 18),
                          label: const Text('匿名'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            if (_isAnonymous)
              Expanded(child: _buildAnonymousHint())
            else
              Expanded(
                child: _sessions.isEmpty
                    ? const Center(child: Text('暂无会话'))
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final s = _sessions[index];
                          return ListTile(
                            selected: s.id == _currentSessionId,
                            title: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_formatTime(s.updatedAt)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: '删除会话',
                              onPressed: () => _deleteSession(s),
                            ),
                            onTap: () => _switchSession(s.id),
                          );
                        },
                      ),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.of(context).pop(); // 关闭 Drawer
                _openSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 匿名模式下的 Drawer 内容：仅提示与退出入口。
  Widget _buildAnonymousHint() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_off, size: 48, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text('当前处于匿名会话', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '匿名会话不会保存记录，\n也不会出现在会话列表中',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.logout),
          label: const Text('退出匿名会话'),
          onPressed: () {
            _toggleAnonymous();
            Navigator.of(context).pop(); // 关闭 Drawer
          },
        ),
      ],
    );
  }

  /// 会话列表中的时间显示：今天显示时分，其他显示月-日。
  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${t.month}-${t.day}';
  }

  static const _effortOptions = [
    ('auto', '思考：自动'),
    ('min', '思考：极低'),
    ('low', '思考：低'),
    ('medium', '思考：中'),
    ('high', '思考：高'),
  ];

  String _effortKey(String? value) => value ?? 'auto';

  /// 工具条中的模型选择：位于思考强度左侧。
  Widget _buildModelSelector(ChatSession session) {
    final theme = Theme.of(context);
    ChatProvider? provider;
    for (final p in _providers) {
      if (p.id == session.providerId) {
        provider = p;
        break;
      }
    }
    provider ??= _providers.firstOrNull;

    if (provider == null || provider.modelIds.isEmpty) {
      return TextButton(
        onPressed: _openSettings,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Text(
          '未配置模型',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final resolvedProvider = provider;
    var current = session.modelId;
    if (current == null || !resolvedProvider.modelIds.contains(current)) {
      current = resolvedProvider.modelIds.first;
    }
    final showProvider = _providers.length > 1;
    return DropdownButton<String>(
      value: current,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: theme.textTheme.bodySmall,
      items: [
        for (final m in resolvedProvider.modelIds)
          DropdownMenuItem(
            value: m,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                showProvider ? '${resolvedProvider.name} · $m' : m,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          session.providerId = resolvedProvider.id;
          session.modelId = v;
        });
        _persist();
      },
    );
  }

  /// 输入框上方的工具条：模型选择 + 思考强度 + 流式输出开关。
  Widget _buildToolbar(ChatSession session) {
    final theme = Theme.of(context);
    final options = session.options;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
      child: Row(
        children: [
          _buildModelSelector(session),
          const SizedBox(width: 8),
          Icon(
            Icons.psychology_outlined,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _effortKey(options.reasoningEffort),
            isDense: true,
            underline: const SizedBox.shrink(),
            style: theme.textTheme.bodySmall,
            items: [
              for (final (key, label) in _effortOptions)
                DropdownMenuItem(value: key, child: Text(label)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                session.options = options.copyWith(
                  reasoningEffort: v == 'auto' ? null : v,
                );
              });
              _persist();
            },
          ),
          const Spacer(),
          // 流式开关：按钮+文字，点击高亮为开，再次点击取消高亮为关
          TextButton.icon(
            onPressed: () {
              setState(() {
                session.options = options.copyWith(stream: !options.stream);
              });
              _persist();
            },
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('流式'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: options.stream
                  ? theme.colorScheme.primaryContainer
                  : null,
              foregroundColor: options.stream
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: '输入消息…',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _send,
              icon: const Icon(Icons.send),
              tooltip: '发送',
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态提示。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '开始和 Nona 对话吧',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条消息气泡。
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser && message.reasoningContent.isNotEmpty) ...[
              _ReasoningSection(reasoning: message.reasoningContent),
              if (message.content.isNotEmpty) const SizedBox(height: 8),
            ],
            if (isUser)
              Text(
                message.content,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              )
            else if (message.content.isNotEmpty)
              MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme,
                ).copyWith(p: TextStyle(color: theme.colorScheme.onSurface)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 思考过程区块：可收起，内容用 Markdown 实时渲染。
class _ReasoningSection extends StatefulWidget {
  final String reasoning;

  const _ReasoningSection({required this.reasoning});

  @override
  State<_ReasoningSection> createState() => _ReasoningSectionState();
}

class _ReasoningSectionState extends State<_ReasoningSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '思考过程',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: MarkdownBody(
                data: widget.reasoning,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

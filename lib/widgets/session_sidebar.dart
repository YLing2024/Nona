import 'package:flutter/material.dart';

import '../models/agent.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';

/// 会话侧边栏：品牌区、新建会话（含 Agent 选择）、搜索、分组会话列表。
class SessionSidebar extends StatefulWidget {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final bool isAnonymous;
  final List<Agent> agents;

  final VoidCallback onNewSession;
  final void Function(Agent agent) onNewSessionWithAgent;
  final ValueChanged<String> onSwitchSession;
  final void Function(ChatSession session) onDeleteSession;
  final void Function(ChatSession session) onRenameSession;
  final void Function(ChatSession session) onPinSession;
  final void Function(ChatSession session) onDuplicateSession;
  final VoidCallback onToggleAnonymous;
  final VoidCallback onOpenSettings;

  const SessionSidebar({
    super.key,
    required this.sessions,
    required this.currentSessionId,
    required this.isAnonymous,
    required this.agents,
    required this.onNewSession,
    required this.onNewSessionWithAgent,
    required this.onSwitchSession,
    required this.onDeleteSession,
    required this.onRenameSession,
    required this.onPinSession,
    required this.onDuplicateSession,
    required this.onToggleAnonymous,
    required this.onOpenSettings,
  });

  @override
  State<SessionSidebar> createState() => SessionSidebarState();
}

class SessionSidebarState extends State<SessionSidebar> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String get _query => _searchController.text.trim().toLowerCase();

  List<ChatSession> get _filtered {
    if (_query.isEmpty) return widget.sessions;
    return widget.sessions.where((s) {
      if (s.title.toLowerCase().contains(_query)) return true;
      return s.messages.any(
        (m) => m.content.toLowerCase().contains(_query),
      );
    }).toList();
  }

  /// 供全局快捷键聚焦搜索框。
  void focusSearch() {
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 292,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (!widget.isAnonymous) _buildSearch(context),
          const SizedBox(height: 4),
          Expanded(
            child: widget.isAnonymous
                ? _buildAnonymousPanel(context)
                : _buildSessionList(context),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nona',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'AI 聊天助手',
                  style: TextStyle(fontSize: 10.5, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
          // 新建会话 + Agent 选择
          MenuAnchor(
            alignmentOffset: const Offset(0, 6),
            menuChildren: [
              if (widget.agents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    '用 Agent 新建会话',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              for (final a in widget.agents)
                MenuItemButton(
                  leadingIcon: Icon(
                    Icons.smart_toy_outlined,
                    size: 17,
                    color: a.isDefault
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.name, style: const TextStyle(fontSize: 13)),
                      if (a.isDefault)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => widget.onNewSessionWithAgent(a),
                ),
              const PopupMenuDivider(),
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.person_off_outlined,
                  size: 17,
                  color: theme.colorScheme.outline,
                ),
                onPressed: widget.onToggleAnonymous,
                child: Text(
                  widget.isAnonymous ? '退出匿名会话' : '匿名会话（不保存）',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              tooltip: '新建会话 / 选择 Agent',
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.add_circle_rounded, size: 28),
              color: theme.colorScheme.primary,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(36, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (_) => setState(() {}),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索会话与消息…',
          hintStyle: TextStyle(color: scheme.outline, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.4),
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _query.isEmpty
                  ? Icons.forum_outlined
                  : Icons.search_off_rounded,
              size: 36,
              color: scheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              _query.isEmpty ? '暂无会话' : '没有匹配的会话',
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
          ],
        ),
      );
    }

    final pinned = filtered.where((s) => s.pinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final others = filtered.where((s) => !s.pinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      children: [
        if (pinned.isNotEmpty) ...[
          _sectionLabel(context, '置顶'),
          for (final s in pinned) _sessionItem(context, s),
        ],
        for (final group in _groupOthers(others))
          ...[
            _sectionLabel(context, group.$1),
            for (final s in group.$2) _sessionItem(context, s),
          ],
      ],
    );
  }

  List<(String, List<ChatSession>)> _groupOthers(List<ChatSession> list) {
    final now = DateTime.now();
    bool isToday(DateTime t) =>
        t.year == now.year && t.month == now.month && t.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    bool isYesterday(DateTime t) =>
        t.year == yesterday.year &&
        t.month == yesterday.month &&
        t.day == yesterday.day;

    final today = list.where((s) => isToday(s.updatedAt)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final yest = list.where((s) => isYesterday(s.updatedAt)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final older = list
        .where((s) => !isToday(s.updatedAt) && !isYesterday(s.updatedAt))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return [
      if (today.isNotEmpty) ('今天', today),
      if (yest.isNotEmpty) ('昨天', yest),
      if (older.isNotEmpty) ('更早', older),
    ];
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

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

  Widget _sessionItem(BuildContext context, ChatSession session) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = session.id == widget.currentSessionId;

    return MouseRegion(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onSwitchSession(session.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 15,
                  color: selected ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatTime(session.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? scheme.onPrimaryContainer.withValues(alpha: 0.6)
                              : scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.pinned)
                  Icon(Icons.push_pin_rounded, size: 13, color: scheme.outline),
                _SessionMenuButton(
                  session: session,
                  selected: selected,
                  onRename: () => widget.onRenameSession(session),
                  onPin: () => widget.onPinSession(session),
                  onDuplicate: () => widget.onDuplicateSession(session),
                  onDelete: () => widget.onDeleteSession(session),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined, size: 26, color: scheme.outline),
            ),
            const SizedBox(height: 14),
            Text('匿名会话进行中', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              '对话内容仅保存在内存中，\n关闭应用后不会留下记录',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.outline, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: widget.onToggleAnonymous,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('退出匿名'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.settings_outlined, size: 19),
        title: const Text('设置', style: TextStyle(fontSize: 13.5)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: widget.onOpenSettings,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// 会话项操作菜单（置顶/重命名/复制/导出/删除）。
class _SessionMenuButton extends StatelessWidget {
  final ChatSession session;
  final bool selected;
  final VoidCallback onRename;
  final VoidCallback onPin;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _SessionMenuButton({
    required this.session,
    required this.selected,
    required this.onRename,
    required this.onPin,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.drive_file_rename_outline, size: 17),
          onPressed: onRename,
          child: const Text('重命名', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            session.pinned ? Icons.push_pin_outlined : Icons.push_pin_outlined,
            size: 17,
            color: session.pinned ? scheme.primary : null,
          ),
          onPressed: onPin,
          child: Text(
            session.pinned ? '取消置顶' : '置顶',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_all_outlined, size: 17),
          onPressed: onDuplicate,
          child: const Text('复制会话', style: TextStyle(fontSize: 13)),
        ),
        const PopupMenuDivider(),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_outline_rounded,
              size: 17, color: scheme.error),
          onPressed: onDelete,
          child: Text(
            '删除',
            style: TextStyle(fontSize: 13, color: scheme.error),
          ),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: Icon(
          Icons.more_vert_rounded,
          size: 16,
          color: selected ? scheme.onPrimaryContainer : scheme.outline,
        ),
        visualDensity: VisualDensity.compact,
        tooltip: '会话操作',
      ),
    );
  }
}

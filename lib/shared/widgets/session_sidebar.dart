import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/models/agent.dart';
import '../../core/models/chat_session.dart';
import '../../core/theme/app_theme.dart';
import '../../features/session/widgets/session_grouper.dart';
import '../../features/session/widgets/session_list_item.dart';

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
    final AppLocalizations l10n = context.l10n;
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
                  l10n.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  l10n.sidebarBrandSubtitle,
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
                    l10n.sidebarNewWithAgent,
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
                            l10n.agentDefault,
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
                  widget.isAnonymous
                      ? l10n.sidebarExitAnonymousConfirm
                      : l10n.sidebarAnonymous,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              tooltip: l10n.sidebarNewSessionAgent,
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
        onTapOutside: unfocusOnTap,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: context.l10n.sidebarSearchHint,
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final filtered = SessionGrouper.search(widget.sessions, _query);
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
              _query.isEmpty
                  ? l10n.sidebarNoSessions
                  : l10n.sidebarNoMatch,
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
          ],
        ),
      );
    }

    final grouped = SessionGrouper.group(filtered, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      children: [
        if (grouped.pinned.isNotEmpty)
          SessionGroupSection(
            label: l10n.sidebarPin,
            sessions: grouped.pinned,
            currentSessionId: widget.currentSessionId,
            onSwitchSession: widget.onSwitchSession,
            onDeleteSession: widget.onDeleteSession,
            onRenameSession: widget.onRenameSession,
            onPinSession: widget.onPinSession,
            onDuplicateSession: widget.onDuplicateSession,
          ),
        for (final group in grouped.groups)
          SessionGroupSection(
            label: switch (group.kind) {
              SessionGroupKind.today => l10n.sidebarToday,
              SessionGroupKind.yesterday => l10n.sidebarYesterday,
              SessionGroupKind.earlier => l10n.sidebarEarlier,
            },
            sessions: group.sessions,
            currentSessionId: widget.currentSessionId,
            onSwitchSession: widget.onSwitchSession,
            onDeleteSession: widget.onDeleteSession,
            onRenameSession: widget.onRenameSession,
            onPinSession: widget.onPinSession,
            onDuplicateSession: widget.onDuplicateSession,
          ),
      ],
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
            Text(context.l10n.sidebarAnonymousActive,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              context.l10n.sidebarAnonymousHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.outline, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: widget.onToggleAnonymous,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(context.l10n.sidebarExitAnonymous),
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
        title: Text(context.l10n.settingsTitle,
            style: const TextStyle(fontSize: 13.5)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: widget.onOpenSettings,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

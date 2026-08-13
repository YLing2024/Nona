import 'package:flutter/material.dart';

import '../../../core/utils/l10n_ext.dart';
import '../../../core/models/chat_session.dart';
import 'session_grouper.dart';

/// 会话分组区块：分组标题 + 会话列表项。
class SessionGroupSection extends StatelessWidget {
  final String label;
  final List<ChatSession> sessions;
  final String? currentSessionId;

  final ValueChanged<String> onSwitchSession;
  final void Function(ChatSession session) onDeleteSession;
  final void Function(ChatSession session) onRenameSession;
  final void Function(ChatSession session) onPinSession;
  final void Function(ChatSession session) onDuplicateSession;

  const SessionGroupSection({
    super.key,
    required this.label,
    required this.sessions,
    required this.currentSessionId,
    required this.onSwitchSession,
    required this.onDeleteSession,
    required this.onRenameSession,
    required this.onPinSession,
    required this.onDuplicateSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
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
        ),
        for (final s in sessions)
          SessionListItem(
            session: s,
            selected: s.id == currentSessionId,
            onSwitchSession: onSwitchSession,
            onDeleteSession: onDeleteSession,
            onRenameSession: onRenameSession,
            onPinSession: onPinSession,
            onDuplicateSession: onDuplicateSession,
          ),
      ],
    );
  }
}

/// 会话列表项：选中态、标题与时间、置顶标记、操作菜单。
class SessionListItem extends StatelessWidget {
  final ChatSession session;
  final bool selected;

  final ValueChanged<String> onSwitchSession;
  final void Function(ChatSession session) onDeleteSession;
  final void Function(ChatSession session) onRenameSession;
  final void Function(ChatSession session) onPinSession;
  final void Function(ChatSession session) onDuplicateSession;

  const SessionListItem({
    super.key,
    required this.session,
    required this.selected,
    required this.onSwitchSession,
    required this.onDeleteSession,
    required this.onRenameSession,
    required this.onPinSession,
    required this.onDuplicateSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MouseRegion(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSwitchSession(session.id),
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
                        SessionGrouper.formatTime(
                          session.updatedAt,
                          DateTime.now(),
                        ),
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
                  onRename: () => onRenameSession(session),
                  onPin: () => onPinSession(session),
                  onDuplicate: () => onDuplicateSession(session),
                  onDelete: () => onDeleteSession(session),
                ),
              ],
            ),
          ),
        ),
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
          child: Text(context.l10n.sidebarRename,
              style: const TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            session.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 17,
            color: session.pinned ? scheme.primary : null,
          ),
          onPressed: onPin,
          child: Text(
            session.pinned ? context.l10n.sidebarUnpin : context.l10n.sidebarPin,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_all_outlined, size: 17),
          onPressed: onDuplicate,
          child: Text(context.l10n.sidebarDuplicate,
              style: const TextStyle(fontSize: 13)),
        ),
        const PopupMenuDivider(),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_outline_rounded,
              size: 17, color: scheme.error),
          onPressed: onDelete,
          child: Text(
            context.l10n.commonDelete,
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
        tooltip: context.l10n.sidebarSessionActions,
      ),
    );
  }
}

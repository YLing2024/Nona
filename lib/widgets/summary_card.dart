import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_session.dart';

/// 摘要压缩条（F3-1）：消息流顶部展示「已压缩 N 条消息」，
/// 展开可见被压缩消息列表（只读灰显）与摘要；支持编辑摘要与清空。
class SummaryCard extends StatefulWidget {
  final ChatSession session;

  /// 保存编辑后的摘要（写回 sessions.summary）。
  final void Function(String summary)? onSummaryEdited;

  /// 清空压缩记录。
  final VoidCallback? onClear;

  const SummaryCard({
    super.key,
    required this.session,
    this.onSummaryEdited,
    this.onClear,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final session = widget.session;
    final count = session.compressedMessageCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.compress_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.summaryCompressed(count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: l10n.summaryClear,
                    icon: Icon(Icons.close_rounded,
                        size: 16, color: scheme.outline),
                    onPressed: () => widget.onClear?.call(),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.summaryTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    session.summary.trim().isEmpty
                        ? l10n.summaryEmpty
                        : session.summary.trim(),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: Text(l10n.summaryEdit),
                          onPressed: () => _editSummary(context),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.summaryCompressedMessages(count),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._buildCompressedMessages(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCompressedMessages(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final blocks = widget.session.compressedBlocks;
    final widgets = <Widget>[];
    for (final block in blocks) {
      for (final m in block.messages) {
        final role = m.role == 'user' ? 'User' : 'Nona';
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    m.content.trim().isEmpty
                        ? '[image]'
                        : m.content.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _editSummary(BuildContext context) async {
    final controller = TextEditingController(text: widget.session.summary);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).summaryEdit),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: AppLocalizations.of(ctx).summaryEditHint,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).toolApprovalDeny),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).commonSave),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.onSummaryEdited?.call(result);
    }
  }
}

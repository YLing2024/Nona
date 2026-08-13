import 'package:flutter/material.dart';

import '../../../core/models/chat_session.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/context_builder.dart';

/// B-08：上下文管理面板——分段卡片 + 用量 + 压缩/清除操作。
///
/// 由宿主注入报告与操作回调；开关只影响会话级
/// [ChatOptions.disabledContextSegments]（下次请求生效）。
class ContextManagementSheet extends StatefulWidget {
  /// 注入分段报告（系统/摘要/历史等同步段 + 异步段）。
  final List<ContextSegment> segments;

  /// 已用 token（历史消息 + 固定注入）。
  final int usedTokens;

  /// 上下文上限；null 表示未设置。
  final int? limitTokens;

  /// 当前会话（读取/写入 truncateIndex 与开关）。
  final ChatSession session;

  /// 压缩上下文（宿主实现模型摘要链）。
  final Future<void> Function() onCompress;

  /// 清除/恢复上下文（宿主实现 truncateIndex 标记）。
  final void Function(bool clear) onSetTruncated;

  const ContextManagementSheet({
    super.key,
    required this.segments,
    required this.usedTokens,
    required this.limitTokens,
    required this.session,
    required this.onCompress,
    required this.onSetTruncated,
  });

  /// 展示面板（桌面对话框 / 移动端底部抽屉）。
  static Future<void> show(
    BuildContext context, {
    required List<ContextSegment> segments,
    required int usedTokens,
    required int? limitTokens,
    required ChatSession session,
    required Future<void> Function() onCompress,
    required void Function(bool clear) onSetTruncated,
  }) {
    final content = ContextManagementSheet(
      segments: segments,
      usedTokens: usedTokens,
      limitTokens: limitTokens,
      session: session,
      onCompress: onCompress,
      onSetTruncated: onSetTruncated,
    );
    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
            child: content,
          ),
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: content,
      ),
    );
  }

  @override
  State<ContextManagementSheet> createState() => _ContextManagementSheetState();
}

class _ContextManagementSheetState extends State<ContextManagementSheet> {
  bool _compressing = false;

  String _titleFor(String type, AppLocalizations l10n) => switch (type) {
        'system' => l10n.contextSegmentSystem,
        'agent' => l10n.contextSegmentAgent,
        'summary' => l10n.contextSegmentSummary,
        'memory' => l10n.contextSegmentMemory,
        'injection' => l10n.contextSegmentInjection,
        'knowledge' => l10n.contextSegmentKnowledge,
        'search' => l10n.contextSegmentSearch,
        'worldBook' => l10n.contextSegmentWorldBook,
        'history' => l10n.contextSegmentHistory,
        _ => type,
      };

  Future<void> _compress() async {
    if (_compressing) return;
    setState(() => _compressing = true);
    try {
      await widget.onCompress();
      if (!mounted) return;
      showAppSnack(context, context.l10n.contextCompressDone);
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.commonSaveFailed);
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;
    final limit = widget.limitTokens;
    final used = widget.usedTokens;
    final truncated = session.truncateIndex != null;
    final disabled = session.options.disabledContextSegments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.contextManageTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.commonCancel,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            limit == null
                ? '${l10n.contextUsedTokens('0', '')} · ${l10n.contextNoLimit}'
                : l10n.contextUsedTokens('', ''),
            style: TextStyle(fontSize: 12.5, color: scheme.outline),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit == null
                  ? null
                  : (used / limit).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (truncated)
                _TruncateBanner(
                  session: session,
                  onRestore: () {
                    widget.onSetTruncated(false);
                    setState(() {});
                  },
                ),
              for (final seg in widget.segments)
                _SegmentCard(
                  title: _titleFor(seg.type, l10n),
                  preview: seg.preview,
                  tokens: seg.tokens,
                  toggleable: seg.toggleable,
                  enabled: !disabled.contains(seg.type),
                  onToggle: seg.toggleable
                      ? (value) {
                          final next = {...disabled};
                          if (value) {
                            next.remove(seg.type);
                          } else {
                            next.add(seg.type);
                          }
                          session.options = session.options.copyWith(
                            disabledContextSegments: next.toList(),
                          );
                          setState(() {});
                        }
                      : null,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: truncated
                        ? null
                        : _compressing
                            ? null
                            : _compress,
                    icon: _compressing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.compress_rounded, size: 18),
                    label: Text(l10n.contextCompress),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _compressing ? null : () {
                      widget.onSetTruncated(!truncated);
                      setState(() {});
                    },
                    icon: Icon(
                      truncated
                          ? Icons.restore_rounded
                          : Icons.cleaning_services_outlined,
                      size: 18,
                    ),
                    label: Text(
                      truncated ? l10n.contextRestore : l10n.contextClear,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final String title;
  final String preview;
  final int tokens;
  final bool toggleable;
  final bool enabled;
  final void Function(bool)? onToggle;

  const _SegmentCard({
    required this.title,
    required this.preview,
    required this.tokens,
    required this.toggleable,
    required this.enabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: enabled
              ? scheme.outlineVariant
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? scheme.onSurface
                              : scheme.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.contextSegmentTokens(''),
                        style: TextStyle(fontSize: 11, color: scheme.outline),
                      ),
                      if (!enabled) ...[
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.contextDisabled,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.length > 140
                          ? '${preview.substring(0, 140)}…'
                          : preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: scheme.outline),
                    ),
                  ],
                ],
              ),
            ),
            if (toggleable && onToggle != null)
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
              ),
          ],
        ),
      ),
    );
  }
}

class _TruncateBanner extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onRestore;

  const _TruncateBanner({
    required this.session,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cleaning_services_outlined,
                size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.contextClearHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRestore, child: Text(context.l10n.contextRestore)),
          ],
        ),
      ),
    );
  }
}

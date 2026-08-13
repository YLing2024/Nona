import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/models/tool_step.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';

/// F-04：工具执行卡——图标 + 名称 + 参数预览 + 状态（spinner/结果摘要），
/// 点击展开详情（参数/结果全文）。审批内联按钮由宿主注入。
class ToolStepCard extends StatefulWidget {
  final ToolStep step;

  /// 展开详情（默认折叠）。
  final bool initiallyExpanded;

  /// 审批内联（等待审批时显示）；null 表示不可审批。
  final Future<void> Function(bool allow)? onApprove;

  const ToolStepCard({
    super.key,
    required this.step,
    this.initiallyExpanded = false,
    this.onApprove,
  });

  @override
  State<ToolStepCard> createState() => _ToolStepCardState();
}

class _ToolStepCardState extends State<ToolStepCard> {
  late bool _expanded = widget.initiallyExpanded;
  bool _approving = false;

  String _statusLabel(AppLocalizations l10n) => switch (widget.step.status) {
        'done' => l10n.toolDone,
        'error' => l10n.toolError,
        'waitingApproval' => l10n.toolWaitingApproval,
        _ => l10n.toolExecuting,
      };

  Color _statusColor(ColorScheme scheme) => switch (widget.step.status) {
        'done' => scheme.primary,
        'error' => scheme.error,
        'waitingApproval' => scheme.tertiary,
        _ => scheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final step = widget.step;
    final isWorking = step.status == 'executing';
    final argsPretty = _pretty(step.argumentsJson);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isWorking
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isWorking)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  else
                    Icon(
                      step.status == 'error'
                          ? Icons.error_outline_rounded
                          : Icons.handyman_outlined,
                      size: 16,
                      color: _statusColor(scheme),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _statusLabel(l10n),
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(scheme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: scheme.outline,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                _DetailRow(label: l10n.toolArguments, text: argsPretty),
                if (step.resultText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: l10n.toolResult,
                    text: _truncateResult(step.resultText),
                    truncated: _isTruncated(step.resultText),
                  ),
                ],
                if (step.status == 'waitingApproval' &&
                    widget.onApprove != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _approving
                            ? null
                            : () => _decide(false),
                        child: Text(l10n.toolReject),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _approving ? null : () => _decide(true),
                        child: Text(l10n.toolApprove),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decide(bool allow) async {
    setState(() => _approving = true);
    try {
      await widget.onApprove?.call(allow);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  static const int _maxResultChars = 800;

  static bool _isTruncated(String text) => text.length > _maxResultChars;

  static String _truncateResult(String text) => _isTruncated(text)
      ? '${text.substring(0, _maxResultChars)}…'
      : text;

  static String _pretty(String json) {
    try {
      final decoded = jsonDecode(json);
      final encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(decoded);
      return pretty.length > 400 ? '${pretty.substring(0, 400)}…' : pretty;
    } catch (_) {
      return json;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String text;
  final bool truncated;

  const _DetailRow({required this.label, required this.text, this.truncated = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          truncated ? '$label ${context.l10n.toolResultTruncated}' : label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: scheme.outline,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            maxLines: 12,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

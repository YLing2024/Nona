import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/mcp/approval_policy.dart';

/// 工具调用审批对话框（桌面 AlertDialog / 移动端 bottomSheet）。
///
/// 展示工具名、风险色提示与参数 JSON 折叠预览；
/// 按钮：允许本次 / 记住并允许 / 拒绝。
class ToolApprovalDialog {
  static Future<ApprovalDecision?> show(
    BuildContext context, {
    required String toolName,
    required String serverName,
    required String argumentsJson,
  }) {
    if (context.mounted && (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android)) {
      return showModalBottomSheet<ApprovalDecision>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _ApprovalSheet(
          toolName: toolName,
          serverName: serverName,
          argumentsJson: argumentsJson,
        ),
      );
    }
    return showDialog<ApprovalDecision>(
      context: context,
      builder: (ctx) => _ApprovalDialog(
        toolName: toolName,
        serverName: serverName,
        argumentsJson: argumentsJson,
      ),
    );
  }
}

class _ApprovalDialog extends StatelessWidget {
  final String toolName;
  final String serverName;
  final String argumentsJson;

  const _ApprovalDialog({
    required this.toolName,
    required this.serverName,
    required this.argumentsJson,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
      title: Text(l10n.toolApprovalTitle(toolName)),
      content: SizedBox(
        width: 420,
        child: _ApprovalContent(
          toolName: toolName,
          serverName: serverName,
          argumentsJson: argumentsJson,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ApprovalDecision.deny),
          child: Text(l10n.toolApprovalDeny),
        ),
        FilledButton.tonal(
          onPressed: () =>
              Navigator.pop(context, ApprovalDecision.allowAndRemember),
          child: Text(l10n.toolApprovalAllowRemember),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ApprovalDecision.allow),
          child: Text(l10n.toolApprovalAllowOnce),
        ),
      ],
    );
  }
}

class _ApprovalSheet extends StatelessWidget {
  final String toolName;
  final String serverName;
  final String argumentsJson;

  const _ApprovalSheet({
    required this.toolName,
    required this.serverName,
    required this.argumentsJson,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.toolApprovalTitle(toolName),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ApprovalContent(
              toolName: toolName,
              serverName: serverName,
              argumentsJson: argumentsJson,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, ApprovalDecision.deny),
                    child: Text(l10n.toolApprovalDeny),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        Navigator.pop(context, ApprovalDecision.allowAndRemember),
                    child: Text(l10n.toolApprovalAllowRemember),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, ApprovalDecision.allow),
                    child: Text(l10n.toolApprovalAllowOnce),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalContent extends StatelessWidget {
  final String toolName;
  final String serverName;
  final String argumentsJson;

  const _ApprovalContent({
    required this.toolName,
    required this.serverName,
    required this.argumentsJson,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.toolApprovalRiskHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onErrorContainer),
          ),
        ),
        const SizedBox(height: 10),
        Text(l10n.toolApprovalServer(serverName),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        // 参数 JSON 折叠预览
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.toolApprovalArguments,
            style: theme.textTheme.bodyMedium,
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  argumentsJson,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

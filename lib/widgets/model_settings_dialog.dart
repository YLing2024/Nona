import 'package:flutter/material.dart';

import '../utils/l10n_ext.dart';
import '../models/chat_provider.dart' show ModelConfig;
import '../services/provider_service.dart' show ModelTestResult;

/// 模型设置弹窗：基础设置 + 高级设置（TabBar），内容列表可滚动。
class ModelSettingsDialog extends StatefulWidget {
  final String model;
  final ModelConfig config;
  final void Function(ModelConfig config) onConfigChanged;
  final Future<ModelTestResult?> Function() onReTest;
  final ModelTestResult? testResult;
  final bool isTesting;

  const ModelSettingsDialog({
    super.key,
    required this.model,
    required this.config,
    required this.onConfigChanged,
    required this.onReTest,
    this.testResult,
    required this.isTesting,
  });

  @override
  State<ModelSettingsDialog> createState() => _ModelSettingsDialogState();
}

class _ModelSettingsDialogState extends State<ModelSettingsDialog> {
  int _selectedTab = 0;
  late ModelConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _setConfig(ModelConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.model,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            // Tab 按钮行（固定高度）
            Row(
              children: [
                _TabButton(
                  label: context.l10n.providerBaseSettings,
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: context.l10n.providerAdvancedSettings,
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
            const Divider(height: 1),
            // 内容列表（可滚动）
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: _selectedTab == 0
                    ? _buildBasicSettings(theme, scheme)
                    : _buildAdvancedSettings(theme, scheme),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonClose),
        ),
      ],
    );
  }

  List<Widget> _buildBasicSettings(ThemeData theme, ColorScheme scheme) {
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(context.l10n.providerMultimodal, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          context.l10n.providerMultimodalHint,
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        value: _config.multimodal,
        onChanged: (v) => _setConfig(_config.copyWith(multimodal: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(context.l10n.providerReasoning, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          context.l10n.providerReasoningHint,
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        value: _config.reasoning,
        onChanged: (v) => _setConfig(_config.copyWith(reasoning: v)),
      ),
    ];
  }

  List<Widget> _buildAdvancedSettings(ThemeData theme, ColorScheme scheme) {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.speed, size: 20),
        title: Text(context.l10n.providerLatencyRecord, style: const TextStyle(fontSize: 14)),
        subtitle: _buildLatencySubtitle(scheme),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () => _showLatencyDetail(theme, scheme),
      ),
      const Divider(height: 1, indent: 40),
    ];
  }

  Widget? _buildLatencySubtitle(ColorScheme scheme) {
    if (widget.isTesting) {
      return Text(context.l10n.providerTesting, style: TextStyle(fontSize: 12, color: scheme.outline));
    }
    final result = widget.testResult;
    if (result == null) {
      return Text(context.l10n.commonUntested, style: TextStyle(fontSize: 12, color: scheme.outline));
    }
    if (result.success) {
      Color color;
      if (result.elapsedMs < 1000) {
        color = Colors.green;
      } else if (result.elapsedMs < 3000) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      return Text(
        '${result.elapsedMs}ms',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      );
    }
    return Text(
      context.l10n.providerTestFailedDetail(
        result.error ?? context.l10n.commonUnknownError,
      ),
      style: TextStyle(fontSize: 12, color: scheme.error),
    );
  }

  void _showLatencyDetail(ThemeData theme, ColorScheme scheme) {
    ModelTestResult? displayResult = widget.testResult;
    bool isReTesting = widget.isTesting;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(ctx.l10n.providerLatencyRecord, style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isReTesting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (displayResult != null)
                  _buildLatencyDetailContent(displayResult!, theme, scheme)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(ctx.l10n.commonUntested, style: TextStyle(color: scheme.outline)),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.commonClose),
            ),
            FilledButton.icon(
              onPressed: isReTesting
                  ? null
                  : () async {
                      setDialogState(() => isReTesting = true);
                      final result = await widget.onReTest();
                      if (ctx.mounted) {
                        setDialogState(() {
                          isReTesting = false;
                          displayResult = result;
                        });
                      }
                    },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(isReTesting ? ctx.l10n.providerTesting : ctx.l10n.providerTestAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatencyDetailContent(ModelTestResult result, ThemeData theme, ColorScheme scheme) {
    if (result.success) {
      Color color;
      if (result.elapsedMs < 1000) {
        color = Colors.green;
      } else if (result.elapsedMs < 3000) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${result.elapsedMs}ms',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.elapsedMs < 1000
                  ? context.l10n.providerLatencyExcellent
                  : result.elapsedMs < 3000
                      ? context.l10n.providerLatencyGood
                      : context.l10n.providerLatencySlow,
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            context.l10n.commonFailedTest,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.error,
            ),
          ),
          if (result.error != null) ...[
            const SizedBox(height: 4),
            Text(
              result.error!,
              style: TextStyle(fontSize: 12, color: scheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? scheme.onPrimaryContainer : scheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

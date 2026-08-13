import 'package:flutter/material.dart';

import '../../../core/utils/l10n_ext.dart';

/// 发送按钮：主色圆形，无模型时禁用置灰。
class SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const SendButton({super.key, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.commonSend;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: label,
        child: Material(
          color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: enabled ? scheme.onPrimary : scheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 停止按钮：错误色圆形，生成中替换发送按钮。
class StopButton extends StatelessWidget {
  final VoidCallback onTap;

  const StopButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.commonStop;
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: scheme.error,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(11),
              child: Icon(Icons.stop_rounded, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// 输入区圆形图标按钮（清空输入等）。
class ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ComposerIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 17, color: scheme.outline),
        ),
      ),
    );
  }
}

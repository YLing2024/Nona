import 'package:flutter/material.dart';

import '../../core/utils/l10n_ext.dart';

/// 统一确认对话框：取消 + 确认按钮。
///
/// [danger] 为 true 时确认按钮使用错误色（删除/清空等危险操作）。
/// [message] 为空时只展示标题。
/// 返回 true 表示用户确认；取消/关闭返回 false。
///
/// 全项目删除/清空确认统一走此入口，避免 10+ 份手写副本
/// 在防误删保护（如确认文本）上出现不一致。
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String message = '',
  String? confirmText,
  bool danger = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: message.isEmpty ? null : Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText ?? ctx.l10n.commonConfirm),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

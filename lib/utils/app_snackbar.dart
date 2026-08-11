import 'package:flutter/material.dart';

/// 统一提示条：多屏 `_snack` 手写副本的收敛入口。
///
/// [error] 为 true 时使用错误色背景（失败提示）。
void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

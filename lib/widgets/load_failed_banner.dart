import 'package:flutter/material.dart';

import '../utils/l10n_ext.dart';

/// 屏级加载失败横幅：数据加载异常后的降级提示 + 重试入口。
class LoadFailedBanner extends StatelessWidget {
  /// 重试回调（重新触发 _load）。
  final VoidCallback? onRetry;

  const LoadFailedBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.loadFailedBanner,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
          ],
        ),
      ),
    );
  }
}

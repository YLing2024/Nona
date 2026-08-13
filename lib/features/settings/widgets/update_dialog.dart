import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/update_service.dart';
import '../../../l10n/app_localizations.dart';

/// 版本更新对话框（J-02）：显示新版本信息与下载入口。
Future<void> showUpdateDialog(BuildContext context, ReleaseInfo release) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.updateVersion}: ${release.tagName}'
              '${release.name.isNotEmpty && release.name != release.tagName ? ' · ${release.name}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (release.body.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                release.body.trim(),
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonCancel),
        ),
        if (release.htmlUrl.isNotEmpty)
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(release.htmlUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.updateDownload),
          ),
      ],
    ),
  );
}

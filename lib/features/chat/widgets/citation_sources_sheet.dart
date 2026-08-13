import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/citation_source.dart';
import '../../../l10n/app_localizations.dart';

/// 引用来源面板（B-03）：消息气泡角标点击后展示全部引用。
///
/// 桌面端 dialog / 移动端 bottom sheet 双形态（对齐 kelivo）。
void showCitationSourcesSheet(
  BuildContext context,
  List<CitationSource> sources,
) {
  final content = _CitationSourcesList(sources: sources);
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(child: content),
    );
  } else {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
          child: content,
        ),
      ),
    );
  }
}

class _CitationSourcesList extends StatelessWidget {
  final List<CitationSource> sources;

  const _CitationSourcesList({required this.sources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.citationSourcesTitle,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              if (sources.length > 1)
                Text(
                  '${sources.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _CitationSourceCard(source: sources[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationSourceCard extends StatelessWidget {
  final CitationSource source;

  const _CitationSourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 序号徽章（≥10 加宽）
                Container(
                  width: source.index >= 10 ? 28 : 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${source.index}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (source.sourceName != null ||
                          source.publishedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (source.sourceName != null)
                              source.sourceName!,
                            if (source.publishedAt != null)
                              source.publishedAt!,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (source.url.isNotEmpty)
                  IconButton(
                    tooltip: 'Open',
                    icon: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: scheme.primary,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(source.url),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
            if (source.snippet != null && source.snippet!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                source.snippet!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (source.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in source.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag.text,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// B-04：建议气泡——空会话时的引导入口，点击即发送。
///
/// 使用静态模板（i18n）；生成中/非空会话不显示。
class SuggestionBubbles extends StatelessWidget {
  /// 建议文案列表（由宿主注入；null 表示使用静态模板）。
  final List<String>? suggestions;

  /// 点击建议回调（宿主负责发送）。
  final void Function(String text) onTap;

  /// 当前是否正在生成（生成中隐藏，避免打断）。
  final bool generating;

  const SuggestionBubbles({
    super.key,
    this.suggestions,
    required this.onTap,
    this.generating = false,
  });

  /// 静态模板：按当前语言返回 3 条引导建议。
  static List<String> templates(AppLocalizations l10n) => [
        l10n.chatSuggestionStart,
        l10n.chatSuggestionFiles,
        l10n.chatSuggestionMcp,
      ];

  @override
  Widget build(BuildContext context) {
    if (generating) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final items = suggestions ?? templates(l10n);
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.chatSuggestionTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: scheme.outline,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final text in items)
              _SuggestionChip(text: text, onTap: () => onTap(text)),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 建议卡片的品牌渐变容器（与空状态 hero 一致）。
class SuggestionCardSurface extends StatelessWidget {
  final Widget child;

  const SuggestionCardSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

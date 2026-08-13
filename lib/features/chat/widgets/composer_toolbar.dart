import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/models/chat_options.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/services/model_resolver.dart';

/// 工具条：模型选择（含服务商分组菜单）、思考强度、流式开关、图片/文档附件入口。
class ComposerToolbar extends StatelessWidget {
  final List<ChatProvider> providers;
  final String? providerId;
  final String? modelId;
  final ChatOptions options;
  final bool isLoading;
  final bool hasPendingImages;
  final bool hasPendingDocuments;

  /// 当 [modelId] 为 null 时是否自动选择第一个模型。
  final bool autoSelectModel;

  final void Function(String providerId, String modelId) onModelChanged;
  final void Function(String? reasoningEffort) onEffortChanged;
  final void Function(bool stream) onStreamChanged;
  final VoidCallback onPickImages;
  final VoidCallback onPickDocuments;

  const ComposerToolbar({
    super.key,
    required this.providers,
    required this.providerId,
    required this.modelId,
    required this.options,
    required this.isLoading,
    required this.hasPendingImages,
    required this.hasPendingDocuments,
    required this.onModelChanged,
    required this.onEffortChanged,
    required this.onStreamChanged,
    required this.onPickImages,
    required this.onPickDocuments,
    this.autoSelectModel = true,
  });

  static const _effortValues = [null, 'low', 'medium', 'high'];

  ChatProvider? get _provider =>
      resolveFirstAvailable(providers, providerId: providerId).provider;

  String? get _resolvedModel {
    final resolution = resolveFirstAvailable(
      providers,
      providerId: providerId,
      modelId: modelId,
      autoSelect: autoSelectModel,
    );
    return resolution.modelId;
  }

  /// 当前模型是否为推理模型；未标记为推理（或未配置）时思考不可用。
  bool get _reasoningEnabled {
    final model = _resolvedModel;
    final provider = _provider;
    if (model == null || provider == null) return true;
    return provider.modelConfigs[model]?.reasoning ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final model = _resolvedModel;
    final provider = _provider;
    // 窄屏下工具条横向滚动，避免溢出
    final hasModels = providers.any((p) => p.modelIds.isNotEmpty);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 模型选择
          if (!hasModels)
            ToolbarChip(
              icon: Icons.model_training,
              label: context.l10n.chatNoModel,
              onTap: null,
            )
          else
            MenuAnchor(
              alignmentOffset: const Offset(0, 6),
              menuChildren: [
                for (final p in providers) ...[
                  if (p.modelIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                    ),
                  for (final m in p.modelIds)
                    MenuItemButton(
                      leadingIcon: Icon(
                        p.id == provider?.id && m == model
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: p.id == provider?.id && m == model
                            ? scheme.primary
                            : scheme.outline,
                      ),
                      child: Text(m, style: const TextStyle(fontSize: 13)),
                      onPressed: () => onModelChanged(p.id, m),
                    ),
                ],
              ],
              builder: (context, controller, child) => ModelChip(
                modelName: model ?? context.l10n.chatSelectModel,
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              ),
            ),
          const SizedBox(width: 6),
          // 思考强度（仅推理模型显示）
          if (_reasoningEnabled)
            MenuAnchor(
              alignmentOffset: const Offset(0, 6),
              menuChildren: [
                for (final value in _effortValues)
                  MenuItemButton(
                    leadingIcon: Icon(
                      options.reasoningEffort == value
                          ? Icons.check_rounded
                          : Icons.circle_outlined,
                      size: 16,
                      color: options.reasoningEffort == value
                          ? scheme.primary
                          : scheme.outline,
                    ),
                    child: Text(_effortMenuLabel(context.l10n, value),
                        style: const TextStyle(fontSize: 13)),
                    onPressed: () => onEffortChanged(value),
                  ),
              ],
              builder: (context, controller, child) => ToolbarChip(
                icon: Icons.psychology_outlined,
                label: _effortLabel(context.l10n, options.reasoningEffort),
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              ),
            ),
          const SizedBox(width: 8),
          // 流式开关
          ToolbarChip(
            icon: Icons.bolt_rounded,
            label: context.l10n.chatStream,
            active: options.stream,
            showExpand: false,
            onTap: isLoading ? null : () => onStreamChanged(!options.stream),
          ),
          const SizedBox(width: 8),
          // 图片附件
          ToolbarChip(
            icon: Icons.image_outlined,
            label: context.l10n.chatImage,
            active: hasPendingImages,
            showExpand: false,
            onTap: isLoading ? null : onPickImages,
          ),
          const SizedBox(width: 8),
          // 文档附件（PDF/DOCX/TXT）
          ToolbarChip(
            icon: Icons.description_outlined,
            label: context.l10n.chatDocument,
            active: hasPendingDocuments,
            showExpand: false,
            onTap: isLoading ? null : onPickDocuments,
          ),
        ],
      ),
    );
  }

  static String _effortLabel(AppLocalizations l10n, String? value) =>
      switch (value) {
        'low' => l10n.chatEffortLow,
        'medium' => l10n.chatEffortMedium,
        'high' => l10n.chatEffortHigh,
        _ => l10n.chatEffortAuto,
      };

  static String _effortMenuLabel(AppLocalizations l10n, String? value) =>
      switch (value) {
        'low' => l10n.chatEffortLowShort,
        'medium' => l10n.chatEffortMediumShort,
        'high' => l10n.chatEffortHighShort,
        _ => l10n.chatEffortAutoShort,
      };
}

/// 模型选择器：单行显示当前模型名，不省略（工具条可横向滚动兜底）。
class ModelChip extends StatelessWidget {
  final String modelName;
  final VoidCallback onTap;

  const ModelChip({
    super.key,
    required this.modelName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.model_training, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              modelName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

/// 通用工具条 chip：图标 + 文案 +（可选）展开箭头；激活态高亮。
class ToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// 激活态（如流式开启）：高亮背景与主色。
  final bool active;

  /// 是否显示右侧展开箭头（菜单类显示，开关类隐藏）。
  final bool showExpand;

  const ToolbarChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.showExpand = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (showExpand) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 14, color: scheme.outline),
            ],
          ],
        ),
      ),
    );
  }
}

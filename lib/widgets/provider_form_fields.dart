import 'package:flutter/material.dart';

import '../utils/focus_utils.dart';
import '../utils/l10n_ext.dart';
import '../services/chat_protocol.dart' show ProviderKind;
import '../services/provider_service.dart' show ModelTestResult;
import '../models/chat_provider.dart' show ModelConfig;

/// 服务商基础表单：名称 / Base URL / API Key / 协议 / 自定义请求头 / 请求体。
///
/// 纯展示组件：状态由父级持有（控制器 + 回调），修改即触发 [onChanged]。
class ProviderFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController customHeadersController;
  final TextEditingController customBodyController;

  final ProviderKind kind;
  final bool obscureApiKey;
  final VoidCallback onToggleObscure;
  final ValueChanged<ProviderKind> onKindChanged;
  final VoidCallback onChanged;

  const ProviderFormFields({
    super.key,
    required this.nameController,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.customHeadersController,
    required this.customBodyController,
    required this.kind,
    required this.obscureApiKey,
    required this.onToggleObscure,
    required this.onKindChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          onTapOutside: unfocusOnTap,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.providerName,
            hintText: context.l10n.providerNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: baseUrlController,
          autocorrect: false,
          onTapOutside: unfocusOnTap,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.providerBaseUrl,
            hintText: context.l10n.providerBaseUrlHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: apiKeyController,
          obscureText: obscureApiKey,
          autocorrect: false,
          enableSuggestions: false,
          onTapOutside: unfocusOnTap,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.providerApiKey,
            hintText: context.l10n.providerApiKeyHint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureApiKey ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.providerProtocol,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            PopupMenuButton<ProviderKind>(
              initialValue: kind,
              onSelected: onKindChanged,
              itemBuilder: (context) => [
                for (final k in ProviderKind.values)
                  PopupMenuItem(
                    value: k,
                    child: Text(
                      protocolLabel(context, k),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      protocolLabel(context, kind),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: customHeadersController,
          maxLines: 3,
          onTapOutside: unfocusOnTap,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.providerCustomHeaders,
            hintText: 'X-Trace-Id: abc',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: customBodyController,
          maxLines: 3,
          onTapOutside: unfocusOnTap,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.l10n.providerCustomBody,
            hintText: '{"extra": "value"}',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  /// 协议展示名（跟随当前语言）。
  static String protocolLabel(BuildContext context, ProviderKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      ProviderKind.auto => l10n.providerProtocolAuto,
      ProviderKind.openai => 'OpenAI',
      ProviderKind.anthropic => 'Anthropic',
      ProviderKind.gemini => 'Gemini',
    };
  }
}

/// 模型能力小标签（多模态 / 推理）。
class CapabilityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const CapabilityBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 模型测试延迟状态：未测试占位（可点击测试）/ 进行中 / 结果（可点击重测）。
class ModelLatencyLabel extends StatelessWidget {
  final String model;
  final bool testing;
  final ModelTestResult? result;
  final Future<void> Function(String model) onTestSingle;

  const ModelLatencyLabel({
    super.key,
    required this.model,
    required this.testing,
    required this.result,
    required this.onTestSingle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (testing) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    // 未测试过的模型显示占位文案，点击可发起测试
    if (result == null) {
      return Tooltip(
        message: context.l10n.providerClickTest,
        child: InkWell(
          onTap: () => onTestSingle(model),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              context.l10n.commonNotTested,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.outline,
              ),
            ),
          ),
        ),
      );
    }
    final Color color;
    final String text;
    if (result!.success) {
      color = result!.elapsedMs < 1000
          ? Colors.green
          : result!.elapsedMs < 3000
              ? Colors.orange
              : Colors.red;
      text = '${result!.elapsedMs}ms';
    } else {
      color = scheme.error;
      text = '-1ms';
    }
    // 点击毫秒数重新测试该模型连通性
    return Tooltip(
      message: context.l10n.providerClickRetest,
      child: InkWell(
        onTap: () => onTestSingle(model),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 模型列表区：标题 + 测试全部/添加模型 + 空态或可拖拽排序的模型行。
///
/// 纯展示组件：状态（模型列表/配置/测试结果）由父级持有。
class ProviderModelTable extends StatelessWidget {
  final List<String> modelIds;
  final Map<String, ModelConfig> modelConfigs;
  final Map<String, ModelTestResult?> testResults;
  final Set<String> testingModels;
  final bool testingAll;

  final Future<void> Function() onAddModel;
  final Future<void> Function() onTestAll;
  final Future<void> Function(String model) onTestSingle;
  final Future<void> Function(String model) onRemove;
  final void Function(String model) onOpenSettings;
  final void Function(int oldIndex, int newIndex) onReorder;

  const ProviderModelTable({
    super.key,
    required this.modelIds,
    required this.modelConfigs,
    required this.testResults,
    required this.testingModels,
    required this.testingAll,
    required this.onAddModel,
    required this.onTestAll,
    required this.onTestSingle,
    required this.onRemove,
    required this.onOpenSettings,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.providerModel,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (modelIds.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: testingAll ? null : onTestAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (testingAll)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      testingAll
                          ? context.l10n.providerTesting
                          : context.l10n.providerTest,
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: onAddModel,
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.l10n.providerAddModel),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (modelIds.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                context.l10n.providerModelsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: onReorder,
            children: [
              for (final model in modelIds)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(model),
                  index: modelIds.indexOf(model),
                  child: _buildModelItem(context, model, scheme),
                ),
            ],
          ),
      ],
    );
  }

  /// 模型行：名称可换行完整展示，能力标签与延迟状态放次行，操作按钮置右。
  Widget _buildModelItem(BuildContext context, String model, ColorScheme scheme) {
    final config = modelConfigs[model];
    final badges = <Widget>[
      if (config?.multimodal == true)
        CapabilityBadge(
          label: context.l10n.providerMultimodal,
          color: scheme.tertiary,
        ),
      if (config?.reasoning == true)
        CapabilityBadge(
          label: context.l10n.providerReasoning,
          color: scheme.primary,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 18, color: scheme.outlineVariant),
          const SizedBox(width: 4),
          const Icon(Icons.model_training_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (badges.isNotEmpty)
                      ...badges
                    else
                      // 无能力标签时给个占位，避免第二行左侧空荡
                      Text(
                        context.l10n.commonNone,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.outline,
                        ),
                      ),
                    const Spacer(),
                    ModelLatencyLabel(
                      model: model,
                      testing: testingModels.contains(model),
                      result: testResults[model],
                      onTestSingle: onTestSingle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: context.l10n.providerModelSettings,
            visualDensity: VisualDensity.compact,
            onPressed: () => onOpenSettings(model),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: context.l10n.commonRemove,
            visualDensity: VisualDensity.compact,
            onPressed: () => onRemove(model),
          ),
        ],
      ),
    );
  }
}

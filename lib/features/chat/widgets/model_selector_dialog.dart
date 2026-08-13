import 'package:flutter/material.dart';

import '../../../core/models/chat_provider.dart';
import '../../../core/services/model_capability_service.dart';
import '../../../core/services/usage/price_service.dart';
import '../../../core/utils/l10n_ext.dart';

/// C-06：增强模型选择器——搜索框 + 能力过滤 + 上下文窗口/价格行内展示。
///
/// 返回 `(providerId, modelId)`；取消返回 null。
Future<(String, String)?> showModelSelector(
  BuildContext context, {
  required List<ChatProvider> providers,
  String? currentProviderId,
  String? currentModelId,
}) async {
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => _ModelSelectorDialog(
      providers: providers,
      currentProviderId: currentProviderId,
      currentModelId: currentModelId,
    ),
  );
}

class _ModelSelectorDialog extends StatefulWidget {
  final List<ChatProvider> providers;
  final String? currentProviderId;
  final String? currentModelId;

  const _ModelSelectorDialog({
    required this.providers,
    this.currentProviderId,
    this.currentModelId,
  });

  @override
  State<_ModelSelectorDialog> createState() => _ModelSelectorDialogState();
}

class _ModelSelectorDialogState extends State<_ModelSelectorDialog> {
  String _query = '';
  bool _onlyMultimodal = false;
  bool _onlyReasoning = false;
  final ModelCapabilityService _capability = ModelCapabilityService();

  /// 当前请求的会话（dialog 内 props 不可变）。
  List<ChatProvider> get _providers => widget.providers;

  List<(ChatProvider, String)> _filtered() {
    final q = _query.trim().toLowerCase();
    final result = <(ChatProvider, String)>[];
    for (final p in _providers) {
      for (final m in p.modelIds) {
        if (q.isNotEmpty && !m.toLowerCase().contains(q)) continue;
        if (_onlyMultimodal || _onlyReasoning) {
          final cfg = p.modelConfigs[m];
          final cap = _capability.lookup(m);
          if (_onlyMultimodal &&
              !(cfg?.multimodal ?? cap?.multimodal ?? false)) {
            continue;
          }
          if (_onlyReasoning &&
              !(cfg?.reasoning ?? cap?.reasoning ?? false)) {
            continue;
          }
        }
        result.add((p, m));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final items = _filtered();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.chatSelectModel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.commonCancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.modelSearch,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 能力过滤
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.modelFilterMultimodal),
                    selected: _onlyMultimodal,
                    onSelected: (v) => setState(() => _onlyMultimodal = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(l10n.modelFilterReasoning),
                    selected: _onlyReasoning,
                    onSelected: (v) => setState(() => _onlyReasoning = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        l10n.chatNoModel,
                        style: TextStyle(color: scheme.outline),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final (p, m) = items[index];
                        final selected =
                            p.id == widget.currentProviderId &&
                            m == widget.currentModelId;
                        return _ModelTile(
                          providerName: p.name,
                          model: m,
                          selected: selected,
                          onTap: () => Navigator.pop(context, (p.id, m)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final String providerName;
  final String model;
  final bool selected;
  final VoidCallback onTap;

  const _ModelTile({
    required this.providerName,
    required this.model,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final capability = ModelCapabilityService();
    final window = capability.contextWindowFor(model);
    final contextWindow = window;
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 18,
        color: selected ? scheme.primary : scheme.outline,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              model,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (contextWindow != null) ...[
            const SizedBox(width: 6),
            Text(
              context.l10n.modelContextWindow('$contextWindow'),
              style: TextStyle(fontSize: 10.5, color: scheme.outline),
            ),
          ],
        ],
      ),
      subtitle: Text(
        providerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: scheme.outline),
      ),
      trailing: _PriceTag(model: model),
    );
  }
}

/// 价格标签（priceFor 缺失显示「-」）。
class _PriceTag extends StatelessWidget {
  final String model;

  const _PriceTag({required this.model});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: _pricePerM(model),
      builder: (context, snapshot) {
        final price = snapshot.data;
        return Text(
          price == null ? '−' : context.l10n.modelPrice(price.toStringAsFixed(2)),
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        );
      },
    );
  }

  static Future<double?> _pricePerM(String model) async {
    try {
      final p = await PriceService.instance.priceFor(model);
      if (p == null) return null;
      return p.promptPerM;
    } catch (_) {
      return null;
    }
  }
}

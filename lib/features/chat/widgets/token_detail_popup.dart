import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/services/usage/price_service.dart';
import '../../../core/utils/token_counter.dart';
import '../../../l10n/app_localizations.dart';

/// B-05：token 明细弹层（点击用量徽标打开）。
///
/// 内容 = 接口 usage（输入/输出）+ 本地 tiktoken 估算对照 +
/// 价格表成本（价格表缺失显示「未收录」）。
void showTokenDetailPopup(BuildContext context, ChatMessage message) {
  showDialog<void>(
    context: context,
    builder: (_) => _TokenDetailDialog(message: message),
  );
}

class _TokenDetailDialog extends StatefulWidget {
  final ChatMessage message;

  const _TokenDetailDialog({required this.message});

  @override
  State<_TokenDetailDialog> createState() => _TokenDetailDialogState();
}

class _TokenDetailDialogState extends State<_TokenDetailDialog> {
  final PriceService _priceService = PriceService.instance;
  double? _cost;
  bool? _hasPrice;

  ChatMessage get message => widget.message;

  @override
  void initState() {
    super.initState();
    _loadCost();
  }

  Future<void> _loadCost() async {
    final modelId = message.modelId ?? '';
    final input = message.promptTokens;
    final output = message.completionTokens;
    final price = await _priceService.priceFor(modelId);
    if (!mounted) return;
    setState(() {
      _hasPrice = price != null;
      if (input != null && output != null) {
        _cost = price == null
            ? null
            : input / 1000000 * price.promptPerM +
                output / 1000000 * price.completionPerM;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = message;
    // 本地 tiktoken 估算对照（精确估算，缓存命中）
    final estimated = TokenCounter.estimate(m.content);
    final input = m.promptTokens;
    final output = m.completionTokens;
    final cost = _cost;
    final hasPrice = _hasPrice;
    return AlertDialog(
      title: Text(l10n.tokenDetailTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              label: l10n.tokenDetailInput,
              value: input != null
                  ? TokenCounter.format(input)
                  : l10n.tokenDetailUnavailable,
            ),
            _Row(
              label: l10n.tokenDetailOutput,
              value: output != null
                  ? TokenCounter.format(output)
                  : l10n.tokenDetailUnavailable,
            ),
            if (m.elapsedMs != null)
              _Row(
                label: l10n.tokenDetailElapsed,
                value: '${(m.elapsedMs! / 1000).toStringAsFixed(1)}s',
              ),
            if (m.modelId != null)
              _Row(label: l10n.tokenDetailModel, value: m.modelId!),
            const Divider(height: 24),
            // 本地估算对照
            _Row(
              label: l10n.tokenDetailEstimated,
              value: TokenCounter.format(estimated),
            ),
            // 成本（异步加载价格表）
            _Row(
              label: l10n.tokenDetailCost,
              value: hasPrice == null
                  ? '…'
                  : cost == null
                  ? (hasPrice
                        ? l10n.tokenDetailUnavailable
                        : l10n.tokenDetailNoPrice)
                  : '\$${cost.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tokenDetailHint,
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

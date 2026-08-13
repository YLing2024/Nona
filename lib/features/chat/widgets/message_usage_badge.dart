import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/utils/token_counter.dart';
import 'token_detail_popup.dart';

/// 消息用量徽标：上行/下行 token 与耗时（仅展示已记录的项）。
///
/// B-05：点击打开 token 明细弹层。
class MessageUsageBadge extends StatelessWidget {
  final ChatMessage message;

  const MessageUsageBadge({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = <String>[
      if (message.promptTokens != null)
        '↑${TokenCounter.format(message.promptTokens!)}',
      if (message.completionTokens != null)
        '↓${TokenCounter.format(message.completionTokens!)}',
      if (message.elapsedMs != null && message.elapsedMs! >= 1000)
        '${(message.elapsedMs! / 1000).toStringAsFixed(1)}s',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        onTap: () => showTokenDetailPopup(context, message),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                parts.join(' · '),
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
              const SizedBox(width: 3),
              Icon(Icons.info_outline_rounded, size: 11, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

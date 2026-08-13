import 'package:flutter/material.dart';

import '../../../core/utils/l10n_ext.dart';

/// E-05：朗读浮动播放器——朗读时显示在输入区上方。
///
/// 提供暂停/继续、停止与速度切换；进度以「当前块/总块」呈现
/// （与消息正文的 chunk 高亮同源）。
class TtsFloatingPlayer extends StatelessWidget {
  final bool paused;
  final double speed;
  final int currentChunk;
  final int totalChunks;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;
  final ValueChanged<double> onSpeed;

  const TtsFloatingPlayer({
    super.key,
    required this.paused,
    required this.speed,
    required this.currentChunk,
    required this.totalChunks,
    required this.onTogglePause,
    required this.onStop,
    required this.onSpeed,
  });

  static const List<double> kSpeeds = [0.8, 1.0, 1.2, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progress = totalChunks <= 0
        ? '1/1'
        : '${(currentChunk + 1).clamp(1, totalChunks)}/$totalChunks';
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              progress,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                paused ? l10n.ttsFloatingPaused : l10n.ttsFloatingSpeaking,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 速度选择
            PopupMenuButton<double>(
              tooltip: l10n.ttsFloatingSpeed,
              initialValue: speed,
              onSelected: onSpeed,
              itemBuilder: (ctx) => [
                for (final s in kSpeeds)
                  PopupMenuItem(
                    value: s,
                    child: Text(
                      '${l10n.ttsFloatingSpeed} ${s.toStringAsFixed(1)}x',
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${speed.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
              tooltip: paused ? l10n.ttsFloatingResume : l10n.ttsFloatingPause,
              onPressed: onTogglePause,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: const Icon(Icons.stop_rounded),
              tooltip: l10n.ttsFloatingStop,
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

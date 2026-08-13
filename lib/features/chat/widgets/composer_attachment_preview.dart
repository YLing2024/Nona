import 'package:flutter/material.dart';

import '../../../core/utils/l10n_ext.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/document_extractor.dart' show ChatDocument;
import '../../../core/utils/token_counter.dart';
import '../../../shared/widgets/chat_image_view.dart';

/// 待发送附件预览：文档 chips + 图片缩略图行（各自带移除按钮）。
class AttachmentPreview extends StatelessWidget {
  final List<ChatImage> images;
  final List<ChatDocument> documents;
  final void Function(int index) onRemoveImage;
  final void Function(int index) onRemoveDocument;

  const AttachmentPreview({
    super.key,
    required this.images,
    required this.documents,
    required this.onRemoveImage,
    required this.onRemoveDocument,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (documents.isNotEmpty) ...[
          _buildDocuments(scheme),
          const SizedBox(height: 6),
        ],
        if (images.isNotEmpty) ...[
          _buildImages(scheme),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// 待发送文档附件 chips。
  Widget _buildDocuments(ColorScheme scheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < documents.length; i++)
          Chip(
            avatar: Icon(Icons.description_outlined, size: 16, color: scheme.primary),
            label: Text(
              documents[i].name,
              style: const TextStyle(fontSize: 12),
            ),
            visualDensity: VisualDensity.compact,
            deleteIconColor: scheme.outline,
            onDeleted: () => onRemoveDocument(i),
          ),
      ],
    );
  }

  /// 待发送图片缩略图行：点击右上角移除。
  Widget _buildImages(ColorScheme scheme) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = images[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ChatImageView(image: image, width: 64, height: 64),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Tooltip(
                  message: context.l10n.commonDelete,
                  child: Semantics(
                    label: context.l10n.commonDelete,
                    button: true,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 上下文用量统计条：估算 token / 上限 / 累计上行下行 token。
class ContextStatsBar extends StatelessWidget {
  final int estimatedTokens;
  final int? contextLimit;
  final int usagePrompt;
  final int usageCompletion;

  const ContextStatsBar({
    super.key,
    required this.estimatedTokens,
    required this.contextLimit,
    required this.usagePrompt,
    required this.usageCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overLimit =
        contextLimit != null && estimatedTokens > contextLimit!;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.data_usage_rounded,
              size: 12,
              color: overLimit ? scheme.error : scheme.outline,
            ),
            const SizedBox(width: 5),
            Text(
              context.l10n.chatContextUsage(
                      TokenCounter.format(estimatedTokens)) +
                  (contextLimit != null
                      ? ' / ${TokenCounter.format(contextLimit!)}'
                      : ''),
              style: _statStyle(context, overLimit: overLimit),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: context.l10n.chatTokensUp,
              child: _statItem(
                context,
                Icons.arrow_upward_rounded,
                TokenCounter.format(usagePrompt),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: context.l10n.chatTokensDown,
              child: _statItem(
                context,
                Icons.arrow_downward_rounded,
                TokenCounter.format(usageCompletion),
              ),
            ),
            if (overLimit) ...[
              const SizedBox(width: 12),
              Text(
                context.l10n.chatOverLimit,
                style: _statStyle(
                  context,
                  overLimit: true,
                  bold: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: scheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

  TextStyle _statStyle(
    BuildContext context, {
    required bool overLimit,
    bool bold = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 11,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
      color: overLimit ? scheme.error : scheme.outline,
    );
  }
}

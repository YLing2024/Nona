import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/capture_export.dart';
import '../../../l10n/app_localizations.dart';
import 'message_content.dart';

/// B-07：消息操作统一菜单——移动端 bottom sheet / 桌面端对话框共用。
enum MessageMoreAction {
  copy,
  edit,
  rollback,
  regenerate,
  delete,
  speak,
  selectCopy,
  exportImage,
  multiSelect,
  ocr,
  openDocument,
}

class MessageMoreSheetResult {
  final MessageMoreAction action;
  const MessageMoreSheetResult(this.action);
}

/// 展示消息「更多」菜单。
///
/// 桌面返回对话框形态，移动端返回 bottom sheet；选择后 pop 出
/// [MessageMoreAction]。
Future<MessageMoreAction?> showMessageMoreSheet(
  BuildContext context, {
  required ChatMessage message,
  required bool isUser,
  required bool isLastAssistant,
  required bool canRegenerate,
  required bool isStreaming,
  required bool longDocument,
  required bool speaking,
}) async {
  final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
      Theme.of(context).platform == TargetPlatform.macOS ||
      Theme.of(context).platform == TargetPlatform.linux;
  final l10n = AppLocalizations.of(context);
  final items = <_SheetItem>[
    _SheetItem(MessageMoreAction.copy, Icons.copy_rounded, l10n.commonCopy),
    if (!longDocument && message.content.trim().isNotEmpty)
      _SheetItem(
        MessageMoreAction.speak,
        speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        speaking ? l10n.chatStopSpeaking : l10n.chatSpeak,
      ),
    if (!longDocument)
      _SheetItem(MessageMoreAction.edit, Icons.edit_outlined, l10n.commonEdit),
    if (isUser)
      _SheetItem(
        MessageMoreAction.rollback,
        Icons.undo_rounded,
        l10n.chatRollback,
      ),
    if (!isUser && canRegenerate)
      _SheetItem(
        MessageMoreAction.regenerate,
        Icons.refresh_rounded,
        message.failed ? l10n.commonRetry : l10n.chatRegenerate,
      ),
    if (!isStreaming)
      _SheetItem(
        MessageMoreAction.selectCopy,
        Icons.text_fields_rounded,
        l10n.chatSelectCopy,
      ),
    if (!longDocument && !isStreaming)
      _SheetItem(
        MessageMoreAction.exportImage,
        Icons.image_outlined,
        l10n.chatExportImage,
      ),
    _SheetItem(
      MessageMoreAction.multiSelect,
      Icons.checklist_rounded,
      l10n.chatEnterSelection,
    ),
    if (message.images.isNotEmpty)
      _SheetItem(MessageMoreAction.ocr, Icons.document_scanner_outlined,
          l10n.ocrAction),
    if (longDocument)
      _SheetItem(
        MessageMoreAction.openDocument,
        Icons.description_outlined,
        l10n.chatOpenDocument,
      ),
    _SheetItem(
      MessageMoreAction.delete,
      Icons.delete_outline_rounded,
      l10n.commonDelete,
      danger: true,
    ),
  ];

  if (isDesktop) {
    return showDialog<MessageMoreAction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chatMoreActions),
        children: [
          for (final item in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, item.action),
              child: Row(
                children: [
                  Icon(item.icon, size: 20, color: item.danger
                      ? Theme.of(ctx).colorScheme.error
                      : Theme.of(ctx).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: item.danger
                          ? Theme.of(ctx).colorScheme.error
                          : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  return showModalBottomSheet<MessageMoreAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.chatMoreActions,
            style: Theme.of(ctx).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          for (final item in items)
            ListTile(
              leading: Icon(
                item.icon,
                size: 20,
                color: item.danger
                    ? Theme.of(ctx).colorScheme.error
                    : Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13.5,
                  color: item.danger
                      ? Theme.of(ctx).colorScheme.error
                      : null,
                ),
              ),
              onTap: () => Navigator.pop(ctx, item.action),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// B-07：选择复制对话框——可选中文本复制，可附带上下文发送。
Future<String?> showSelectCopySheet(
  BuildContext context, {
  required String text,
  bool allowSendWithContext = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: text);
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.chatSelectCopy, style: Theme.of(ctx).textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l10n.commonCopy),
                ),
              ),
              if (allowSendWithContext) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(ctx, '${controller.text}\n\n'),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.chatCopyWithContext),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}

/// B-07：单条消息导出图片——对话框内离屏渲染气泡并截图保存。
Future<Uint8List?> showMessageExportImageDialog(
  BuildContext context, {
  required ChatMessage message,
  required bool isUser,
}) async {
  final boundaryKey = GlobalKey();
  final l10n = AppLocalizations.of(context);
  final captured = await showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.chatExportImage),
      content: SizedBox(
        width: 420,
        height: 480,
        child: RepaintBoundary(
          key: boundaryKey,
          child: _ExportMessageCanvas(
            message: message,
            isUser: isUser,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.commonCancel),
        ),
        FilledButton.icon(
          onPressed: () async {
            try {
              final bytes = await CaptureExport.captureWidgetPng(boundaryKey);
              if (ctx.mounted) Navigator.pop(ctx, bytes);
            } catch (_) {
              if (ctx.mounted) {
                showAppSnack(ctx, l10n.chatExportImage);
              }
            }
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(l10n.chatExportImage),
        ),
      ],
    ),
  );
  return captured;
}

/// 导出画布：白底卡片 + 头像 + 消息内容 + 用量徽标。
class _ExportMessageCanvas extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ExportMessageCanvas({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                isUser ? 'User' : 'Assistant',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message.promptTokens != null ||
                  message.completionTokens != null)
                const Spacer(),
              if (message.promptTokens != null ||
                  message.completionTokens != null)
                Text(
                  '↑${message.promptTokens ?? 0} ↓${message.completionTokens ?? 0}',
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: MessageContent(
                message: message,
                isUser: isUser,
                isStreaming: false,
                speaking: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetItem {
  final MessageMoreAction action;
  final IconData icon;
  final String label;
  final bool danger;

  const _SheetItem(this.action, this.icon, this.label, {this.danger = false});
}

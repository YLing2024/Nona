import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../utils/l10n_ext.dart';

/// 消息操作条：复制 / 朗读 / 编辑 / 回滚 / 版本回退 / 重新生成 / 删除。
///
/// 显隐由 [show] 控制（hover / 触屏设备常显），键盘聚焦时同样显示
/// （Tab 可聚焦操作条内全部按钮）；[longDocument] 时
/// 朗读与编辑移至文档详情页，气泡仅保留其他操作。
class MessageActionBar extends StatefulWidget {
  final ChatMessage message;
  final bool isUser;
  final bool show;
  final bool speaking;
  final bool longDocument;
  final bool canRegenerate;

  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRollback;
  final VoidCallback? onRollbackVersion;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final VoidCallback? onSpeak;

  /// F1-5：图片消息「转为文字」（OCR）。
  final VoidCallback? onOcr;

  const MessageActionBar({
    super.key,
    required this.message,
    required this.isUser,
    required this.show,
    required this.speaking,
    required this.longDocument,
    required this.canRegenerate,
    this.onCopy,
    this.onEdit,
    this.onRollback,
    this.onRollbackVersion,
    this.onRegenerate,
    this.onDelete,
    this.onSpeak,
    this.onOcr,
  });

  @override
  State<MessageActionBar> createState() => _MessageActionBarState();
}

class _MessageActionBarState extends State<MessageActionBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = widget.isUser;
    final show = widget.show;
    final speaking = widget.speaking;
    final longDocument = widget.longDocument;
    final canRegenerate = widget.canRegenerate;
    final onCopy = widget.onCopy;
    final onEdit = widget.onEdit;
    final onRollback = widget.onRollback;
    final onRollbackVersion = widget.onRollbackVersion;
    final onRegenerate = widget.onRegenerate;
    final onDelete = widget.onDelete;
    final onSpeak = widget.onSpeak;
    final onOcr = widget.onOcr;
    final actions = <Widget>[
      _ActionIcon(
        icon: Icons.copy_rounded,
        tooltip: context.l10n.commonCopy,
        onTap: onCopy,
      ),
      // TTS 朗读：正在朗读时变为停止
      if (!longDocument &&
          onSpeak != null &&
          message.content.trim().isNotEmpty)
        _ActionIcon(
          icon: speaking
              ? Icons.stop_circle_outlined
              : Icons.volume_up_outlined,
          tooltip: speaking ? context.l10n.chatStopSpeaking : context.l10n.chatSpeak,
          highlight: speaking,
          onTap: onSpeak,
        ),
      // 用户与助手消息都支持编辑（跳转独立编辑页）
      if (!longDocument && onEdit != null)
        _ActionIcon(
          icon: Icons.edit_outlined,
          tooltip: context.l10n.commonEdit,
          onTap: onEdit,
        ),
      // 用户消息支持回滚到此处：清空其后的消息并回填输入框
      if (isUser && onRollback != null)
        _ActionIcon(
          icon: Icons.undo_rounded,
          tooltip: context.l10n.chatRollback,
          onTap: onRollback,
        ),
      // 版本历史：回退到上一版回复
      if (!isUser &&
          message.alternatives.isNotEmpty &&
          onRollbackVersion != null)
        _ActionIcon(
          icon: Icons.history_rounded,
          tooltip: context.l10n.chatRollbackVersion(
            message.alternatives.length + 1,
          ),
          onTap: onRollbackVersion,
        ),
      if (!isUser && canRegenerate && onRegenerate != null)
        _ActionIcon(
          icon: Icons.refresh_rounded,
          tooltip: message.failed ? context.l10n.commonRetry : context.l10n.chatRegenerate,
          onTap: onRegenerate,
        ),
      if (onDelete != null)
        _ActionIcon(
          icon: Icons.delete_outline_rounded,
          tooltip: context.l10n.commonDelete,
          danger: true,
          onTap: onDelete,
        ),
      // F1-5：图片消息可转为文字（OCR）
      if (message.images.isNotEmpty && onOcr != null)
        _ActionIcon(
          icon: Icons.document_scanner_outlined,
          tooltip: context.l10n.ocrAction,
          onTap: onOcr,
        ),
    ];

    // 键盘可聚焦的操作条：hover 或键盘聚焦时显示（Tab 可达全部操作）。
    return FocusableActionDetector(
      focusNode: FocusNode(debugLabel: 'message-actions'),
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: show || _focused ? 1 : 0,
        child: IgnorePointer(
          ignoring: !show && !_focused,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息操作小图标按钮。
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool danger;

  /// 高亮态（如 TTS 正在朗读）：图标使用主色。
  final bool highlight;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = highlight
        ? scheme.primary
        : danger
            ? scheme.error
            : scheme.outline;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

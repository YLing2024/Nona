import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/markdown_view.dart';
import 'message_actions.dart';
import 'message_content.dart';
import 'message_usage_badge.dart';

/// 单条聊天消息：头像 + 内容 + 操作（复制/编辑/重新生成/继续/删除/朗读）。
///
/// 各区域委托独立组件：
/// - [MessageContent]：角色分发 / 思考过程 / 流式渲染 / 图片条 / 文档卡
/// - [MessageUsageBadge]：用量徽标
/// - [MessageActionBar]：操作按钮条
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  /// 该消息是否正在流式生成中。
  final bool isStreaming;

  /// 是否允许重新生成（仅最后一条助手消息）。
  final bool canRegenerate;

  /// 该消息是否正在被 TTS 朗读。
  final bool speaking;

  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRollback;
  final VoidCallback? onRollbackVersion;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final VoidCallback? onSpeak;

  /// F1-5：图片消息「转为文字」。
  final VoidCallback? onOcr;

  /// 打开超长文本消息的文档详情页（气泡内文档占位卡点击）。
  final VoidCallback? onOpenDocument;

  /// B-07：统一「更多」菜单入口。
  final VoidCallback? onMore;

  /// 流式生成期间是否实时渲染 Markdown（设置项，默认开）。
  final bool streamMarkdown;

  /// 超过该字符数的消息折叠为「文本文档」入口（点击进详情页）；
  /// 0 表示不折叠。默认与 [MarkdownView.kDefaultMaxRenderChars] 一致。
  final int documentThreshold;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.canRegenerate = false,
    this.speaking = false,
    this.onCopy,
    this.onEdit,
    this.onRollback,
    this.onRollbackVersion,
    this.onRegenerate,
    this.onDelete,
    this.onSpeak,
    this.onOcr,
    this.onOpenDocument,
    this.onMore,
    this.streamMarkdown = true,
    this.documentThreshold = MarkdownView.kDefaultMaxRenderChars,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hovered = false;

  bool get _isUser => widget.message.role == 'user';

  /// 超长文本消息：不在气泡内渲染内容，仅显示文本文档占位卡，
  /// 点击进入详情页全量查看（避免长文档解析阻塞主线程）。
  /// 阈值由设置项「文本文档阈值」控制，0 表示不折叠。
  bool get _isLongDocument =>
      !widget.isStreaming &&
      widget.documentThreshold > 0 &&
      widget.message.content.length > widget.documentThreshold;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isUser) const MessageAvatar(isUser: false, size: 30),
            if (!_isUser) const SizedBox(width: 10),
            Expanded(
              child: _isUser
                  // 用户消息：内容与头像整体靠右
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.sizeOf(context).width * 0.72,
                        ),
                        child: _messageColumn(context),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width * 0.9,
                      ),
                      child: _messageColumn(context),
                    ),
            ),
            if (_isUser) const SizedBox(width: 10),
            if (_isUser) const MessageAvatar(isUser: true, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _messageColumn(BuildContext context) {
    final message = widget.message;
    final isTouch = Theme.of(context).platform != TargetPlatform.windows &&
        Theme.of(context).platform != TargetPlatform.macOS &&
        Theme.of(context).platform != TargetPlatform.linux;
    return Column(
      crossAxisAlignment: _isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        MessageContent(
          message: message,
          isUser: _isUser,
          isStreaming: widget.isStreaming,
          speaking: widget.speaking,
          onOpenDocument: widget.onOpenDocument,
          streamMarkdown: widget.streamMarkdown,
          documentThreshold: widget.documentThreshold,
        ),
        const SizedBox(height: 4),
        if (message.promptTokens != null ||
            message.completionTokens != null ||
            message.elapsedMs != null)
          MessageUsageBadge(message: message),
        MessageActionBar(
          message: message,
          isUser: _isUser,
          show: _hovered || isTouch,
          speaking: widget.speaking,
          longDocument: _isLongDocument,
          canRegenerate: widget.canRegenerate,
          onCopy: widget.onCopy,
          onEdit: widget.onEdit,
          onRollback: widget.onRollback,
          onRollbackVersion: widget.onRollbackVersion,
          onRegenerate: widget.onRegenerate,
          onDelete: widget.onDelete,
          onSpeak: widget.onSpeak,
          onOcr: widget.onOcr,
          onMore: widget.onMore,
        ),
      ],
    );
  }
}

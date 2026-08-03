import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'message_bubble.dart';

/// 消息列表：入场动画、智能滚动跟随、回底 FAB。
class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;

  /// 当前正在流式生成的消息索引（用于动画与光标）。
  final int? streamingIndex;

  final ScrollController controller;

  /// 是否允许重新生成（最后一条助手消息）。
  final bool canRegenerate;

  final void Function(ChatMessage message) onCopy;
  final void Function(ChatMessage message) onEdit;
  final void Function(ChatMessage message) onRegenerate;
  final void Function(ChatMessage message) onContinue;
  final void Function(ChatMessage message) onDelete;

  const MessageList({
    super.key,
    required this.messages,
    required this.streamingIndex,
    required this.controller,
    required this.canRegenerate,
    required this.onCopy,
    required this.onEdit,
    required this.onRegenerate,
    required this.onContinue,
    required this.onDelete,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  static const double _bottomTolerance = 100;

  bool get _isNearBottom {
    if (!widget.controller.hasClients) return true;
    final position = widget.controller.position;
    return position.pixels >= position.maxScrollExtent - _bottomTolerance;
  }

  /// 是否跟随滚动：仅在用户停在底部时自动跟随。
  bool _follow = true;

  void _onScroll() {
    final near = _isNearBottom;
    if (_follow != near) {
      setState(() => _follow = near);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    } else if (widget.streamingIndex != null && _follow) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      widget.controller.animateTo(
        widget.controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView.builder(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final message = widget.messages[index];
            final isStreaming = index == widget.streamingIndex;
            final isLastAssistant = index == widget.messages.length - 1 &&
                message.role == 'assistant' &&
                !isStreaming;
            return _AnimatedEntry(
              key: ValueKey('msg-${message.hashCode}-$index'),
              child: MessageBubble(
                message: message,
                isStreaming: isStreaming,
                canRegenerate: widget.canRegenerate &&
                    isLastAssistant &&
                    index > 0 &&
                    !message.failed,
                onCopy: () => widget.onCopy(message),
                onEdit: () => widget.onEdit(message),
                onRegenerate: () => widget.onRegenerate(message),
                onContinue: () => widget.onContinue(message),
                onDelete: () => widget.onDelete(message),
              ),
            );
          },
        ),
        // 回底按钮：仅在未跟随滚动时显示
        AnimatedOpacity(
          opacity: _follow ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: _follow,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: scheme.surface,
                  elevation: 3,
                  shadowColor: scheme.shadow,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _scrollToBottom,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 新消息入场动画：淡入 + 轻微上移。
class _AnimatedEntry extends StatefulWidget {
  final Widget child;

  const _AnimatedEntry({super.key, required this.child});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

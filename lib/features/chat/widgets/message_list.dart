import 'package:flutter/material.dart';

import '../../../core/utils/l10n_ext.dart';

import '../../../core/models/chat_message.dart';
import 'message_bubble.dart';

/// 消息列表：入场动画、智能滚动跟随、回底 FAB。
class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;

  /// 当前正在流式生成的消息索引（用于动画与光标）。
  final int? streamingIndex;

  final ScrollController controller;

  /// 是否允许重新生成（最后一条助手消息）。
  final bool canRegenerate;

  /// 正在被 TTS 朗读的消息对象标识（identityHashCode）；无朗读时为 null。
  final int? speakingMessageId;

  /// 进入后需要滚动定位到的消息索引（如搜索结果跳转）；null 表示不定位。
  final int? initialScrollIndex;

  /// 定位完成后回调（用于调用方清理一次性定位状态）。
  final VoidCallback? onScrollTargetHandled;

  final void Function(ChatMessage message) onCopy;
  final void Function(ChatMessage message) onEdit;
  final void Function(ChatMessage message) onRollback;
  final void Function(ChatMessage message) onRollbackVersion;
  final void Function(ChatMessage message) onRegenerate;
  final void Function(ChatMessage message) onDelete;
  final void Function(ChatMessage message) onSpeak;

  /// F1-5：图片消息「转为文字」（OCR）。
  final void Function(ChatMessage message)? onOcr;

  /// 打开超长文本消息的文档详情页。
  final void Function(ChatMessage message)? onOpenDocument;

  /// 流式生成期间是否实时渲染 Markdown（设置项，默认开）。
  final bool streamMarkdown;

  /// 超过该字符数的消息折叠为「文本文档」入口；0 表示不折叠。
  final int documentThreshold;

  /// B-01：多选模式与选中索引集合。
  final bool selectionActive;
  final Set<int> selectedIndices;
  final void Function(int index)? onToggleSelect;

  /// 连续选择（长按/右键触发，范围 = 锚点 → index）。
  final void Function(int index)? onRangeSelect;

  const MessageList({
    super.key,
    required this.messages,
    required this.streamingIndex,
    required this.controller,
    required this.canRegenerate,
    required this.onCopy,
    required this.onEdit,
    required this.onRollback,
    required this.onRollbackVersion,
    required this.onRegenerate,
    required this.onDelete,
    required this.onSpeak,
    this.onOcr,
    this.onOpenDocument,
    this.streamMarkdown = true,
    this.documentThreshold = 40000,
    this.speakingMessageId,
    this.initialScrollIndex,
    this.onScrollTargetHandled,
    this.selectionActive = false,
    this.selectedIndices = const {},
    this.onToggleSelect,
    this.onRangeSelect,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  static const double _bottomTolerance = 24;

  /// 搜索结果跳转定位的目标消息 key（命中项构建后 ensureVisible）。
  final GlobalKey _targetKey = GlobalKey();

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
    // 搜索结果跳转：定位到指定消息（跳过默认回底，避免打断定位动画）
    if (widget.initialScrollIndex != null) {
      _scrollToIndex(widget.initialScrollIndex!);
      return;
    }
    // 进入会话：直接定位到底部（无动画，配合 initialScrollOffset 首帧即底）
    _jumpToBottom();
    // 首帧后内容高度可能因图片/样式等继续变化，延迟再校正一次
    _delayed(_jumpToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同会话内再次搜索跳转：定位目标变化时重新滚动（初次跳转在 initState）
    if (widget.initialScrollIndex != null &&
        widget.initialScrollIndex != oldWidget.initialScrollIndex) {
      _scrollToIndex(widget.initialScrollIndex!);
    } else if (!identical(widget.messages, oldWidget.messages)) {
      // 切换会话（消息列表实例变化）时直接回到最新消息底部
      _jumpToBottom();
      _delayed(_jumpToBottom);
    } else if (widget.streamingIndex != null && _follow) {
      // 流式输出且贴底：内容持续增长，瞬时跳转保证窗口始终贴住最新数据
      _stickToBottom();
    } else if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  /// 延迟执行（防抖动后的兜底，避免与进场动画/图片加载抢占布局）。
  void _delayed(VoidCallback fn) {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) fn();
    });
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      if (!force && !_follow) return;
      widget.controller.animateTo(
        widget.controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// 流式输出贴底：执行时再次校验是否仍贴底。
  /// 必须在执行时校验，否则 _jumpToBottom 会取消用户主动上滑的拖动手势，
  /// 导致「想往上滑却一直被拽回底部」。
  void _stickToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      if (!_follow) return;
      widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
    });
  }

  /// 立即跳到底部（用于切换会话，避免从旧位置动画滚动）。
  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
    });
  }

  /// 定位到指定消息索引：先按估算高度跳近以触发目标项构建，
  /// 再 ensureVisible 精确对齐（消息高度不定，直接 jumpTo 无法精确）。
  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      final max = widget.controller.position.maxScrollExtent;
      final estimated = index * 96.0;
      widget.controller.jumpTo(estimated.clamp(0.0, max));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.12,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else if (widget.controller.hasClients) {
          widget.controller.animateTo(
            widget.controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
        widget.onScrollTargetHandled?.call();
      });
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
            final speaking = widget.speakingMessageId != null &&
                widget.speakingMessageId == identityHashCode(message);
            // B-01：多选模式下的选中态包裹
            final selected = widget.selectionActive &&
                widget.selectedIndices.contains(index);
            final bubble = isStreaming
                ? MessageBubble(
                    message: message,
                    isStreaming: true,
                    canRegenerate: false,
                    speaking: speaking,
                    streamMarkdown: widget.streamMarkdown,
                    documentThreshold: widget.documentThreshold,
                    onCopy: () => widget.onCopy(message),
                    onEdit: () => widget.onEdit(message),
                    onRollback: () => widget.onRollback(message),
                    onRollbackVersion: () => widget.onRollbackVersion(message),
                    onRegenerate: () => widget.onRegenerate(message),
                    onDelete: () => widget.onDelete(message),
                    onSpeak: () => widget.onSpeak(message),
                    onOcr: () => widget.onOcr?.call(message),
                    onOpenDocument: () => widget.onOpenDocument?.call(message),
                  )
                : _MemoizedBubble(
                    message: message,
                    isStreaming: false,
                    // 失败消息同样允许重试（重试即重新生成该回复）
                    canRegenerate: widget.canRegenerate &&
                        isLastAssistant &&
                        index > 0,
                    speaking: speaking,
                    // 搜索结果跳转目标：挂 key 供 ensureVisible 定位
                    isScrollTarget: widget.initialScrollIndex == index,
                    targetKey: _targetKey,
                    documentThreshold: widget.documentThreshold,
                    onCopy: () => widget.onCopy(message),
                    onEdit: () => widget.onEdit(message),
                    onRollback: () => widget.onRollback(message),
                    onRegenerate: () => widget.onRegenerate(message),
                    onDelete: () => widget.onDelete(message),
                    onSpeak: () => widget.onSpeak(message),
                    onOcr: () => widget.onOcr?.call(message),
                    onOpenDocument: () => widget.onOpenDocument?.call(message),
                  );
            Widget item = RepaintBoundary(
              child: _AnimatedEntry(
                key: ValueKey('msg-${message.hashCode}-$index'),
                child: bubble,
              ),
            );
            if (widget.selectionActive) {
              item = _SelectableMessage(
                selected: selected,
                onTap: () => widget.onToggleSelect?.call(index),
                onRange: () => widget.onRangeSelect?.call(index),
                child: item,
              );
            }
            return item;
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
                child: Semantics(
                  label: context.l10n.messageScrollToBottom,
                  button: true,
                  child: Material(
                    color: scheme.surface,
                    elevation: 3,
                    shadowColor: scheme.shadow,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _scrollToBottom(force: true),
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
        ),
      ],
    );
  }
}

/// 消息气泡记忆化缓存：输入（消息/流式状态/操作可用性/朗读/定位目标）未变时
/// 复用已构建的整棵子树，Flutter 对相同 widget 实例直接跳过 diff 与重建，
/// 彻底避免流式生成期间父级每帧重建带来的 Markdown 重解析/代码高亮重算，
/// 保证滚动不卡顿。主题、本地化等依赖变化时自动失效（didChangeDependencies）。
///
/// 回调闭包不参与失效判断：每次重建都会生成新闭包，但它们都指向同一批
/// 会话操作方法，且 [message] 引用不变，行为保持一致。
class _MemoizedBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final bool canRegenerate;
  final bool speaking;
  final bool isScrollTarget;
  final GlobalKey targetKey;

  /// 文本文档阈值（变化时需重建气泡以更新文档卡判定）。
  final int documentThreshold;

  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRollback;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final VoidCallback? onSpeak;
  final VoidCallback? onOcr;
  final VoidCallback? onOpenDocument;

  const _MemoizedBubble({
    required this.message,
    required this.isStreaming,
    required this.canRegenerate,
    required this.speaking,
    required this.isScrollTarget,
    required this.targetKey,
    this.documentThreshold = 40000,
    this.onCopy,
    this.onEdit,
    this.onRollback,
    this.onRegenerate,
    this.onDelete,
    this.onSpeak,
    this.onOcr,
    this.onOpenDocument,
  });

  @override
  State<_MemoizedBubble> createState() => _MemoizedBubbleState();
}

class _MemoizedBubbleState extends State<_MemoizedBubble> {
  Widget? _cached;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 主题/字号/本地化等依赖变化（MaterialApp 重建）时缓存失效
    _cached = null;
  }

  @override
  void didUpdateWidget(covariant _MemoizedBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 消息内容/状态就地修改（如编辑消息、token 用量回填）时缓存失效；
    // 流式消息不进入本缓存，无需担心高频内容比较
    final m = widget.message;
    final om = oldWidget.message;
    if (m != om ||
        m.content != om.content ||
        m.reasoningContent != om.reasoningContent ||
        m.interrupted != om.interrupted ||
        m.failed != om.failed ||
        widget.isStreaming != oldWidget.isStreaming ||
        widget.canRegenerate != oldWidget.canRegenerate ||
        widget.speaking != oldWidget.speaking ||
        widget.isScrollTarget != oldWidget.isScrollTarget ||
        widget.documentThreshold != oldWidget.documentThreshold) {
      _cached = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cached ??= MessageBubble(
      key: widget.isScrollTarget ? widget.targetKey : null,
      message: widget.message,
      isStreaming: widget.isStreaming,
      canRegenerate: widget.canRegenerate,
      speaking: widget.speaking,
      documentThreshold: widget.documentThreshold,
      onCopy: widget.onCopy,
      onEdit: widget.onEdit,
      onRollback: widget.onRollback,
      onRegenerate: widget.onRegenerate,
      onDelete: widget.onDelete,
      onSpeak: widget.onSpeak,
      onOcr: widget.onOcr,
      onOpenDocument: widget.onOpenDocument,
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

/// B-01：多选模式消息包裹层——点击切换选中、长按/右键连续选择，
/// 选中时显示强调边框与右上角选中圈。
class _SelectableMessage extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRange;
  final Widget child;

  const _SelectableMessage({
    required this.selected,
    required this.onTap,
    required this.onRange,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onRange,
      onSecondaryTap: onRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.0),
            width: 1.5,
          ),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : scheme.surface,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 14, color: scheme.onPrimary)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

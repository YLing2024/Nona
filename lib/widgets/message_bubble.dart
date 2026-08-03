import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../utils/token_counter.dart';
import 'avatar.dart';
import 'markdown_view.dart';

/// 单条聊天消息：头像 + 内容 + 操作（复制/编辑/重新生成/继续/删除）。
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  /// 该消息是否正在流式生成中。
  final bool isStreaming;

  /// 是否允许重新生成（仅最后一条助手消息）。
  final bool canRegenerate;

  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;
  final VoidCallback? onContinue;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.canRegenerate = false,
    this.onCopy,
    this.onEdit,
    this.onRegenerate,
    this.onContinue,
    this.onDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hovered = false;

  bool get _isUser => widget.message.role == 'user';

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
    return Column(
      crossAxisAlignment: _isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _buildContent(context),
        const SizedBox(height: 4),
        if (message.promptTokens != null ||
            message.completionTokens != null ||
            message.elapsedMs != null)
          _buildUsage(context),
        _buildActions(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = widget.message;

    if (_isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontSize: 14.5,
            height: 1.55,
          ),
        ),
      );
    }

    final showReasoning = message.reasoningContent.isNotEmpty;
    final hasContent = message.content.trim().isNotEmpty ||
        widget.isStreaming ||
        message.interrupted ||
        message.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nona',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isStreaming) ...[
              const SizedBox(width: 8),
              const _StreamingDots(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (showReasoning)
          _ReasoningSection(reasoning: message.reasoningContent),
        if (showReasoning && hasContent) const SizedBox(height: 8),
        if (hasContent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: message.content.isEmpty
                ? (widget.isStreaming
                      ? const _StreamingCaretLine()
                      : const SizedBox.shrink())
                : _AssistantMarkdown(
                    content: message.content,
                    isStreaming: widget.isStreaming,
                  ),
          ),
        if (message.failed)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: scheme.error),
                const SizedBox(width: 6),
                Text(
                  '生成失败',
                  style: TextStyle(fontSize: 12, color: scheme.error),
                ),
              ],
            ),
          ),
        if (message.interrupted && !message.failed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '已停止生成',
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ),
      ],
    );
  }

  Widget _buildUsage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = widget.message;
    final parts = <String>[
      if (m.promptTokens != null) '↑${TokenCounter.format(m.promptTokens!)}',
      if (m.completionTokens != null)
        '↓${TokenCounter.format(m.completionTokens!)}',
      if (m.elapsedMs != null && m.elapsedMs! >= 1000)
        '${(m.elapsedMs! / 1000).toStringAsFixed(1)}s',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        parts.join(' · '),
        style: TextStyle(fontSize: 11, color: scheme.outline),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final message = widget.message;
    final isTouch = Theme.of(context).platform != TargetPlatform.windows &&
        Theme.of(context).platform != TargetPlatform.macOS &&
        Theme.of(context).platform != TargetPlatform.linux;
    final show = _hovered || isTouch;

    final actions = <Widget>[
      _ActionIcon(
        icon: Icons.copy_rounded,
        tooltip: '复制',
        onTap: widget.onCopy,
      ),
      if (_isUser && widget.onEdit != null)
        _ActionIcon(
          icon: Icons.edit_outlined,
          tooltip: '编辑并重发',
          onTap: widget.onEdit,
        ),
      if (!_isUser && widget.canRegenerate && widget.onRegenerate != null)
        _ActionIcon(
          icon: Icons.refresh_rounded,
          tooltip: message.failed ? '重试' : '重新生成',
          onTap: widget.onRegenerate,
        ),
      if (!_isUser &&
          !widget.canRegenerate &&
          message.interrupted &&
          !message.failed &&
          widget.onContinue != null)
        _ActionIcon(
          icon: Icons.play_arrow_rounded,
          tooltip: '继续生成',
          onTap: widget.onContinue,
        ),
      if (widget.onDelete != null)
        _ActionIcon(
          icon: Icons.delete_outline_rounded,
          tooltip: '删除',
          danger: true,
          onTap: widget.onDelete,
        ),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: show ? 1 : 0,
      child: IgnorePointer(
        ignoring: !show,
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
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  final String content;
  final bool isStreaming;

  const _AssistantMarkdown({
    required this.content,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownView(data: content),
        if (isStreaming) const _StreamingCaret(),
      ],
    );
  }
}

/// 流式输出时的闪烁光标。
class _StreamingCaret extends StatefulWidget {
  const _StreamingCaret();

  @override
  State<_StreamingCaret> createState() => _StreamingCaretState();
}

class _StreamingCaretState extends State<_StreamingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_controller),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 8,
            height: 16,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// 等待首个 token 时的流式行。
class _StreamingCaretLine extends StatelessWidget {
  const _StreamingCaretLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          _StreamingCaret(),
          const SizedBox(width: 8),
          Text(
            '正在生成…',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「正在生成」的跳动三点。
class _StreamingDots extends StatefulWidget {
  const _StreamingDots();

  @override
  State<_StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<_StreamingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Opacity(
                  // 相位错开的三角波，结果恒在 [0,1]
                  opacity: _dotOpacity(i),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: kBrandGradient,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _dotOpacity(int index) {
    final phase = (_controller.value + index * 0.33) % 1.0;
    final wave = 1.0 - (phase * 2 - 1).abs();
    return 0.35 + 0.65 * wave;
  }
}

/// 思考过程：默认收起（显示前 5 行），点击展开全部。
class _ReasoningSection extends StatefulWidget {
  final String reasoning;

  const _ReasoningSection({required this.reasoning});

  @override
  State<_ReasoningSection> createState() => _ReasoningSectionState();
}

class _ReasoningSectionState extends State<_ReasoningSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    size: 14,
                    color: scheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '思考过程',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: scheme.outline,
                  ),
                ],
              ),
            ),
          ),
          // 收起时显示前 5 行，展开时渲染完整 Markdown
          if (!_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                widget.reasoning.trim(),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: MarkdownView(
                data: widget.reasoning,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme,
                ).copyWith(
                  p: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
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

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.outline;
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

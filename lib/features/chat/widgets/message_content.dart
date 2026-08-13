import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/chat_image_view.dart';
import '../../../shared/widgets/markdown_view.dart';
import 'citation_sources_sheet.dart';

/// 流式实时 Markdown 渲染的正文长度上限：超过后流式期间降级纯文本
/// （每帧全量解析超长文档会阻塞主线程）；生成完成后仍按文档阈值
/// 正常渲染或转为文本文档入口。
const int kStreamMarkdownMaxChars = 20000;

/// 消息内容区：按角色分发（用户气泡 / 助手内容），含思考过程、
/// 流式渲染、失败/中断标记、图片条与超长文档占位卡。
class MessageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final bool isStreaming;
  final bool speaking;

  /// 打开超长文本消息的文档详情页（气泡内文档占位卡点击）。
  final VoidCallback? onOpenDocument;

  /// 流式生成期间是否实时渲染 Markdown（设置项，默认开）。
  final bool streamMarkdown;

  /// 超过该字符数的消息折叠为「文本文档」入口（点击进详情页）；
  /// 0 表示不折叠。默认与 [MarkdownView.kDefaultMaxRenderChars] 一致。
  final int documentThreshold;

  const MessageContent({
    super.key,
    required this.message,
    required this.isUser,
    required this.isStreaming,
    required this.speaking,
    this.onOpenDocument,
    this.streamMarkdown = true,
    this.documentThreshold = MarkdownView.kDefaultMaxRenderChars,
  });

  /// 超长文本消息：不在气泡内渲染内容，仅显示文本文档占位卡，
  /// 点击进入详情页全量查看（避免长文档解析阻塞主线程）。
  /// 阈值由设置项「文本文档阈值」控制，0 表示不折叠。
  bool get _isLongDocument =>
      !isStreaming &&
      documentThreshold > 0 &&
      message.content.length > documentThreshold;

  @override
  Widget build(BuildContext context) {
    if (isUser) return _buildUser(context);
    return _buildAssistant(context);
  }

  Widget _buildUser(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
        // 朗读中的消息高亮描边
        border: speaking
            ? Border.all(color: scheme.primary, width: 1.6)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.images.isNotEmpty) ...[
            _ImageStrip(images: message.images),
            if (message.content.trim().isNotEmpty) const SizedBox(height: 8),
          ],
          if (message.content.trim().isNotEmpty)
            _isLongDocument
                ? _LongDocumentCard(
                    charCount: message.content.length,
                    onTap: onOpenDocument,
                  )
                : Text(
                    message.content,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 14.5,
                      height: 1.55,
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildAssistant(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showReasoning = message.reasoningContent.isNotEmpty;
    final hasContent = message.content.trim().isNotEmpty ||
        isStreaming ||
        message.interrupted ||
        message.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.assistantDisplayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            // 标注本次回复的服务商与模型名（小字）
            if (message.providerName != null && message.modelId != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.messageProviderBadge(
                    message.providerName!,
                    message.modelId!,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.outline,
                  ),
                ),
              ),
            ],
            if (isStreaming) ...[
              const SizedBox(width: 8),
              const _StreamingDots(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (showReasoning)
          _ReasoningSection(
            reasoning: message.reasoningContent,
            isStreaming: isStreaming,
          ),
        if (showReasoning && hasContent) const SizedBox(height: 8),
        if (hasContent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: speaking
                ? BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  )
                : null,
            // 超长文本：不渲染正文，只显示文档占位卡（点击进详情页）
            // 流式期间：设置开启时实时渲染 Markdown（生成多少渲染多少），
            // 关闭或内容超实时渲染上限时降级纯文本，流结束后正常渲染
            child: _isLongDocument
                ? _LongDocumentCard(
                    charCount: message.content.length,
                    onTap: onOpenDocument,
                  )
                : isStreaming
                    ? (message.content.isEmpty
                          ? const _StreamingCaretLine()
                          : (streamMarkdown &&
                                  message.content.length <=
                                      kStreamMarkdownMaxChars
                              ? _AssistantMarkdownLive(
                                  content: message.content,
                                )
                              : _StreamingPlainText(content: message.content)))
                    : (message.content.isEmpty
                          ? const SizedBox.shrink()
                          : _AssistantMarkdown(content: message.content)),
          ),
        // B-03：引用出处角标行（点击打开来源面板）
        if (message.citations.isNotEmpty && !isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final citation in message.citations)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      citation.url.startsWith('nona-kb://')
                          ? Icons.menu_book
                          : Icons.language,
                      size: 14,
                      color: scheme.primary,
                    ),
                    label: Text(
                      '[${citation.index}] ${citation.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => showCitationSourcesSheet(
                      context,
                      message.citations,
                    ),
                  ),
              ],
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
                  context.l10n.chatGenerationFailed,
                  style: TextStyle(fontSize: 12, color: scheme.error),
                ),
              ],
            ),
          ),
        if (message.interrupted && !message.failed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              context.l10n.chatStopped,
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ),
      ],
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  final String content;

  const _AssistantMarkdown({required this.content});

  @override
  Widget build(BuildContext context) {
    return MarkdownView(data: content);
  }
}

/// 流式期间的实时 Markdown 渲染（设置开启且内容未超限时）：
/// 与完整渲染共用同一个 [MarkdownView]，生成多少渲染多少。
class _AssistantMarkdownLive extends StatelessWidget {
  final String content;

  const _AssistantMarkdownLive({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownView(data: content),
        const _StreamingCaret(),
      ],
    );
  }
}

/// 流式输出期间的轻量正文：纯文本渲染（不解析 Markdown/代码高亮/Mermaid），
/// 内容增长仅需构建单个 TextSpan，避免高频全量解析导致主线程卡顿。
/// 流式结束后由 MessageContent 切换回 [MarkdownView]。
class _StreamingPlainText extends StatelessWidget {
  final String content;

  const _StreamingPlainText({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.5,
            height: 1.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const _StreamingCaret(),
      ],
    );
  }
}

/// 超长文本的文档占位卡：不渲染正文，仅展示「文本文档」样式入口，
/// 点击进入详情页全量查看（文档页渲染效果与气泡内 Markdown 一致）。
class _LongDocumentCard extends StatelessWidget {
  final int charCount;
  final VoidCallback? onTap;

  const _LongDocumentCard({required this.charCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.description_outlined,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.chatDocumentTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.chatDocumentSubtitle(charCount),
                    style: TextStyle(fontSize: 11.5, color: scheme.outline),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_full_rounded,
              size: 16,
              color: scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// 消息中的图片展示条（横向排列缩略图）。
class _ImageStrip extends StatelessWidget {
  final List<ChatImage> images;

  const _ImageStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final image in images)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 180,
              height: 180,
              child: ChatImageView(image: image, fit: BoxFit.contain),
            ),
          ),
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
            context.l10n.chatGenerating,
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

  /// 流式生成中：展开时同样使用纯文本，避免高频 Markdown 解析。
  final bool isStreaming;

  const _ReasoningSection({required this.reasoning, this.isStreaming = false});

  @override
  State<_ReasoningSection> createState() => _ReasoningSectionState();
}

class _ReasoningSectionState extends State<_ReasoningSection> {
  bool _expanded = false;

  /// 取正文的最后 [count] 行：流式刷新时始终展示最新内容。
  String _lastLines(String text, int count) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final lines = trimmed.split('\n');
    if (lines.length <= count) return trimmed;
    return lines.sublist(lines.length - count).join('\n');
  }

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
                    context.l10n.chatThinking,
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
          // 收起时显示最后 5 行（随流式刷新滚动到最新），展开时渲染完整 Markdown
          if (!_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                _lastLines(widget.reasoning, 5),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            )
          else if (widget.isStreaming)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                widget.reasoning.trim(),
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

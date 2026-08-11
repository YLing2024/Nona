import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/app_theme.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../utils/l10n_ext.dart';
import 'markdown_math.dart';

/// 增强版 Markdown 渲染：
/// - 代码块语法高亮 + 语言标签 + 一键复制
/// - 行内代码胶囊样式
/// - 链接点击跳转（http/https/mailto）
/// - 网络图片加载（带占位与失败兜底）
/// - 任务列表复选框（只读）
/// - 宽表格横向滚动
/// - Mermaid 图渲染（解析失败回退显示源码）
/// - 超长文本默认截断渲染 + 「显示全文」（防一次性大文档解析卡顿）
class MarkdownView extends StatefulWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  /// 超过该字符数的文档默认只渲染开头部分，点击「显示全文」后完整渲染；
  /// 传 null 表示不限制。默认 [kDefaultMaxRenderChars]。
  final int? maxRenderChars;

  /// 默认超长阈值：超出后触发截断渲染。
  static const int kDefaultMaxRenderChars = 40000;

  const MarkdownView({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
    this.maxRenderChars = kDefaultMaxRenderChars,
  });

  static const _kCodeFontFamily = 'monospace';

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  bool _expanded = false;

  void _onTapLink(String text, String? href, String title) {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'mailto') {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildImage(BuildContext context, MarkdownImageConfig config) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context).width * 0.6;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        config.uri.toString(),
        width: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: 160,
            color: scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: size,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 20, color: scheme.outline),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.chatImageLoadFailed(
                    config.alt ?? config.uri,
                  ),
                  style: TextStyle(color: scheme.outline, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final limit = widget.maxRenderChars;
    // 超长文档截断渲染：仅在段落边界截断，避免切断代码围栏等结构
    if (limit != null && data.length > limit && !_expanded) {
      final cut = _safeCut(data, limit);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBody(context, cut),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = true),
              icon: const Icon(Icons.expand_more_rounded, size: 16),
              label: Text(context.l10n.chatShowFull(data.length)),
            ),
          ),
        ],
      );
    }
    return _buildBody(context, data);
  }

  /// 在 [limit] 附近最近的换行处截断（限定往回找的窗口，避免长行退化）。
  static String _safeCut(String text, int limit) {
    final idx = text.lastIndexOf('\n', limit);
    final end = idx >= limit - 2000 ? idx : limit;
    return text.substring(0, end);
  }

  Widget _buildBody(BuildContext context, String data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final base = widget.styleSheet ?? MarkdownStyleSheet.fromTheme(theme);

    final sheet = base.copyWith(
      p: base.p?.copyWith(height: 1.6),
      h1: base.h1?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
      h2: base.h2?.copyWith(fontWeight: FontWeight.w700, fontSize: 19),
      h3: base.h3?.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
      h4: base.h4?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      blockquoteDecoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? AppColors.codeBlockBgDark : AppColors.codeBlockBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      codeblockPadding: EdgeInsets.zero,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tableBorder: TableBorder.all(
        color: scheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      // 宽表启用横向滚动（flutter_markdown 在 IntrinsicColumnWidth 下自动包裹滚动容器）
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableScrollbarThumbVisibility: true,
      tableHead: base.tableHead?.copyWith(fontWeight: FontWeight.w600),
      listBullet: base.listBullet?.copyWith(color: scheme.primary),
    );

    final gfm = md.ExtensionSet.gitHubFlavored;
    return MarkdownBody(
      data: data,
      selectable: widget.selectable,
      styleSheet: sheet,
      extensionSet: md.ExtensionSet(
        [...gfm.blockSyntaxes, MathBlockSyntax(), BracketMathBlockSyntax()],
        [
          ...gfm.inlineSyntaxes,
          DoubleDollarInlineSyntax(),
          MathInlineSyntax(),
          BracketMathInlineSyntax(),
          ParenMathInlineSyntax(),
        ],
      ),
      builders: {
        'code': _InlineCodeBuilder(theme: theme),
        'pre': _CodeBlockBuilder(theme: theme),
        'math': MathBlockBuilder(),
        'math-inline': MathInlineBuilder(),
      },
      checkboxBuilder: (checked) => _buildCheckbox(context, checked),
      sizedImageBuilder: (config) => _buildImage(context, config),
      onTapLink: _onTapLink,
    );
  }

  /// 任务列表复选框：只读展示（✓ 勾选 / 空心未勾选），跟随主题色。
  Widget _buildCheckbox(BuildContext context, bool checked) {
    final scheme = Theme.of(context).colorScheme;
    final size = 17.0;
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: checked ? scheme.primary : scheme.outline,
            width: 1.4,
          ),
        ),
        alignment: Alignment.center,
        child: checked
            ? Icon(Icons.check_rounded, size: 13, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}

/// 行内代码：胶囊样式。
class _InlineCodeBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _InlineCodeBuilder({required this.theme});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    // 块级代码由 pre builder 统一处理（带 class 或含换行的视为块级）
    if (code.isEmpty ||
        element.attributes.containsKey('class') ||
        code.contains('\n')) {
      return null;
    }
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: MarkdownView._kCodeFontFamily,
          fontSize: 13,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// 块级代码：从 pre 元素中提取代码与语言，渲染高亮代码块。
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeData theme;

  _CodeBlockBuilder({required this.theme});

  @override
  bool isBlockElement() => true;

  /// flutter_markdown 对「带内联子节点的块级自定义元素」会生成父级 inline，
  /// 只有 visitText 返回非 null 时该 inline 才会在块结束时被清空，
  /// 否则 _inlines 残留导致 debug 断言崩溃。实际渲染在
  /// [visitElementAfterWithContext] 完成，这里返回不可见占位即可。
  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    return const SizedBox.shrink();
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final children = element.children ?? const [];
    if (children.isEmpty) return null;
    final first = children.first;
    if (first is! md.Element || first.tag != 'code') return null;
    final code = first.textContent;
    if (code.isEmpty) return null;

    final langAttr = first.attributes['class'] ?? '';
    final language = langAttr.startsWith('language-')
        ? langAttr.substring('language-'.length)
        : null;
    // Mermaid 图：交给专用渲染器（解析失败回退显示源码）
    if (language == 'mermaid') {
      return MermaidBlock(
        code: code,
        isDark: theme.brightness == Brightness.dark,
        theme: theme,
      );
    }
    return CodeBlock(
      code: code,
      language: language,
      isDark: theme.brightness == Brightness.dark,
      theme: theme,
    );
  }
}

/// Mermaid 图渲染块：纯 Dart 渲染流程图/时序图/饼图等；
/// 解析失败时回退为带边框的等宽源码展示，保证内容不丢失。
class MermaidBlock extends StatelessWidget {
  final String code;
  final bool isDark;
  final ThemeData theme;

  const MermaidBlock({
    super.key,
    required this.code,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: MermaidDiagram(
          code: code,
          style: isDark ? MermaidStyle.dark() : const MermaidStyle(),
          errorBuilder: (context, error) =>
              _MermaidFallback(theme: theme, code: code),
        ),
      ),
    );
  }
}

/// Mermaid 解析失败的兜底：展示源码，提示语法不支持。
class _MermaidFallback extends StatelessWidget {
  final ThemeData theme;
  final String code;

  const _MermaidFallback({required this.theme, required this.code});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.chatMermaidUnsupported,
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
          const SizedBox(height: 6),
          Text(
            code,
            style: TextStyle(
              fontFamily: MarkdownView._kCodeFontFamily,
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 代码块组件：语言标签 + 高亮内容 + 复制按钮。
class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;
  final bool isDark;
  final ThemeData theme;

  const CodeBlock({
    super.key,
    required this.code,
    required this.language,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.codeBlockBgDark : AppColors.codeBlockBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language ?? 'text',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: scheme.outline,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code, theme: theme),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: HighlightView(
                code,
                language: language,
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontFamily: MarkdownView._kCodeFontFamily,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String code;
  final ThemeData theme;

  const _CopyButton({required this.code, required this.theme});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy_rounded,
              size: 13,
              color: _copied ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? context.l10n.commonCopied : context.l10n.commonCopy,
              style: TextStyle(
                fontSize: 11,
                color: _copied ? scheme.primary : scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

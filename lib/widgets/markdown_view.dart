import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// 增强版 Markdown 渲染：
/// - 代码块语法高亮 + 语言标签 + 一键复制
/// - 行内代码胶囊样式
/// - 链接点击跳转（http/https/mailto）
/// - 网络图片加载（带占位与失败兜底）
class MarkdownView extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  const MarkdownView({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
  });

  static const _kCodeFontFamily = 'monospace';

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
                  '图片加载失败：${config.alt ?? config.uri}',
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final base = styleSheet ?? MarkdownStyleSheet.fromTheme(theme);

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
        color: isDark
            ? const Color(0xFF0F1220)
            : const Color(0xFFF4F5FA),
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
      tableHead: base.tableHead?.copyWith(fontWeight: FontWeight.w600),
      listBullet: base.listBullet?.copyWith(color: scheme.primary),
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: sheet,
      builders: {
        'code': _InlineCodeBuilder(theme: theme),
        'pre': _CodeBlockBuilder(theme: theme),
      },
      sizedImageBuilder: (config) => _buildImage(context, config),
      onTapLink: _onTapLink,
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
    return CodeBlock(
      code: code,
      language: language,
      isDark: theme.brightness == Brightness.dark,
      theme: theme,
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
        color: isDark ? const Color(0xFF0F1220) : const Color(0xFFF4F5FA),
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
              _copied ? '已复制' : '复制',
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

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// LaTeX 数学公式支持（基于 flutter_math_fork / KaTeX 解析器）。
///
/// 支持的定界符：
/// - 行内（text 样式）：`$...$`、`\(...\)`
/// - 行内（display 样式，段落中）：`$$...$$`、`\[...\]`
/// - 块级（独占一行的 display）：`$$ ... $$`（围栏或多行）、`\[ ... \]`
///
/// 与 [MarkdownBody] 配合使用：
/// ```dart
/// extensionSet: md.ExtensionSet(
///   [MathBlockSyntax(), BracketMathBlockSyntax()],
///   [DoubleDollarInlineSyntax(), MathInlineSyntax(),
///    BracketMathInlineSyntax(), ParenMathInlineSyntax()],
/// ),
/// builders: {
///   'math': MathBlockBuilder(),
///   'math-inline': MathInlineBuilder(),
/// },
/// ```

md.Element _inline({required String math, required bool display}) {
  final el = md.Element('math-inline', [md.Text(math)]);
  el.attributes['class'] = display ? 'math-inline-display' : 'math-inline';
  return el;
}

md.Element _block(String tex) {
  // 公式内容存 attribute，避免 Text 子节点被 flutter_markdown 当作
  // inline 文本处理导致 _inlines 残留断言崩溃。
  final el = md.Element('math', []);
  el.attributes['class'] = 'math-block';
  el.attributes['tex'] = tex;
  return el;
}

/// 行内 `$...$`：两端不能紧跟空白，避免误伤价格等普通文本。
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax()
      : super(
          r'\$([^\s$][^$\n]*?[^\s$]|[^\s$])\$',
          startCharacter: 0x24,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_inline(math: match[1]!, display: false));
    return true;
  }
}

/// 段落中内嵌的 `$$...$$`（display 样式）。
/// 必须在 [MathInlineSyntax] 之前注册，避免 `$$` 被拆成两个 `$`。
class DoubleDollarInlineSyntax extends md.InlineSyntax {
  DoubleDollarInlineSyntax()
      : super(
          r'\$\$([^$\n]+?)\$\$',
          startCharacter: 0x24,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_inline(math: match[1]!, display: true));
    return true;
  }
}

/// 行内 `\(...\)`。
class ParenMathInlineSyntax extends md.InlineSyntax {
  ParenMathInlineSyntax()
      : super(
          r'\\\(([\s\S]*?)\\\)',
          startCharacter: 0x5C,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_inline(math: match[1]!, display: false));
    return true;
  }
}

/// 段落中内嵌的 `\[...\]`（display 样式）。
class BracketMathInlineSyntax extends md.InlineSyntax {
  BracketMathInlineSyntax()
      : super(
          r'\\\[([\s\S]*?)\\\]',
          startCharacter: 0x5C,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(_inline(math: match[1]!, display: true));
    return true;
  }
}

/// 块级公式：`$$ ... $$`（单行 `$$x+1$$` 或围栏式多行）。
class MathBlockSyntax extends md.BlockSyntax {
  static final RegExp _openFence = RegExp(r'^\$\$\s*$');
  static final RegExp _singleLine = RegExp(r'^\$\$(.*?)\$\$\s*$');

  @override
  RegExp get pattern => RegExp(r'^\$\$');

  @override
  bool canEndBlock(md.BlockParser parser) => true;

  @override
  md.Node? parse(md.BlockParser parser) {
    final current = parser.current.content;

    // 单行 `$$...$$`：整行作为公式。
    final single = _singleLine.firstMatch(current);
    if (single != null) {
      parser.advance();
      return _block(single[1]!.trim());
    }

    if (!_openFence.hasMatch(current)) return null;

    // 围栏式：`$$` 起，收集到下一个 `$$` 为止。
    parser.advance();
    final buffer = StringBuffer();
    while (!parser.isDone) {
      final line = parser.current.content;
      if (_openFence.hasMatch(line)) {
        parser.advance();
        return _block(buffer.toString().trim());
      }
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(line);
      parser.advance();
    }
    return _block(buffer.toString().trim());
  }
}

/// 块级公式：`\[ ... \]`（单行 `\[x+1\]` 或围栏式多行）。
class BracketMathBlockSyntax extends md.BlockSyntax {
  static final RegExp _openFence = RegExp(r'^\s*\\\[\s*$');
  static final RegExp _closeFence = RegExp(r'^\s*\\\]\s*$');
  static final RegExp _singleLine = RegExp(r'^\s*\\\[(.*?)\\\]\s*$');

  @override
  RegExp get pattern => RegExp(r'^\s*\\\[');

  @override
  bool canEndBlock(md.BlockParser parser) => true;

  @override
  md.Node? parse(md.BlockParser parser) {
    final current = parser.current.content;

    // 单行 `\[...\]`。
    final single = _singleLine.firstMatch(current);
    if (single != null) {
      parser.advance();
      return _block(single[1]!.trim());
    }

    if (!_openFence.hasMatch(current)) return null;

    parser.advance();
    final buffer = StringBuffer();
    while (!parser.isDone) {
      final line = parser.current.content;
      if (_closeFence.hasMatch(line)) {
        parser.advance();
        return _block(buffer.toString().trim());
      }
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(line);
      parser.advance();
    }
    return _block(buffer.toString().trim());
  }
}

/// 块级公式渲染：居中展示，超宽时可横向滚动，解析失败时回退显示源码。
class MathBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = (element.attributes['tex'] ?? element.textContent).trim();
    if (tex.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final fontSize = (parentStyle?.fontSize ?? 14) + 2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Center(
              child: Math.tex(
                tex,
                mathStyle: MathStyle.display,
                textStyle: TextStyle(
                  inherit: false,
                  fontSize: fontSize,
                  color: scheme.onSurface,
                ),
                onErrorFallback: (e) => _fallback(context, tex, fontSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 行内公式渲染：跟随正文字号与颜色。
class MathInlineBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent.trim();
    if (tex.isEmpty) return null;
    final display = element.attributes['class'] == 'math-inline-display';
    final scheme = Theme.of(context).colorScheme;
    final fontSize = parentStyle?.fontSize ?? 13;
    return Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(
        inherit: false,
        fontSize: fontSize,
        color: scheme.onSurface,
      ),
      onErrorFallback: (e) => _fallback(context, tex, fontSize),
    );
  }
}

/// 解析失败兜底：以普通等宽文本展示 LaTeX 源码，保证内容不丢失。
Widget _fallback(BuildContext context, String tex, double fontSize) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: Text(
      tex.isEmpty ? '' : r'$' + tex + r'$',
      style: TextStyle(
        inherit: false,
        fontSize: fontSize - 2,
        color: scheme.onSurfaceVariant,
        fontFamily: 'monospace',
      ),
    ),
  );
}

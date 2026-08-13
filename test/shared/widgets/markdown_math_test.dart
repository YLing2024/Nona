import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nona_chat/shared/widgets/markdown_math.dart';

void main() {
  md.Document buildDocument() => md.Document(
        extensionSet: md.ExtensionSet(
          [MathBlockSyntax(), BracketMathBlockSyntax()],
          [
            DoubleDollarInlineSyntax(),
            MathInlineSyntax(),
            BracketMathInlineSyntax(),
            ParenMathInlineSyntax(),
          ],
        ),
        encodeHtml: false,
      );

  String? findMathContent(List<md.Node> roots, String tag) {
    String? visit(md.Node node) {
      if (node is md.Element && node.tag == tag) {
        return (node.attributes['tex'] ?? node.textContent).trim();
      }
      for (final child in node is md.Element
          ? (node.children ?? const <md.Node>[])
          : const <md.Node>[]) {
        final result = visit(child);
        if (result != null) return result;
      }
      return null;
    }

    for (final root in roots) {
      final result = visit(root);
      if (result != null) return result;
    }
    return null;
  }

  md.Element? firstElement(List<md.Node> roots, String tag) {
    md.Element? visit(md.Node node) {
      if (node is md.Element && node.tag == tag) return node;
      for (final child in node is md.Element
          ? (node.children ?? const <md.Node>[])
          : const <md.Node>[]) {
        final result = visit(child);
        if (result != null) return result;
      }
      return null;
    }

    for (final root in roots) {
      final result = visit(root);
      if (result != null) return result;
    }
    return null;
  }

  test(r'行内公式 $...$', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'求 $E=mc^2$ 的能量');
    final tex = findMathContent(root, 'math-inline');
    expect(tex, 'E=mc^2');
  });

  test('行内公式首尾带空格时不匹配（价格等普通文本）', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'价格是 $5 和 $10，都是现价');
    expect(findMathContent(root, 'math-inline'), isNull);
  });

  test('行内公式美元转义不误匹配', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'\$5 不是公式');
    expect(findMathContent(root, 'math-inline'), isNull);
  });

  test(r'单行块级公式 $$x+1$$', () {
    final doc = buildDocument();
    final nodes = doc.parseLines(
      const LineSplitter().convert(r'$$x^2 + y^2 = z^2$$'),
    );
    expect(findMathContent(nodes, 'math'), 'x^2 + y^2 = z^2');
  });

  test('围栏式多行块级公式', () {
    final doc = buildDocument();
    final nodes = doc.parseLines(const LineSplitter().convert(r'''
$$
\frac{a}{b} = \frac{c}{d}
\quad \text{and} \quad
\int_0^1 x \, dx
$$
'''));
    final tex = findMathContent(nodes, 'math');
    expect(tex, isNotNull);
    expect(tex, contains(r'\frac{a}{b}'));
    expect(tex, contains(r'\int_0^1'));
  });

  test(r'行内公式 \(...\) 定界符', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'公式 \(E=mc^2\) 结束');
    expect(findMathContent(root, 'math-inline'), 'E=mc^2');
  });

  test(r'段落内嵌 $$...$$ 为 display 行内公式', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'解得 $$x = \frac{1}{2}$$，其中 x>0');
    final el = firstElement(root, 'math-inline');
    expect(el, isNotNull);
    expect(el!.attributes['class'], 'math-inline-display');
  });

  test(r'段落内嵌 \[...\] 为 display 行内公式', () {
    final doc = buildDocument();
    final root = doc.parseInline(r'解得 \[x = 1\]，其中 x>0');
    final el = firstElement(root, 'math-inline');
    expect(el, isNotNull);
    expect(el!.attributes['class'], 'math-inline-display');
  });

  test(r'围栏式块级 \[...\]', () {
    final doc = buildDocument();
    final nodes = doc.parseLines(const LineSplitter().convert(r'''
\[
\frac{a}{b}
\]
'''));
    expect(findMathContent(nodes, 'math'), r'\frac{a}{b}');
  });

  test(r'未闭合的 $$ 保持普通文本', () {
    final doc = buildDocument();
    final nodes = doc.parseLines(const LineSplitter().convert(r'成本 $$5 起步'));
    expect(findMathContent(nodes, 'math'), isNull);
  });
}

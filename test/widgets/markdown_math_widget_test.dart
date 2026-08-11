import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'package:nona_chat/l10n/app_localizations.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/widgets/message_bubble.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Future<void> pump(WidgetTester tester, String content) async {
    await tester.pumpWidget(wrap(MessageBubble(
      message: ChatMessage(role: 'assistant', content: content),
    )));
    await tester.pump(const Duration(milliseconds: 100));
  }

  int mathCount(WidgetTester tester) =>
      find.byType(Math).evaluate().length;

  testWidgets('dollar inline', (tester) async {
    await pump(tester, r'公式 $E=mc^2$ 结束');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paren inline', (tester) async {
    await pump(tester, r'公式 \(E=mc^2\) 结束');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double-dollar embedded in paragraph', (tester) async {
    await pump(tester, r'解得 $$x = \frac{1}{2}$$，其中 x>0');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket inline embedded', (tester) async {
    await pump(tester, r'解得 \[x = \frac{1}{2}\]，其中 x>0');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dollar block', (tester) async {
    await pump(tester, r'$$\frac{a}{b}$$');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket block fenced', (tester) async {
    await pump(tester, '\\[\n\\frac{a}{b}\n\\]');
    expect(mathCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed realistic content', (tester) async {
    const content = r'''推导：
$$
\begin{aligned}
E &= mc^2
\end{aligned}
$$
因此 \(v = \sqrt{2gh}\) 且 $v \geq 0$。''';
    await pump(tester, content);
    expect(mathCount(tester), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escaped dollar stays literal', (tester) async {
    await pump(tester, r'价格 \$5 起，\$10 封顶');
    expect(mathCount(tester), 0);
    expect(tester.takeException(), isNull);
  });
}

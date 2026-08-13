import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/features/chat/screens/message_edit_screen.dart';

import '../../../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

void main() {
  group('MessageEditScreen', () {
    testWidgets('用户消息只显示正文输入，保存返回编辑结果', (tester) async {
      final msg = ChatMessage(role: 'user', content: '原始内容');
      (String, String)? result;
      await tester.pumpWidget(
        wrapZh(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<(String, String)>(
                MaterialPageRoute(
                  builder: (_) => MessageEditScreen(message: msg),
                ),
              );
            },
            child: const Text('open'),
          ),
        )),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 用户消息：无「思考内容」输入框
      expect(find.text('消息内容'), findsOneWidget);
      expect(find.text('思考内容'), findsNothing);

      await tester.enterText(find.byType(TextField), '修改后的内容');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.$1, '修改后的内容');
      expect(result!.$2, '');
    });

    testWidgets('助手消息可编辑思考内容与回复内容', (tester) async {
      final msg = ChatMessage(
        role: 'assistant',
        content: '回复',
        reasoningContent: '思考',
      );
      (String, String)? result;
      await tester.pumpWidget(
        wrapZh(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<(String, String)>(
                MaterialPageRoute(
                  builder: (_) => MessageEditScreen(message: msg),
                ),
              );
            },
            child: const Text('open'),
          ),
        )),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('回复内容'), findsOneWidget);
      expect(find.text('思考内容'), findsOneWidget);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      await tester.enterText(
        find.widgetWithText(TextField, '修改模型生成时的思考过程…'),
        '新的思考',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(result!.$1, '回复');
      expect(result!.$2, '新的思考');
    });
  });
}

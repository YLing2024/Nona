import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/features/settings/screens/context_settings_screen.dart';

import '../../../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

void main() {
  group('ContextSettingsScreen', () {
    testWidgets('保存上下文参数并返回结果', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ContextSettingsResult? result;
      await tester.pumpWidget(
        wrapZh(Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<ContextSettingsResult>(
                MaterialPageRoute(
                  builder: (_) =>
                      const ContextSettingsScreen(initial: ChatOptions()),
                ),
              );
            },
            child: const Text('open'),
          ),
        )),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('会话上下文'), findsOneWidget);
      expect(find.text('系统提示词'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '可选，设定助手的角色与行为'),
        '你是我的助手',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.options.systemPrompt, '你是我的助手');
    });
  });
}

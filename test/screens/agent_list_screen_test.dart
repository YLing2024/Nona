import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/screens/agent_list_screen.dart';

import '../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

void main() {
  group('AgentListScreen', () {
    testWidgets('空态与新建入口', (tester) async {
      SharedPreferences.setMockInitialValues({
        'agents_initialized': true,
        'agents': '[]',
      });
      await tester.pumpWidget(wrapZh(const AgentListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('暂无 Agent，点右上角添加'), findsOneWidget);
    });

    testWidgets('已有 Agent 展示默认标记', (tester) async {
      SharedPreferences.setMockInitialValues({
        'agents_initialized': true,
        'agents':
            '[{"id":"a1","name":"测试Agent","isDefault":true,'
            '"options":{"systemPrompt":"你是助手"}}]',
      });
      await tester.pumpWidget(wrapZh(const AgentListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('测试Agent'), findsOneWidget);
      expect(find.text('默认'), findsOneWidget);
    });
  });
}

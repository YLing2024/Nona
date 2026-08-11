import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/models/agent.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/screens/agent_edit_screen.dart';

import '../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

void main() {
  group('AgentEditScreen', () {
    testWidgets('新建 Agent 必填名称校验', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        wrapZh(const AgentEditScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请填写 Agent 名称'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '翻译官');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      // 保存后返回上一页（pop）
      expect(find.text('新建 Agent'), findsNothing);
    });

    testWidgets('编辑已有 Agent 回填名称', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final agent = Agent(
        id: 'a1',
        name: '旧名称',
        options: const ChatOptions(systemPrompt: '你好'),
      );
      await tester.pumpWidget(
        wrapZh(AgentEditScreen(agent: agent)),
      );
      await tester.pumpAndSettle();
      expect(find.text('旧名称'), findsOneWidget);
      expect(find.text('编辑 Agent'), findsOneWidget);
    });
  });
}

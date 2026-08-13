import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/shared/widgets/add_model_dialog.dart';

import '../../../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

void main() {
  group('AddModelDialog', () {
    testWidgets('未填 API Key 时点获取模型提示', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        wrapZh(Scaffold(
          body: AddModelDialog(
            baseUrl: 'https://x/v1',
            apiKey: '',
            existing: <String>{},
          ),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('添加模型'), findsOneWidget);
      // 切换到「从列表获取」分段
      await tester.tap(find.text('从列表获取'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('获取模型列表'));
      await tester.pumpAndSettle();
      expect(find.text('请先填写 API Key'), findsOneWidget);
    });
  });
}

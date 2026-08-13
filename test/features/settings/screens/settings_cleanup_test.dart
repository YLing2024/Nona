import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/features/settings/screens/about_screen.dart';
import 'package:nona_chat/features/model/screens/model_config_screen.dart';
import 'package:nona_chat/features/settings/screens/settings_screen.dart';
import 'package:nona_chat/version.dart';

import '../../../support/app_test_wrapper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(wrapApp(screen));
    await tester.pumpAndSettle();
  }

  group('设置页清理', () {
    testWidgets('偏好设置 subtitle 随 Enter 偏好更新', (tester) async {
      SharedPreferences.setMockInitialValues({'send_on_enter': true});
      // 大视口使全部入口可见（避免嵌套 Scrollable 的滚动问题）
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpScreen(tester, const SettingsScreen());
      expect(
        find.text('Enter 发送，Shift+Enter 换行'),
        findsOneWidget,
        reason: '开启 Enter 发送时展示对应说明',
      );
      expect(find.textContaining('浅色主题'), findsNothing,
          reason: '过时的主题相关文案已移除');
    });

    testWidgets('模型配置 subtitle 展示聊天/标题生成模型', (tester) async {
      await pumpScreen(tester, const SettingsScreen());
      expect(find.text('聊天默认模型 · 标题生成模型'), findsOneWidget);
    });

    testWidgets('模型配置页不再有过期占位提示', (tester) async {
      await pumpScreen(tester, const ModelConfigScreen());
      expect(find.textContaining('后续版本中扩展到'), findsNothing);
      expect(find.text('聊天模型'), findsOneWidget);
      expect(find.text('标题生成模型'), findsOneWidget);
    });

    testWidgets('关于页展示当前版本号', (tester) async {
      await pumpScreen(tester, const AboutScreen());
      expect(find.text(kAppVersion), findsOneWidget);
    });

    test('kAppVersion 与 pubspec.yaml 的 version 字段一致', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^version:\s*(.+)$',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml 应包含 version 字段');
      expect(kAppVersion, match!.group(1)!.trim());
    });
  });
}

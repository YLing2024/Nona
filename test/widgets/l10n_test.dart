import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/l10n/app_localizations.dart';
import 'package:nona_chat/main.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/screens/preferences_screen.dart';
import 'package:nona_chat/services/settings_service.dart';
import 'package:nona_chat/widgets/chat_composer.dart';

import '../support/app_test_wrapper.dart';

Widget wrapZh(Widget child) => wrapApp(child);

Widget wrapEn(Widget child) => wrapApp(child, locale: const Locale('en'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('本地化资源', () {
    test('zh 与 en 键数量一致（通过 AppLocalizations 编译期保证）', () {
      final zh = lookupAppLocalizations(const Locale('zh'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(zh.commonSave, '保存');
      expect(en.commonSave, 'Save');
      expect(en.chatNewSession, 'New chat');
      expect(zh.chatNewSession, '新建会话');
    });

    test('localeFromSetting 映射正确', () {
      expect(localeFromSetting('zh'), const Locale('zh'));
      expect(localeFromSetting('en'), const Locale('en'));
      expect(localeFromSetting('system'), isNull);
      expect(localeFromSetting('未知'), isNull);
    });
  });

  group('英文界面冒烟', () {
    testWidgets('en locale 下聊天输入区显示英文提示', (tester) async {
      await tester.pumpWidget(
        wrapEn(
          Scaffold(
            body: ChatComposer(
              controller: TextEditingController(),
              providers: const [],
              providerId: null,
              modelId: null,
              options: const ChatOptions(),
              isLoading: false,
              estimatedTokens: 0,
              usagePrompt: 0,
              usageCompletion: 0,
              onModelChanged: (_, __) {},
              onEffortChanged: (_) {},
              onStreamChanged: (_) {},
              onSend: () {},
              onStop: () {},
              sendOnEnter: true,
              pendingImages: const [],
              onPickImages: () {},
              onAddImageUrl: (_) {},
              onRemoveImage: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('Type a message, Enter to send, Shift+Enter for newline'),
        findsOneWidget,
      );
    });

    testWidgets('zh locale 下输入区提示为中文', (tester) async {
      await tester.pumpWidget(
        wrapZh(
          Scaffold(
            body: ChatComposer(
              controller: TextEditingController(),
              providers: const [],
              providerId: null,
              modelId: null,
              options: const ChatOptions(),
              isLoading: false,
              estimatedTokens: 0,
              usagePrompt: 0,
              usageCompletion: 0,
              onModelChanged: (_, __) {},
              onEffortChanged: (_) {},
              onStreamChanged: (_) {},
              onSend: () {},
              onStop: () {},
              sendOnEnter: true,
              pendingImages: const [],
              onPickImages: () {},
              onAddImageUrl: (_) {},
              onRemoveImage: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('输入消息，Enter 发送，Shift+Enter 换行'),
        findsOneWidget,
      );
    });
  });

  group('语言切换', () {
    testWidgets('偏好设置切换语言后 localeNotifier 更新并持久化', (tester) async {
      SharedPreferences.setMockInitialValues({});
      localeNotifier.value = null;
      await tester.pumpWidget(
        wrapZh(const PreferencesScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.expand_more).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(localeNotifier.value, const Locale('en'));
      final settings = await SettingsService().load();
      expect(settings.locale, 'en');
    });
  });
}

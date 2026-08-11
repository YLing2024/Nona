import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/l10n/app_localizations.dart';
import 'package:nona_chat/services/theme_controller.dart';

import '../support/reset_globals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetGlobalState();
  });

  group('ThemeController', () {
    test('themeModeFromStr / themeModeToStr 互逆', () {
      expect(themeModeFromStr('light'), ThemeMode.light);
      expect(themeModeFromStr('dark'), ThemeMode.dark);
      expect(themeModeFromStr('system'), ThemeMode.system);
      expect(themeModeFromStr('未知'), ThemeMode.system);
      expect(themeModeToStr(ThemeMode.light), 'light');
      expect(themeModeToStr(ThemeMode.dark), 'dark');
      expect(themeModeToStr(ThemeMode.system), 'system');
    });

    test('themeModeLabel 中文展示', () {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      expect(themeModeLabel('light', l10n), '浅色');
      expect(themeModeLabel('dark', l10n), '深色');
      expect(themeModeLabel('system', l10n), '跟随系统');
    });

    test('预设强调色名称唯一且含默认色', () {
      final names = AppAccentPreset.presets.map((p) => p.$1).toSet();
      expect(names.length, AppAccentPreset.presets.length);
      expect(
        AppAccentPreset.presetName(AppAccentPreset.defaultColor),
        isNotNull,
      );
    });
  });
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 全局主题模式通知器，设置页修改后驱动 MaterialApp 切换主题。
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

/// 全局主题强调色（seed）通知器，修改后重建主题。
final ValueNotifier<Color> accentColorNotifier = ValueNotifier(
  AppAccentPreset.defaultColor,
);

/// 深色模式是否使用 OLED 纯黑背景。
final ValueNotifier<bool> oledDarkNotifier = ValueNotifier(false);

ThemeMode themeModeFromStr(String value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

String themeModeToStr(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  _ => 'system',
};

/// 主题模式展示名（跟随当前语言）。
String themeModeLabel(String value, AppLocalizations l10n) => switch (value) {
  'light' => l10n.themeModeLight,
  'dark' => l10n.themeModeDark,
  _ => l10n.themeModeSystem,
};

/// 内置主题强调色预设（品牌靛蓝为默认）。
class AppAccentPreset {
  static const Color defaultColor = Color(0xFF4F46E5);

  /// 预设色板：名称 + 颜色。
  static const List<(String, Color)> presets = [
    ('indigo', Color(0xFF4F46E5)),
    ('violet', Color(0xFF8B5CF6)),
    ('sky', Color(0xFF0EA5E9)),
    ('teal', Color(0xFF10B981)),
    ('orange', Color(0xFFF59E0B)),
    ('rose', Color(0xFFEC4899)),
    ('red', Color(0xFFEF4444)),
    ('slate', Color(0xFF64748B)),
  ];

  /// 预设的本地化名称（fallback 为中文名）。
  static String presetLabel(String name, AppLocalizations l10n) => switch (name) {
    'indigo' => l10n.accentIndigo,
    'violet' => l10n.accentViolet,
    'sky' => l10n.accentSky,
    'teal' => l10n.accentTeal,
    'orange' => l10n.accentOrange,
    'rose' => l10n.accentRose,
    'red' => l10n.accentRed,
    'slate' => l10n.accentSlate,
    _ => name,
  };

  /// 取预设名称；非预设色返回 null（用于自定义色展示）。
  static String? presetName(Color color) {
    for (final (name, c) in presets) {
      if (c.toARGB32() == color.toARGB32()) return name;
    }
    return null;
  }
}

import 'package:flutter/material.dart';

/// 全局主题模式通知器，设置页修改后驱动 MaterialApp 切换主题。
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

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

String themeModeLabel(String value) => switch (value) {
  'light' => '浅色',
  'dark' => '深色',
  _ => '跟随系统',
};

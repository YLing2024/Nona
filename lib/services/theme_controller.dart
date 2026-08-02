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

ThemeData buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  );
}

/// 深色模式：OLED 屏幕纯黑背景（surface 与页面背景均为 #000000）。
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ).copyWith(surface: Colors.black);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.black,
  );
}

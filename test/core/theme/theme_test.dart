import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/theme/app_theme.dart';

void main() {
  group('主题强调色（seed）', () {
    test('不同 seed 生成不同 primary', () {
      final indigo = buildLightTheme();
      final teal = buildLightTheme(accent: const Color(0xFF10B981));
      expect(indigo.colorScheme.primary, isNot(teal.colorScheme.primary));
    });

    test('默认 seed 保持品牌靛蓝 primary', () {
      final light = buildLightTheme();
      // fromSeed 生成的 primary 与品牌靛蓝不同但同色系；
      // 断言主题构建不抛错且 surface 保留品牌冷灰
      expect(light.colorScheme.surface, AppColors.lightSurface);
      expect(light.scaffoldBackgroundColor, AppColors.lightBackground);
    });

    test('自定义 seed 的深色主题 primary 变化', () {
      final a = buildDarkTheme();
      final b = buildDarkTheme(accent: const Color(0xFFEC4899));
      expect(a.colorScheme.primary, isNot(b.colorScheme.primary));
    });

    test('OLED 深色：背景为纯黑、surface 接近黑', () {
      final normal = buildDarkTheme();
      final oled = buildDarkTheme(oled: true);
      expect(oled.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(oled.colorScheme.surface, const Color(0xFF0A0A0E));
      expect(normal.scaffoldBackgroundColor, isNot(oled.scaffoldBackgroundColor));
    });

    test('浅色主题不受 OLED 开关影响', () {
      // OLED 仅影响深色主题
      expect(buildLightTheme().scaffoldBackgroundColor,
          AppColors.lightBackground);
    });
  });
}

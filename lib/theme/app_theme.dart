import 'package:flutter/material.dart';

/// Nona 设计系统 —— 冷调靛蓝紫·科技感。
///
/// 设计要点：
/// - 主色靛蓝 + 辅色紫罗兰，双主题均以此为签名色
/// - 浅色：冷灰白底 (#F6F7FB) + 纯白 surface，低饱和阴影
/// - 深色：蓝黑底 (#0B0D12) 而非纯黑，surface 略亮一档
/// - 统一圆角：卡片 20 / 输入 14 / 按钮 12 / 对话框 24
abstract final class AppColors {
  // ---- 品牌色 ----
  static const Color primary = Color(0xFF4F46E5); // 靛蓝
  static const Color secondary = Color(0xFF8B5CF6); // 紫罗兰
  static const Color tertiary = Color(0xFF0EA5E9); // 天蓝（点缀）
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  // ---- 浅色 ----
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceDim = Color(0xFFEEF0F7);
  static const Color lightOutline = Color(0xFFE4E6EF);

  // ---- 深色 ----
  static const Color darkBackground = Color(0xFF0B0D12);
  static const Color darkSurface = Color(0xFF14161E);
  static const Color darkSurfaceDim = Color(0xFF1A1D27);
  static const Color darkOutline = Color(0xFF262A38);
}

/// 品牌渐变：助手头像 / 高亮点缀。
final LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: const [AppColors.primary, AppColors.secondary],
);

final List<BoxShadow> kSoftShadow = [
  BoxShadow(
    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

final List<BoxShadow> kCardShadowLight = [
  BoxShadow(
    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];

final List<BoxShadow> kCardShadowDark = [
  BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: 0.35),
    blurRadius: 20,
    offset: const Offset(0, 6),
  ),
];

ThemeData buildLightTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark
      ? ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          onPrimary: const Color(0xFF141228),
          primaryContainer: const Color(0xFF312E81),
          onPrimaryContainer: const Color(0xFFC7D2FE),
          secondary: const Color(0xFFA78BFA),
          onSecondary: const Color(0xFF1E1B33),
          secondaryContainer: const Color(0xFF4C1D95),
          onSecondaryContainer: const Color(0xFFDDD6FE),
          tertiary: const Color(0xFF38BDF8),
          onTertiary: const Color(0xFF082F49),
          tertiaryContainer: const Color(0xFF075985),
          onTertiaryContainer: const Color(0xFFBAE6FD),
          error: const Color(0xFFF87171),
          onError: const Color(0xFF2B0A0A),
          errorContainer: const Color(0xFF7F1D1D),
          onErrorContainer: const Color(0xFFFECACA),
          surface: AppColors.darkSurface,
          onSurface: const Color(0xFFE6E8F0),
          surfaceDim: AppColors.darkSurfaceDim,
          surfaceBright: const Color(0xFF1E212B),
          surfaceContainerLowest: const Color(0xFF0B0D12),
          surfaceContainerLow: const Color(0xFF12141C),
          surfaceContainer: const Color(0xFF161922),
          surfaceContainerHigh: const Color(0xFF1A1D27),
          surfaceContainerHighest: const Color(0xFF20242F),
          onSurfaceVariant: const Color(0xFFA7ADBF),
          outline: const Color(0xFF4A4F61),
          outlineVariant: AppColors.darkOutline,
          shadow: const Color(0xFF000000),
          scrim: const Color(0xFF000000),
          inverseSurface: const Color(0xFFE6E8F0),
          onInverseSurface: const Color(0xFF14161E),
          inversePrimary: const Color(0xFF4F46E5),
        )
      : ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE0E7FF),
          onPrimaryContainer: const Color(0xFF312E81),
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFEDE9FE),
          onSecondaryContainer: const Color(0xFF4C1D95),
          tertiary: const Color(0xFF0284C7),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFBAE6FD),
          onTertiaryContainer: const Color(0xFF0C4A6E),
          error: const Color(0xFFDC2626),
          onError: Colors.white,
          errorContainer: const Color(0xFFFEE2E2),
          onErrorContainer: const Color(0xFF7F1D1D),
          surface: AppColors.lightSurface,
          onSurface: const Color(0xFF17181F),
          surfaceDim: const Color(0xFFE8EAF2),
          surfaceBright: AppColors.lightSurface,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF8F9FD),
          surfaceContainer: const Color(0xFFF3F4FA),
          surfaceContainerHigh: const Color(0xFFEDEFF6),
          surfaceContainerHighest: const Color(0xFFE7E9F2),
          onSurfaceVariant: const Color(0xFF5A5F6E),
          outline: const Color(0xFF9BA1B0),
          outlineVariant: AppColors.lightOutline,
          shadow: const Color(0xFF0F172A),
          scrim: const Color(0xFF000000),
          inverseSurface: const Color(0xFF262A38),
          onInverseSurface: const Color(0xFFEDEFF6),
          inversePrimary: const Color(0xFFC7D2FE),
        );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
  );

  final inputRadius = BorderRadius.circular(14);

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(color: scheme.outline, fontSize: 14),
      labelStyle: TextStyle(color: scheme.outline, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
      prefixIconColor: scheme.outline,
      suffixIconColor: scheme.outline,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF262A38) : const Color(0xFF23253A),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outlineVariant,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: BorderSide(color: scheme.outline),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
    ),
    dividerColor: scheme.outlineVariant,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: const FadeForwardsPageTransitionsBuilder(),
      },
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262A38) : const Color(0xFF23253A),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 400),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        elevation: const WidgetStatePropertyAll(6),
      ),
    ),
  );
}

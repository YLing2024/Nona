import 'package:flutter/material.dart';

/// Nona 设计系统 —— 冷调靛蓝紫·科技感。
///
/// 设计要点：
/// - 强调色默认靛蓝，可由用户自定义（seed 驱动 M3 色板）
/// - 浅色：冷灰白底 (#F6F7FB) + 纯白 surface，低饱和阴影
/// - 深色：蓝黑底 (#0B0D12) 而非纯黑，surface 略亮一档；OLED 模式为纯黑
/// - 统一圆角：卡片 20 / 输入 14 / 按钮 12 / 对话框 24
abstract final class AppColors {
  // ---- 品牌色 ----
  static const Color primary = Color(0xFF4F46E5); // 靛蓝
  static const Color secondary = Color(0xFF8B5CF6); // 紫罗兰
  static const Color tertiary = Color(0xFF0EA5E9); // 天蓝（点缀）
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  // ---- 语义色 ----
  /// 状态成功色（网络日志等；与 [success] 同值）。
  static const Color statusSuccess = success;

  /// 状态警告色（网络日志等）。
  static const Color statusWarn = Color(0xFFF59E0B);

  /// 头像品牌色渲染（带透明度的靛蓝）。
  static const Color avatarTint = Color(0x334F46E5);

  /// 代码块背景（浅色）。
  static const Color codeBlockBgLight = Color(0xFFF4F5FA);

  /// 代码块背景（深色）。
  static const Color codeBlockBgDark = Color(0xFF0F1220);

  // ---- 浅色 ----
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceDim = Color(0xFFE8EAF2);
  static const Color lightSurfaceContainerLow = Color(0xFFF8F9FD);
  static const Color lightSurfaceContainer = Color(0xFFF3F4FA);
  static const Color lightSurfaceContainerHigh = Color(0xFFEDEFF6);
  static const Color lightSurfaceContainerHighest = Color(0xFFE7E9F2);
  static const Color lightOutline = Color(0xFFE4E6EF);
  static const Color lightOutlineStrong = Color(0xFF9BA1B0);
  static const Color lightOnSurface = Color(0xFF17181F);
  static const Color lightOnSurfaceVariant = Color(0xFF5A5F6E);

  // ---- 深色 ----
  static const Color darkBackground = Color(0xFF0B0D12);
  static const Color darkSurface = Color(0xFF14161E);
  static const Color darkSurfaceDim = Color(0xFF1A1D27);
  static const Color darkSurfaceContainerLow = Color(0xFF12141C);
  static const Color darkSurfaceContainer = Color(0xFF161922);
  static const Color darkSurfaceContainerHighest = Color(0xFF20242F);
  static const Color darkSurfaceBright = Color(0xFF1E212B);
  static const Color darkOutline = Color(0xFF262A38);
  static const Color darkOutlineStrong = Color(0xFF4A4F61);
  static const Color darkOnSurface = Color(0xFFE6E8F0);
  static const Color darkOnSurfaceVariant = Color(0xFFA7ADBF);

  // ---- OLED（深色纯黑变体）----
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0A0A0E);
  static const Color oledSurfaceDim = Color(0xFF0D0D12);
  static const Color oledSurfaceContainerLow = Color(0xFF0F0F15);
  static const Color oledSurfaceContainer = Color(0xFF131319);
  static const Color oledSurfaceContainerHigh = Color(0xFF17171E);
  static const Color oledSurfaceContainerHighest = Color(0xFF1C1C24);
  static const Color oledSurfaceBright = Color(0xFF18181F);
  static const Color oledOutlineVariant = Color(0xFF1E1E26);

  // ---- 阴影 ----
  static const Color shadowLight = Color(0xFF0F172A);
  static const Color shadowDark = Colors.black;
}

/// 品牌渐变：助手头像 / 高亮点缀。
final LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: const [AppColors.primary, AppColors.secondary],
);

final List<BoxShadow> kSoftShadow = [
  BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

final List<BoxShadow> kCardShadowLight = [
  BoxShadow(
    color: AppColors.shadowLight.withValues(alpha: 0.05),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];

final List<BoxShadow> kCardShadowDark = [
  BoxShadow(
    color: AppColors.shadowDark.withValues(alpha: 0.35),
    blurRadius: 20,
    offset: const Offset(0, 6),
  ),
];

/// 构建浅色主题；[accent] 为强调色 seed（null 使用品牌靛蓝）。
///
/// H-02/H-03：[fontFamily] 自定义界面字体（null=系统）；[density]
/// 界面密度（compact 更紧凑，comfortable 更宽松）；[chatFontScale]
/// 聊天字号倍率。
ThemeData buildLightTheme({
  Color? accent,
  String? fontFamily,
  String density = 'standard',
  double chatFontScale = 1.0,
}) => _buildTheme(
      Brightness.light,
      accent,
      fontFamily: fontFamily,
      density: density,
      chatFontScale: chatFontScale,
    );

/// 构建深色主题；[accent] 为强调色 seed；[oled] 时背景使用纯黑。
ThemeData buildDarkTheme({
  Color? accent,
  bool oled = false,
  String? fontFamily,
  String density = 'standard',
  double chatFontScale = 1.0,
}) => _buildTheme(
      Brightness.dark,
      accent,
      oled: oled,
      fontFamily: fontFamily,
      density: density,
      chatFontScale: chatFontScale,
    );

ThemeData _buildTheme(
  Brightness brightness,
  Color? accent, {
  bool oled = false,
  String? fontFamily,
  String density = 'standard',
  double chatFontScale = 1.0,
}) {
  final isDark = brightness == Brightness.dark;
  final seed = accent ?? AppColors.primary;

  // H-03：密度 → visualDensity / 间距缩放
  final visualDensity = switch (density) {
    'compact' => VisualDensity.compact,
    'comfortable' => VisualDensity.comfortable,
    _ => VisualDensity.standard,
  };

  // 基于 seed 的 M3 色板；表面/背景保留品牌冷灰色系（OLED 时深色用纯黑）
  final seedScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  final bg = isDark
      ? (oled ? AppColors.oledBackground : AppColors.darkBackground)
      : AppColors.lightBackground;
  final surface = isDark
      ? (oled ? AppColors.oledSurface : AppColors.darkSurface)
      : AppColors.lightSurface;
  final surfaceDim = isDark
      ? (oled ? AppColors.oledSurfaceDim : AppColors.darkSurfaceDim)
      : AppColors.lightSurfaceDim;
  final surfaceContainerLowest = isDark
      ? (oled ? AppColors.oledBackground : AppColors.darkBackground)
      : Colors.white;
  final surfaceContainerLow = isDark
      ? (oled
            ? AppColors.oledSurfaceContainerLow
            : AppColors.darkSurfaceContainerLow)
      : AppColors.lightSurfaceContainerLow;
  final surfaceContainer = isDark
      ? (oled
            ? AppColors.oledSurfaceContainer
            : AppColors.darkSurfaceContainer)
      : AppColors.lightSurfaceContainer;
  final surfaceContainerHigh = isDark
      ? (oled
            ? AppColors.oledSurfaceContainerHigh
            : AppColors.darkSurfaceDim)
      : AppColors.lightSurfaceContainerHigh;
  final surfaceContainerHighest = isDark
      ? (oled
            ? AppColors.oledSurfaceContainerHighest
            : AppColors.darkSurfaceContainerHighest)
      : AppColors.lightSurfaceContainerHighest;
  final outline = isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
  final outlineVariant = isDark
      ? (oled ? AppColors.oledOutlineVariant : AppColors.darkOutline)
      : AppColors.lightOutline;

  final scheme = seedScheme.copyWith(
    brightness: brightness,
    surface: surface,
    surfaceDim: surfaceDim,
    surfaceBright: isDark
        ? (oled ? AppColors.oledSurfaceBright : AppColors.darkSurfaceBright)
        : AppColors.lightSurface,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurface:
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
    onSurfaceVariant: isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: isDark ? AppColors.shadowDark : AppColors.shadowLight,
    scrim: Colors.black,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    // H-02/H-03：字体与密度
    fontFamily: fontFamily,
    visualDensity: visualDensity,
  );

  final inputRadius = BorderRadius.circular(14);

  // H-03：聊天字号倍率（仅放大，不缩小）
  final chatScale = chatFontScale < 1.0 ? 1.0 : chatFontScale;

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // 聊天正文/消息字号随倍率
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14 * chatScale,
      ),
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
      backgroundColor: surfaceContainerHighest,
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
        color: surfaceContainerHighest,
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

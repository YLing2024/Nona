import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/app_scope.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/knowledge_base_service.dart';
import 'services/memory/memory_service.dart';
import 'services/model_capability_service.dart';
import 'services/network_log_service.dart';
import 'services/settings_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';
import 'utils/token_estimator.dart';

/// 全局界面语言通知器（设置页修改后驱动 MaterialApp 刷新）。
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

Future<void> main() async {
  // 全局错误边界：未捕获异常记录日志、不崩溃进程
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Logger.error(
      'flutter_error',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (e, s) {
    Logger.error('platform_error', e.toString(), e, s);
    return true; // 已处理：不崩溃
  };
  // 错误卡片兜底：替换默认红屏
  ErrorWidget.builder = (details) => _ErrorCard(details: details);

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env', isOptional: true);
    final settings = await SettingsService().load();
    themeModeNotifier.value = themeModeFromStr(settings.themeMode);
    accentColorNotifier.value = Color(settings.accentColor == 0
        ? AppAccentPreset.defaultColor.toARGB32()
        : settings.accentColor);
    oledDarkNotifier.value = settings.oledDark;
    localeNotifier.value = localeFromSetting(settings.locale);
    NetworkLogService.instance.setEnabled(settings.networkLogEnabled);
    NetworkLogService.instance.setMaxLogs(settings.networkLogMaxLogs);
    // 恢复持久化的网络日志（与记录开关无关）
    await NetworkLogService.instance.init();
    // 预加载 tiktoken 词表（失败静默，估算回退启发式）
    unawaited(TokenEstimator.instance.load());
    // 旧版知识库 prefs 数据一次性迁移（成功即删键，幂等）
    unawaited(KnowledgeBaseService().migrateLegacy());
    // 旧版记忆 v1（Agent.memories prefs）一次性迁移进 memories 表（幂等）
    unawaited(MemoryService().migrateV1Memories());
    // 开发者选项开启「启动时自动更新」时，静默更新模型能力映射表，失败不影响启动
    unawaited(_maybeAutoUpdateCapabilities(settings));
    runApp(const AiChatApp());
  }, (e, s) {
    Logger.error('zone_error', e.toString(), e, s);
  });
}

/// 兜底错误卡片：显示错误信息并提供「复制」按钮（替换默认红屏）。
class _ErrorCard extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorCard({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF101014),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: details.exceptionAsString()),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制错误信息'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 语言设置值 → Locale：system 表示跟随系统（null）。
Locale? localeFromSetting(String value) => switch (value) {
  'zh' => const Locale('zh'),
  'en' => const Locale('en'),
  _ => null,
};

/// 按设置静默更新模型能力映射表；异常仅吞掉，不阻塞启动。
Future<void> _maybeAutoUpdateCapabilities(AppSettings settings) async {
  if (!settings.autoUpdateModelCapabilities) return;
  try {
    await ModelCapabilityService().updateFromNetwork();
  } catch (_) {
    // 联网失败时保留现有映射表
  }
}

class AiChatApp extends StatelessWidget {
  const AiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // DI 根在 MaterialApp 之上：Navigator 推出的所有路由共享服务单例
    return AppScope(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return ValueListenableBuilder<Color>(
            valueListenable: accentColorNotifier,
            builder: (context, accent, _) {
              // 动态主题色（Android 12+ / iOS）：未自定义强调色时跟随系统取色
              return DynamicColorBuilder(
                builder: (lightDynamic, darkDynamic) {
                  final isDefaultAccent =
                      accent.toARGB32() ==
                      AppAccentPreset.defaultColor.toARGB32();
                  return ValueListenableBuilder<bool>(
                    valueListenable: oledDarkNotifier,
                    builder: (context, oled, _) {
                      return ValueListenableBuilder<Locale?>(
                        valueListenable: localeNotifier,
                        builder: (context, locale, _) {
                          return MaterialApp(
                            title: 'Nona',
                            theme: buildLightTheme(
                              accent: isDefaultAccent
                                  ? (lightDynamic?.primary ?? accent)
                                  : accent,
                            ),
                            darkTheme: buildDarkTheme(
                              accent: isDefaultAccent
                                  ? (darkDynamic?.primary ?? accent)
                                  : accent,
                              oled: oled,
                            ),
                            themeMode: mode,
                            locale: locale,
                            supportedLocales:
                                AppLocalizations.supportedLocales,
                            localizationsDelegates: [
                              ...AppLocalizations.localizationsDelegates,
                              GlobalMaterialLocalizations.delegate,
                              GlobalWidgetsLocalizations.delegate,
                              GlobalCupertinoLocalizations.delegate,
                            ],
                            home: const HomeScreen(),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

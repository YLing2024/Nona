import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/app_scope.dart';
import 'core/services/app_exit_flush.dart';
import 'core/services/checkpoint_service.dart';
import 'core/services/knowledge_base_service.dart';
import 'core/services/model_capability_service.dart';
import 'core/services/network_log_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/theme_controller.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/utils/token_estimator.dart';
import 'features/chat/screens/home_screen.dart';
import 'features/desktop/desktop_shell.dart';
import 'features/automation/workflow_service.dart';
import 'features/settings/widgets/update_dialog.dart';
import 'l10n/app_localizations.dart';

/// 全局界面语言通知器（设置页修改后驱动 MaterialApp 刷新）。
final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

/// 根导航 key（J-02 更新对话框等启动期全局对话框使用）。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // J-01：崩溃上报初始化（设置开关控制；默认关闭，隐私友好）。
  // DSN 由 .env 注入（SENTRY_DSN），未配置时上报自动失效。
  final prefs = await SharedPreferences.getInstance();
  final crashEnabled = prefs.getBool('crash_reporting_enabled') ?? false;
  const dsn = String.fromEnvironment('SENTRY_DSN');
  if (crashEnabled && dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0;
        options.environment = kReleaseMode ? 'release' : 'debug';
        options.beforeSend = (event, hint) => _stripSecrets(event);
      },
    );
  }
  // 全局错误边界：未捕获异常记录日志、不崩溃进程
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Logger.error(
      'flutter_error',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    if (crashEnabled) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    }
  };
  PlatformDispatcher.instance.onError = (e, s) {
    Logger.error('platform_error', e.toString(), e, s);
    if (crashEnabled) {
      Sentry.captureException(e, stackTrace: s);
    }
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
    // B-06：启动恢复——遗留 streaming 消息回填已存内容并置 failed（可重试）
    unawaited(CheckpointService().recover());
    // A-03：桌面基座（窗口/托盘/热键；非桌面平台 no-op）
    unawaited(DesktopShell.instance.init());
    // X-01：自动化工作流调度（分钟级 tick + 事件订阅）
    WorkflowService().start();
    // B-06/A-03：退出前冲刷注册（checkpoint barrier + 网络日志落盘）
    AppExitFlush.instance.register(() async {
      await CheckpointService().barrier();
      await NetworkLogService.instance.flush();
    });
    // 开发者选项开启「启动时自动更新」时，静默更新模型能力映射表，失败不影响启动
    unawaited(_maybeAutoUpdateCapabilities(settings));
    // J-02：启动时检查更新（设置开启时；静默，不阻塞启动）
    if (settings.checkUpdatesOnStart) {
      unawaited(_checkUpdateSilently(settings));
    }
    runApp(const AiChatApp());
  }, (e, s) {
    Logger.error('zone_error', e.toString(), e, s);
  });
}

/// J-02：启动更新检查——有新版则弹对话框（首帧后，避免阻塞首屏）。
Future<void> _checkUpdateSilently(AppSettings settings) async {
  try {
    final release = await UpdateService().checkForUpdate(settings: settings);
    if (release == null) return;
    await WidgetsBinding.instance.endOfFrame;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await showUpdateDialog(ctx, release);
    }
  } catch (_) {
    // 静默失败
  }
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

/// J-01：上报前脱敏——剥离常见密钥字段（contexts/request）。
SentryEvent _stripSecrets(SentryEvent event) {
  const secretKeys = {
    'apikey',
    'api_key',
    'password',
    'token',
    'authorization',
    'secret',
  };
  for (final entry in event.contexts.entries) {
    _stripMap(entry.value, secretKeys);
  }
  final request = event.request;
  if (request != null) {
    _stripMap(request.headers, secretKeys);
    if (request.data != null && request.data is Map) {
      _stripMap((request.data as Map).cast<String, dynamic>(), secretKeys);
    }
  }
  return event;
}

void _stripMap(Map<String, dynamic> map, Set<String> keys) {
  map.removeWhere((k, v) => keys.contains(k.toLowerCase()));
}

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
                            navigatorKey: rootNavigatorKey,
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

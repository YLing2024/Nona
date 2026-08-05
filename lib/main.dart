import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/model_capability_service.dart';
import 'services/network_log_service.dart';
import 'services/settings_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final settings = await SettingsService().load();
  themeModeNotifier.value = themeModeFromStr(settings.themeMode);
  NetworkLogService.instance.setEnabled(settings.networkLogEnabled);
  NetworkLogService.instance.setMaxLogs(settings.networkLogMaxLogs);
  // 恢复持久化的网络日志（与记录开关无关）
  await NetworkLogService.instance.init();
  // 开发者选项开启「启动时自动更新」时，静默更新模型能力映射表，失败不影响启动
  unawaited(_maybeAutoUpdateCapabilities(settings));
  runApp(const AiChatApp());
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Nona',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          // 中文项目：系统组件（文本选择菜单/复制粘贴等）使用中文
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}

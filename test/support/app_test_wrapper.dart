import 'package:flutter/material.dart';

import 'package:nona_chat/di/app_scope.dart';
import 'package:nona_chat/l10n/app_localizations.dart';

/// 测试用应用包装：MaterialApp + l10n + DI 根（[AppScope]）。
///
/// 需要注入 fake 服务时，在 [child] 外再套一层 `Provider<X>.value`
/// 覆盖即可（Provider 就近解析优先于 AppScope 根）。
Widget wrapApp(Widget child, {Locale? locale}) {
  final loc = locale ?? const Locale('zh');
  return AppScope(
    child: MaterialApp(
      locale: loc,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

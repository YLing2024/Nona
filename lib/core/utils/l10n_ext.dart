import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../models/network_log.dart';

/// BuildContext 便捷访问本地化文案。
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 网络日志类型的本地化展示文案。
extension NetworkLogTypeL10n on NetworkLogType {
  String labelOf(AppLocalizations l10n) {
    switch (this) {
      case NetworkLogType.chat:
        return l10n.networkLogTypeChat;
      case NetworkLogType.test:
        return l10n.networkLogTypeTest;
      case NetworkLogType.models:
        return l10n.networkLogTypeModels;
      case NetworkLogType.capability:
        return l10n.networkLogTypeCapability;
      case NetworkLogType.other:
        return l10n.networkLogTypeOther;
    }
  }
}

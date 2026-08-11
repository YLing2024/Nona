import 'package:flutter/material.dart';

import 'package:nona_chat/services/network_log_service.dart';
import 'package:nona_chat/services/theme_controller.dart';
import 'package:nona_chat/utils/logger.dart';
import 'package:nona_chat/utils/token_estimator.dart';

/// 测试全局状态复位：随机顺序跑用例时避免跨测试污染。
void resetGlobalState() {
  themeModeNotifier.value = ThemeMode.system;
  accentColorNotifier.value = AppAccentPreset.defaultColor;
  oledDarkNotifier.value = false;
  NetworkLogService.instance.setEnabled(false);
  NetworkLogService.instance.setMaxLogs(1000);
  TokenEstimator.instance.resetCache();
  Logger.setEnabled(true);
}

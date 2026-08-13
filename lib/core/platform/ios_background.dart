import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// I-05：iOS 后台生成——BGTask + 完成通知（原生侧 MethodChannel）。
///
/// 系统限制：iOS 后台最长约 30 秒；完成后发本地通知提示。
class IosBackgroundGeneration {
  IosBackgroundGeneration._();

  static const MethodChannel _channel = MethodChannel(
    'app.ios_background_generation',
  );

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool _enabled = false;

  /// 开启后台生成窗口（切后台时由原生侧调度）。
  static Future<void> enable() async {
    if (!supported || _enabled) return;
    _enabled = true;
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }

  /// 更新后台进度（latest-wins 节流，原生侧实现）。
  static Future<void> scheduleUpdate({
    required String content,
    required bool finished,
    bool cancelled = false,
  }) async {
    if (!supported || !_enabled) return;
    try {
      await _channel.invokeMethod(
        'scheduleUpdate',
        {
          'content': content,
          'finished': finished,
          'cancelled': cancelled,
        },
      );
    } catch (_) {}
  }

  /// 结束后台窗口。
  static Future<void> finish() async {
    if (!supported || !_enabled) return;
    _enabled = false;
    try {
      await _channel.invokeMethod('finish');
    } catch (_) {}
  }
}

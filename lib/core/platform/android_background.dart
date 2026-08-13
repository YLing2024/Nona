import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';

/// I-01：Android 后台生成——前台服务保活 + 完成通知。
///
/// 模式：
/// - off：关闭（默认）
/// - on：开启（退后台/锁屏保持生成）
/// - onNotify：开启并在完成时发通知
class AndroidBackground {
  AndroidBackground._();

  static const _config = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Nona',
    notificationText: '后台生成中…',
    notificationImportance: AndroidNotificationImportance.normal,
  );

  static bool _initialized = false;

  /// 是否支持（仅 Android）。
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 启用前台服务（幂等）。
  static Future<bool> enable() async {
    if (!supported) return false;
    try {
      if (!_initialized) {
        final ok = await FlutterBackground.initialize(
          androidConfig: _config,
        );
        if (!ok) return false;
        _initialized = true;
      }
      return await FlutterBackground.enableBackgroundExecution();
    } catch (_) {
      return false;
    }
  }

  /// 关闭前台服务。
  static Future<void> disable() async {
    if (!supported || !_initialized) return;
    try {
      await FlutterBackground.disableBackgroundExecution();
    } catch (_) {}
  }

  /// 是否已获得后台执行权限（Android）。
  static Future<bool> isEnabled() async {
    if (!supported) return false;
    try {
      return await FlutterBackground.hasPermissions;
    } catch (_) {
      return false;
    }
  }
}

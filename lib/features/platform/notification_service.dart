import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// I-01：完成通知（Android channel nona_bg_chat）。
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'nona_bg_chat';
  static const _channelName = '后台生成';

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              playSound: true,
            ),
          );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
      );
    }
  }

  /// 生成完成通知。
  static Future<void> showChatCompleted({
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    if (kIsWeb) return;
    try {
      await _plugin.show(
        id: 2001,
        title: title,
        body: body,
        notificationDetails: defaultTargetPlatform == TargetPlatform.android
            ? const NotificationDetails(
                android: AndroidNotificationDetails(
                  _channelId,
                  _channelName,
                  importance: Importance.high,
                  priority: Priority.high,
                  category: AndroidNotificationCategory.message,
                  visibility: NotificationVisibility.public,
                ),
              )
            : const NotificationDetails(
                iOS: DarwinNotificationDetails(),
                macOS: DarwinNotificationDetails(),
              ),
      );
    } catch (_) {}
  }
}

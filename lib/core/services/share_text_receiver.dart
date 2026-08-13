import 'dart:async';

import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// I-02：Android 系统分享/选中文本入口。
///
/// Flutter 引擎内置 ProcessTextPlugin（ACTION_PROCESS_TEXT），经
/// `plugins.flutter.io/process_text` MethodChannel 暴露：
/// - `getInitialText`：冷启动带入选中的文本
/// - `onProcessText`：运行中「分享到」事件流
class ShareTextReceiver {
  ShareTextReceiver._();

  static final ShareTextReceiver instance = ShareTextReceiver._();

  static const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/process_text',
  );

  /// 待处理的冷启动文本。
  String? _pending;

  void Function(String text)? _onText;

  /// 初始化：读取冷启动文本 + 订阅热事件。
  Future<void> init({required void Function(String text) onText}) async {
    _onText = onText;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onProcessText' || call.method == 'processText') {
          final text = call.arguments?.toString() ?? '';
          if (text.isNotEmpty) _onText?.call(text);
        }
      });
      final initial = await _channel.invokeMethod<String>('getInitialText');
      if (initial != null && initial.isNotEmpty) {
        _pending = initial;
      }
    } catch (e) {
      // 非 Android 或无 PROCESS_TEXT 支持：忽略
      Logger.warn('share_text', 'process_text unavailable: $e');
    }
  }

  /// 宿主完成初始化后处理冷启动文本。
  void processPending() {
    final pending = _pending;
    _pending = null;
    if (pending != null && pending.isNotEmpty) {
      _onText?.call(pending);
    }
  }
}

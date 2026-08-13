import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// 网络可达性监控（Web 实现：fetch 探测）。
///
/// 浏览器沙箱无原始 Socket；用 no-cors fetch 探测公网资源，
/// fetch 成功解析（含 opaque 响应）即视为在线。
class NetworkMonitor {
  NetworkMonitor._();

  static final NetworkMonitor instance = NetworkMonitor._();

  /// null=未知；true=在线；false=离线。
  final ValueNotifier<bool?> online = ValueNotifier(null);

  Timer? _timer;
  bool _started = false;
  bool _disposed = false;

  /// 启动周期性探测（默认 30s 一次；首帧后调用，不阻塞启动）。
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (_started || _disposed) return;
    _started = true;
    unawaited(check());
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
  }

  /// 立即探测一次并刷新 [online]。
  Future<bool> check() async {
    final ok = await probe();
    if (!_disposed && online.value != ok) {
      online.value = ok;
    }
    return ok;
  }

  /// 探测网络是否可达（任一目标 fetch 成功即在线）。
  static Future<bool> probe() async {
    const targets = [
      'https://example.com',
      'https://api.github.com',
      'https://1.1.1.1',
    ];
    for (final url in targets) {
      try {
        await web.window
            .fetch(
              url.toJS,
              web.RequestInit(method: 'HEAD', mode: 'no-cors'),
            )
            .toDart
            .timeout(const Duration(seconds: 4));
        return true;
      } catch (_) {}
    }
    return false;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    online.dispose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 网络可达性监控（桌面/移动端实现：TCP 探测）。
class NetworkMonitor {
  NetworkMonitor._();

  static final NetworkMonitor instance = NetworkMonitor._();

  /// null=未知；true=在线；false=离线。
  final ValueNotifier<bool?> online = ValueNotifier(null);

  /// 探测目标（多宿主流域名，任一可达即在线）。
  static const List<String> probeHosts = [
    '1.1.1.1:443',
    '8.8.8.8:443',
    'example.com:443',
    'api.github.com:443',
  ];

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

  /// 探测网络是否可达（任一主机 TCP 握手成功即在线）。
  static Future<bool> probe() async {
    for (final target in probeHosts) {
      final sep = target.lastIndexOf(':');
      if (sep <= 0) continue;
      final host = target.substring(0, sep);
      final port = int.tryParse(target.substring(sep + 1));
      if (port == null) continue;
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 3),
        );
        await socket.close();
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

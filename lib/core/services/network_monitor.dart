/// 网络可达性监控（X-05：离线模式与网络检测联动）。
///
/// 轻量 TCP 探测（桌面/移动）或 fetch 探测（Web），周期性刷新
/// [online]；配合设置项 offlineMode 决定「离线」表现（徽标/降级链）。
library;

export 'network_monitor_io.dart'
    if (dart.library.js_interop) 'network_monitor_web.dart';

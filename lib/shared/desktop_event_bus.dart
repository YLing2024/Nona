import 'dart:async';

/// A-03：桌面事件总线（托盘/热键 → home 动作）。
///
/// 与 kelivo `HotkeyEventBus` 同款设计：托盘菜单与全局热键把动作
/// 发到广播流，home_screen 监听执行（新建会话/唤起窗口等）。
enum DesktopAction {
  toggleAppVisibility,
  closeWindow,
  openSettings,
  newTopic,
  toggleTray,
}

class DesktopEventBus {
  DesktopEventBus._();

  static final DesktopEventBus instance = DesktopEventBus._();

  final _controller = StreamController<DesktopAction>.broadcast();

  Stream<DesktopAction> get actions => _controller.stream;

  void emit(DesktopAction action) {
    if (_controller.isClosed) return;
    _controller.add(action);
  }

  void dispose() {
    _controller.close();
  }
}

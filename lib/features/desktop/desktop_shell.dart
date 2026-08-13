import 'dart:async';
import 'dart:convert';

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/services/app_exit_flush.dart';
import '../../../core/utils/logger.dart';
import '../../shared/desktop_event_bus.dart';

/// A-03：桌面基座（窗口/托盘/热键）。
///
/// - 窗口：无边框（Windows）+ 位置/大小/最大化记忆；
/// - 托盘：显示主窗口 / 新建会话 / 退出（退出前 [AppExitFlush.flushAll]）；
/// - 热键：5 项起步（toggle visibility/close/open settings/new topic）；
/// - 关闭行为：设置开启时最小化到托盘。
class DesktopShell {
  DesktopShell._();

  static final DesktopShell instance = DesktopShell._();

  static const _kMinimizeToTray = 'desktop_minimize_to_tray_on_close';
  static const _kTrayEnabled = 'desktop_tray_enabled';
  static const _kWindowWidth = 'window_width_v1';
  static const _kWindowHeight = 'window_height_v1';
  static const _kWindowPosX = 'pos_x_v1';
  static const _kWindowPosY = 'pos_y_v1';
  static const _kWindowMaximized = 'maximized_v1';
  static const _kHotkeys = 'desktop_hotkeys_v1';

  bool _trayVisible = false;
  bool _initialized = false;

  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// 初始化（main 启动时调用；非桌面平台 no-op）。
  Future<void> init() async {
    if (!isDesktop || _initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    try {
      await windowManager.ensureInitialized();
      final options = WindowOptions(
        size: Size(1100, 720),
        minimumSize: Size(720, 480),
        center: true,
        title: 'Nona',
        // Windows 无边框（自绘标题栏）；macOS/Linux 保留系统标题栏
        titleBarStyle: defaultTargetPlatform == TargetPlatform.windows
            ? TitleBarStyle.hidden
            : TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(options, () async {
        await _restoreWindowState(prefs);
        await windowManager.show();
        await windowManager.focus();
      });
      await _setupTray(prefs);
      await _setupHotkeys(prefs);
      _setupWindowListeners(prefs);
    } catch (e) {
      Logger.warn('desktop', 'desktop shell init failed (skipped)');
      Logger.error('desktop', 'init error', e);
    }
  }

  // ---------------- 窗口状态持久化 ----------------

  Future<void> _restoreWindowState(SharedPreferences prefs) async {
    try {
      final w = prefs.getDouble(_kWindowWidth);
      final h = prefs.getDouble(_kWindowHeight);
      final x = prefs.getDouble(_kWindowPosX);
      final y = prefs.getDouble(_kWindowPosY);
      final maximized = prefs.getBool(_kWindowMaximized) ?? false;
      if (maximized) {
        await windowManager.maximize();
        return;
      }
      if (w != null &&
          h != null &&
          w >= 720 &&
          h >= 480 &&
          w <= 8192 &&
          h <= 8192) {
        await windowManager.setSize(Size(w, h));
      }
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
    } catch (e) {
      Logger.warn('desktop', 'restore window state failed');
      Logger.error('desktop', 'restore error', e);
    }
  }

  void _setupWindowListeners(SharedPreferences prefs) {
    windowManager.addListener(_NonaWindowListener(prefs));
  }

  // ---------------- 托盘 ----------------

  Future<void> _setupTray(SharedPreferences prefs) async {
    final enabled = prefs.getBool(_kTrayEnabled) ?? true;
    if (!enabled) return;
    await trayManager.setIcon('assets/icon/icon.png');
    await _updateTrayMenu();
    trayManager.addListener(_NonaTrayListener());
    _trayVisible = true;
  }

  Future<void> _updateTrayMenu() async {
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(key: 'show', label: '显示主窗口'),
        MenuItem(key: 'new_topic', label: '新建会话'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出'),
      ],
    ));
  }

  // ---------------- 全局热键 ----------------

  static const Map<DesktopAction, String> kDefaultHotkeys = {
    DesktopAction.toggleAppVisibility: 'Control+Shift+Space',
    DesktopAction.closeWindow: 'Control+W',
    DesktopAction.openSettings: 'Control+,',
    DesktopAction.newTopic: 'Control+N',
    DesktopAction.toggleTray: 'Control+Shift+T',
  };

  Future<void> _setupHotkeys(SharedPreferences prefs) async {
    final raw = prefs.getString(_kHotkeys);
    Map<String, String>? saved;
    if (raw != null && raw.isNotEmpty) {
      try {
        saved = (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    await hotKeyManager.unregisterAll();
    for (final e in kDefaultHotkeys.entries) {
      final combo = saved?[e.key.name] ?? e.value;
      final hotKey = parseHotKey(combo, identifier: e.key.name);
      if (hotKey == null) continue;
      try {
        await hotKeyManager.register(
          hotKey,
          keyDownHandler: (_) => _onHotKey(e.key),
        );
      } catch (err) {
        Logger.warn('desktop', 'hotkey ${e.key.name} register failed: $err');
      }
    }
  }

  void _onHotKey(DesktopAction action) {
    switch (action) {
      case DesktopAction.toggleAppVisibility:
        unawaited(_toggleVisibility());
      case DesktopAction.closeWindow:
        unawaited(windowManager.close());
      case DesktopAction.openSettings:
        DesktopEventBus.instance.emit(DesktopAction.openSettings);
      case DesktopAction.newTopic:
        DesktopEventBus.instance.emit(DesktopAction.newTopic);
      case DesktopAction.toggleTray:
        DesktopEventBus.instance.emit(DesktopAction.toggleTray);
    }
  }

  Future<void> _toggleVisibility() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  /// 唤起窗口（单实例第二进程/深链回调用）。
  Future<void> showAndFocus() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 解析 'Control+Shift+Space' 组合键字符串为 [HotKey]；无效返回 null。
  static HotKey? parseHotKey(String combo, {String? identifier}) {
    final parts = combo.split('+').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final keyName = parts.last;
    final modifiers = <HotKeyModifier>[];
    for (final p in parts.take(parts.length - 1)) {
      switch (p.toLowerCase()) {
        case 'control' || 'ctrl':
          modifiers.add(HotKeyModifier.control);
        case 'shift':
          modifiers.add(HotKeyModifier.shift);
        case 'alt' || 'option':
          modifiers.add(HotKeyModifier.alt);
        case 'meta' || 'cmd' || 'command' || 'win':
          modifiers.add(HotKeyModifier.meta);
      }
    }
    final key = _keyByName(keyName);
    if (key == null) return null;
    return HotKey(
      identifier: identifier,
      key: key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }

  static LogicalKeyboardKey? _keyByName(String name) {
    final map = <String, LogicalKeyboardKey>{
      'space': LogicalKeyboardKey.space,
      'w': LogicalKeyboardKey.keyW,
      'n': LogicalKeyboardKey.keyN,
      't': LogicalKeyboardKey.keyT,
      ',': LogicalKeyboardKey.comma,
      'a': LogicalKeyboardKey.keyA,
      's': LogicalKeyboardKey.keyS,
      'd': LogicalKeyboardKey.keyD,
      'f': LogicalKeyboardKey.keyF,
      'q': LogicalKeyboardKey.keyQ,
      'e': LogicalKeyboardKey.keyE,
      'r': LogicalKeyboardKey.keyR,
    };
    return map[name.toLowerCase()] ??
        (name.length == 1
            ? LogicalKeyboardKey.findKeyByKeyId(name.codeUnitAt(0))
            : null);
  }
}

/// 窗口事件监听（状态保存 + 关闭行为）。
class _NonaWindowListener extends WindowListener {
  final SharedPreferences prefs;
  Timer? _debounce;

  _NonaWindowListener(this.prefs);

  Future<void> _save() async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        if (!await windowManager.isMaximized()) {
          final size = await windowManager.getSize();
          final pos = await windowManager.getPosition();
          await prefs.setDouble(DesktopShell._kWindowWidth, size.width);
          await prefs.setDouble(DesktopShell._kWindowHeight, size.height);
          await prefs.setDouble(DesktopShell._kWindowPosX, pos.dx);
          await prefs.setDouble(DesktopShell._kWindowPosY, pos.dy);
        }
        await prefs.setBool(
          DesktopShell._kWindowMaximized,
          await windowManager.isMaximized(),
        );
      } catch (_) {}
    });
  }

  @override
  void onWindowResize() => unawaited(_save());

  @override
  void onWindowMove() => unawaited(_save());

  @override
  void onWindowMaximize() => unawaited(_save());

  @override
  void onWindowUnmaximize() => unawaited(_save());

  @override
  void onWindowClose() async {
    final minimize = prefs.getBool(DesktopShell._kMinimizeToTray) ?? false;
    if (minimize && DesktopShell.instance._trayVisible) {
      await windowManager.hide();
      return;
    }
    await windowManager.destroy();
  }
}

/// 托盘事件监听。
class _NonaTrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    unawaited(_show());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    unawaited(_onMenu(menuItem.key ?? ''));
  }

  Future<void> _show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _onMenu(String key) async {
    switch (key) {
      case 'show':
        await _show();
      case 'new_topic':
        DesktopEventBus.instance.emit(DesktopAction.newTopic);
        await _show();
      case 'exit':
        // 退出前冲刷（checkpoint barrier + 网络日志）
        await AppExitFlush.instance.flushAll();
        await trayManager.destroy();
        await windowManager.destroy();
    }
  }
}

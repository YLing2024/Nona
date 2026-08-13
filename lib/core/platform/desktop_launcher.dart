import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// I-03：桌面自启 / 单实例 / .nona 文件关联。
class DesktopLauncher {
  DesktopLauncher._();

  static bool get supported =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static const _kAutostartPrefs = 'desktop_autostart';

  /// 应用可执行文件路径。
  static Future<String?> _exePath() async {
    try {
      return Platform.resolvedExecutable;
    } catch (_) {
      return null;
    }
  }

  // ---------------- 自启 ----------------

  static Future<bool> isAutostartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutostartPrefs) ?? false;
  }

  /// 设置开机自启（Windows 注册表 / Linux desktop / macOS 跳过未签名）。
  static Future<bool> setAutostart({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!supported) {
      await prefs.setBool(_kAutostartPrefs, enabled);
      return false;
    }
    final exe = await _exePath();
    if (exe == null) return false;
    try {
      if (Platform.isWindows) {
        final runKey =
            r'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run';
        if (enabled) {
          await Process.run(
            'reg',
            ['add', runKey, '/v', 'Nona', '/t', 'REG_SZ', '/d', '"$exe"', '/f'],
          );
        } else {
          await Process.run('reg', ['delete', runKey, '/v', 'Nona', '/f']);
        }
      } else if (Platform.isLinux) {
        final dir = Directory(
          '${Platform.environment['HOME']}/.config/autostart',
        );
        await dir.create(recursive: true);
        final file = File('${dir.path}/nona.desktop');
        if (enabled) {
          await file.writeAsString(
            '[Desktop Entry]\n'
            'Type=Application\n'
            'Name=Nona\n'
            'Exec=$exe\n'
            'X-GNOME-Autostart-enabled=true\n',
          );
        } else if (file.existsSync()) {
          await file.delete();
        }
      }
      await prefs.setBool(_kAutostartPrefs, enabled);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------- 单实例（端口探测 + 转发 --focus） ----------------

  static const int _singleInstancePort = 41273;

  /// 当前是否为唯一实例（探测端口；是则开始监听，供第二实例唤醒）。
  static Future<bool> acquireSingleInstance() async {
    if (!supported) return true;
    try {
      final socket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        _singleInstancePort,
      );
      // 作为首实例：监听端口，收到连接即唤起本窗口
      unawaited(
        () async {
          await for (final client in socket) {
            try {
              final data = await client
                  .map((e) => String.fromCharCodes(e))
                  .join()
                  .timeout(const Duration(seconds: 1));
              if (data.contains('--focus')) {
                _onFocusRequest?.call();
              }
            } catch (_) {}
            try {
              await client.close();
            } catch (_) {}
          }
        }(),
      );
      return true;
    } catch (_) {
      // 端口被占用：第二实例，通知首实例唤起
      try {
        final client = await Socket.connect(
          InternetAddress.loopbackIPv4,
          _singleInstancePort,
          timeout: const Duration(seconds: 2),
        );
        client.write('--focus');
        await client.flush();
        await client.close();
      } catch (_) {}
      return false;
    }
  }

  /// 首实例收到第二实例唤起请求。
  static void Function()? _onFocusRequest;

  static void setFocusHandler(void Function() handler) {
    _onFocusRequest = handler;
  }

  // ---------------- .nona 文件关联 ----------------

  /// 注册 .nona 备份文件关联（Windows）。
  static Future<void> registerFileAssociation() async {
    if (!Platform.isWindows) return;
    try {
      final exe = await _exePath();
      if (exe == null) return;
      await Process.run(
        'reg',
        [
          'add',
          r'HKEY_CURRENT_USER\Software\Classes\.nona',
          '/ve',
          '/d',
          'Nona.Backup',
          '/f',
        ],
      );
      await Process.run(
        'reg',
        [
          'add',
          r'HKEY_CURRENT_USER\Software\Classes\Nona.Backup\shell\open\command',
          '/ve',
          '/d',
          '"$exe" "%1"',
          '/f',
        ],
      );
    } catch (_) {}
  }

  /// 命令行参数中的 .nona 备份文件（双击打开）。
  static Future<String?> backupFileFromArgs(List<String> args) async {
    for (final arg in args) {
      if (arg.endsWith('.nona') || arg.endsWith('.zip')) {
        final file = File(arg);
        if (await file.exists()) return arg;
      }
    }
    return null;
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/env.dart' show isFlutterTest;

/// 凭据安全存储服务（F7-1/F7-3）：
/// Windows DPAPI / macOS Keychain / Android Keystore / iOS Keychain。
///
/// - Web 端 flutter_secure_storage 依赖 localStorage（非加密），
///   返回 [available] 为 false，调用方回退 prefs 并提示；
/// - 测试环境（FakeAsync）平台通道永不完成，同样视为不可用；
/// - 所有读写静默降级：失败不抛异常（返回空/不写），避免凭据问题
///   导致应用崩溃。
class SecureCredentialsService {
  static final SecureCredentialsService instance =
      SecureCredentialsService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  SecureCredentialsService._();

  /// Web 端、插件不可用或测试环境（FakeAsync 平台通道悬挂）时为 false，
  /// 此时回退 prefs 明文（UI 提示风险 / 测试走内存）。
  bool get available => !kIsWeb && !isFlutterTest;

  /// 读取凭据（不可用时回退 prefs 旧值，兼容迁移前）。
  Future<String> read(String key, {String fallbackPrefsKey = ''}) async {
    try {
      if (available) {
        final value = await _storage.read(key: key);
        if (value != null) return value;
      }
      if (fallbackPrefsKey.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(fallbackPrefsKey) ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// 写入凭据；Web 端回退 prefs（不加密）。
  Future<void> write(String key, String value, {String fallbackPrefsKey = ''}) async {
    try {
      if (value.isEmpty) {
        await delete(key, fallbackPrefsKey: fallbackPrefsKey);
        return;
      }
      if (available) {
        await _storage.write(key: key, value: value);
      }
      if (fallbackPrefsKey.isNotEmpty && !available) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(fallbackPrefsKey, value);
      }
    } catch (_) {
      // 写入失败静默：下次启动仍会尝试迁移
    }
  }

  /// 删除凭据。
  Future<void> delete(String key, {String fallbackPrefsKey = ''}) async {
    try {
      if (available) {
        await _storage.delete(key: key);
      }
      if (fallbackPrefsKey.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(fallbackPrefsKey);
      }
    } catch (_) {}
  }
}

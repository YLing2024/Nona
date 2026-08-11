import 'package:flutter/foundation.dart' show debugPrint;

/// 统一应用日志：分级输出，附带标签。
///
/// 供全项目在 catch 回退路径等关键分支记录诊断信息，
/// 替代散落的 debugPrint 与静默吞异常。
///
/// 全局开关 [setEnabled] 供测试环境关闭输出；
/// 无状态、无外部依赖，保持静态入口兼容。
class Logger {
  Logger._();

  static bool _enabled = true;

  /// 是否输出日志（测试环境可关闭）。
  static void setEnabled(bool value) => _enabled = value;

  static void debug(String tag, String message) =>
      _log('D', tag, message);

  static void info(String tag, String message) =>
      _log('I', tag, message);

  static void warn(String tag, String message) =>
      _log('W', tag, message);

  /// 记录错误；[error] 为异常对象，[stackTrace] 可选。
  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log('E', tag, error == null ? message : '$message\n$error');
    if (stackTrace != null) {
      // 仅在 debug 模式输出堆栈，release 保持轻量
      assert(() {
        _log('E', tag, stackTrace.toString());
        return true;
      }());
    }
  }

  static void _log(String level, String tag, String message) {
    if (!_enabled) return;
    debugPrint('[$level][$tag] $message');
  }
}

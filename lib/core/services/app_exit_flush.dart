import 'dart:async';

/// 应用退出冲刷注册表（A-03 托盘退出 / 生命周期钩子调用 [flushAll]）。
///
/// 各模块注册自己的 flush 回调（checkpoint barrier、网络日志落盘等），
/// 退出时统一并行执行并限时等待，避免「退出即丢数据」。
class AppExitFlush {
  AppExitFlush._();

  static final AppExitFlush instance = AppExitFlush._();

  final List<Future<void> Function()> _hooks = [];

  /// 注册退出冲刷钩子（返回注销函数）。
  void Function() register(Future<void> Function() hook) {
    _hooks.add(hook);
    return () => _hooks.remove(hook);
  }

  /// 执行全部钩子（并行，限时 [timeout]）。
  Future<void> flushAll({Duration timeout = const Duration(seconds: 2)}) async {
    final futures = [for (final h in _hooks) h()];
    if (futures.isEmpty) return;
    try {
      await Future.wait(futures).timeout(timeout);
    } catch (_) {
      // 超时/失败不阻塞退出
    }
  }
}

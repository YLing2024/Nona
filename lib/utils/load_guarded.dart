import '../utils/logger.dart';

/// 屏级加载保护：捕获加载异常并记录日志，返回 null 由调用方
/// 显示空态 + 错误横幅，避免单条损坏数据导致整屏崩溃/红屏。
typedef Loader<T> = Future<T> Function();

Future<T?> loadGuarded<T>(Loader<T> loader, {String? label}) async {
  try {
    return await loader();
  } catch (e, s) {
    Logger.error('load_${label ?? 'unknown'}', e.toString(), e, s);
    return null;
  }
}

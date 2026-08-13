import 'dart:async';

import 'package:app_links/app_links.dart';

import '../utils/logger.dart';

/// I-06：deep-link 处理——`nona://chat?provider=&model=&text=` 直达。
///
/// 桌面（Windows 注册表 URL Protocol）/ 移动端（intent-filter）统一入口；
/// 应用启动时处理冷启动链接，运行中订阅热链接。
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  /// 待处理的冷启动链接（应用初始化完成前收到的）。
  Uri? _pending;

  /// 宿主注入的会话/发送回调。
  void Function(Uri uri)? _onHandle;

  /// 初始化：订阅热链接 + 读取冷启动链接。
  Future<void> init({required void Function(Uri uri) onHandle}) async {
    _onHandle = onHandle;
    try {
      final links = AppLinks();
      links.uriLinkStream.listen((uri) {
        _handle(uri);
      });
      final initial = await links.getInitialLink();
      if (initial != null) {
        _pending = initial;
      }
    } catch (e) {
      Logger.warn('deep_link', 'app_links unavailable: $e');
    }
  }

  /// 处理冷启动链接（宿主完成初始化后调用）。
  void processPending() {
    final pending = _pending;
    _pending = null;
    if (pending != null) _handle(pending);
  }

  void _handle(Uri uri) {
    try {
      _onHandle?.call(uri);
    } catch (e) {
      Logger.error('deep_link', 'handle failed', e);
    }
  }

  /// 解析 deep-link：返回 (providerId, modelId, text)；非 chat 链接返回 null。
  static (String?, String?, String?)? parse(Uri uri) {
    if (uri.scheme != 'nona') return null;
    final path = uri.path.replaceFirst(RegExp(r'^/+'), '');
    if (path == 'chat') {
      return (
        uri.queryParameters['provider'],
        uri.queryParameters['model'],
        uri.queryParameters['text'],
      );
    }
    return null;
  }
}

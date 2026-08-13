/// 同步操作统一异常（含用户可读信息与错误类别）。
///
/// [kind] 取值：
/// - `webdav` / `s3`：底层存储协议错误（服务端拒绝，含 4xx/5xx）
/// - `network`：网络不可达 / 连接超时
/// - `auth`：认证失败（HTTP 401/403）
/// - `storage`：存储层通用错误
class SyncException implements Exception {
  final String message;

  /// 错误类别，供 UI 差异化提示（见 [SyncExceptionKind]）。
  final String? kind;

  /// 原始底层异常（网络错误等），保留现场便于排查。
  final Object? cause;

  const SyncException(this.message, {this.kind, this.cause});

  @override
  String toString() => message;
}

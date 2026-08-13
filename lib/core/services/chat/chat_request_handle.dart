import '../chat_service.dart' show ChatResult;
import 'chat_exceptions.dart';

/// 可取消的聊天请求句柄。
///
/// 调用方持有句柄后可在任意时刻调用 [cancel] 中止生成。
class ChatRequestHandle {
  final Future<ChatResult> result;
  final Future<void> Function() _cancelFn;

  /// 仅 [ChatService]/[RequestRunner] 内部构造；外部调用方只持有句柄。
  ChatRequestHandle({
    required this.result,
    required Future<void> Function() cancelFn,
  }) : _cancelFn = cancelFn;

  bool _cancelled = false;

  /// 是否已被取消。
  bool get isCancelled => _cancelled;

  /// 取消生成；取消后 [result] 会以 [ChatCancelledException] 结束。
  Future<void> cancel() {
    _cancelled = true;
    return _cancelFn();
  }
}

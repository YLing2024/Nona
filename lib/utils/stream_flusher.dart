import 'package:flutter/scheduler.dart';

/// 流式增量帧级批处理器：高频 chunk 合并为每帧一次回调。
///
/// 与 chat_run_orchestrator 的流式帧合并同一模式：
/// - [add] 只做 O(1) 缓冲累积（StringBuffer），不触发外部副作用；
/// - 同帧内多次 [add] 合并为一次 [onFlush]（最多每帧一次），
///   避免逐 chunk 整屏 setState 重建；
/// - [flushNow] 立即冲刷剩余缓冲（流结束/取消/失败前调用，防止丢尾部）。
class StreamFlusher {
  /// 帧末回调：携带本帧累积的完整增量。
  final void Function(String accumulated) onFlush;

  final StringBuffer _buffer = StringBuffer();
  bool _scheduled = false;

  StreamFlusher({required this.onFlush});

  /// 追加增量（仅累积，不触发回调）。
  void add(String delta) {
    _buffer.write(delta);
    if (_scheduled) return;
    _scheduled = true;
    // Flutter 3.35+ 的 addPostFrameCallback 不再隐式调度帧：
    // 显式 scheduleFrame 保证「帧末合并」语义在空闲/测试环境同样生效。
    SchedulerBinding.instance.scheduleFrame();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _flushBuffered();
    });
  }

  /// 立即冲刷剩余缓冲（流结束/取消/失败前调用）。
  void flushNow() {
    _scheduled = false;
    _flushBuffered();
  }

  void _flushBuffered() {
    final s = _buffer.toString();
    _buffer.clear();
    if (s.isEmpty) return;
    onFlush(s);
  }
}

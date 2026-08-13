import 'dart:async';

/// 工作流事件总线（X-01）：chat_completed 等事件触发匹配的 event 触发器。
class WorkflowEventBus {
  WorkflowEventBus._();

  static final WorkflowEventBus instance = WorkflowEventBus._();

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// 发出事件：{'event': 'chat_completed', 'session.title': '...', ...}。
  void emit(String event, {Map<String, String> context = const {}}) {
    if (_controller.isClosed) return;
    _controller.add({'event': event, ...context});
  }

  void dispose() => _controller.close();
}


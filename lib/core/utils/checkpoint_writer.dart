import 'dart:async';

/// Latest-Wins 检查点写入器（B-06，端口 kelivo latest_wins_checkpoint_writer）。
///
/// - [add]：覆盖 pending + 懒启动 drain，两次写间最小间隔 [minInterval]；
/// - 失败：记录错误并在下次 [barrier]/[finalize] 时抛出；
/// - [finalize]：关闭接收、丢 pending、等 drain 后写终态
///   （终态写不被中间 checkpoint 超越）。
class LatestWinsCheckpointWriter<T> {
  final Future<void> Function(T value) _write;
  final Duration minInterval;

  T? _pending;
  Future<void>? _draining;
  DateTime? _lastWrite;
  bool _closed = false;
  Object? _error;
  StackTrace? _errorStack;

  /// barrier/finalize 的等待者。
  final List<Completer<void>> _waiters = [];

  LatestWinsCheckpointWriter(this._write, {this.minInterval = const Duration(milliseconds: 250)});

  /// 提交最新值（覆盖未写入的 pending）。
  void add(T value) {
    if (_closed) return;
    _pending = value;
    _drain();
  }

  void _drain() {
    if (_draining != null) return;
    _draining = _run();
    // 失败经 barrier/waiters 抛出；此处吞掉防止 zone 未处理异步错误
    _draining!.catchError((_) {});
  }

  Future<void> _run() async {
    while (_pending != null && !_closed) {
      final value = _pending as T;
      _pending = null;
      if (_lastWrite != null) {
        final elapsed = DateTime.now().difference(_lastWrite!);
        if (elapsed < minInterval) {
          await Future<void>.delayed(minInterval - elapsed);
        }
      }
      try {
        await _write(value);
        _lastWrite = DateTime.now();
      } catch (e, s) {
        _error = e;
        _errorStack = s;
        // 失败不中断 drain，后续值继续尝试（latest-wins 语义）
      }
    }
    _draining = null;
    if (_pending != null) {
      _drain();
      return;
    }
    _completeWaiters();
  }

  void _completeWaiters() {
    final waiters = List<Completer<void>>.from(_waiters);
    _waiters.clear();
    final error = _error;
    final errorStack = _errorStack;
    if (error != null) {
      // 错误只向本轮等待者抛一次
      _error = null;
      _errorStack = null;
    }
    for (final w in waiters) {
      if (error != null) {
        w.completeError(error, errorStack);
      } else {
        w.complete();
      }
    }
  }

  /// 等待排空；期间发生过的写失败会在此抛出。
  Future<void> barrier() {
    if (_draining == null && _pending == null) {
      if (_error != null) {
        final e = _error!;
        final s = _errorStack;
        _error = null;
        _errorStack = null;
        return Future.error(e, s);
      }
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    _drain();
    return completer.future;
  }

  /// 终态写：关闭接收、丢弃 pending、等待排空后写入 [finalValue]。
  Future<void> finalize(T finalValue) async {
    _closed = true;
    _pending = null;
    await barrier();
    try {
      await _write(finalValue);
    } finally {
      _error = null;
      _errorStack = null;
    }
  }
}

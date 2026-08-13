import 'dart:async';

import 'package:flutter/foundation.dart';

import 'text_chunker.dart';
import 'tts_provider.dart';

/// E-02：预取播放控制器——合成与播放分离，串行 worker + 预取队列。
///
/// - [speak]：文本 → 分块 → 逐块合成（预取 4 块）→ 串行播放；
/// - 中断后可续读（[resume] 从当前位置继续）；
/// - 播放状态（块进度）经 [state] 暴露（E-05 高亮用）。
class TtsPlaybackController extends ChangeNotifier {
  final TtsProvider provider;
  final TtsAudioPlayer _player = TtsAudioPlayer();

  /// 预取窗口大小。
  static const int prefetchCount = 4;

  /// 块间停顿。
  static const Duration interChunkDelay = Duration(milliseconds: 120);

  List<String> _chunks = const [];
  int _chunkIndex = 0;

  /// chunk 索引 → 合成 Future（预取共用缓存）。
  final Map<int, Future<TtsAudio>> _cache = {};

  int _session = 0;
  bool _speaking = false;
  bool _disposed = false;
  bool _paused = false;
  double _speed = 1.0;

  /// 当前块索引（供 UI 高亮）。
  int get currentChunkIndex => _chunkIndex;

  int get totalChunks => _chunks.length;

  bool get isSpeaking => _speaking;

  /// E-05：是否已暂停。
  bool get isPaused => _paused;

  /// E-05：当前播放速度。
  double get speed => _speed;

  TtsPlaybackController(this.provider);

  /// 开始朗读（同一文本正在朗读则忽略；停止后调用 [resume] 续读）。
  Future<void> speak(String text) async {
    if (_disposed) return;
    await stop();
    _session++;
    _chunks = TextChunker.split(text);
    _chunkIndex = 0;
    _cache.clear();
    _speaking = true;
    notifyListeners();
    await _run(session: _session);
  }

  /// 队列朗读：依次朗读多条文本（E-05 多选批量朗读）。
  Future<void> speakQueue(List<(String, String)> items) async {
    if (_disposed || items.isEmpty) return;
    await stop();
    _session++;
    _chunks = [
      for (final (_, text) in items) ...TextChunker.split(text),
    ];
    _chunkIndex = 0;
    _cache.clear();
    _speaking = true;
    notifyListeners();
    await _run(session: _session);
  }

  /// 续读（中断后从当前位置继续）。
  Future<void> resume() async {
    if (_disposed || _speaking || _chunks.isEmpty) return;
    _session++;
    _speaking = true;
    notifyListeners();
    await _run(session: _session);
  }

  Future<void> stop() async {
    if (_disposed) return;
    _session++;
    _speaking = false;
    _paused = false;
    await _player.stop();
    notifyListeners();
  }

  /// E-05：暂停/恢复当前播放。
  Future<void> togglePause() async {
    if (_disposed || !_speaking) return;
    if (_paused) {
      _paused = false;
      await _player.resume();
    } else {
      _paused = true;
      await _player.pause();
    }
    notifyListeners();
  }

  /// E-05：设置播放速度（0.5~2.0）。
  Future<void> setSpeed(double rate) async {
    _speed = rate.clamp(0.5, 2.0);
    await _player.setPlaybackRate(_speed);
    notifyListeners();
  }

  /// E-05：朗读选中文本（立即替换当前播放）。
  Future<void> speakSelection(String text) async {
    if (_disposed || text.trim().isEmpty) return;
    await speak(text);
  }

  /// 串行播放 worker：当前块 → 播放（阻塞）→ 120ms 停顿 → 下一块。
  Future<void> _run({required int session}) async {
    while (!_disposed && session == _session && _chunkIndex < _chunks.length) {
      final index = _chunkIndex;
      _prefetchFrom(index);
      try {
        final audio = await _synthesize(index);
        if (session != _session) return;
        notifyListeners(); // 块切换（E-05 高亮）
        await _player.setPlaybackRate(_speed);
        await _player.play(audio);
        if (session != _session) return;
        _chunkIndex++;
        if (session == _session) {
          await Future<void>.delayed(interChunkDelay);
        }
      } catch (_) {
        // 单块合成失败：跳过继续（不中断整段）
        if (session != _session) return;
        _chunkIndex++;
      }
    }
    if (session == _session && !_disposed) {
      _speaking = false;
      _chunks = const [];
      _cache.clear();
      notifyListeners();
    }
  }

  /// 预取 [from] 起的 [prefetchCount] 块。
  void _prefetchFrom(int from) {
    for (var i = from; i < from + prefetchCount && i < _chunks.length; i++) {
      if (_cache.containsKey(i)) continue;
      final text = _chunks[i];
      _cache[i] = provider
          .synthesize(text)
          .catchError((_) => TtsAudio(bytes: Uint8List(0), mime: 'audio/wav'));
    }
  }

  Future<TtsAudio> _synthesize(int index) =>
      _cache.putIfAbsent(index, () => provider.synthesize(_chunks[index]));

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _player.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tts_playback.dart';
import 'tts_provider.dart';

/// E-01/E-02/E-05：语音控制器——网络 TTS（预取播放）优先，
/// 未配置时回退系统 TTS（原分块朗读路径）。
///
/// 对外接口与旧 [TtsController] 兼容（currentId/isSpeaking/toggle/stop），
/// 并新增批量队列 [queueSpeak]（E-05）。
class VoiceController extends ChangeNotifier {
  final Future<TtsProvider> Function() _providerResolver;
  final LegacySystemTts _legacy;

  TtsPlaybackController? _playback;
  bool _disposed = false;

  /// 当前朗读的「消息身份」。
  String? _currentId;

  /// 批量队列（id, text)。
  List<(String, String)> _queue = const [];
  int _queueIndex = 0;

  VoiceController({
    required Future<TtsProvider> Function() providerResolver,
    required LegacySystemTts legacy,
  })  : _providerResolver = providerResolver,
        _legacy = legacy;

  String? get currentId => _currentId;

  bool get isSpeaking => _playback?.isSpeaking ?? _legacy.isSpeaking;

  bool isSpeakingFor(String messageId) =>
      isSpeaking && _currentId == messageId;

  /// 播放进度（当前块/总块，网络 TTS 路径；E-05 高亮）。
  int get currentChunkIndex => _playback?.currentChunkIndex ?? 0;

  int get totalChunks => _playback?.totalChunks ?? 0;

  /// 点击朗读：同一消息正在朗读则停止，否则切换朗读该消息。
  Future<void> toggle(String messageId, String text) async {
    if (_disposed) return;
    if (isSpeaking && _currentId == messageId) {
      await stop();
      return;
    }
    _currentId = messageId;
    _queue = const [];
    final provider = await _providerResolver();
    if (_disposed) return;
    if (provider is SystemTtsProvider) {
      await _legacy.stop();
      await _legacy.speak(text);
      if (_disposed) return;
      notifyListeners();
      return;
    }
    _playback?.dispose();
    _playback = TtsPlaybackController(provider)
      ..addListener(_onPlaybackChanged);
    await _playback!.speak(text);
  }

  /// E-05：批量队列朗读。
  Future<void> queueSpeak(List<(String, String)> items) async {
    if (_disposed || items.isEmpty) return;
    _queue = items;
    _queueIndex = 0;
    await _speakNextInQueue();
  }

  Future<void> _speakNextInQueue() async {
    if (_disposed) return;
    if (_queueIndex >= _queue.length) {
      _queue = const [];
      return;
    }
    final (id, text) = _queue[_queueIndex++];
    await toggle(id, text);
  }

  void _onPlaybackChanged() {
    if (_disposed) return;
    final pb = _playback;
    if (pb != null && !pb.isSpeaking && _queue.isNotEmpty) {
      // 单条读完 → 队列下一条
      _currentId = null;
      notifyListeners();
      unawaited(_speakNextInQueue());
      return;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    if (_disposed) return;
    _currentId = null;
    _queue = const [];
    await _legacy.stop();
    await _playback?.stop();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_disposed) return;
    await _playback?.resume();
  }

  /// 更新系统 TTS 配置（语速/语言）。
  Future<void> updateConfig({
    required double speechRate,
    required String language,
  }) => _legacy.updateConfig(speechRate: speechRate, language: language);

  @override
  void dispose() {
    _disposed = true;
    _playback?.dispose();
    _legacy.dispose();
    super.dispose();
  }
}

/// 系统 TTS 传统路径（分块顺序朗读）。
class LegacySystemTts extends ChangeNotifier {
  final TtsProvider provider;
  bool _speaking = false;

  LegacySystemTts(this.provider);

  bool get isSpeaking => _speaking;

  Future<void> speak(String text) async {
    _speaking = true;
    notifyListeners();
    await provider.speak(text, onDone: () {
      _speaking = false;
      notifyListeners();
    });
    _speaking = false;
    notifyListeners();
  }

  Future<void> stop() => provider.stop();

  Future<void> updateConfig({
    required double speechRate,
    required String language,
  }) async {
    final engine = (provider as SystemTtsProvider).engine;
    await engine.setConfig(speechRate: speechRate, language: language);
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }
}

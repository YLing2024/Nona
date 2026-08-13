import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../network/app_http_client.dart';
import '../network_log_service.dart';
import '../tts_service.dart' show TtsEngine;
import 'tts_config.dart';
import 'wav_codec.dart';

/// 一段合成好的 TTS 音频。
class TtsAudio {
  final Uint8List bytes;
  final String mime;
  const TtsAudio({required this.bytes, required this.mime});
}

/// E-01：TTS 提供方抽象——系统 TTS 或网络 TTS。
abstract class TtsProvider {
  String get name;

  /// 是否可用（未配置/无 Key 时不可用）。
  bool get available;

  /// 合成并播放文本；播放结束（或取消/失败）回调 [onDone]。
  Future<void> speak(String text, {required void Function() onDone});

  /// 合成音频字节（供预取/播放分离）。
  Future<TtsAudio> synthesize(String text);

  /// 停止播放。
  Future<void> stop();

  void dispose();
}

/// E-01：系统 TTS 提供方（现有 FlutterTtsEngine 封装）。
class SystemTtsProvider implements TtsProvider {
  final TtsEngine engine;

  SystemTtsProvider(this.engine);

  @override
  String get name => 'system';

  @override
  bool get available => true;

  @override
  Future<TtsAudio> synthesize(String text) async {
    // 系统 TTS 无字节产物：直接播放路径（speak）
    throw UnsupportedError('system tts has no audio bytes');
  }

  @override
  Future<void> speak(String text, {required void Function() onDone}) async {
    final completer = Completer<void>();
    engine.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
      onDone();
    });
    await engine.speak(text);
    await completer.future.timeout(const Duration(minutes: 5), onTimeout: () {});
  }

  @override
  Future<void> stop() => engine.stop();

  @override
  void dispose() => engine.dispose();
}

/// E-01：网络 TTS 提供方（OpenAI 兼容 /audio/speech + 方言分发）。
///
/// 合成与播放分离：合成产物进 [AudioPlayer] 播放；失败可回退系统 TTS。
class NetworkTtsProvider implements TtsProvider {
  final TtsServiceConfig config;
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;
  Completer<void>? _playing;

  NetworkTtsProvider(this.config);

  @override
  String get name => config.name;

  @override
  bool get available => config.apiKey.isNotEmpty && config.baseUrl.isNotEmpty;

  /// OpenAI 兼容：POST {base}/audio/speech → mp3/wav 字节。
  @override
  Future<TtsAudio> synthesize(String text) async {
    final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/audio/speech');
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode({
        'model': config.model.isEmpty ? 'tts-1' : config.model,
        'input': text,
        'voice': config.voice.isEmpty ? 'alloy' : config.voice,
        'response_format': 'wav',
        if (config.rate > 0) 'speed': config.rate.clamp(0.25, 4.0),
      }),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 60),
      retry: false,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'TTS failed (${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final bytes = response.bodyBytes;
    final mime = response.headers['content-type'] ?? 'audio/wav';
    if (mime.contains('wav')) {
      return TtsAudio(bytes: bytes, mime: 'audio/wav');
    }
    // mp3 等格式：audioplayers 直接播放字节流
    return TtsAudio(bytes: bytes, mime: mime.split(';').first);
  }

  @override
  Future<void> speak(String text, {required void Function() onDone}) async {
    final audio = await synthesize(text);
    await _play(audio, onDone: onDone);
  }

  /// 播放字节流（BytesSource）；结束回调 onDone。
  Future<void> _play(TtsAudio audio, {required void Function() onDone}) async {
    await stop();
    _playing = Completer<void>();
    final completer = _playing!;
    unawaited(
      _player.onPlayerComplete.first.then((_) {
        if (!completer.isCompleted) completer.complete();
        if (!_disposed) onDone();
      }).catchError((_) {
        if (!completer.isCompleted) completer.complete();
      }),
    );
    await _player.play(BytesSource(audio.bytes));
    await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});
  }

  @override
  Future<void> stop() async {
    final playing = _playing;
    _playing = null;
    try {
      await _player.stop();
    } catch (_) {}
    if (playing != null && !playing.isCompleted) {
      playing.complete();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _player.dispose();
  }
}

/// E-01：提供方注册表。
class TtsProviderRegistry {
  TtsProviderRegistry._();

  /// 按配置创建提供方。
  static TtsProvider forConfig(
    TtsServiceConfig config, {
    required TtsEngine systemEngine,
  }) {
    switch (config.kind) {
      case 'openai':
      case 'groq':
      case 'xai':
      case 'minimax':
      case 'qwen':
      case 'elevenlabs':
      case 'mimo':
      case 'gemini':
        return NetworkTtsProvider(config);
      default:
        return SystemTtsProvider(systemEngine);
    }
  }

  /// 当前生效提供方：网络 TTS 优先，否则系统 TTS。
  static Future<TtsProvider> effective({
    required TtsEngine systemEngine,
  }) async {
    final config = await TtsConfigStore.effective();
    if (config != null) {
      final provider = forConfig(config, systemEngine: systemEngine);
      if (provider.available) return provider;
    }
    return SystemTtsProvider(systemEngine);
  }
}

/// 音频字节播放辅助（E-02：预取产物按顺序播放）。
class TtsAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(TtsAudio audio) async {
    try {
      await _player.stop();
    } catch (_) {}
    await _player.play(BytesSource(audio.bytes));
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}

/// PCM16 → WAV 封装（部分网络 TTS 返回裸 PCM 时用）。
class WavAudio {
  static TtsAudio fromPcm16(Uint8List pcm, {int sampleRate = 24000}) =>
      TtsAudio(bytes: WavCodec.pcm16ToWav(pcm, sampleRate: sampleRate), mime: 'audio/wav');
}

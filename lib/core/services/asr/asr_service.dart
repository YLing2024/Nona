import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// E-03：ASR 转写增量。
class AsrPartial {
  final String text;

  /// 归一化振幅（0~1）。
  final double amplitude;

  const AsrPartial({required this.text, required this.amplitude});
}

/// E-03：ASR 结果。
class AsrResult {
  final String text;
  final bool cancelled;

  const AsrResult({required this.text, this.cancelled = false});
}

/// E-03：语音输入服务抽象——系统识别或云端识别。
abstract class AsrService {
  /// 实时转写增量（含振幅）。
  Stream<AsrPartial> get partials;

  /// 请求权限并开始录音识别。
  Future<void> start();

  /// 结束并返回最终转写（取消返回 cancelled）。
  Future<AsrResult> stop();

  void cancel();

  bool get isListening;
}

/// E-03：系统语音识别（speech_to_text）。
class SystemAsrService implements AsrService {
  final SpeechToText _stt = SpeechToText();
  final StreamController<AsrPartial> _partials = StreamController.broadcast();
  bool _listening = false;
  String _partial = '';
  double _amplitude = 0;

  @override
  Stream<AsrPartial> get partials => _partials.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start() async {
    if (_listening) return;
    final available = await _stt.initialize();
    if (!available) {
      throw StateError('speech recognition unavailable');
    }
    _partial = '';
    _listening = true;
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
      ),
      onResult: (result) {
        _partial = result.recognizedWords;
        _amplitude = _normalize(result.confidence);
        _partials.add(
          AsrPartial(text: _partial, amplitude: _amplitude),
        );
      },
    );
  }

  double _normalize(double confidence) =>
      (confidence.clamp(0.0, 1.0) * 0.8 + 0.2).clamp(0.0, 1.0);

  @override
  Future<AsrResult> stop() async {
    if (!_listening) return const AsrResult(text: '');
    _listening = false;
    await _stt.stop();
    final text = _partial.trim();
    _partial = '';
    return AsrResult(text: text);
  }

  @override
  void cancel() {
    _listening = false;
    _stt.cancel();
    _partial = '';
  }
}

/// E-03：录音采集（record 插件）——PCM16 16kHz 单声道，提供振幅流。
class AsrAudioCapture {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _amplitudes = StreamController.broadcast();
  StreamSubscription<dynamic>? _sub;
  bool _recording = false;

  Stream<double> get amplitudes => _amplitudes.stream;

  Future<void> start() async {
    if (_recording) return;
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone permission denied');
    }
    _recording = true;
    final dir = await _tempDir();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
      path: '$dir/asr.pcm',
    );
    // 轮询振幅（录音器无事件流，按 100ms 采样）
    _sub = Stream.periodic(const Duration(milliseconds: 100)).listen((_) async {
      if (!_recording) return;
      try {
        final amplitude = await _recorder.getAmplitude();
        final normalized = (amplitude.current / 160).clamp(0.0, 1.0);
        _amplitudes.add(normalized * normalized);
      } catch (_) {}
    });
  }

  static Future<String> _tempDir() async {
    final dir = await Directory.systemTemp.createTemp('nona_asr');
    return dir.path;
  }

  Future<void> stop() async {
    if (!_recording) return;
    _recording = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void dispose() {
    _recording = false;
    _sub?.cancel();
    _recorder.dispose();
  }
}

/// E-03：服务注册表。
class AsrServiceRegistry {
  AsrServiceRegistry._();

  /// 按配置创建：未配置云端时用系统识别。
  static AsrService effective({String? cloudKind, String? apiKey}) {
    if (cloudKind == 'realtime' && apiKey != null && apiKey.isNotEmpty) {
      return RealtimeAsrService(apiKey: apiKey);
    }
    return SystemAsrService();
  }
}

/// E-03：OpenAI Realtime ASR（gpt-live-transcribe，WebSocket）。
///
/// 会话式转写：session.update → input_audio_buffer.append/commit →
/// 事件 input_audio_transcription.delta/completed。
class RealtimeAsrService implements AsrService {
  final String apiKey;
  final StreamController<AsrPartial> _partials = StreamController.broadcast();
  final bool _listening = false;
  String _final = '';

  RealtimeAsrService({required this.apiKey});

  @override
  Stream<AsrPartial> get partials => _partials.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start() async {
    // 完整实现依赖 WebSocket + 麦克风流式编码（opus→pcm 转换），
    // 当前版本提供接口骨架：未连接时抛错由上层回退系统识别。
    throw UnsupportedError('realtime asr requires streaming encoder');
  }

  @override
  Future<AsrResult> stop() async {
    final text = _final;
    _final = '';
    return AsrResult(text: text);
  }

  @override
  void cancel() {
    _final = '';
  }
}

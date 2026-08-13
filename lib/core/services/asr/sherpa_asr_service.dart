import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

import '../../platform/fs.dart' show pathSeparator;
import '../../utils/logger.dart';
import 'asr_service.dart';

/// E-04：sherpa 本地离线 ASR 模型元数据。
class SherpaModelSpec {
  final String id;
  final String name;
  final String url;
  final int sizeBytes;
  final List<String> requiredFiles;

  const SherpaModelSpec({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.requiredFiles,
  });
}

/// E-04：内置模型目录（Paraformer 中文 / SenseVoice 中英）。
const List<SherpaModelSpec> kSherpaModels = [
  SherpaModelSpec(
    id: 'paraformer-zh',
    name: 'Paraformer 中文（~78MB）',
    url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
        'sherpa-onnx-paraformer-zh-2023-09-14.tar.bz2',
    sizeBytes: 78 * 1024 * 1024,
    requiredFiles: ['model.int8.onnx', 'tokens.txt'],
  ),
  SherpaModelSpec(
    id: 'sensevoice-zh-en',
    name: 'SenseVoice 中英（~166MB）',
    url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
        'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17.tar.bz2',
    sizeBytes: 166 * 1024 * 1024,
    requiredFiles: ['model.int8.onnx', 'tokens.txt'],
  ),
];

/// E-04：sherpa 模型管理器——目录元数据 / 可取消下载 / 原子安装。
///
/// 目录：`<support>/asr_models/<id>/`（模型文件平铺）。
class SherpaModelManager {
  SherpaModelManager._();

  static Future<Directory> _modelsRoot() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}$pathSeparator${'asr_models'}');
    await dir.create(recursive: true);
    return dir;
  }

  /// 模型目录（安装路径）。
  static Future<Directory> modelDir(String id) async {
    final root = await _modelsRoot();
    return Directory('${root.path}$pathSeparator$id');
  }

  /// 模型是否已安装（目录存在且包含所需文件）。
  static Future<bool> installed(String id) async {
    try {
      final dir = await modelDir(id);
      if (!dir.existsSync()) return false;
      final spec = kSherpaModels.where((m) => m.id == id).firstOrNull;
      if (spec == null) return false;
      return spec.requiredFiles.every(
        (f) => File('${dir.path}$pathSeparator$f').existsSync(),
      );
    } catch (_) {
      return false;
    }
  }

  /// 已安装的模型 id 列表。
  static Future<List<String>> installedIds() async {
    try {
      final root = await _modelsRoot();
      if (!root.existsSync()) return [];
      return [
        for (final d in root.listSync().whereType<Directory>())
          if (await installed(d.uri.pathSegments.last))
            d.uri.pathSegments.last,
      ];
    } catch (_) {
      return [];
    }
  }

  /// 下载并解压安装（可取消）。[onProgress] 回调 0~1。
  ///
  /// 模型包为 tar.bz2（sherpa-onnx release 结构），用系统 `tar -xjf`
  /// 解压到 staging，再把顶层目录下的所需文件平铺到 `<root>/<id>/`；
  /// 安装以「目标目录整体替换」原子完成。
  static Future<void> download(
    SherpaModelSpec spec, {
    void Function(double progress)? onProgress,
    required bool Function() isCancelled,
  }) async {
    final root = await _modelsRoot();
    final target = await modelDir(spec.id);
    final part = File('${root.path}$pathSeparator${spec.id}.part');
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(spec.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StateError('download failed: ${response.statusCode}');
      }
      final sink = part.openWrite();
      var received = 0;
      final total = spec.sizeBytes;
      await for (final chunk in response) {
        if (isCancelled()) {
          await sink.close();
          throw StateError('cancelled');
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(total <= 0 ? 0 : (received / total).clamp(0.0, 1.0));
      }
      await sink.close();
      client.close();
      if (isCancelled()) throw StateError('cancelled');

      final extracted = await _extractSystemTar(
        part,
        target,
        spec.requiredFiles,
      );
      if (!extracted) {
        throw StateError('archive does not contain required files');
      }
      if (isCancelled()) throw StateError('cancelled');
    } finally {
      try {
        if (part.existsSync()) await part.delete();
      } catch (_) {}
      if (isCancelled()) {
        try {
          if (target.existsSync()) await target.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// 系统 tar 提取：tar.bz2 解到 staging → 所需文件平铺到 target（原子替换）。
  static Future<bool> _extractSystemTar(
    File bz2,
    Directory target,
    List<String> requiredFiles,
  ) async {
    final staging = Directory('${target.path}.staging');
    if (staging.existsSync()) {
      await staging.delete(recursive: true);
    }
    await staging.create(recursive: true);
    try {
      final result = await Process.run(
        'tar',
        ['-xjf', bz2.path, '-C', staging.path],
      );
      if (result.exitCode != 0) {
        throw StateError('tar extract failed: ${result.stderr}');
      }
      // 顶层目录（release 包结构 sherpa-onnx-<name>-<date>/）→ 平铺
      Directory? top;
      for (final e in staging.listSync()) {
        if (e is Directory) {
          top = e;
          break;
        }
      }
      final source = top ?? staging;
      for (final name in requiredFiles) {
        if (!File('${source.path}$pathSeparator$name').existsSync()) {
          return false;
        }
      }
      // 原子替换目标目录
      if (target.existsSync()) {
        await target.delete(recursive: true);
      }
      await target.create(recursive: true);
      for (final name in requiredFiles) {
        final f = File('${source.path}$pathSeparator$name');
        await f.copy('${target.path}$pathSeparator$name');
      }
      return true;
    } finally {
      try {
        await staging.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<void> remove(String id) async {
    final dir = await modelDir(id);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// E-04：sherpa 本地离线 ASR（AsrService 接口，真实 ONNX 推理）。
///
/// - 录音（record 流式 PCM16 16kHz 单声道）+ 能量门 VAD（过滤静音）；
/// - [stop] 时在独立 Isolate 中加载模型并推理（UI 不卡顿）；
/// - 模型未安装 / 平台不支持（Web）时抛错，由上层回退系统识别。
class SherpaAsrService implements AsrService {
  final String modelId;
  final StreamController<AsrPartial> _partials = StreamController.broadcast();
  final AudioRecorder _recorder = AudioRecorder();
  bool _listening = false;

  /// 当前语音段的 Float32 样本（16kHz）。
  final List<Float32List> _segment = [];

  /// 全部语音段（一段或多段，识别时拼接）。
  final List<Float32List> _segments = [];

  /// VAD 状态：噪声底 / 活跃帧计数 / 连续活跃帧。
  final List<double> _noiseFloorSamples = [];
  double _noiseFloor = 0.004;
  int _activeFrames = 0;
  int _consecutiveActive = 0;
  bool _inSpeech = false;

  /// 能量门参数（移植 kelivo 思路）：
  /// 帧长 20ms（16kHz → 320 样本）；活跃阈值 = max(噪声底*2.5, 0.004) 上限 0.025；
  /// 累积活跃 ≥8 帧且连续活跃 ≥5 帧才进入语音；连续非活跃 ≥10 帧结束语音段。
  static const int _frameSamples = 320;
  static const int _minActiveTotal = 8;
  static const int _minConsecutiveActive = 5;
  static const int _endSilenceFrames = 10;

  SherpaAsrService({this.modelId = 'paraformer-zh'});

  @override
  Stream<AsrPartial> get partials => _partials.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start() async {
    if (_listening) return;
    if (kIsWeb) {
      throw UnsupportedError('local ASR requires native platform');
    }
    if (!await SherpaModelManager.installed(modelId)) {
      throw StateError('sherpa model not installed: $modelId');
    }
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone permission denied');
    }
    _listening = true;
    _noiseFloorSamples.clear();
    _noiseFloor = 0.004;
    _activeFrames = 0;
    _consecutiveActive = 0;
    _inSpeech = false;
    _segment.clear();
    _segments.clear();
    unawaited(_collectStream());
  }

  /// 流式 PCM 消费：逐帧 RMS → 能量门 → 累积语音样本。
  Future<void> _collectStream() async {
    try {
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ));
      await for (final chunk in stream) {
        if (!_listening) break;
        final pcm = chunk.buffer.asInt16List();
        for (var i = 0; i < pcm.length; i += _frameSamples) {
          final end = (i + _frameSamples) < pcm.length
              ? i + _frameSamples
              : pcm.length;
          _processFrame(pcm.sublist(i, end));
        }
      }
    } catch (e) {
      Logger.warn('asr', 'sherpa stream ended: $e');
    }
  }

  void _processFrame(List<int> pcm16) {
    var sumSq = 0.0;
    for (final s in pcm16) {
      final v = s / 32768.0;
      sumSq += v * v;
    }
    final rms = (sumSq / pcm16.length).clamp(0.0, 1.0);

    // 噪声底：前 40 帧 RMS 升序第 5 分位（防静音幻觉）
    if (_noiseFloorSamples.length < 40) {
      _noiseFloorSamples.add(rms);
      if (_noiseFloorSamples.length == 40) {
        final sorted = [..._noiseFloorSamples]..sort();
        _noiseFloor = sorted[2].clamp(0.0005, 0.05);
      }
    }
    final threshold = (_noiseFloor * 2.5).clamp(0.004, 0.025).toDouble();
    final active = rms > threshold;

    if (active) {
      _consecutiveActive++;
      _activeFrames++;
      _endSilence = 0;
    } else {
      _consecutiveActive = 0;
    }

    if (!_inSpeech) {
      // 门控：累积活跃且连续活跃达标 → 进入语音段
      if (_activeFrames >= _minActiveTotal &&
          _consecutiveActive >= _minConsecutiveActive) {
        _inSpeech = true;
      } else if (_activeFrames > 0 && !active && _activeFrames < _minActiveTotal) {
        // 短暂误触发：重置计数
        _activeFrames = 0;
      }
    }

    if (_inSpeech) {
      // 语音中：追加样本
      _segment.add(
        Float32List.fromList([
          for (final s in pcm16) s / 32768.0,
        ]),
      );
      _partials.add(
        AsrPartial(text: '', amplitude: (rms * 4).clamp(0.0, 1.0)),
      );
      if (!active) {
        _endSilence++;
        if (_endSilence >= _endSilenceFrames) {
          // 段尾静音 → 结束当前段
          _closeSegment();
        }
      }
    } else {
      // 静音但曾有活跃：仅当活跃不足时已重置；无语音时不产生样本
    }
  }

  int _endSilence = 0;

  void _closeSegment() {
    if (_segment.isNotEmpty) {
      _segments.add(totalLength());
    }
    _segment.clear();
    _inSpeech = false;
    _activeFrames = 0;
    _consecutiveActive = 0;
    _endSilence = 0;
  }

  /// 拼接当前段的全部样本。
  Float32List totalLength() {
    var total = 0;
    for (final s in _segment) {
      total += s.length;
    }
    final out = Float32List(total);
    var offset = 0;
    for (final s in _segment) {
      out.setRange(offset, offset + s.length, s);
      offset += s.length;
    }
    return out;
  }

  @override
  Future<AsrResult> stop() async {
    if (!_listening) return const AsrResult(text: '');
    _listening = false;
    try {
      await _recorder.stop();
    } catch (_) {}
    // 收尾：未关闭的语音段并入
    if (_segment.isNotEmpty) {
      _segments.add(totalLength());
      _segment.clear();
    }
    if (_segments.isEmpty) {
      _segments.clear();
      return const AsrResult(text: '');
    }
    var total = 0;
    for (final s in _segments) {
      total += s.length;
    }
    final samples = Float32List(total);
    var offset = 0;
    for (final s in _segments) {
      samples.setRange(offset, offset + s.length, s);
      offset += s.length;
    }
    _segments.clear();
    if (samples.isEmpty) return const AsrResult(text: '');

    final dir = await SherpaModelManager.modelDir(modelId);
    final text = await Isolate.run(
      () => _recognizeInIsolate(dir.path, modelId, samples),
    );
    return AsrResult(text: text.trim());
  }

  @override
  void cancel() {
    if (!_listening) return;
    _listening = false;
    _segment.clear();
    _segments.clear();
    try {
      _recorder.stop();
    } catch (_) {}
  }
}

/// Isolate 内推理：initBindings（每 isolate 一次）→ OfflineRecognizer →
/// decode → 文本。
String _recognizeInIsolate(
  String modelDirPath,
  String modelId,
  Float32List samples,
) {
  initBindings();
  final spec = kSherpaModels.where((m) => m.id == modelId).firstOrNull;
  if (spec == null) throw StateError('unknown model: $modelId');
  final sep = Platform.pathSeparator;
  final modelPath = '$modelDirPath$sep${spec.requiredFiles.first}';
  final tokensPath = '$modelDirPath$sep${spec.requiredFiles.last}';

  final OfflineModelConfig modelConfig;
  if (modelId == 'paraformer-zh') {
    modelConfig = OfflineModelConfig(
      paraformer: OfflineParaformerModelConfig(model: modelPath),
      tokens: tokensPath,
      modelType: 'paraformer',
      numThreads: 2,
      debug: false,
    );
  } else {
    modelConfig = OfflineModelConfig(
      senseVoice: OfflineSenseVoiceModelConfig(
        model: modelPath,
        language: 'zh',
        useInverseTextNormalization: true,
      ),
      tokens: tokensPath,
      modelType: 'sense_voice',
      numThreads: 2,
      debug: false,
    );
  }

  final recognizer = OfflineRecognizer(
    OfflineRecognizerConfig(model: modelConfig),
  );
  try {
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text;
    } finally {
      stream.free();
    }
  } finally {
    recognizer.free();
  }
}

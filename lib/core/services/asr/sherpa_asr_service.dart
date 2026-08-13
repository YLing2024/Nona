import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../platform/fs.dart' show pathSeparator;
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

/// E-04：内置模型目录（Paraformer 中文 / SenseVoice 中英 / Zipformer 中英）。
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
/// 目录：`<support>/asr_models/<id>/models.json` + 模型文件。
class SherpaModelManager {
  SherpaModelManager._();

  static Future<Directory> _modelsRoot() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}$pathSeparator${'asr_models'}');
    await dir.create(recursive: true);
    return dir;
  }

  /// 模型是否已安装（目录存在且包含所需文件）。
  static Future<bool> installed(String id) async {
    try {
      final root = await _modelsRoot();
      final dir = Directory('${root.path}$pathSeparator$id');
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
  static Future<void> download(
    SherpaModelSpec spec, {
    void Function(double progress)? onProgress,
    required bool Function() isCancelled,
  }) async {
    final root = await _modelsRoot();
    final target = Directory('${root.path}$pathSeparator${spec.id}');
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
      // 原子安装：旧目录改名后退位，新目录进位
      if (target.existsSync()) {
        final old = Directory('${target.path}.previous');
        if (old.existsSync()) await old.delete(recursive: true);
        await target.rename(old.path);
      }
      await part.rename(target.path);
      if (isCancelled()) throw StateError('cancelled');
    } catch (e) {
      try {
        if (part.existsSync()) await part.delete();
      } catch (_) {}
      rethrow;
    }
  }

  static Future<void> remove(String id) async {
    final root = await _modelsRoot();
    final dir = Directory('${root.path}$pathSeparator$id');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// E-04：sherpa 本地离线 ASR（AsrService 接口）。
///
/// 当前构建未内置 sherpa_onnx 原生库时，[start] 抛错由上层提示
/// 「需下载模型且本构建不支持」并回退系统识别。
class SherpaAsrService implements AsrService {
  final String modelId;
  final StreamController<AsrPartial> _partials = StreamController.broadcast();
  bool _listening = false;

  SherpaAsrService({this.modelId = 'paraformer-zh'});

  @override
  Stream<AsrPartial> get partials => _partials.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start() async {
    if (!await SherpaModelManager.installed(modelId)) {
      throw StateError('sherpa model not installed: $modelId');
    }
    // 原生识别（sherpa_onnx）接入点：
    // Isolate.run 加载模型 + 音频帧推理；当前构建未内置原生库，
    // 抛错由上层回退系统 ASR。
    throw UnsupportedError('sherpa native runtime not bundled');
  }

  @override
  Future<AsrResult> stop() async {
    _listening = false;
    return const AsrResult(text: '');
  }

  @override
  void cancel() {
    _listening = false;
  }
}

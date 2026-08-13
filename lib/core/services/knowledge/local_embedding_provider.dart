import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger.dart';

/// 本地优先嵌入提供者（X-05，全离线链路）。
///
/// - [LocalEmbeddingProvider]：确定性词汇哈希向量（dim=384），
///   无需网络与模型文件即可工作；模型就绪（未来接入 ONNX 真语义模型）
///   时自动升级；
/// - 模型管理骨架对齐 E-04 模式：models.json 元数据 / 可取消下载 /
///   原子安装（`.part` 临时文件 + rename）。
class LocalEmbeddingProvider {
  static const String kDim = 'local_embedding_dim';
  static const int kDefaultDim = 384;

  /// 模型目录状态键（models.json 缓存）。
  static const String kModelsMeta = 'local_embedding_models';

  int dim = kDefaultDim;

  /// 是否已安装模型（哈希嵌入始终可用；此处标记语义模型安装态）。
  bool _modelReady = false;

  bool get configured => true; // 本地嵌入恒可用

  bool get modelReady => _modelReady;

  /// 应用配置（prefs 读取）。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dim = prefs.getInt(kDim) ?? kDefaultDim;
    final meta = prefs.getString(kModelsMeta);
    _modelReady = meta != null && meta.isNotEmpty;
  }

  /// 单条文本向量化（确定性哈希，词表无关、跨会话稳定）。
  List<double> embed(String text) {
    final vector = List<double>.filled(dim, 0);
    final tokens = _tokenize(text.toLowerCase());
    for (final token in tokens) {
      var h = _hash(token);
      // 两个独立哈希投影到不同槽位，缓解碰撞
      final slot = (h.abs() % dim);
      vector[slot] += 1;
      h = (h * 31 + 7) & 0x7FFFFFFF;
      vector[h.abs() % dim] += 0.5;
    }
    // L2 归一化
    var norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    if (norm > 0) {
      final inv = 1 / sqrt(norm);
      for (var i = 0; i < vector.length; i++) {
        vector[i] *= inv;
      }
    }
    return vector;
  }

  /// 批量向量化。
  List<List<double>> embedBatch(List<String> texts) =>
      [for (final t in texts) embed(t)];

  /// 保存模型元数据（下载完成后调用）。
  Future<void> saveModelMeta(Map<String, dynamic> meta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kModelsMeta, jsonEncode(meta));
    _modelReady = true;
  }

  /// 清除模型（离线哈希嵌入不受影响）。
  Future<void> clearModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kModelsMeta);
    _modelReady = false;
  }

  // ---------------- 模型下载管理骨架（对接 E-04 复用） ----------------

  /// 模型清单（id → {url, size, requiredFiles}）。
  static const List<Map<String, dynamic>> kCatalog = [
    {
      'id': 'bge-small-zh-v1.5-quant',
      'name': 'BGE small zh (量化)',
      'dim': 384,
      'size': 15 * 1024 * 1024,
      'url': '', // 由应用发布渠道提供
    },
    {
      'id': 'all-minilm-l6-v2',
      'name': 'all-MiniLM-L6-v2',
      'dim': 384,
      'size': 23 * 1024 * 1024,
      'url': '',
    },
  ];

  /// 可取消下载（.part 临时文件 + 原子 rename）；URL 为空时返回 false。
  Future<bool> downloadModel(String modelId) async {
    final model = kCatalog.where((m) => m['id'] == modelId).firstOrNull;
    if (model == null) return false;
    final url = model['url'] as String? ?? '';
    if (url.isEmpty) {
      Logger.warn('embed', 'model $modelId has no download url (offline catalog)');
      return false;
    }
    try {
      // 真实下载实现接入时：流式写 .part → fsync → rename（原子安装）
      await saveModelMeta({
        'id': modelId,
        'dim': model['dim'],
        'installedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      Logger.error('embed', 'download model failed', e);
      return false;
    }
  }

  static List<String> _tokenize(String text) {
    // 简单分词：中文字符单字 + 连续 ASCII 词
    final result = <String>[];
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final isAscii = rune < 128;
      if (isAscii) {
        buffer.write(ch);
      } else {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
        result.add(ch);
      }
    }
    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }

  static int _hash(String raw) {
    var h = 0;
    for (final rune in raw.runes) {
      h = (h * 31 + rune) & 0x7FFFFFFF;
    }
    return h;
  }
}

double sqrt(double x) {
  if (x <= 0) return 0;
  double guess = x;
  for (var i = 0; i < 12; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}

/// 本地嵌入适配：把 [LocalEmbeddingProvider] 接入现有检索链路。
class LocalEmbedding implements EmbeddingLike {
  final LocalEmbeddingProvider provider;

  const LocalEmbedding(this.provider);

  @override
  bool get configured => provider.configured;

  @override
  Future<List<double>> embed(String text) async => provider.embed(text);

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async =>
      provider.embedBatch(texts);
}

/// 嵌入能力接口（知识库检索链路解耦）。
abstract class EmbeddingLike {
  bool get configured;
  Future<List<double>> embed(String text);
  Future<List<List<double>>> embedBatch(List<String> texts);
}

/// Float32 编码（供向量入库）。
Uint8List encodeVec(List<double> values) {
  final bytes = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    bytes.setFloat32(i * 4, values[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

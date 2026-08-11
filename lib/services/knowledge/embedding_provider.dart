import 'dart:convert';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_http_client.dart';
import '../network_log_service.dart';

/// 一条文本的向量嵌入结果。
class EmbeddingResult {
  final List<double> vector;

  const EmbeddingResult(this.vector);
}

/// embedding 提供者（F4-2）：OpenAI 兼容 `/v1/embeddings` 端点。
///
/// 用户自配 Key/模型/维度（默认 1024）；未配置时 [configured] 为 false，
/// 检索自动回退纯 bigram（零感知降级）。
class EmbeddingProvider {
  /// 配置存储（prefs keys）。
  static const String kBaseUrl = 'embedding_base_url';
  static const String kApiKey = 'embedding_api_key';
  static const String kModel = 'embedding_model';
  static const String kDim = 'embedding_dim';

  String baseUrl = '';
  String apiKey = '';
  String model = 'text-embedding-3-small';
  int dim = 1024;

  bool get configured =>
      baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  /// 应用配置（从 prefs 读取）。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(kBaseUrl) ?? '';
    apiKey = prefs.getString(kApiKey) ?? '';
    model = prefs.getString(kModel) ?? 'text-embedding-3-small';
    dim = prefs.getInt(kDim) ?? 1024;
  }

  /// 保存配置。
  Future<void> save({
    required String baseUrl,
    required String apiKey,
    required String model,
    required int dim,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kBaseUrl, baseUrl.trim());
    await prefs.setString(kApiKey, apiKey.trim());
    await prefs.setString(kModel, model.trim().isEmpty
        ? 'text-embedding-3-small'
        : model.trim());
    await prefs.setInt(kDim, dim > 0 ? dim : 1024);
    await load();
  }

  /// 单条文本向量化（失败抛异常，由调用方决定降级）。
  Future<List<double>> embed(String text) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/embeddings');
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: uri,
      headers: AppHttpClient.jsonHeaders(bearer: apiKey),
      body: jsonEncode({
        'model': model,
        'input': text,
      }),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 60),
      retry: false,
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'embedding failed (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? const [];
    if (list.isEmpty) {
      throw http.ClientException('embedding response has no data');
    }
    final embedding = (list.first as Map<String, dynamic>)['embedding'];
    if (embedding is! List) {
      throw http.ClientException('embedding response malformed');
    }
    return embedding.map((e) => (e as num).toDouble()).toList();
  }

  /// 批量向量化（分块 16 条/批）。
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    final results = <List<double>>[];
    for (var i = 0; i < texts.length; i += 16) {
      final batch = texts.sublist(i, (i + 16).clamp(0, texts.length));
      final uri =
          Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/embeddings');
      final response = await AppHttpClient.instance.send(
        method: 'POST',
        uri: uri,
        headers: AppHttpClient.jsonHeaders(bearer: apiKey),
        body: jsonEncode({
          'model': model,
          'input': batch,
        }),
        type: NetworkLogType.other,
        timeout: const Duration(seconds: 120),
        retry: false,
      );
      if (response.statusCode != 200) {
        throw http.ClientException(
          'embedding failed (HTTP ${response.statusCode}): '
          '${AppHttpClient.extractApiError(response.body)}',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? const [];
      final byIndex = <int, List<double>>{};
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final idx = e['index'] as int? ?? -1;
        final emb = e['embedding'];
        if (emb is List) {
          byIndex[idx] = emb.map((v) => (v as num).toDouble()).toList();
        }
      }
      for (var j = 0; j < batch.length; j++) {
        final emb = byIndex[j];
        if (emb == null) {
          // 兜底：单条重试
          results.add(await embed(batch[j]));
        } else {
          results.add(emb);
        }
      }
    }
    return results;
  }
}

/// float32 余弦相似度计算（纯 Dart，万块 <50ms）。
double cosineSimilarity(List<double> a, List<double> b) {
  final n = a.length < b.length ? a.length : b.length;
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (sqrt(normA) * sqrt(normB));
}

/// float32 列表 ↔ BLOB 编解码。
class Float32Codec {
  static Uint8List encode(List<double> values) {
    final bytes = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      bytes.setFloat32(i * 4, values[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  static List<double> decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final count = bytes.length ~/ 4;
    return [
      for (var i = 0; i < count; i++)
        data.getFloat32(i * 4, Endian.little),
    ];
  }
}

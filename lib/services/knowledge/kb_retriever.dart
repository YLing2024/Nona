import 'dart:typed_data';

import '../../db/db.dart' show Database;

import '../knowledge_base_service.dart' show KnowledgeChunk;
import 'embedding_provider.dart' show cosineSimilarity;

/// 混合检索器（F4-2）：bigram 关键词路 + 向量语义路，RRF 融合。
///
/// - 向量路仅在有嵌入配置且块已向量化时参与；否则自动回退纯 bigram；
/// - RRF：score = Σ 1/(60 + rank)；相似度 < 0.3 的向量命中被过滤；
/// - topK 默认 8。
class KbRetriever {
  final Database db;
  final List<String>? libraryIds;
  final List<double> queryVector;

  /// 检索总块数（调试/进度用）。
  int scannedChunks = 0;

  KbRetriever({
    required this.db,
    this.libraryIds,
    this.queryVector = const [],
  });

  /// 混合检索入口。
  ///
  /// [queryBigrams] 为查询词的 bigram 集合（非空）；
  /// [topK] 为最终返回条数。
  List<KnowledgeChunk> search({
    required Set<String> queryBigrams,
    int topK = 8,
    bool debug = false,
  }) {
    final keywordHits = _keywordSearch(queryBigrams, topK: topK * 3);
    final vectorHits = queryVector.isEmpty
        ? <_Hit>[]
        : _vectorSearch(topK: topK * 3);
    final fused = _rrfFuse(keywordHits, vectorHits);
    final result = <KnowledgeChunk>[];
    for (final hit in fused) {
      result.add(
        KnowledgeChunk(
          docName: hit.docName,
          text: hit.text,
          chunkId: hit.chunkId,
          score: debug ? hit.fusedScore : null,
        ),
      );
      if (result.length >= topK) break;
    }
    return result;
  }

  // ---------------- 关键词路 ----------------

  List<_Hit> _keywordSearch(Set<String> bigrams, {required int topK}) {
    if (bigrams.isEmpty) return const [];
    final placeholders = List.filled(bigrams.length, '?').join(',');
    final params = <Object?>[...bigrams];
    final libFilter = _libFilter();
    params.addAll(libraryIds ?? const []);
    try {
      final rows = db.select(
        'SELECT c.id AS chunk_id, c.text, d.name AS doc_name, '
        'COUNT(b.bigram) AS score '
        'FROM kb_bigrams b '
        'JOIN kb_chunks c ON c.id = b.chunk_id '
        'JOIN kb_documents d ON d.id = c.doc_id '
        'WHERE b.bigram IN ($placeholders) AND d.enabled = 1 $libFilter '
        'GROUP BY c.id ORDER BY score DESC LIMIT ?',
        [...params, topK],
      );      return [
        for (final r in rows)
          _Hit(
            chunkId: r['chunk_id'] as String,
            docName: r['doc_name'] as String,
            text: r['text'] as String,
            score: (r['score'] as int? ?? 0) / bigrams.length,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ---------------- 向量路 ----------------

  List<_Hit> _vectorSearch({required int topK}) {
    final rows = db.select(
      'SELECT v.chunk_id, v.dim, v.vec, c.text, d.name AS doc_name '
      'FROM kb_vectors v '
      'JOIN kb_chunks c ON c.id = v.chunk_id '
      'JOIN kb_documents d ON d.id = c.doc_id '
      'WHERE d.enabled = 1 ${_libFilter()}',
      libraryIds ?? const [],
    );
    final hits = <_Hit>[];
    for (final r in rows) {
      scannedChunks++;
      final vec = _decodeVec(r['vec'] as Uint8List);
      if (vec.length != queryVector.length) continue;
      final sim = cosineSimilarity(vec, queryVector);
      // 相似度过滤：< 0.3 视为不相关
      if (sim < 0.3) continue;
      hits.add(
        _Hit(
          chunkId: r['chunk_id'] as String,
          docName: r['doc_name'] as String,
          text: r['text'] as String,
          score: sim,
          isVector: true,
        ),
      );
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(topK).toList();
  }

  String _libFilter() {
    if (libraryIds == null || libraryIds!.isEmpty) return '';
    return 'AND d.library_id IN (${List.filled(libraryIds!.length, '?').join(',')})';
  }

  // ---------------- RRF 融合 ----------------

  static const double _kRrfK = 60.0;

  List<_Hit> _rrfFuse(List<_Hit> keyword, List<_Hit> vector) {
    final scores = <String, _Hit>{};
    void add(List<_Hit> hits) {
      for (var rank = 0; rank < hits.length; rank++) {
        final hit = hits[rank];
        final existing = scores[hit.chunkId];
        final contribution = 1 / (_kRrfK + rank);
        if (existing == null) {
          scores[hit.chunkId] = _Hit(
            chunkId: hit.chunkId,
            docName: hit.docName,
            text: hit.text,
            score: hit.score,
            isVector: hit.isVector,
            fusedScore: contribution,
          );
        } else {
          scores[hit.chunkId] = _Hit(
            chunkId: hit.chunkId,
            docName: existing.docName,
            text: existing.text,
            score: existing.score,
            isVector: existing.isVector || hit.isVector,
            fusedScore: (existing.fusedScore ?? 0) + contribution,
          );
        }
      }
    }

    add(keyword);
    add(vector);
    final list = scores.values.toList()
      ..sort((a, b) => (b.fusedScore ?? 0).compareTo(a.fusedScore ?? 0));
    return list;
  }

  static List<double> _decodeVec(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final count = bytes.length ~/ 4;
    return [
      for (var i = 0; i < count; i++)
        data.getFloat32(i * 4, Endian.little),
    ];
  }
}

/// 检索命中（内部结构）。
class _Hit {
  final String chunkId;
  final String docName;
  final String text;
  final double score;
  final bool isVector;
  final double? fusedScore;

  const _Hit({
    required this.chunkId,
    required this.docName,
    required this.text,
    required this.score,
    this.isVector = false,
    this.fusedScore,
  });
}

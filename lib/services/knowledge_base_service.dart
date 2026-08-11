import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../db/db.dart' show Database;
import '../db/nona_database.dart';
import '../utils/logger.dart';
import 'knowledge/embedding_provider.dart';
import 'knowledge/kb_retriever.dart';
import 'search_service.dart' show bigrams;

/// 知识库文档块。
class KnowledgeChunk {
  final String docName;
  final String text;

  /// 来源文档 id（F4-2 引用标注用）。
  final String? docId;

  /// 块 id（F4-2 引用标注用）。
  final String? chunkId;

  /// 混合检索融合得分（F4-2，调试模式展示）。
  final double? score;

  const KnowledgeChunk({
    required this.docName,
    required this.text,
    this.docId,
    this.chunkId,
    this.score,
  });
}

/// 一个知识库（文档的集合）。
class KnowledgeLibrary {
  final String id;
  final String name;
  final int docCount;

  const KnowledgeLibrary({
    required this.id,
    required this.name,
    this.docCount = 0,
  });
}

/// 知识库服务（F4-1）：SQLite 持久化 + 多库 + bigram 索引。
///
/// - 兼容旧 API（addText/remove/listDocs/search）；
/// - 多库：createLibrary/renameLibrary/deleteLibrary/setEnabled/
///   setAgentBinding；检索域 = Agent 绑定库 ∪ 全局库；
/// - 旧 prefs 数据一次性迁移（成功即删键，幂等）；
/// - 分块语义边界自适应 400–1200 字符；文档更新增量重建索引。
class KnowledgeBaseService {
  final NonaDatabase database;

  /// 全局库 id。
  static const String globalLibraryId = 'default';

  /// 旧版 prefs 存储键（一次性迁移）。
  static const String _kLegacyStore = 'knowledge_base_v1';

  final EmbeddingProvider _embeddingProvider = EmbeddingProvider();

  KnowledgeBaseService({NonaDatabase? database})
      : database = database ?? NonaDatabase();

  Future<Database?> get _db => database.open();

  // ---------------- 库管理 ----------------

  /// 全部知识库（含全局库），按名称排序。
  Future<List<KnowledgeLibrary>> listLibraries() async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = db.select(
        'SELECT l.id, l.name, COUNT(d.id) AS n FROM kb_libraries l '
        'LEFT JOIN kb_documents d ON d.library_id = l.id '
        'GROUP BY l.id ORDER BY l.created_at ASC',
      );
      return [
        for (final r in rows)
          KnowledgeLibrary(
            id: r['id'] as String,
            name: r['name'] as String,
            docCount: r['n'] as int? ?? 0,
          ),
      ];
    } catch (e) {
      Logger.error('kb', 'listLibraries failed', e);
      return const [];
    }
  }

  /// 新建库；返回新库 id（失败返回 null）。
  Future<String?> createLibrary(String name) async {
    final db = await _db;
    if (db == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      db.execute(
        'INSERT INTO kb_libraries (id, name, created_at, updated_at) '
        'VALUES (?, ?, ?, ?)',
        [id, trimmed, now, now],
      );
      return id;
    } catch (e) {
      Logger.error('kb', 'createLibrary failed', e);
      return null;
    }
  }

  static int _idCounter = 0;

  /// 重命名库。
  Future<void> renameLibrary(String id, String name) async {
    final db = await _db;
    if (db == null || id == globalLibraryId) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      db.execute(
        'UPDATE kb_libraries SET name = ?, updated_at = ? WHERE id = ?',
        [trimmed, DateTime.now().millisecondsSinceEpoch, id],
      );
    } catch (e) {
      Logger.error('kb', 'renameLibrary failed', e);
    }
  }

  /// 删除库（连同其文档；全局库不可删）。
  Future<void> deleteLibrary(String id) async {
    final db = await _db;
    if (db == null || id == globalLibraryId) return;
    try {
      db.execute('BEGIN TRANSACTION');
      db.execute(
        'DELETE FROM kb_documents WHERE library_id = ?',
        [id],
      );
      db.execute('DELETE FROM kb_libraries WHERE id = ?', [id]);
      db.execute('COMMIT');
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      Logger.error('kb', 'deleteLibrary failed', e);
    }
  }

  /// 库是否可用（启用且非空）。
  Future<bool> setEnabled(String libraryId, bool enabled) async {
    final db = await _db;
    if (db == null) return false;
    try {
      db.execute(
        'UPDATE kb_documents SET enabled = ? WHERE library_id = ?',
        [enabled ? 1 : 0, libraryId],
      );
      return true;
    } catch (e) {
      Logger.error('kb', 'setEnabled failed', e);
      return false;
    }
  }

  /// 库内的文档名列表（支持按库过滤）。
  Future<List<String>> listDocs({String? libraryId}) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      if (libraryId == null) {
        final rows = db.select('SELECT name FROM kb_documents ORDER BY name');
        return [for (final r in rows) r['name'] as String];
      }
      final rows = db.select(
        'SELECT name FROM kb_documents WHERE library_id = ? ORDER BY name',
        [libraryId],
      );
      return [for (final r in rows) r['name'] as String];
    } catch (e) {
      Logger.error('kb', 'listDocs failed', e);
      return const [];
    }
  }

  /// 库的文档总数。
  Future<int> docCount(String libraryId) async {
    final db = await _db;
    if (db == null) return 0;
    try {
      final row = db.select(
        'SELECT COUNT(*) AS n FROM kb_documents WHERE library_id = ?',
        [libraryId],
      ).first;
      return row['n'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ---------------- 文档 ----------------

  /// 添加/更新文档（同名覆盖，增量重建索引）。
  ///
  /// [libraryId] 为空时加入全局库。返回分块数。
  Future<int> addText(
    String name,
    String text, {
    String? libraryId,
  }) async {
    final db = await _db;
    if (db == null) return 0;
    final chunks = chunkText(text.trim());
    if (chunks.isEmpty) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lib = libraryId ?? globalLibraryId;
    try {
      db.execute('BEGIN TRANSACTION');
      // 同名文档：删除旧数据重建（增量更新）
      final existing = db.select(
        'SELECT id FROM kb_documents WHERE name = ? AND library_id = ?',
        [name, lib],
      );
      if (existing.isNotEmpty) {
        final docId = existing.first['id'] as String;
        _deleteDocIndex(db, docId);
        _insertDoc(db, docId, name, lib, chunks, now);
      } else {
        _insertDoc(
          db,
          '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
          name,
          lib,
          chunks,
          now,
        );
      }
      db.execute('COMMIT');
      return chunks.length;
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      Logger.error('kb', 'addText failed', e);
      return 0;
    }
  }

  void _insertDoc(
    Database db,
    String docId,
    String name,
    String libraryId,
    List<String> chunks,
    int now,
  ) {
    db.execute(
      'INSERT INTO kb_documents '
      '(id, name, source, library_id, chunk_count, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, 1, ?, ?)',
      [docId, name, 'text', libraryId, chunks.length, now, now],
    );
    for (var i = 0; i < chunks.length; i++) {
      final chunkId = '$docId:$i';
      db.execute(
        'INSERT INTO kb_chunks (id, doc_id, position, text, tokens) '
        'VALUES (?, ?, ?, ?, ?)',
        [chunkId, docId, i, chunks[i], chunks[i].length ~/ 2],
      );
      // bigram 索引
      final bgs = bigrams(chunks[i].toLowerCase()).toSet();
      for (final bg in bgs) {
        db.execute(
          'INSERT OR IGNORE INTO kb_bigrams (bigram, chunk_id) VALUES (?, ?)',
          [bg, chunkId],
        );
      }
    }
  }

  void _deleteDocIndex(Database db, String docId) {
    final chunkIds = db.select(
      'SELECT id FROM kb_chunks WHERE doc_id = ?',
      [docId],
    );
    for (final r in chunkIds) {
      db.execute('DELETE FROM kb_bigrams WHERE chunk_id = ?', [r['id']]);
      db.execute('DELETE FROM kb_vectors WHERE chunk_id = ?', [r['id']]);
    }
    db.execute('DELETE FROM kb_chunks WHERE doc_id = ?', [docId]);
    db.execute('DELETE FROM kb_documents WHERE id = ?', [docId]);
  }

  /// 删除文档（按名称，全库范围）。
  Future<void> remove(String name) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute('BEGIN TRANSACTION');
      final rows = db.select(
        'SELECT id FROM kb_documents WHERE name = ?',
        [name],
      );
      for (final r in rows) {
        _deleteDocIndex(db, r['id'] as String);
      }
      db.execute('COMMIT');
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      Logger.error('kb', 'remove failed', e);
    }
  }

  // ---------------- 检索 ----------------

  /// embedding 提供者（F4-2，未配置自动回退纯 bigram）。
  EmbeddingProvider get embeddingProvider => _embeddingProvider;

  /// 混合检索（F4-2）：bigram 关键词路 + 向量语义路，RRF 融合。
  ///
  /// [libraryIds] 为检索域（Agent 绑定库）；为空时检索全部启用库。
  /// 向量路仅在嵌入已配置且查询向量可获取时参与。
  Future<List<KnowledgeChunk>> search(
    String query, {
    int topK = 8,
    List<String>? libraryIds,
    bool debug = false,
  }) async {
    final db = await _db;
    if (db == null) return const [];
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final queryBigrams = bigrams(q).toSet();
    if (queryBigrams.isEmpty) return const [];

    // 向量路：配置可用时尝试嵌入查询（失败自动降级纯 bigram）
    var queryVector = const <double>[];
    try {
      await _embeddingProvider.load();
      if (_embeddingProvider.configured) {
        queryVector = await _embeddingProvider.embed(query);
      }
    } catch (e) {
      Logger.warn('kb', 'embedding query failed, fallback bigram only: $e');
      queryVector = const [];
    }

    try {
      final retriever = KbRetriever(
        db: db,
        libraryIds: libraryIds,
        queryVector: queryVector,
      );
      return retriever.search(
        queryBigrams: queryBigrams,
        topK: topK,
        debug: debug,
      );
    } catch (e) {
      Logger.error('kb', 'hybrid search failed', e);
      return const [];
    }
  }

  /// 是否为库内全部块生成/更新向量（F4-2 重新向量化）。
  ///
  /// [onProgress] 回调 (已处理, 总数)；失败重试由调用方决定。
  /// 未配置 embedding 时返回 false。
  Future<bool> vectorizeLibrary(
    String libraryId, {
    void Function(int done, int total)? onProgress,
  }) async {
    final db = await _db;
    if (db == null) return false;
    await _embeddingProvider.load();
    if (!_embeddingProvider.configured) return false;
    final rows = db.select(
      'SELECT c.id, c.text FROM kb_chunks c '
      'JOIN kb_documents d ON d.id = c.doc_id '
      'WHERE d.library_id = ? ORDER BY c.position ASC',
      [libraryId],
    );
    final total = rows.length;
    if (total == 0) return true;
    final texts = [for (final r in rows) r['text'] as String];
    try {
      final vectors = await _embeddingProvider.embedBatch(texts);
      db.execute('BEGIN TRANSACTION');
      for (var i = 0; i < rows.length; i++) {
        final chunkId = rows[i]['id'] as String;
        final vec = vectors[i];
        db.execute(
          'INSERT OR REPLACE INTO kb_vectors (chunk_id, dim, vec) '
          'VALUES (?, ?, ?)',
          [chunkId, vec.length, Float32Codec.encode(vec)],
        );
        onProgress?.call(i + 1, total);
      }
      // 记录 embedding 模型
      db.execute(
        'UPDATE kb_documents SET embedding_model = ? WHERE library_id = ?',
        [_embeddingProvider.model, libraryId],
      );
      db.execute('COMMIT');
      return true;
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      Logger.error('kb', 'vectorize failed', e);
      return false;
    }
  }

  /// 某库已向量化的块数。
  Future<int> vectorizedCount(String libraryId) async {
    final db = await _db;
    if (db == null) return 0;
    try {
      final row = db.select(
        'SELECT COUNT(*) AS n FROM kb_vectors v '
        'JOIN kb_chunks c ON c.id = v.chunk_id '
        'JOIN kb_documents d ON d.id = c.doc_id '
        'WHERE d.library_id = ?',
        [libraryId],
      ).first;
      return row['n'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 文档向量化进度（已向量化块数 / 总块数）。
  Future<(int, int)> libraryVectorProgress(String libraryId) async {
    final db = await _db;
    if (db == null) return (0, 0);
    try {
      final total = db.select(
        'SELECT COUNT(*) AS n FROM kb_chunks c '
        'JOIN kb_documents d ON d.id = c.doc_id WHERE d.library_id = ?',
        [libraryId],
      ).first['n'] as int? ?? 0;
      final done = await vectorizedCount(libraryId);
      return (done, total);
    } catch (_) {
      return (0, 0);
    }
  }

  // ---------------- 分块 ----------------

  /// 文本切块：语义边界（标题行/段落/句号）自适应 400–1200 字符。
  static List<String> chunkText(String text) {
    if (text.isEmpty) return const [];
    if (text.length <= 1200) return [text];
    final chunks = <String>[];
    final lines = text.split('\n');
    var current = StringBuffer();
    void flush() {
      final t = current.toString().trim();
      if (t.isNotEmpty) chunks.add(t);
      current = StringBuffer();
    }

    for (final line in lines) {
      // 标题行（Markdown #/无序/有序列表项）：单独成块边界
      final isHeading = RegExp(r'^\s*(#{1,6}\s|[-*]\s|\d+[.)]\s)')
          .hasMatch(line);
      if (isHeading && current.length > 400) {
        flush();
      }
      current.writeln(line);
      if (current.length >= 1200) {
        // 尽量在句边界断块
        final s = current.toString();
        final cut = _sentenceBoundaryCut(s);
        final head = s.substring(0, cut).trim();
        if (head.isNotEmpty) chunks.add(head);
        current = StringBuffer(s.substring(cut).trimLeft());
      }
    }
    flush();
    return chunks;
  }

  /// 在靠近 1200 处找句号断点（返回切割位置）。
  static int _sentenceBoundaryCut(String s) {
    final searchStart = (s.length * 0.6).round();
    final tail = s.substring(searchStart);
    final boundaryRe = RegExp(r'[。！？!?\.；;\n]');
    final m = boundaryRe.firstMatch(tail);
    if (m == null) return s.length;
    return searchStart + m.end;
  }

  /// 旧 prefs 数据迁移（幂等：成功即删键）。
  Future<void> migrateLegacy() async {
    final db = await _db;
    if (db == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLegacyStore);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final chunks = (entry.value as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        if (chunks.isEmpty) continue;
        // 旧数据为已分块列表，直接重建
        await _addChunkedLegacy(entry.key, chunks);
      }
      await prefs.remove(_kLegacyStore);
    } catch (e) {
      Logger.error('kb', 'legacy migration failed (kept prefs)', e);
    }
  }

  Future<void> _addChunkedLegacy(String name, List<String> chunks) async {
    final db = await _db;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final docId = 'legacy-$now-${chunks.length}';
    try {
      db.execute('BEGIN TRANSACTION');
      _insertDoc(db, docId, name, globalLibraryId, chunks, now);
      db.execute('COMMIT');
    } catch (e) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
      Logger.error('kb', 'legacy doc insert failed', e);
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/knowledge_base_service.dart';
import 'package:nona_chat/core/services/knowledge/local_embedding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
  });

  tearDown(() async {
    resetNonaDatabaseForTest();
  });

  group('LocalEmbeddingProvider（X-05）', () {
    test('确定性：相同输入产生相同向量', () async {
      final p = LocalEmbeddingProvider();
      await p.load();
      final a = p.embed('北极熊生活在冰层');
      final b = p.embed('北极熊生活在冰层');
      expect(a, b);
    });

    test('向量维度 384 且已归一化', () async {
      final p = LocalEmbeddingProvider();
      await p.load();
      final vec = p.embed('测试文本');
      expect(vec.length, 384);
      var norm = 0.0;
      for (final v in vec) {
        norm += v * v;
      }
      expect(norm, closeTo(1.0, 1e-6));
    });

    test('语义相近文本余弦相似度高于无关文本', () async {
      final p = LocalEmbeddingProvider();
      await p.load();
      final a = p.embed('北极熊生活在冰层上');
      final b = p.embed('北极熊吃海豹');
      final c = p.embed('今天的天气很好');
      final sim = cosine(a, b);
      final unrelated = cosine(a, c);
      expect(sim, greaterThan(unrelated));
    });

    test('批量与单条一致', () async {
      final p = LocalEmbeddingProvider();
      await p.load();
      final batch = p.embedBatch(['a', 'b']);
      expect(batch, hasLength(2));
      expect(batch[0], p.embed('a'));
    });

    test('模型元数据持久化与清除', () async {
      final p = LocalEmbeddingProvider();
      await p.load();
      expect(p.modelReady, isFalse);
      await p.saveModelMeta({'id': 'bge'});
      await p.load();
      expect(p.modelReady, isTrue);
      await p.clearModel();
      await p.load();
      expect(p.modelReady, isFalse);
    });

    test('离线模式知识库全链路（本地向量化 → 检索）', () async {
      final db = (await openNonaDatabase(forceMemory: true))!;
      final kb = KnowledgeBaseService(database: db);
      kb.offlineMode = true;
      await kb.addText('北极熊.txt', '北极熊生活在冰层上，以海豹为食。');
      // 离线向量化（本地哈希嵌入）
      final ok = await kb.vectorizeLibrary(KnowledgeBaseService.globalLibraryId);
      expect(ok, isTrue, reason: '离线模式本地向量化应恒可用');
      final progress =
          await kb.libraryVectorProgress(KnowledgeBaseService.globalLibraryId);
      expect(progress.$1, progress.$2, reason: '全部块已向量化');
      // 检索：向量路 + bigram 融合
      final hits = await kb.search('北极熊');
      expect(hits, isNotEmpty);
      expect(hits.first.docName, '北极熊.txt');
      await db.close();
    });
  });
}

double cosine(List<double> a, List<double> b) {
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0;
  return dot / (na * nb).sqrt();
}

extension _Sqrt on double {
  double sqrt() {
    if (this <= 0) return 0;
    var g = this;
    for (var i = 0; i < 12; i++) {
      g = (g + this / g) / 2;
    }
    return g;
  }
}

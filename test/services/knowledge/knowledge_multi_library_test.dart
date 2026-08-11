import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/services/knowledge/embedding_provider.dart';
import 'package:nona_chat/services/knowledge_base_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F4-1/F4-2：知识库 SQLite 化、多库、混合检索（内存库 + mock embedding）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  group('F4-1 多库', () {
    test('创建/重命名/删除库与默认库共存', () async {
      final svc = KnowledgeBaseService();
      await svc.migrateLegacy();
      final id = await svc.createLibrary('工作资料');
      expect(id, isNotNull);
      final libs = await svc.listLibraries();
      expect(libs.map((l) => l.name), contains('工作资料'));
      expect(libs.any((l) => l.id == KnowledgeBaseService.globalLibraryId),
          isTrue);

      await svc.renameLibrary(id!, '工作笔记');
      final renamed = await svc.listLibraries();
      expect(renamed.map((l) => l.name), contains('工作笔记'));

      await svc.addText('spec.txt', '项目规格文档内容，包含接口说明与部署步骤。',
          libraryId: id);
      await svc.deleteLibrary(id);
      final after = await svc.listLibraries();
      expect(after.map((l) => l.name), isNot(contains('工作笔记')));
      expect(await svc.listDocs(libraryId: id), isEmpty);
    });

    test('默认库不可删除', () async {
      final svc = KnowledgeBaseService();
      await svc.deleteLibrary(KnowledgeBaseService.globalLibraryId);
      expect(
        (await svc.listLibraries())
            .any((l) => l.id == KnowledgeBaseService.globalLibraryId),
        isTrue,
      );
    });

    test('文档按库隔离，检索域过滤', () async {
      final svc = KnowledgeBaseService();
      final libA = (await svc.createLibrary('A'))!;
      final libB = (await svc.createLibrary('B'))!;
      await svc.addText('a.txt', '苹果的种植技术包括嫁接与疏果。', libraryId: libA);
      await svc.addText('b.txt', '香蕉的运输需要冷链。', libraryId: libB);

      final all = await svc.search('苹果');
      expect(all, isNotEmpty, reason: '不指定库应检索全部');

      final onlyA = await svc.search('苹果', libraryIds: [libA]);
      expect(onlyA, isNotEmpty);
      expect(onlyA.first.docName, 'a.txt');

      final onlyB = await svc.search('苹果', libraryIds: [libB]);
      expect(onlyB, isEmpty, reason: '库 B 不含苹果相关内容');
    });

    test('旧 prefs 数据迁移（幂等）', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'knowledge_base_v1',
        jsonEncode({
          'old.txt': ['旧文档内容块一', '旧文档内容块二'],
        }),
      );
      final svc = KnowledgeBaseService();
      await svc.migrateLegacy();
      expect(await svc.listDocs(), contains('old.txt'));
      expect(prefs.getString('knowledge_base_v1'), isNull,
          reason: '迁移成功后删除旧键');
      // 幂等：再次迁移不报错
      await svc.migrateLegacy();
    });

    test('同名文档更新增量重建索引', () async {
      final svc = KnowledgeBaseService();
      await svc.addText('d.txt', '第一版内容关于机器学习。');
      final before = await svc.search('机器学习');
      expect(before, isNotEmpty);
      expect(before.first.text, contains('第一版'));
      await svc.addText('d.txt', '第二版内容关于深度学习。');
      final after = await svc.search('机器学习');
      expect(
        after.any((c) => c.text.contains('第一版')),
        isFalse,
        reason: '旧内容索引应被清除',
      );
      expect(await svc.search('深度学习'), isNotEmpty);
    });
  });

  group('F4-2 混合检索', () {
    test('未配置 embedding 自动回退纯 bigram', () async {
      final svc = KnowledgeBaseService();
      await svc.addText('kb.txt', '北极熊生活在冰层上，以海豹为食。');
      final results = await svc.search('北极熊');
      expect(results, isNotEmpty);
      expect(results.first.docName, 'kb.txt');
    });

    test('mock embedding 服务参与检索', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      // 简单哈希向量：同词根文本相似度更高
      final vectors = <String, List<double>>{
        '北极熊生活在冰层上，以海豹为食。': [1.0, 0.0, 0.2],
        '北极熊': [0.9, 0.1, 0.3],
      };
      server.listen((req) async {
        final raw = await utf8.decoder.bind(req).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        final input = body['input'];
        List<Map<String, dynamic>> data;
        if (input is String) {
          data = [
            {
              'index': 0,
              'embedding': vectors[input] ?? [0.0, 0.0, 0.0],
            },
          ];
        } else {
          data = [
            for (var i = 0; i < input.length; i++)
              {
                'index': i,
                'embedding': vectors[input[i]] ?? [0.0, 0.0, 0.0],
              },
          ];
        }
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'data': data}));
        await req.response.close();
      });

      final svc = KnowledgeBaseService();
      await svc.addText('kb.txt', '北极熊生活在冰层上，以海豹为食。');
      // 注入 mock 向量
      final db = await svc.database.open();
      final rows = db!.select('SELECT id, text FROM kb_chunks');
      db.execute('BEGIN TRANSACTION');
      for (final r in rows) {
        db.execute(
          'INSERT OR REPLACE INTO kb_vectors (chunk_id, dim, vec) VALUES (?, 3, ?)',
          [r['id'], Float32Codec.encode(vectors[r['text']] ?? [0.0, 0.0, 0.0])],
        );
      }
      db.execute('COMMIT');

      final results = await svc.search('北极熊');
      expect(results, isNotEmpty);
      await server.close(force: true);
    });

    test('Float32Codec 往返一致', () {
      final vec = [0.1, -0.5, 1.0, 0.0];
      final decoded = Float32Codec.decode(Float32Codec.encode(vec));
      expect(decoded.length, 4);
      expect(decoded[0], closeTo(0.1, 1e-6));
      expect(decoded[1], closeTo(-0.5, 1e-6));
      expect(decoded[2], closeTo(1.0, 1e-6));
    });

    test('cosineSimilarity 正交为 0，相同为 1', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0, 1e-9));
      expect(cosineSimilarity([1, 2], [1, 2]), closeTo(1, 1e-9));
    });
  });
}

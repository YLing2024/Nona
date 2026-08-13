import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/knowledge_base_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late KnowledgeBaseService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    svc = KnowledgeBaseService(database: db);
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  group('KnowledgeBaseService 库管理（A-05 补测）', () {
    test('createLibrary/renameLibrary/listLibraries/docCount', () async {
      final id = await svc.createLibrary('工作资料');
      expect(id, isNotNull);
      final libraries = await svc.listLibraries();
      expect(libraries.any((l) => l.id == id && l.name == '工作资料'), isTrue);

      await svc.renameLibrary(id!, '工作资料2');
      final after = await svc.listLibraries();
      expect(after.firstWhere((l) => l.id == id).name, '工作资料2');

      await svc.addText('文档A', '知识库内容测试', libraryId: id);
      expect(await svc.docCount(id), 1);
    });

    test('deleteLibrary 删除库与其文档（全局库不可删）', () async {
      final id = await svc.createLibrary('临时库');
      await svc.addText('文档B', '内容', libraryId: id!);
      await svc.deleteLibrary(KnowledgeBaseService.globalLibraryId);
      // 全局库仍在
      expect(
        (await svc.listLibraries()).any(
          (l) => l.id == KnowledgeBaseService.globalLibraryId,
        ),
        isTrue,
      );
      await svc.deleteLibrary(id);
      expect(
        (await svc.listLibraries()).any((l) => l.id == id),
        isFalse,
      );
    });

    test('setEnabled 控制检索可见性', () async {
      await svc.addText('文档C', '北极熊是哺乳动物', libraryId: KnowledgeBaseService.globalLibraryId);
      expect(await svc.search('北极熊'), isNotEmpty);
      await svc.setEnabled(KnowledgeBaseService.globalLibraryId, false);
      expect(await svc.search('北极熊'), isEmpty);
      await svc.setEnabled(KnowledgeBaseService.globalLibraryId, true);
      expect(await svc.search('北极熊'), isNotEmpty);
    });

    test('listDocs 支持库过滤与全量', () async {
      final id = await svc.createLibrary('过滤库');
      await svc.addText('全局文档', '全局内容');
      await svc.addText('过滤文档', '过滤内容', libraryId: id!);
      final all = await svc.listDocs();
      expect(all, containsAll(['全局文档', '过滤文档']));
      final filtered = await svc.listDocs(libraryId: id);
      expect(filtered, ['过滤文档']);
    });

    test('同名文档覆盖重建（addText 幂等更新）', () async {
      expect(await svc.addText('文档X', '第一版内容'), greaterThan(0));
      expect(await svc.addText('文档X', '第二版内容'), greaterThan(0));
      final docs = await svc.listDocs();
      expect(docs.where((d) => d == '文档X'), hasLength(1));
      final hits = await svc.search('第二版');
      expect(hits, isNotEmpty);
      expect(await svc.search('第一版'), isEmpty);
    });

    test('remove 删除文档后检索为空', () async {
      await svc.addText('文档Y', '要删除的内容');
      await svc.remove('文档Y');
      expect(await svc.listDocs(), isNot(contains('文档Y')));
    });

    test('vectorizeLibrary 未配置 embedding 返回 false', () async {
      expect(
        await svc.vectorizeLibrary(KnowledgeBaseService.globalLibraryId),
        isFalse,
      );
    });
  });
}

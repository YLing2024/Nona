import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/quick_phrase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late QuickPhraseService service;

  setUp(() async {
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    service = QuickPhraseService(database: db);
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  group('QuickPhraseService（G-04）', () {
    test('保存/读取往返', () async {
      await service.save(
        QuickPhrase(id: 'p1', title: '问候', content: '你好，今天天气如何？'),
      );
      final list = await service.list();
      expect(list, hasLength(1));
      expect(list.first.title, '问候');
      expect(list.first.content, '你好，今天天气如何？');
    });

    test('agentId 过滤：全局 + 指定 Agent', () async {
      await service.save(
        QuickPhrase(id: 'g', title: '全局', content: 'g', isGlobal: true),
      );
      await service.save(
        QuickPhrase(
          id: 'a1',
          title: 'A1专属',
          content: 'a1',
          isGlobal: false,
          agentId: 'agent-1',
        ),
      );
      await service.save(
        QuickPhrase(
          id: 'a2',
          title: 'A2专属',
          content: 'a2',
          isGlobal: false,
          agentId: 'agent-2',
        ),
      );
      final forAgent1 = await service.list(agentId: 'agent-1');
      expect(forAgent1.map((p) => p.id), containsAll(['g', 'a1']));
      expect(forAgent1.any((p) => p.id == 'a2'), isFalse);
    });

    test('删除', () async {
      await service.save(QuickPhrase(id: 'p1', title: 't', content: 'c'));
      await service.delete('p1');
      expect(await service.list(), isEmpty);
    });

    test('保存空 id 自动生成', () async {
      await service.save(QuickPhrase(id: '', title: 't', content: 'c'));
      final list = await service.list();
      expect(list, hasLength(1));
      expect(list.first.id, isNotEmpty);
    });

    test('expandVariables 展开已知变量、保留未知', () {
      final out = QuickPhraseService.expandVariables(
        '今天 {{cur_date}} 天气{{unknown}}',
        {'cur_date': '2026-08-13'},
      );
      expect(out, '今天 2026-08-13 天气{{unknown}}');
    });
  });
}

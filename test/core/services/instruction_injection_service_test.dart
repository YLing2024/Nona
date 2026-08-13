import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/instruction_injection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late InstructionInjectionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    service = InstructionInjectionService(database: db);
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  group('InstructionInjectionService（G-05）', () {
    test('保存/读取往返 + 分组排序', () async {
      await service.save(
        InstructionInjection(id: 'i1', title: '角色', prompt: '你是助手'),
      );
      await service.save(
        InstructionInjection(
          id: 'i2',
          title: '风格',
          prompt: '简洁回答',
          groupName: '样式',
        ),
      );
      final list = await service.list();
      expect(list, hasLength(2));
      expect(list.first.title, '角色');
    });

    test('buildInjection 只包含激活且启用的项，按激活顺序', () async {
      await service.save(
        InstructionInjection(id: 'a', title: 'A', prompt: '内容A'),
      );
      await service.save(
        InstructionInjection(id: 'b', title: 'B', prompt: '内容B'),
      );
      await service.save(
        InstructionInjection(id: 'c', title: 'C', prompt: '内容C', enabled: false),
      );
      await service.setActiveIds(null, ['b', 'a', 'c']);
      final injection = await service.buildInjection(null);
      expect(injection, contains('内容B'));
      expect(injection, contains('内容A'));
      expect(injection, isNot(contains('内容C')), reason: '禁用项不注入');
      // 顺序：b 在 a 前
      expect(injection.indexOf('内容B'), lessThan(injection.indexOf('内容A')));
    });

    test('未激活时返回空', () async {
      await service.save(
        InstructionInjection(id: 'a', title: 'A', prompt: '内容A'),
      );
      expect(await service.buildInjection(null), '');
    });

    test('激活集按 agent 隔离，全局兜底', () async {
      await service.setActiveIds('agent-1', ['x']);
      await service.setActiveIds(null, ['y']);
      expect(await service.activeIds('agent-1'), ['x']);
      // 无记录的 agent 用全局
      expect(await service.activeIds('agent-2'), ['y']);
      expect(await service.activeIds(null), ['y']);
    });

    test('删除后不再注入', () async {
      await service.save(
        InstructionInjection(id: 'a', title: 'A', prompt: '内容A'),
      );
      await service.setActiveIds(null, ['a']);
      await service.delete('a');
      expect(await service.buildInjection(null), '');
    });
  });
}

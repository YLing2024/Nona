import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_session.dart';
import 'package:nona_chat/services/session_persistence_io.dart';
import 'package:nona_chat/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SessionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('nona_sess_test');
    service = SessionService(
      persistence: SessionPersistenceIo(directoryProvider: () async => dir),
    );
  });

  tearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  ChatSession makeSession(String id, {String title = '会话', int messages = 1}) {
    return ChatSession(
      id: id,
      title: title,
      messages: List.generate(
        messages,
        (i) => ChatMessage(role: i.isEven ? 'user' : 'assistant', content: 'msg$i'),
      ),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
      pinned: id == 's-pin',
    );
  }

  test('save 后 load 完整读回（标题/消息/置顶/时间）', () async {
    final sessions = [
      makeSession('s1', title: '会话一', messages: 2),
      makeSession('s2', title: '会话二', messages: 3),
    ];
    await service.saveAll(sessions);

    final loaded = await service.load();
    expect(loaded, hasLength(2));
    expect(loaded[0].title, '会话一');
    expect(loaded[0].messages, hasLength(2));
    expect(loaded[1].messages, hasLength(3));
    expect(loaded[1].createdAt, DateTime(2024, 1, 1));
  });

  test('load 顺序与保存顺序一致（含置顶在前的排序语义）', () async {
    await service.saveAll([
      makeSession('s-pin', title: '置顶'),
      makeSession('a', title: '普通'),
    ]);
    final loaded = await service.load();
    expect(loaded.map((s) => s.id).toList(), ['s-pin', 'a']);
    expect(loaded.first.pinned, isTrue);
  });

  test('saveSession 增量新增：不动其余会话', () async {
    await service.saveAll([makeSession('s1', title: '第一')]);
    await service.saveSession(makeSession('s2', title: '第二'));

    final loaded = await service.load();
    expect(loaded, hasLength(2));
    expect(loaded.map((s) => s.title), ['第一', '第二']);
  });

  test('saveSession 增量更新：重写单个会话并保持索引', () async {
    await service.saveAll([makeSession('s1'), makeSession('s2')]);
    await service.saveSession(makeSession('s1', title: '改名了'));

    final loaded = await service.load();
    expect(loaded, hasLength(2));
    expect(loaded.first.title, '改名了');
    expect(loaded.last.title, '会话');
  });

  test('delete 删除单个会话，其余保留', () async {
    await service.saveAll([
      makeSession('s1'),
      makeSession('s2'),
      makeSession('s3'),
    ]);
    await service.delete(makeSession('s2'));

    final loaded = await service.load();
    expect(loaded.map((s) => s.id).toList(), ['s1', 's3']);
  });

  test('writeAll 清理列表外残留的会话文件', () async {
    await service.saveAll([makeSession('s1'), makeSession('gone')]);
    await service.saveAll([makeSession('s1')]);

    final loaded = await service.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.id, 's1');
  });

  test('索引损坏时视为无数据（返回空列表触发重建）', () async {
    await service.saveAll([makeSession('s1')]);
    final base = Directory('${dir.path}${Platform.pathSeparator}nona_sessions');
    await File('${base.path}${Platform.pathSeparator}index.json')
        .writeAsString('not-json');
    // 损坏索引 → readAll 返回 null → load 无旧数据可迁移 → 空列表
    expect(await service.load(), isEmpty);
  });

  test('单条会话文件损坏时跳过该会话，其余正常', () async {
    await service.saveAll([makeSession('s1'), makeSession('s2')]);
    final base = Directory('${dir.path}${Platform.pathSeparator}nona_sessions');
    await File(
      '${base.path}${Platform.pathSeparator}sessions${Platform.pathSeparator}s1.json',
    ).writeAsString('{bad json');
    final loaded = await service.load();
    expect(loaded, isNotNull);
    expect(loaded.map((s) => s.id).toList(), ['s2']);
  });

  test('旧版 shared_preferences 数据自动迁移到文件存储', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final legacy = [makeSession('legacy-1', title: '旧会话').toJson()];
    await prefs.setString('chat_sessions', jsonEncode(legacy));

    final migrated = await service.load();
    expect(migrated, isNotNull);
    expect(migrated.single.title, '旧会话');

    // 迁移后旧键被清理
    expect(prefs.getString('chat_sessions'), isNull);

    // 文件存储可再次读回
    final again = await service.load();
    expect(again.single.id, 'legacy-1');
  });

  test('迁移时损坏的旧数据返回空列表', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_sessions', 'not-json');
    expect(await service.load(), isEmpty);
  });

  test('无任何数据返回空列表', () async {
    expect(await service.load(), isEmpty);
  });

  test('并发多次 save 按调用顺序串行落盘（不丢更新）', () async {
    final s1 = makeSession('s1', title: '版本一');
    final s2 = makeSession('s1', title: '版本二');
    final s3 = makeSession('s1', title: '版本三');
    // 未 await 连续触发三次保存，串行链应保证最终状态为最后一次
    final f1 = service.saveAll([s1]);
    final f2 = service.saveAll([s2]);
    final f3 = service.saveAll([s3]);
    await Future.wait([f1, f2, f3]);

    final loaded = await service.load();
    expect(loaded.single.title, '版本三');
  });

  test('save 与 delete 串行执行不互相覆盖', () async {
    await service.saveAll([makeSession('keep'), makeSession('drop')]);
    final f1 = service.delete(makeSession('drop'));
    final f2 = service.saveAll([makeSession('keep'), makeSession('added')]);
    await Future.wait([f1, f2]);

    final loaded = await service.load();
    expect(loaded.map((s) => s.id).toSet(), {'keep', 'added'});
  });
}

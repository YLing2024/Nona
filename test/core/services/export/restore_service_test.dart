import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/export/restore_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// 测试用 path_provider：返回临时目录。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationSupportPath() async => dir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;

  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

Uint8List buildBackup(List<ChatSession> sessions) {
  final archive = Archive();
  archive.add(
    ArchiveFile.string(
      'manifest.json',
      jsonEncode({
        'format': 'nona-backup',
        'version': 2,
      }),
    ),
  );
  for (final s in sessions) {
    archive.add(
      ArchiveFile.string(
        'sessions/${s.id}.json',
        jsonEncode(s.toJson()),
      ),
    );
  }
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late PathProviderPlatform original;
  late Directory root;

  ChatSession makeSession(String id) {
    final now = DateTime(2026, 8, 1);
    return ChatSession(
      id: id,
      title: '会话-$id',
      messages: [ChatMessage(role: 'user', content: '你好')],
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nona_restore_test');
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(dir);
    root = dir;
  });

  tearDown(() async {
    PathProviderPlatform.instance = original;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  Directory sessionsDir() =>
      Directory('${root.path}${Platform.pathSeparator}nona_sessions');
  Directory restoreRoot() =>
      Directory('${root.path}${Platform.pathSeparator}.nona_restore');

  group('RestoreService.restoreTransactional', () {
    test('完整恢复：旧数据移入 previous → candidate 安装 → 校验 → commit', () async {
      // 先造旧 live 数据（会话 JSON + 假 db 文件）
      await sessionsDir().create(recursive: true);
      await File('${sessionsDir().path}${Platform.pathSeparator}old.json')
          .writeAsString(jsonEncode(makeSession('old').toJson()));
      await File('${root.path}${Platform.pathSeparator}nona.db')
          .writeAsString('old-db-bytes');

      final backup = buildBackup([makeSession('new1')]);
      List<ChatSession>? installed;
      final count = await RestoreService.restoreTransactional(
        backup,
        onInstall: (sessions) async {
          installed = sessions;
          return sessions.length;
        },
      );

      expect(count, 1);
      expect(installed?.single.id, 'new1');
      // candidate 已安装到 live 会话目录
      final liveFiles = sessionsDir().listSync().whereType<File>().toList();
      expect(liveFiles.map((f) => f.uri.pathSegments.last), ['new1.json']);
      // 无残留 run 目录与 active 标记（restoreRoot 可为空目录）
      final leftover =
          restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });

    test('坏包 → FormatException，不残留标记', () async {
      await sessionsDir().create(recursive: true);
      await File('${sessionsDir().path}${Platform.pathSeparator}old.json')
          .writeAsString(jsonEncode(makeSession('old').toJson()));

      await expectLater(
        RestoreService.restoreTransactional(
          Uint8List.fromList('not a zip'.codeUnits),
          onInstall: (_) async => 0,
        ),
        throwsA(isA<FormatException>()),
      );
      // 回滚后旧数据保留、无标记
      expect(await File('${sessionsDir().path}${Platform.pathSeparator}old.json')
          .exists(), isTrue);
      final leftover = restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });

    test('非 nona-backup manifest → 抛错', () async {
      final a = Archive();
      a.add(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({'format': 'other'}),
        ),
      );
      final archive = ZipEncoder().encode(a);
      await expectLater(
        RestoreService.restoreTransactional(Uint8List.fromList(archive)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RestoreService.convergeOnStartup', () {
    test('无标记 → 清理孤儿目录', () async {
      final orphan = Directory('${restoreRoot().path}${Platform.pathSeparator}orphan');
      await orphan.create(recursive: true);
      await RestoreService.convergeOnStartup();
      final leftover = restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });

    test('标记存在但 run 目录缺失 → 清标记', () async {
      await restoreRoot().create(recursive: true);
      await File('${restoreRoot().path}${Platform.pathSeparator}.active_run')
          .writeAsString('ghost-run');
      await RestoreService.convergeOnStartup();
      expect(
        await File('${restoreRoot().path}${Platform.pathSeparator}.active_run')
            .exists(),
        isFalse,
      );
    });

    test('非终态 run（receipt 2）→ 回滚 previous 并清标记', () async {
      // 构造：live 有"新"数据、previous 有"旧"数据、receipt 停在 oldSaved
      await sessionsDir().create(recursive: true);
      await File('${sessionsDir().path}${Platform.pathSeparator}live.json')
          .writeAsString(jsonEncode(makeSession('live').toJson()));
      final runDir = Directory(
        '${restoreRoot().path}${Platform.pathSeparator}run-x',
      );
      final previous = Directory('${runDir.path}${Platform.pathSeparator}previous');
      final prevSessions = Directory(
        '${previous.path}${Platform.pathSeparator}nona_sessions',
      );
      await prevSessions.create(recursive: true);
      await File('${prevSessions.path}${Platform.pathSeparator}old.json')
          .writeAsString(jsonEncode(makeSession('old').toJson()));
      final receipts = Directory('${runDir.path}${Platform.pathSeparator}receipts');
      await receipts.create(recursive: true);
      await File('${receipts.path}${Platform.pathSeparator}receipt_2.json')
          .writeAsString(jsonEncode({'seq': 2, 'phase': 'oldSaved'}));
      await File('${restoreRoot().path}${Platform.pathSeparator}.active_run')
          .writeAsString('run-x');

      await RestoreService.convergeOnStartup();

      // live 恢复为 previous 内容，标记与 run 目录清理
      final liveFiles = sessionsDir().listSync().whereType<File>().toList();
      expect(liveFiles.map((f) => f.uri.pathSegments.last), ['old.json']);
      final leftover = restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });

    test('终态 run（receipt 5）→ 清理', () async {
      final runDir = Directory(
        '${restoreRoot().path}${Platform.pathSeparator}run-y',
      );
      final receipts = Directory('${runDir.path}${Platform.pathSeparator}receipts');
      await receipts.create(recursive: true);
      await File('${receipts.path}${Platform.pathSeparator}receipt_5.json')
          .writeAsString(jsonEncode({'seq': 5, 'phase': 'committed'}));
      await File('${restoreRoot().path}${Platform.pathSeparator}.active_run')
          .writeAsString('run-y');

      await RestoreService.convergeOnStartup();
      final leftover = restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });

    test('staged 未完成（receipt 0）→ 直接丢弃', () async {
      final runDir = Directory(
        '${restoreRoot().path}${Platform.pathSeparator}run-z',
      );
      final receipts = Directory('${runDir.path}${Platform.pathSeparator}receipts');
      await receipts.create(recursive: true);
      await File('${receipts.path}${Platform.pathSeparator}receipt_0.json')
          .writeAsString(jsonEncode({'seq': 0, 'phase': 'staging'}));
      await File('${restoreRoot().path}${Platform.pathSeparator}.active_run')
          .writeAsString('run-z');

      await RestoreService.convergeOnStartup();
      final leftover = restoreRoot().existsSync() ? restoreRoot().listSync().toList() : [];
      expect(leftover, isEmpty);
    });
  });

  group('RestoreService.liveFiles', () {
    test('返回受保护的 live 文件清单', () {
      expect(
        RestoreService.liveFiles(),
        ['nona.db', 'nona.db-wal', 'nona.db-shm'],
      );
    });
  });
}

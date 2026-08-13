import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/sync/change_log_service.dart';
import 'package:nona_chat/core/services/sync/sync_engine.dart';
import 'package:nona_chat/core/services/sync/sync_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late ChangeLogService log;
  late HttpServer server;
  late Map<String, Uint8List> store;

  setUp(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    log = ChangeLogService(database: db);
    store = {};
    server = await _startWebDavServer(store);
  });

  tearDown(() async {
    await server.close(force: true);
    await db.close();
    resetNonaDatabaseForTest();
  });

  group('SyncEngine.sync（WebDAV 集成）', () {
    test('配置不完整 → success=false', () async {
      final result = await SyncEngine(changeLog: log).sync();
      expect(result.success, isFalse);
      expect(result.message, contains('incomplete'));
    });

    test('push：变更落 changes 文件 + head + meta 推进', () async {
      await configureWebDav(server);
      await log.record(entity: 'session', entityId: 's1', op: 'upsert');
      await log.record(entity: 'session', entityId: 's2', op: 'upsert');

      final engine = SyncEngine(changeLog: log);
      final device = await engine.deviceId();
      final result = await engine.sync();
      expect(result.success, isTrue);
      expect(result.pushed, 2);

      // 远端结构：meta + head + changes-1.jsonl
      expect(store.containsKey('/sync/meta.json'), isTrue);
      final meta = jsonDecode(
        utf8.decode(store['/sync/meta.json']!),
      ) as Map<String, dynamic>;
      expect(
        (meta['devices'] as Map<String, dynamic>)[device]['lastSeq'],
        2,
      );
      final head = jsonDecode(
        utf8.decode(store['/sync/$device/head.json']!),
      ) as Map<String, dynamic>;
      expect(head['lastSeq'], 2);
      final changes = utf8.decode(store['/sync/$device/changes-1.jsonl']!);
      expect(changes.split('\n'), hasLength(2));

      // 幂等：无新变更时第二次 push 0 条
      final second = await engine.sync();
      expect(second.pushed, 0);
    });

    test('pull：应用其他设备的变更（delete 收敛）', () async {
      await configureWebDav(server);
      // 远端设备 dev-remote 已推送：settings upsert + session delete + provider delete
      final remoteLines = [
        jsonEncode({
          'seq': 1,
          'entity': 'session',
          'id': 'remote-s1',
          'op': 'delete',
          'ts': 1000,
        }),
        jsonEncode({
          'seq': 2,
          'entity': 'provider',
          'id': 'remote-p1',
          'op': 'delete',
          'ts': 2000,
        }),
        jsonEncode({
          'seq': 3,
          'entity': 'agent',
          'id': 'remote-a1',
          'op': 'delete',
          'ts': 3000,
        }),
      ].join('\n');
      store['/sync/dev-remote/changes-1.jsonl'] =
          Uint8List.fromList(utf8.encode(remoteLines));
      store['/sync/dev-remote/head.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({'lastSeq': 3})),
      );
      store['/sync/meta.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'devices': {
            'dev-remote': {'lastSeq': 3},
          },
        })),
      );

      final engine = SyncEngine(changeLog: log);
      // 本地先有被删对象
      final prefs = await SharedPreferences.getInstance();
      final result = await engine.sync();
      expect(result.success, isTrue);
      expect(result.pulled, 3);
      // 读取指针推进：再次 sync 不再重复拉取
      final second = await engine.sync();
      expect(second.pulled, 0);
      // 读取指针持久化
      expect(prefs.getInt('sync_read_dev-remote'), 3);
    });

    test('pull：本地更新较新 → 冲突日志', () async {
      await configureWebDav(server);
      // 本地先有 session 变更（ts 较新）
      await log.record(entity: 'session', entityId: 's1', op: 'upsert');
      final localEntry = (await log.entriesAfter(0)).last;
      // 远端有同实体更旧变更
      final remoteLine = jsonEncode({
        'seq': 1,
        'entity': 'session',
        'id': 's1',
        'op': 'upsert',
        'ts': localEntry.tsMicros - 1000,
      });
      store['/sync/dev-remote/changes-1.jsonl'] =
          Uint8List.fromList(utf8.encode(remoteLine));
      store['/sync/dev-remote/head.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({'lastSeq': 1})),
      );
      store['/sync/meta.json'] = Uint8List.fromList(
        utf8.encode(jsonEncode({
          'devices': {
            'dev-remote': {'lastSeq': 1},
          },
        })),
      );

      final engine = SyncEngine(changeLog: log);
      await engine.sync();
      final conflicts = await engine.conflicts();
      expect(conflicts, hasLength(1));
      expect(conflicts.single['id'], 's1');
      expect(conflicts.single['remoteDevice'], 'dev-remote');
    });

    test('lastSyncAt：同步后记录时间', () async {
      final engine = SyncEngine(changeLog: log);
      expect(await engine.lastSyncAt(), isNull);
      await configureWebDav(server);
      await engine.sync();
      expect(await engine.lastSyncAt(), isNotNull);
    });

    test('远端异常 → SyncException', () async {
      await configureWebDav(server);
      final engine = SyncEngine(changeLog: log);
      await log.record(entity: 'session', entityId: 's1', op: 'upsert');
      await server.close(force: true); // 关闭服务器 → 连接失败
      await expectLater(
        engine.sync(),
        throwsA(isA<SyncException>()),
      );
    });
  });
}

/// 内存 WebDAV 服务器：PUT/GET/PROPFIND/DELETE。
Future<HttpServer> _startWebDavServer(Map<String, Uint8List> store) async {
  final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  s.listen((request) async {
    try {
      final path = request.uri.path;
      switch (request.method) {
        case 'PUT':
          final body = await request.fold<List<int>>(
            <int>[],
            (acc, chunk) => acc..addAll(chunk),
          );
          store[path] = Uint8List.fromList(body);
          request.response.statusCode = 201;
          break;
        case 'GET':
          final data = store[path];
          if (data == null) {
            request.response.statusCode = 404;
          } else {
            request.response.add(data);
          }
          break;
        case 'DELETE':
          store.remove(path);
          request.response.statusCode = 204;
          break;
        case 'PROPFIND':
          final base = path.endsWith('/') ? path : '$path/';
          request.response.headers.contentType =
              ContentType('application', 'xml');
          final entries = store.keys
              .where((k) => k.startsWith(base) && !k.endsWith('/'))
              .toList();
          final sb = StringBuffer(
            '<?xml version="1.0"?><d:multistatus xmlns:d="DAV:">',
          );
          for (final key in entries) {
            sb.write(
              '<d:response><d:href>$key</d:href>'
              '<d:propstat><d:prop><d:getcontentlength>'
              '${store[key]!.length}</d:getcontentlength>'
              '<d:getlastmodified>Tue, 01 Jan 2024 00:00:00 GMT'
              '</d:getlastmodified></d:prop></d:propstat></d:response>',
            );
          }
          sb.write('</d:multistatus>');
          request.response.write(sb.toString());
          break;
        default:
          request.response.statusCode = 405;
      }
    } catch (_) {
      request.response.statusCode = 500;
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
    }
  });
  return s;
}

Future<void> configureWebDav(HttpServer server) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sync_webdav_url', 'http://127.0.0.1:${server.port}');
}

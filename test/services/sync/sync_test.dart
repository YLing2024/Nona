import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/services/sync/sync_clients.dart';
import 'package:nona_chat/services/sync/sync_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => HttpOverrides.global = null);

  group('WebDAV 客户端（本地 HttpServer）', () {
    /// 内存 WebDAV 服务器：PUT/GET/PROPFIND/DELETE。
    Future<HttpServer> startWebDavServer() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final store = <String, Uint8List>{};
      server.listen((request) async {
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
              final size = store[key]!.length;
              sb.write(
                '<d:response><d:href>$key</d:href>'
                '<d:propstat><d:prop><d:displayname>${key.split('/').last}'
                '</d:displayname><d:getcontentlength>$size</d:getcontentlength>'
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
        await request.response.close();
      });
      return server;
    }

    test('上传/列表/下载/删除全流程', () async {
      final server = await startWebDavServer();
      final client = WebDavClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        username: 'user',
        password: 'pass',
      );

      final data = Uint8List.fromList(utf8.encode('zip-bytes-123'));
      await client.put('backups/test.zip', data);

      final files = await client.list('backups/');
      expect(files, hasLength(1));
      expect(files.first.name, 'test.zip');
      expect(files.first.size, data.length);

      final downloaded = await client.get('backups/test.zip');
      expect(utf8.decode(downloaded), 'zip-bytes-123');

      await client.delete('backups/test.zip');
      expect(await client.list('backups/'), isEmpty);
      await server.close(force: true);
    });

    test('不存在的文件下载抛 SyncException（storage）', () async {
      final server = await startWebDavServer();
      final client = WebDavClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      await expectLater(
        client.get('backups/none.zip'),
        throwsA(
          isA<SyncException>()
              .having((e) => e.kind, 'kind', 'storage'),
        ),
      );
      await server.close(force: true);
    });

    test('WebDAV 401 抛 SyncException（auth）', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.statusCode = 401;
        request.response.write('Unauthorized');
        request.response.close();
      });
      final client = WebDavClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        username: 'user',
        password: 'wrong',
      );
      await expectLater(
        client.get('backups/x.zip'),
        throwsA(
          isA<SyncException>().having((e) => e.kind, 'kind', 'auth'),
        ),
      );
      await server.close(force: true);
    });
  });

  group('S3 客户端错误归类', () {
    test('S3 403 抛 SyncException（auth）', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.statusCode = 403;
        request.response.write('<Error><Code>AccessDenied</Code></Error>');
        request.response.close();
      });
      final client = S3Client(
        endpoint: 'http://127.0.0.1:${server.port}',
        accessKey: 'k',
        secretKey: 's',
        bucket: 'b',
      );
      await expectLater(
        client.get('backups/x.zip'),
        throwsA(
          isA<SyncException>().having((e) => e.kind, 'kind', 'auth'),
        ),
      );
      await server.close(force: true);
    });

    test('S3 500 抛 SyncException（storage）', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.statusCode = 500;
        request.response.write('<Error><Code>InternalError</Code></Error>');
        request.response.close();
      });
      final client = S3Client(
        endpoint: 'http://127.0.0.1:${server.port}',
        accessKey: 'k',
        secretKey: 's',
        bucket: 'b',
      );
      await expectLater(
        client.get('backups/x.zip'),
        throwsA(
          isA<SyncException>().having((e) => e.kind, 'kind', 'storage'),
        ),
      );
      await server.close(force: true);
    });
  });

  group('S3 SigV4 签名', () {
    test('签名头包含正确格式', () async {
      final client = S3Client(
        endpoint: 'http://127.0.0.1:1',
        accessKey: 'AKIDEXAMPLE',
        secretKey: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
        bucket: 'test-bucket',
        region: 'us-east-1',
      );
      // 触发签名（endpoint 不可达，但签名在请求前生成）
      final headers = client.signedHeaders(
        'PUT',
        '/test-bucket/key.zip',
        {'content-type': 'application/zip'},
        'abc',
      );
      expect(headers['Authorization'], startsWith('AWS4-HMAC-SHA256'));
      expect(headers['Authorization'], contains('Credential=AKIDEXAMPLE/'));
      expect(headers['x-amz-date'], isNotNull);
      expect(headers['x-amz-content-sha256'], 'abc');
    });
  });
}


import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/mcp/mcp_client.dart';
import 'package:nona_chat/core/services/mcp/mcp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null; // 恢复真实网络（HttpServer 测试）
  });

  /// 假 MCP 服务：initialize + tools/list + tools/call。
  Future<HttpServer> startMcpServer() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        final method = body['method'] as String;
        Map<String, dynamic> result;
        if (method == 'initialize') {
          result = {
            'protocolVersion': '2025-03-26',
            'capabilities': {},
            'serverInfo': {'name': 'svc', 'version': '1.0'},
          };
        } else if (method == 'tools/list') {
          result = {
            'tools': [
              {
                'name': 'notes_save',
                'description': '保存笔记',
                'inputSchema': {
                  'type': 'object',
                  'properties': {'title': {'type': 'string'}},
                },
              },
            ],
          };
        } else if (method == 'tools/call') {
          result = {
            'content': [
              {'type': 'text', 'text': 'saved'},
            ],
          };
        } else {
          result = {};
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': result}),
        );
      } catch (_) {
        request.response.statusCode = 500;
      } finally {
        try {
          await request.response.close();
        } catch (_) {}
      }
    });
    addTearDown(() async {
      await server.close(force: true);
    });
    return server;
  }

  group('McpServerConfig', () {
    test('fromJson/toJson 往返（含 stdio/headers）', () {
      final config = McpServerConfig(
        id: 's1',
        name: '本地',
        url: 'stdio://s1',
        transport: 'stdio',
        headers: {'X-A': '1'},
        needsApproval: true,
        stdio: const StdioConfig(
          command: 'npx',
          args: ['-y', 'filesystem'],
          env: {'K': 'V'},
          cwd: 'C:/work',
        ),
      );
      final round = McpServerConfig.fromJson(config.toJson());
      expect(round.transport, 'stdio');
      expect(round.needsApproval, isTrue);
      expect(round.stdio?.command, 'npx');
      expect(round.stdio?.args, ['-y', 'filesystem']);
      expect(round.stdio?.cwd, 'C:/work');
      expect(round.headers['X-A'], '1');
    });

    test('fromJson 缺字段容错', () {
      final config = McpServerConfig.fromJson({'id': 'x'});
      expect(config.name, '');
      expect(config.url, '');
      expect(config.enabled, isTrue);
      expect(config.transport, 'http');
    });
  });

  group('McpService 持久化', () {
    test('load/save 往返；空/坏数据回退空列表', () async {
      final service = McpService();
      expect(await service.load(), isEmpty);

      await service.save([
        McpServerConfig(id: 'a', name: 'A', url: 'https://a/mcp'),
      ]);
      final loaded = await service.load();
      expect(loaded.single.id, 'a');

      SharedPreferences.setMockInitialValues({
        'mcp_servers': 'not-json{{',
      });
      expect(await service.load(), isEmpty);
    });
  });

  group('McpService.collectTools', () {
    test('命名空间 key + 跳过禁用服务 + 失败服务跳过', () async {
      final server = await startMcpServer();
      final service = McpService();
      final tools = await service.collectTools([
        McpServerConfig(id: 's1', name: '在线', url: 'http://127.0.0.1:${server.port}'),
        McpServerConfig(id: 's2', name: '禁用', url: 'https://x', enabled: false),
        McpServerConfig(id: 's3', name: '故障', url: 'http://127.0.0.1:1'),
      ]);
      expect(tools.keys, ['s1__notes_save']);
      expect(tools['s1__notes_save']?.name, 'notes_save');
    });

    test('stdio 配置不完整 → collectTools 跳过并返回空', () async {
      final service = McpService();
      final tools = await service.collectTools([
        McpServerConfig(id: 'st', name: 'x', url: 'stdio://st', transport: 'stdio'),
      ]);
      expect(tools, isEmpty);
    });
  });

  group('McpService.callTool', () {
    test('按原始名反查命名空间 key 并调用', () async {
      final server = await startMcpServer();
      final service = McpService();
      final servers = [
        McpServerConfig(id: 's1', name: '在线', url: 'http://127.0.0.1:${server.port}'),
      ];
      final tools = await service.collectTools(servers);
      final result = await service.callTool(
        servers,
        tools,
        'notes_save',
        {'title': 't'},
      );
      expect(result.content, contains('saved'));
      expect(result.isError, isFalse);
    });

    test('工具不存在 → McpException', () async {
      final service = McpService();
      expect(
        () => service.callTool(const [], const {}, 'ghost', {}),
        throwsA(isA<McpException>()),
      );
    });

    test('非法命名空间 key → McpException', () async {
      final service = McpService();
      final tools = {
        'bad-key': const McpToolDefinition(
          name: 'x',
          description: '',
          inputSchema: null,
        ),
      };
      expect(
        () => service.callTool(const [], tools, 'x', {}),
        throwsA(isA<McpException>()),
      );
    });

    test('serverId 不在配置中 → McpException', () async {
      final service = McpService();
      final tools = {
        'gone__tool': const McpToolDefinition(
          name: 'tool',
          description: '',
          inputSchema: null,
        ),
      };
      expect(
        () => service.callTool(const [], tools, 'tool', {}),
        throwsA(isA<McpException>()),
      );
    });
  });

  group('McpService.closeAll', () {
    test('空连接池可安全关闭', () async {
      final service = McpService();
      await service.closeAll();
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/services/mcp/approval_policy.dart';
import 'package:nona_chat/core/services/mcp/local_tools.dart';
import 'package:nona_chat/core/services/mcp/mcp_client.dart';
import 'package:nona_chat/core/services/mcp/mcp_service.dart';
import 'package:nona_chat/core/services/mcp/tool_loop.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  group('ApprovalPolicy', () {
    McpServerConfig server({bool needsApproval = true}) => McpServerConfig(
          id: 'srv1',
          name: 'srv1',
          url: 'http://127.0.0.1:1',
          needsApproval: needsApproval,
        );

    test('未配置策略时按 needsApproval ?? true 决定', () async {
      expect(await ApprovalPolicy.needsApproval(server(), 'tool_x'), isTrue);
      expect(
        await ApprovalPolicy.needsApproval(
          server(needsApproval: false),
          'tool_x',
        ),
        isTrue,
      );
    });

    test('记住后自动放行，可撤销', () async {
      final s = server();
      await ApprovalPolicy.remember('srv1', 'tool_x');
      expect(await ApprovalPolicy.needsApproval(s, 'tool_x'), isFalse);
      await ApprovalPolicy.forget('srv1', 'tool_x');
      expect(await ApprovalPolicy.needsApproval(s, 'tool_x'), isTrue);
    });

    test('auto 模式全部放行', () async {
      await ApprovalPolicy.setMode('srv1', ApprovalPolicy.modeAuto);
      expect(await ApprovalPolicy.needsApproval(server(), 'tool_x'), isFalse);
    });
  });

  group('ToolLoopRunner 审批路径', () {
    Future<HttpServer> startLoopServer() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        final messages = body['messages'] as List<dynamic>;
        final hasToolResult = messages.any(
          (m) => m is Map && m['role'] == 'tool',
        );
        request.response.headers
          ..contentType = ContentType.text
          ..set('Cache-Control', 'no-cache');
        if (!hasToolResult) {
          request.response.write(
            'data: {"choices":[{"delta":{"tool_calls":['
            '{"index":0,"id":"call_1","type":"function",'
            '"function":{"name":"get_weather","arguments":"{}"}}'
            ']}}]}\n\n'
            'data: [DONE]\n\n',
          );
        } else {
          request.response.write(
            'data: {"choices":[{"delta":{"content":"done"}}]}\n\n'
            'data: [DONE]\n\n',
          );
        }
        await request.response.close();
      });
      return server;
    }

    AppSettings settings(int port) => AppSettings(
          baseUrl: 'http://127.0.0.1:$port',
          apiKey: 'k',
          model: 'gpt-4o',
          providerKind: 'openai',
          chatAutoRetry: false,
        );

    test('自动放行（auto）不调用审批回调', () async {
      final server = await startLoopServer();
      var executed = false;
      var approvalCalls = 0;
      final result = await ToolLoopRunner.run(
        settings: settings(server.port),
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
        tools: [
          {
            'type': 'function',
            'function': {'name': 'get_weather', 'description': 'x'},
          },
        ],
        onApprovalRequired: (call) {
          approvalCalls++;
          return Future.value(const ApprovalDecision(allowed: true));
        },
        onToolCall: (call) async {
          executed = true;
          return const McpToolResult(content: 'ok');
        },
      );
      expect(result.content, 'done');
      expect(executed, isTrue);
      expect(approvalCalls, 1);
      await server.close(force: true);
    });

    test('拒绝后跳过执行并以 denied 回传模型', () async {
      final server = await startLoopServer();
      var executed = false;
      final result = await ToolLoopRunner.run(
        settings: settings(server.port),
        messages: [ChatMessage(role: 'user', content: 'hi')],
        options: const ChatOptions(),
        tools: [
          {
            'type': 'function',
            'function': {'name': 'get_weather', 'description': 'x'},
          },
        ],
        onApprovalRequired: (call) async => ApprovalDecision.deny,
        onToolCall: (call) async {
          executed = true;
          return const McpToolResult(content: 'ok');
        },
      );
      // 被拒绝后模型收到 denied 结果，进入第二轮并输出 done
      expect(result.content, 'done');
      expect(executed, isFalse);
      await server.close(force: true);
    });

    test('审批回调异常时按拒绝处理', () async {
      final server = await startLoopServer();
      await expectLater(
        ToolLoopRunner.run(
          settings: settings(server.port),
          messages: [ChatMessage(role: 'user', content: 'hi')],
          options: const ChatOptions(),
          tools: [
            {
              'type': 'function',
              'function': {'name': 'get_weather', 'description': 'x'},
            },
          ],
          onApprovalRequired: (call) async => throw Exception('dialog failed'),
          onToolCall: (call) async => const McpToolResult(content: 'ok'),
        ),
        throwsA(anything),
      );
      await server.close(force: true);
    });
  });

  group('LocalTools', () {
    test('注册表含全部内置工具', () {
      final names = LocalTools.all().map((t) => t.definition.name).toSet();
      expect(names, {
        'builtin__fetch',
        'builtin__time_info',
        'builtin__calculator',
        'builtin__clipboard',
        'builtin__memory_tool',
      });
    });

    test('calculator 正常求值与错误返回 isError', () async {
      final calc = LocalTools.find('builtin__calculator')!;
      final ok = await calc.handler({'expression': '1 + 2 * 3'});
      expect(ok.isError, isFalse);
      expect(ok.content, contains('7'));
      final bad = await calc.handler({'expression': '1 +'});
      expect(bad.isError, isTrue);
    });

    test('time_info 返回当前时间与时区', () async {
      final t = LocalTools.find('builtin__time_info')!;
      final result = await t.handler(const {});
      expect(result.isError, isFalse);
      expect(result.content, contains('date:'));
      expect(result.content, contains('timezone:'));
    });

    test('fetch 拒绝非 http(s) 与回环地址', () async {
      final fetch = LocalTools.find('builtin__fetch')!;
      final bad = await fetch.handler({'url': 'file:///etc/passwd'});
      expect(bad.isError, isTrue);
      expect(bad.content, contains('only http(s)'));
      final loopback = await fetch.handler({'url': 'http://localhost:8080/x'});
      expect(loopback.isError, isTrue);
      expect(loopback.content, contains('blocked'));
    });

    test('clipboard 读取空剪贴板（测试环境无插件，返回空）', () async {
      final cb = LocalTools.find('builtin__clipboard')!;
      final result = await cb.handler({'action': 'read'});
      expect(result.isError, isFalse);
      expect(result.content, contains('empty'));
    });
  });

  group('McpService.callTool 定位服务', () {
    test('按工具名反查 serverId 并调用', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final body = jsonDecode(raw) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': {
              'content': [
                {'type': 'text', 'text': 'echo-ok'},
              ],
            },
          }),
        );
        await request.response.close();
      });
      final config = McpServerConfig(
        id: 'svr',
        name: 'svr',
        url: 'http://127.0.0.1:${server.port}/mcp',
      );
      final tools = <String, McpToolDefinition>{
        'svr__do_thing': const McpToolDefinition(
          name: 'do_thing',
          description: 'x',
        ),
      };
      final result = await McpService().callTool(
        [config],
        tools,
        'do_thing',
        const {},
      );
      expect(result.content, 'echo-ok');
      await server.close(force: true);
    });
  });
}

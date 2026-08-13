import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/mcp/mcp_client.dart';
import 'package:nona_chat/core/services/mcp/mcp_service.dart';
import 'package:nona_chat/core/services/session_persistence.dart';
import 'package:nona_chat/core/services/session_service.dart';

/// 关键缺陷回归测试：工具消息过滤、工具名路由、持久化链自愈。
void main() {
  group('tool 消息持久化与过滤', () {
    test('hasSendableContent 包含工具调用消息', () {
      expect(
        ChatMessage(role: 'assistant', content: '', toolCallsJson: '[]')
            .hasSendableContent,
        isTrue,
      );
      expect(
        ChatMessage(role: 'tool', content: '', toolCallId: 'call_1')
            .hasSendableContent,
        isTrue,
      );
      expect(
        ChatMessage(role: 'assistant', content: '').hasSendableContent,
        isFalse,
      );
    });

    test('toApiJson 工具调用消息省略空 content', () {
      final json = ChatMessage(
        role: 'assistant',
        content: '',
        toolCallsJson: jsonEncode([
          {
            'id': 'call_1',
            'type': 'function',
            'function': {'name': 'get_weather', 'arguments': '{}'},
          },
        ]),
      ).toApiJson();
      expect(json.containsKey('content'), isFalse);
      expect(json['tool_calls'], isA<List<dynamic>>());
      expect(json['role'], 'assistant');
    });

    test('toApiJson 工具结果消息携带 tool_call_id', () {
      final json = ChatMessage(
        role: 'tool',
        content: '23℃',
        toolCallId: 'call_1',
      ).toApiJson();
      expect(json['tool_call_id'], 'call_1');
      expect(json['content'], '23℃');
    });

    test('toJson/fromJson 保留工具元数据', () {
      final m = ChatMessage(
        role: 'tool',
        content: '结果',
        toolCallId: 'call_1',
      );
      final restored = ChatMessage.fromJson(m.toJson());
      expect(restored.toolCallId, 'call_1');

      final assistant = ChatMessage(
        role: 'assistant',
        content: '',
        toolCallsJson: '[{"id":"call_1"}]',
      );
      final restored2 = ChatMessage.fromJson(assistant.toJson());
      expect(restored2.toolCallsJson, '[{"id":"call_1"}]');
    });

    test('会话复制保留工具/文档字段', () {
      final session = ChatSession(
        id: 's1',
        title: 't',
        messages: [
          ChatMessage(
            role: 'tool',
            content: 'r',
            toolCallId: 'c1',
          ),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final dup = session.duplicate();
      expect(dup.messages.first.toolCallId, 'c1');
    });
  });

  group('MCP 工具名路由', () {
    test('按原始名反查命名空间 key 并定位服务', () async {
      final tools = <String, McpToolDefinition>{
        'srv-a__get_weather': const McpToolDefinition(
          name: 'get_weather',
          description: 'd',
        ),
        'srv-b__search': const McpToolDefinition(
          name: 'search',
          description: 'd',
        ),
      };
      // 服务列表为空 → 应报「server not found srv-a」，
      // 而不是「invalid tool name format / tool not found」，证明路由正确
      await expectLater(
        McpService().callTool(const [], tools, 'get_weather', const {}),
        throwsA(isA<McpException>().having(
          (e) => e.message,
          'message',
          contains('server not found: srv-a'),
        )),
      );
    });

    test('未知工具名报工具不存在', () async {
      final tools = <String, McpToolDefinition>{
        'srv-a__get_weather': const McpToolDefinition(
          name: 'get_weather',
          description: 'd',
        ),
      };
      await expectLater(
        McpService().callTool(const [], tools, 'nope', const {}),
        throwsA(isA<McpException>().having(
          (e) => e.message,
          'message',
          contains('tool not found'),
        )),
      );
    });
  });

  group('持久化链自愈', () {
    test('一次写入失败后后续保存仍执行（链不中毒）', () async {
      var failNext = true;
      var writes = 0;
      final flaky = _FlakyPersistence(() {
        writes++;
        if (failNext) {
          failNext = false;
          throw Exception('disk full');
        }
      });
      final service = SessionService(persistence: flaky);

      await service.saveAll([]); // 第一次：失败
      await service.saveAll([]); // 第二次：应正常执行
      expect(writes, 2);
    });
  });
}

class _FlakyPersistence implements SessionPersistence {
  final void Function() onWrite;

  _FlakyPersistence(this.onWrite);

  @override
  Future<void> deleteSession(String id) async {
    onWrite();
  }

  @override
  Future<List<ChatSession>?> readAll() async => null;

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    onWrite();
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    onWrite();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/agent.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/models/network_log.dart';

void main() {
  group('ChatMessage', () {
    test('toJson -> fromJson 完整往返', () {
      final original = ChatMessage(
        role: 'assistant',
        content: '你好',
        reasoningContent: '思考中',
        interrupted: true,
        failed: false,
        promptTokens: 100,
        completionTokens: 50,
        elapsedMs: 1200,
        providerName: 'OpenAI',
        modelId: 'gpt-4o-mini',
      );
      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.role, 'assistant');
      expect(restored.content, '你好');
      expect(restored.reasoningContent, '思考中');
      expect(restored.interrupted, isTrue);
      expect(restored.failed, isFalse);
      expect(restored.promptTokens, 100);
      expect(restored.completionTokens, 50);
      expect(restored.elapsedMs, 1200);
      expect(restored.providerName, 'OpenAI');
      expect(restored.modelId, 'gpt-4o-mini');
    });

    test('缺失字段时使用默认值', () {
      final restored = ChatMessage.fromJson({
        'role': 'user',
        'content': 'hi',
      });
      expect(restored.reasoningContent, '');
      expect(restored.interrupted, isFalse);
      expect(restored.failed, isFalse);
      expect(restored.promptTokens, isNull);
      expect(restored.modelId, isNull);
    });

    test('toApiJson 只包含 role 与 content', () {
      final msg = ChatMessage(role: 'system', content: '规则');
      expect(msg.toApiJson(), {'role': 'system', 'content': '规则'});
    });
  });

  group('ChatOptions', () {
    test('toJson -> fromJson 完整往返（含空值字段）', () {
      final original = const ChatOptions(
        systemPrompt: '你是助手',
        temperature: 0.7,
        topP: 0.9,
        maxTokens: 2048,
        presencePenalty: -0.5,
        frequencyPenalty: 0.3,
        n: 2,
        stop: ['\n\n', '###'],
        seed: 42,
        responseFormat: 'json_object',
        reasoningEffort: 'high',
        stream: false,
        maxContextTokens: 16000,
        autoTrim: false,
      );
      final restored = ChatOptions.fromJson(original.toJson());
      expect(restored.systemPrompt, '你是助手');
      expect(restored.temperature, 0.7);
      expect(restored.topP, 0.9);
      expect(restored.maxTokens, 2048);
      expect(restored.presencePenalty, -0.5);
      expect(restored.frequencyPenalty, 0.3);
      expect(restored.n, 2);
      expect(restored.stop, ['\n\n', '###']);
      expect(restored.seed, 42);
      expect(restored.responseFormat, 'json_object');
      expect(restored.reasoningEffort, 'high');
      expect(restored.stream, isFalse);
      expect(restored.maxContextTokens, 16000);
      expect(restored.autoTrim, isFalse);
    });

    test('null 或缺失 json 返回默认值', () {
      expect(ChatOptions.fromJson(null), const ChatOptions());
      final restored = ChatOptions.fromJson(const {});
      expect(restored.temperature, 1.0);
      expect(restored.topP, 1.0);
      expect(restored.stream, isTrue);
      expect(restored.autoTrim, isTrue);
      expect(restored.stop, isEmpty);
    });

    test('copyWith 可将字段清空为 null', () {
      const base = ChatOptions(maxTokens: 100, seed: 1, responseFormat: 'text');
      final cleared = base.copyWith(maxTokens: null, seed: null, responseFormat: null);
      expect(cleared.maxTokens, isNull);
      expect(cleared.seed, isNull);
      expect(cleared.responseFormat, isNull);
      expect(cleared.temperature, 1.0);
    });
  });

  group('ChatSession', () {
    ChatMessage assistant({String content = '回复'}) => ChatMessage(
          role: 'assistant',
          content: content,
          reasoningContent: '理由',
          interrupted: false,
          failed: false,
          promptTokens: 10,
          completionTokens: 5,
          elapsedMs: 100,
          providerName: 'P',
          modelId: 'm1',
        );

    test('toJson -> fromJson 完整往返', () {
      final original = ChatSession(
        id: 's1',
        title: '会话',
        options: const ChatOptions(systemPrompt: 'x', stream: false),
        agentId: 'a1',
        providerId: 'p1',
        modelId: 'm1',
        messages: [
          ChatMessage(role: 'user', content: '问题'),
          assistant(),
        ],
        createdAt: DateTime(2024, 1, 1, 12, 0),
        updatedAt: DateTime(2024, 1, 2, 8, 30),
        pinned: true,
      );
      final restored = ChatSession.fromJson(original.toJson());
      expect(restored.id, 's1');
      expect(restored.title, '会话');
      expect(restored.agentId, 'a1');
      expect(restored.providerId, 'p1');
      expect(restored.modelId, 'm1');
      expect(restored.pinned, isTrue);
      expect(restored.messages, hasLength(2));
      expect(restored.messages[1].reasoningContent, '理由');
      expect(restored.messages[1].promptTokens, 10);
      expect(restored.options.stream, isFalse);
      expect(restored.createdAt, DateTime(2024, 1, 1, 12, 0));
      expect(restored.updatedAt, DateTime(2024, 1, 2, 8, 30));
    });

    test('create 生成空会话', () {
      final session = ChatSession.create();
      expect(session.title, 'New chat');
      expect(session.messages, isEmpty);
      expect(session.pinned, isFalse);
    });

    test('updateTitleFromFirstMessage 取第一条用户消息并截断', () {
      final session = ChatSession.create();
      session.messages.add(ChatMessage(role: 'assistant', content: '先回答'));
      session.messages.add(ChatMessage(role: 'user', content: '这是一个非常长的用户问题，超过二十个字的长度限制'));
      session.updateTitleFromFirstMessage();
      expect(session.title.length, 21);
      expect(session.title, endsWith('…'));

      final short = ChatSession.create()
        ..messages.add(ChatMessage(role: 'user', content: 'hi\nthere'));
      short.updateTitleFromFirstMessage();
      expect(short.title, 'hi there');

      final empty = ChatSession.create();
      empty.updateTitleFromFirstMessage();
      expect(empty.title, 'New chat');
    });

    test('duplicate 生成新 id 与「副本」后缀并复制消息', () {
      final session = ChatSession(
        id: 's1',
        title: '标题',
        messages: [assistant(content: '正文')],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final dup = session.duplicate();
      expect(dup.id, isNot(session.id));
      expect(dup.title, '标题 (copy)');
      expect(dup.messages, hasLength(1));
      expect(dup.messages.first.content, '正文');
      expect(identical(dup.messages.first, session.messages.first), isFalse);
      expect(dup.messages.first.providerName, 'P');
    });

    test('truncateMessagesFrom 删除指定索引及之后的消息', () {
      final session = ChatSession.create()
        ..messages.addAll([
          ChatMessage(role: 'user', content: 'a'),
          ChatMessage(role: 'assistant', content: 'b'),
          ChatMessage(role: 'user', content: 'c'),
        ]);
      session.truncateMessagesFrom(1);
      expect(session.messages, hasLength(1));
      expect(session.messages.first.content, 'a');

      session.truncateMessagesFrom(5);
      expect(session.messages, hasLength(1));

      session.truncateMessagesFrom(-1);
      expect(session.messages, hasLength(1));
    });
  });

  group('ChatProvider / ModelConfig', () {
    test('toJson -> fromJson 往返，含 modelConfigs', () {
      final original = ChatProvider(
        id: 'p1',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-123',
        modelIds: ['gpt-4o', 'o1'],
        modelConfigs: const {
          'gpt-4o': ModelConfig(multimodal: true),
          'o1': ModelConfig(reasoning: true),
        },
      );
      final restored = ChatProvider.fromJson(original.toJson());
      expect(restored.id, 'p1');
      expect(restored.name, 'OpenAI');
      expect(restored.baseUrl, 'https://api.openai.com/v1');
      expect(restored.apiKey, 'sk-123');
      expect(restored.modelIds, ['gpt-4o', 'o1']);
      expect(restored.modelConfigs['gpt-4o']?.multimodal, isTrue);
      expect(restored.modelConfigs['o1']?.reasoning, isTrue);
    });

    test('fromJson 缺失字段回退默认值', () {
      final restored = ChatProvider.fromJson({'id': 'x'});
      expect(restored.name, 'Unnamed');
      expect(restored.baseUrl, 'https://api.openai.com/v1');
      expect(restored.apiKey, '');
      expect(restored.modelIds, isEmpty);
    });

    test('ModelConfig.copyWith', () {
      const c = ModelConfig(multimodal: true);
      final r = c.copyWith(reasoning: true);
      expect(r.multimodal, isTrue);
      expect(r.reasoning, isTrue);
      final same = c.copyWith();
      expect(same.multimodal, isTrue);
      expect(same.reasoning, isFalse);
    });
  });

  group('Agent', () {
    test('toJson -> fromJson 往返', () {
      final original = Agent(
        id: 'a1',
        name: 'Nona',
        options: const ChatOptions(systemPrompt: '你是 Nona'),
        isDefault: true,
      );
      final restored = Agent.fromJson(original.toJson());
      expect(restored.id, 'a1');
      expect(restored.name, 'Nona');
      expect(restored.isDefault, isTrue);
      expect(restored.options.systemPrompt, '你是 Nona');
    });

    test('fromJson 缺失字段回退默认值', () {
      final restored = Agent.fromJson({'id': 'a2'});
      expect(restored.name, 'Unnamed');
      expect(restored.isDefault, isFalse);
      expect(restored.options, const ChatOptions());
    });
  });

  group('NetworkLog', () {
    NetworkLog build({
      int? statusCode = 200,
      String? error,
      NetworkLogType type = NetworkLogType.chat,
    }) {
      return NetworkLog(
        id: 'l1',
        time: DateTime(2024, 5, 1, 10, 0),
        method: 'POST',
        url: 'https://x/v1/chat/completions',
        statusCode: statusCode,
        durationMs: 123,
        requestBytes: 10,
        responseBytes: 20,
        requestHeaders: const {'Content-Type': 'application/json'},
        requestBody: '{"a":1}',
        responseHeaders: const {'Server': 'nginx'},
        responseBody: 'ok',
        error: error,
        type: type,
      );
    }

    test('toJson -> fromJson 往返', () {
      final restored = NetworkLog.fromJson(build().toJson());
      expect(restored.id, 'l1');
      expect(restored.time, DateTime(2024, 5, 1, 10, 0));
      expect(restored.method, 'POST');
      expect(restored.statusCode, 200);
      expect(restored.durationMs, 123);
      expect(restored.requestBytes, 10);
      expect(restored.responseBytes, 20);
      expect(restored.requestHeaders['Content-Type'], 'application/json');
      expect(restored.responseHeaders['Server'], 'nginx');
      expect(restored.requestBody, '{"a":1}');
      expect(restored.type, NetworkLogType.chat);
    });

    test('isSuccess：2xx/3xx 成功，错误/5xx/网络失败不成功', () {
      expect(build().isSuccess, isTrue);
      expect(build(statusCode: 302).isSuccess, isTrue);
      expect(build(statusCode: 404).isSuccess, isFalse);
      expect(build(statusCode: 500).isSuccess, isFalse);
      expect(build(error: '网络错误').isSuccess, isFalse);
      expect(build(statusCode: null, error: '超时').isSuccess, isFalse);
    });

    test('未知 type 回退为 other', () {
      final json = build().toJson()..['type'] = 'unknown';
      final restored = NetworkLog.fromJson(json);
      expect(restored.type, NetworkLogType.other);
    });

    test('type label 展示', () {
      expect(NetworkLogType.chat.label, 'chat');
      expect(NetworkLogType.test.label, 'test');
      expect(NetworkLogType.models.label, 'models');
      expect(NetworkLogType.capability.label, 'capability');
      expect(NetworkLogType.other.label, 'other');
    });
  });
}

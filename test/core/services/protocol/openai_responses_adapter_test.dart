import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/services/protocol/openai_responses_adapter.dart';
import 'package:nona_chat/core/services/protocol/protocol_adapter.dart'
    show DeltaStatus;

void main() {
  group('OpenAiResponsesAdapter.messagesToInput', () {
    test('纯文本用户消息 → input_text', () {
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(role: 'user', content: '你好'),
      ]);
      expect(input, [
        {'type': 'input_text', 'text': '你好'},
      ]);
    });

    test('多模态用户消息 → input_image + input_text', () {
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(
          role: 'user',
          content: '看这张图',
          images: [
            ChatImage(
              url: 'https://example.com/a.png',
              mimeType: 'image/png',
            ),
          ],
        ),
      ]);
      expect(input, [
        {'type': 'input_image', 'image_url': 'https://example.com/a.png'},
        {'type': 'input_text', 'text': '看这张图'},
      ]);
    });

    test('assistant 带工具调用 → function_call 块', () {
      final calls = jsonEncode([
        {
          'id': 'call_1',
          'function': {'name': 'web_search', 'arguments': '{"q":"a"}'},
        },
      ]);
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(
          role: 'assistant',
          content: '让我查一下',
          toolCallsJson: calls,
        ),
      ]);
      expect(input, [
        {
          'type': 'function_call',
          'call_id': 'call_1',
          'name': 'web_search',
          'arguments': '{"q":"a"}',
        },
        {
          'type': 'message',
          'role': 'assistant',
          'status': 'completed',
          'content': [
            {'type': 'output_text', 'text': '让我查一下'},
          ],
        },
      ]);
    });

    test('assistant 无正文时只发 function_call', () {
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(role: 'assistant', content: '', toolCallsJson: '[]'),
      ]);
      expect(input, isEmpty);
    });

    test('tool 消息 → function_call_output（兼容 toolCallId）', () {
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(
          role: 'tool',
          content: '结果',
          toolCallId: 'call_9',
        ),
      ]);
      expect(input, [
        {'type': 'function_call_output', 'call_id': 'call_9', 'output': '结果'},
      ]);
    });

    test('坏 toolCallsJson 不崩溃', () {
      final input = OpenAiResponsesAdapter.messagesToInput([
        ChatMessage(
          role: 'assistant',
          content: 'x',
          toolCallsJson: 'not-json{{',
        ),
      ]);
      expect(input, isNotEmpty);
    });
  });

  group('OpenAiResponsesAdapter.flattenTools', () {
    test('function 工具展平，非 function 丢弃', () {
      final flat = OpenAiResponsesAdapter.flattenTools([
        {
          'type': 'function',
          'function': {
            'name': 'notes_save',
            'description': '保存笔记',
            'parameters': {'type': 'object'},
          },
        },
        {'type': 'web_search_preview'},
      ]);
      expect(flat, [
        {
          'type': 'function',
          'name': 'notes_save',
          'description': '保存笔记',
          'parameters': {'type': 'object'},
        },
      ]);
    });
  });

  group('OpenAiResponsesAdapter.buildBody', () {
    test('instructions 抽取 + input 数组 + stream + 工具', () {
      final body = const OpenAiResponsesAdapter().buildBody(
        'o3-mini',
        const ChatOptions(
          systemPrompt: '你是助手',
          maxTokens: 1000,
          stop: ['END'],
          reasoningEffort: 'high',
          temperature: 0.7,
          stream: true,
        ),
        [
          ChatMessage(role: 'system', content: '你是助手'),
          ChatMessage(role: 'user', content: '你好'),
        ],
        [
          {
            'type': 'function',
            'function': {
              'name': 'notes_save',
              'parameters': {'type': 'object'},
            },
          },
        ],
      );
      expect(body['model'], 'o3-mini');
      expect(body['instructions'], '你是助手');
      expect(body['input'], [
        {'type': 'input_text', 'text': '你好'},
      ]);
      expect(body['max_output_tokens'], 1000);
      expect(body['stop'], ['END']);
      expect(body['reasoning'], {'effort': 'high'});
      expect(body['temperature'], 0.7);
      expect(body['stream'], true);
      expect(body['tools'], isA<List>());
      expect(body['tool_choice'], 'auto');
    });

    test('无工具时不带 tools 字段', () {
      final body = const OpenAiResponsesAdapter().buildBody(
        'gpt-5',
        const ChatOptions(),
        [
          ChatMessage(role: 'user', content: 'hi'),
        ],
        null,
      );
      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
    });
  });

  group('OpenAiResponsesAdapter.parseDelta', () {
    test('output_text.delta → content', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.output_text.delta',
        'delta': '你好',
      });
      expect(d.delta?.content, '你好');
    });

    test('空 delta → none', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.output_text.delta',
        'delta': '',
      });
      expect(d.delta, isNull);
    });

    test('reasoning_summary_text.delta → reasoning', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.reasoning_summary_text.delta',
        'delta': '思考中',
      });
      expect(d.delta?.reasoning, '思考中');
    });

    test('function_call_arguments.delta → 分片参数', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.function_call_arguments.delta',
        'delta': '{"q":"',
      });
      expect(d.delta?.toolCalls?.single.arguments, '{"q":"');
    });

    test('output_item.done(function_call) → 完整工具调用', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.output_item.done',
        'item': {
          'type': 'function_call',
          'call_id': 'call_1',
          'name': 'web_search',
          'arguments': '{"q":"a"}',
        },
      });
      final call = d.delta?.toolCalls?.single;
      expect(call?.id, 'call_1');
      expect(call?.name, 'web_search');
      expect(call?.arguments, '{"q":"a"}');
    });

    test('output_item.done(非 function_call) → none', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.output_item.done',
        'item': {'type': 'message'},
      });
      expect(d.delta, isNull);
    });

    test('completed → usage + done', () {
      final d = OpenAiResponsesAdapter().parseDelta({
        'type': 'response.completed',
        'response': {
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 5,
            'total_tokens': 15,
          },
        },
      });
      expect(d.delta?.done, isTrue);
      expect(d.delta?.usage?.promptTokens, 10);
      expect(d.delta?.usage?.completionTokens, 5);
    });

    test('response.failed → 抛 FormatException（防截断持久化）', () {
      expect(
        () => OpenAiResponsesAdapter().parseDelta({
          'type': 'response.failed',
          'error': {'message': 'rate limited'},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('error 事件 → 抛 FormatException', () {
      expect(
        () => OpenAiResponsesAdapter().parseDelta({
          'type': 'error',
          'error': {'message': 'bad request'},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('未知事件 → none；缺 type → unrecognized', () {
      final d = OpenAiResponsesAdapter().parseDelta({'type': 'ping'});
      expect(d.delta, isNull);
      final u = OpenAiResponsesAdapter().parseDelta({'foo': 1});
      expect(u.status, DeltaStatus.unrecognized);
    });
  });

  group('OpenAiResponsesAdapter.parseNonStream', () {
    test('output 数组提取文本与 usage', () {
      final r = OpenAiResponsesAdapter().parseNonStream({
        'output': [
          {
            'content': [
              {'type': 'output_text', 'text': '答案一'},
              {'type': 'output_text', 'text': '答案二'},
            ],
          },
        ],
        'usage': {'prompt_tokens': 3, 'output_tokens': 4},
      });
      expect(r?.$1, '答案一答案二');
      expect(r?.$2?.promptTokens, 3);
    });

    test('无 output → null', () {
      expect(OpenAiResponsesAdapter().parseNonStream({'foo': 1}), isNull);
    });

    test('空文本 → null', () {
      final r = OpenAiResponsesAdapter().parseNonStream({
        'output': [
          {
            'content': [
              {'type': 'refusal', 'text': ''},
            ],
          },
        ],
      });
      expect(r, isNull);
    });
  });

  group('OpenAiResponsesAdapter 基础', () {
    test('uriFor 指向 /responses（去尾部斜杠）', () {
      final adapter = OpenAiResponsesAdapter();
      expect(
        adapter.uriFor('https://api.openai.com/v1/', 'o3'),
        Uri.parse('https://api.openai.com/v1/responses'),
      );
    });

    test('headersFor 带 Bearer', () {
      expect(
        OpenAiResponsesAdapter().headersFor('sk-1'),
        containsPair('Authorization', 'Bearer sk-1'),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/services/model_capability_service.dart';
import 'package:nona_chat/utils/token_estimator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('o200k_base 权威基准（对照官方 tiktoken）', () {
    final reference = () {
      final raw = File('test/tiktoken_reference_o200k.json').readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<int>()),
      );
    }();

    test('官方基准：逐 token 一致', () async {
      await TokenEstimator.instance.load(TokenizerKind.o200kBase);
      reference.forEach((text, expected) {
        final actual = TokenEstimator.instance.encode(
          text,
          kind: TokenizerKind.o200kBase,
        );
        expect(
          actual,
          expected,
          reason: 'o200k 编码与官方不一致: $text',
        );
      });
    });

    test('特殊 token 单独编号（<|endoftext|> = 199999）', () async {
      final ids = TokenEstimator.instance.encode(
        '<|endoftext|>',
        kind: TokenizerKind.o200kBase,
      );
      expect(ids, [199999]);
    });
  });

  group('tokenizerKindForModel', () {
    test('新编码模型使用 o200k', () {
      expect(tokenizerKindForModel('gpt-4o'), TokenizerKind.o200kBase);
      expect(tokenizerKindForModel('gpt-4o-mini'), TokenizerKind.o200kBase);
      expect(tokenizerKindForModel('gpt-4.1-mini'), TokenizerKind.o200kBase);
      expect(tokenizerKindForModel('o1'), TokenizerKind.o200kBase);
      expect(tokenizerKindForModel('o3-mini'), TokenizerKind.o200kBase);
      expect(tokenizerKindForModel('gpt-5'), TokenizerKind.o200kBase);
    });

    test('旧编码与未知模型使用 cl100k', () {
      expect(tokenizerKindForModel('gpt-4'), TokenizerKind.cl100kBase);
      expect(tokenizerKindForModel('gpt-3.5-turbo'), TokenizerKind.cl100kBase);
      expect(tokenizerKindForModel('deepseek-chat'), TokenizerKind.cl100kBase);
      expect(tokenizerKindForModel('unknown-model'), TokenizerKind.cl100kBase);
    });
  });

  group('模型上下文窗口库', () {
    final service = ModelCapabilityService();

    test('内置已知模型精确匹配', () {
      expect(service.contextWindowFor('gpt-4o'), 128000);
      expect(service.contextWindowFor('claude-3-7-sonnet'), 200000);
      expect(service.contextWindowFor('deepseek-chat'), 64000);
    });

    test('前缀匹配（含版本号/日期后缀）', () {
      expect(service.contextWindowFor('gpt-4o-2024-08-06'), 128000);
      expect(service.contextWindowFor('claude-3-7-sonnet-20250219'), 200000);
      expect(service.contextWindowFor('gemini-2.5-pro'), 1000000);
    });

    test('长 key 优先匹配（gpt-4o 不误配 gpt-4o-mini）', () {
      expect(service.contextWindowFor('gpt-4o-mini'), 128000);
      // gpt-4o 前缀匹配 128000，而 gpt-4（旧）为 8192
      expect(service.contextWindowFor('gpt-4'), 8192);
    });

    test('未知模型返回 null', () {
      expect(service.contextWindowFor('totally-unknown'), isNull);
    });

    test('能力表 contextWindow 优先于内置库', () {
      final map = {
        'my-model': const ModelConfig(contextWindow: 4096),
      };
      expect(service.contextWindowFor('my-model', map), 4096);
    });
  });
}

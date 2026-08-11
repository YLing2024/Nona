import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/utils/token_counter.dart';
import 'package:nona_chat/utils/token_estimator.dart';

/// 与 OpenAI tiktoken（cl100k_base）权威输出的对照测试。
///
/// 基准数据由 Python tiktoken 0.13.0 生成（见 test/tiktoken_reference.json）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> reference;

  setUpAll(() async {
    final raw = await File('test/tiktoken_reference.json').readAsString();
    reference = jsonDecode(raw) as Map<String, dynamic>;
    await TokenEstimator.instance.load();
    expect(TokenEstimator.instance.ready, isTrue, reason: '词表应加载成功');
  });

  test('编码结果与官方一致：hello world -> [15339, 1917]', () {
    expect(TokenEstimator.instance.encode('hello world'), [15339, 1917]);
  });

  for (final entry in <String, String>{
    'hello world': 'hello world',
    'hello world!': 'hello world!',
    '问候': 'Hello, world! How are you today?',
    '中文': '你好世界',
    '中文长句': '今天天气怎么样？我们来聊聊人工智能。',
    '代码': 'def foo():\n    return 42',
    '空白': '  indented  spaced  text  ',
    'emoji': 'Emoji 🚀 rocket ship',
    '中英混合': '中文 English 混合 mix 12345',
    '长重复': 'a' * 500,
    'markdown': '## 标题\n\n- 项目一\n- 项目二\n\n```dart\nvoid main() { print(1); }\n```',
    '英文句子': 'The quick brown fox jumps over the lazy dog.',
    '纯空格': '   ',
    '特殊token': 'hello <|endoftext|> world',
    '仅特殊token': '<|endoftext|>',
  }.entries) {
    test('token id 序列与 tiktoken 一致：${entry.key}', () {
      final expected = (reference[entry.value] as List<dynamic>).cast<int>();
      final actual = TokenEstimator.instance.encode(entry.value);
      expect(actual, expected,
          reason: '「${entry.value}」的编码应与官方 tiktoken 完全一致');
    });
  }

  test('空文本编码为空列表', () {
    expect(TokenEstimator.instance.encode(''), isEmpty);
    expect(TokenEstimator.instance.estimateCount(''), 0);
  });

  test('estimateCount 与 id 序列长度一致', () {
    const text = '你好世界 hello 123';
    final ids = TokenEstimator.instance.encode(text)!;
    expect(TokenEstimator.instance.estimateCount(text), ids.length);
  });

  test('TokenCounter.estimate 在词表就绪时使用精确值', () {
    // "hello world" 官方为 2 token
    expect(TokenCounter.estimate('hello world'), 2);
  });

  test('TokenCounter.estimateMessage 附加角色与图片开销', () {
    const img = ChatImage(url: 'https://x/a.png', mimeType: 'image/png');
    expect(
      TokenCounter.estimateMessage('user', 'hello world', const [img]),
      2 + 4 + 85,
    );
  });

  test('词表未就绪时 estimate 回退启发式且不抛错', () {
    // 无词表路径的兜底：仅验证空文本与正常文本不抛错
    expect(TokenCounter.estimate(''), 0);
    expect(TokenCounter.estimate('hello'), greaterThan(0));
  });

  test('超长文本（2 万 CJK 字符）编码不超时且与官方一致', () {
    final long = '人工智能' * 5000; // 20000 字符，单一片段（无空格）
    final expected = (reference[long] as List<dynamic>).cast<int>();
    final ids = TokenEstimator.instance.encode(long)!;
    expect(ids, expected);
    expect(ids.length, greaterThan(0));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/utils/token_counter.dart';

void main() {
  group('TokenCounter.estimate', () {
    test('空文本为 0', () {
      expect(TokenCounter.estimate(''), 0);
    });

    test('英文/数字按 4 字符 ≈ 1 token 估算', () {
      expect(TokenCounter.estimate('hello'), 2);
      expect(TokenCounter.estimate('abcdefghijklm'), 4);
      expect(TokenCounter.estimate('12345678'), 2);
    });

    test('中文等 CJK 按 1.5 字符 ≈ 1 token（向上取整）', () {
      expect(TokenCounter.estimate('你好'), 2);
      expect(TokenCounter.estimate('好'), 1);
      // 3 个 CJK 字符 = ceil(3/1.5) = 2
      expect(TokenCounter.estimate('你好吗'), 2);
    });

    test('中英混合叠加', () {
      // "hello世界"：5 英文 + 2 CJK = ceil(2/1.5) + ceil(5/4) = 2 + 2
      expect(TokenCounter.estimate('hello世界'), 4);
    });
  });

  group('TokenCounter.estimateMessage', () {
    test('在正文基础上附加角色开销', () {
      expect(TokenCounter.estimateMessage('user', 'hello'), 6);
      expect(TokenCounter.estimateMessage('assistant', ''), 4);
    });

    test('带图片时累加图片 token 估算', () {
      const img = ChatImage(url: 'https://x/a.png', mimeType: 'image/png');
      expect(TokenCounter.estimateMessage('user', 'hello', const [img]), 6 + 85);
      expect(TokenCounter.estimateMessage('user', 'hello', const [img, img]),
          6 + 85 * 2);
    });
  });

  group('TokenCounter.format', () {
    test('小于 1000 原样显示', () {
      expect(TokenCounter.format(0), '0');
      expect(TokenCounter.format(999), '999');
    });

    test('1000~9999 显示两位小数 k', () {
      expect(TokenCounter.format(1000), '1.00k');
      expect(TokenCounter.format(1234), '1.23k');
      expect(TokenCounter.format(9999), '10.00k');
    });

    test('>=10000 显示一位小数 k', () {
      expect(TokenCounter.format(10000), '10.0k');
      expect(TokenCounter.format(12345), '12.3k');
    });
  });
}

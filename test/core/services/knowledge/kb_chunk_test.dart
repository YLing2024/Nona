import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/knowledge_base_service.dart';

void main() {
  group('KnowledgeBaseService.chunkText 分块边界', () {
    test('空文本与短文本', () {
      expect(KnowledgeBaseService.chunkText(''), isEmpty);
      expect(KnowledgeBaseService.chunkText('短文本'), ['短文本']);
      final long = List.filled(800, '字').join();
      expect(KnowledgeBaseService.chunkText(long), hasLength(1));
    });

    test('标题行作为分块边界', () {
      final text = [
        '# 第一章',
        List.filled(800, '甲').join(),
        '# 第二章',
        List.filled(800, '乙').join(),
      ].join('\n');
      final chunks = KnowledgeBaseService.chunkText(text);
      expect(chunks.length, greaterThanOrEqualTo(2));
      expect(chunks.any((c) => c.contains('第一章')), isTrue);
      expect(chunks.any((c) => c.contains('第二章')), isTrue);
    });

    test('超长文本在句边界断块且不丢内容', () {
      final sentence = '第一句话。第二句话！第三句话？';
      final long = List.filled(200, sentence).join();
      final chunks = KnowledgeBaseService.chunkText(long);
      expect(chunks.length, greaterThan(1));
      final joined = chunks.join();
      // 内容不丢失（断块保留全部字符）
      expect(joined.replaceAll(RegExp(r'\s+'), '').length,
          long.replaceAll(RegExp(r'\s+'), '').length);
    });
  });
}

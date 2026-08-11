import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/models/chat_message.dart';

void main() {
  group('ChatImage', () {
    test('Data URL 构造器解析 MIME', () {
      final img = ChatImage.fromDataUrl(
        'data:image/png;base64,iVBORw0KGgo=',
      );
      expect(img.mimeType, 'image/png');
      expect(img.isDataUrl, isTrue);
      expect(img.isNetwork, isFalse);
    });

    test('网络图 URL', () {
      const img = ChatImage(url: 'https://x.com/a.png', mimeType: 'image/*');
      expect(img.isNetwork, isTrue);
      expect(img.isDataUrl, isFalse);
    });

    test('estimatedTokens：网络图固定 85', () {
      const img = ChatImage(url: 'https://x.com/a.png', mimeType: 'image/*');
      expect(img.estimatedTokens, 85);
    });

    test('estimatedTokens：Data URL 随体积增长', () {
      // base64 字符长度 → 字节数估算
      final small = ChatImage.fromDataUrl(
        'data:image/png;base64,${'A' * 100}',
      );
      final large = ChatImage.fromDataUrl(
        'data:image/png;base64,${'A' * 20000}',
      );
      expect(small.estimatedTokens, 85);
      expect(large.estimatedTokens, greaterThan(85));
    });

    test('toJson -> fromJson 往返', () {
      const img = ChatImage(url: 'https://x/a.png', mimeType: 'image/png');
      final restored = ChatImage.fromJson(img.toJson());
      expect(restored.url, 'https://x/a.png');
      expect(restored.mimeType, 'image/png');
    });
  });

  group('ChatMessage 图片消息', () {
    test('无图片时 toApiJson 保持纯文本 content', () {
      final msg = ChatMessage(role: 'user', content: 'hi');
      expect(msg.toApiJson(), {'role': 'user', 'content': 'hi'});
    });

    test('有图片时输出 content 数组（多模态）', () {
      final msg = ChatMessage(
        role: 'user',
        content: '看看这张图',
        images: const [
          ChatImage(url: 'data:image/png;base64,xxx', mimeType: 'image/png'),
        ],
      );
      final json = msg.toApiJson();
      expect(json['role'], 'user');
      final content = json['content'] as List<dynamic>;
      expect(content, hasLength(2));
      expect(content[0], {
        'type': 'text',
        'text': '看看这张图',
      });
      expect(content[1], {
        'type': 'image_url',
        'image_url': {'url': 'data:image/png;base64,xxx'},
      });
    });

    test('纯图片消息（正文为空）content 数组不含 text 部分', () {
      final msg = ChatMessage(
        role: 'user',
        content: '  ',
        images: const [
          ChatImage(url: 'https://x/a.png', mimeType: 'image/png'),
        ],
      );
      final json = msg.toApiJson();
      final content = json['content'] as List<dynamic>;
      expect(content, hasLength(1));
      expect(content[0]['type'], 'image_url');
    });

    test('hasSendableContent：图片消息即使正文为空也算可发送', () {
      expect(
        ChatMessage(role: 'user', content: '', images: const [
          ChatImage(url: 'https://x/a.png', mimeType: 'image/png'),
        ]).hasSendableContent,
        isTrue,
      );
      expect(ChatMessage(role: 'user', content: '   ').hasSendableContent,
          isFalse);
    });

    test('toJson -> fromJson 完整往返含图片', () {
      final original = ChatMessage(
        role: 'user',
        content: '附图',
        images: const [
          ChatImage(url: 'data:image/png;base64,abc', mimeType: 'image/png'),
        ],
      );
      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.content, '附图');
      expect(restored.images, hasLength(1));
      expect(restored.images.first.url, 'data:image/png;base64,abc');
      expect(restored.images.first.mimeType, 'image/png');
    });

    test('旧数据无 images 字段时回退空列表', () {
      final restored = ChatMessage.fromJson({
        'role': 'user',
        'content': 'hi',
      });
      expect(restored.images, isEmpty);
    });
  });
}

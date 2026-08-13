import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/services/chat_protocol.dart';
import 'package:nona_chat/core/services/provider_share_codec.dart';

void main() {
  ChatProvider makeProvider({
    String kind = 'openai',
    bool withHeaders = true,
    bool withBody = true,
    bool withConfigs = true,
  }) {
    return ChatProvider(
      id: 'p1',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'sk-test-123',
      kind: ProviderKind.fromName(kind),
      customHeaders: withHeaders
          ? {'X-Custom': 'v1', 'X-Other': 'v2'}
          : const {},
      customBody: withBody
          ? {'temperature': 0.7, 'extra': {'a': 1}}
          : null,
      modelIds: const ['gpt-4o', 'gpt-4o-mini'],
      modelConfigs: withConfigs
          ? {
              'gpt-4o': const ModelConfig(
                reasoning: true,
                contextWindow: 128000,
              ),
            }
          : const {},
    );
  }

  test('编码 → 解码往返保真（全部字段）', () {
    final provider = makeProvider();
    final decoded = ProviderShareCodec.decode(
      ProviderShareCodec.encode(provider),
    );
    expect(decoded, isNotNull);
    expect(decoded!.name, 'OpenAI');
    expect(decoded.baseUrl, 'https://api.openai.com/v1');
    expect(decoded.apiKey, 'sk-test-123');
    expect(decoded.kind, ProviderKind.openai);
    expect(decoded.customHeaders, {'X-Custom': 'v1', 'X-Other': 'v2'});
    expect(decoded.customBody, {'temperature': 0.7, 'extra': {'a': 1}});
    expect(decoded.modelIds, ['gpt-4o', 'gpt-4o-mini']);
    expect(decoded.modelConfigs['gpt-4o']?.reasoning, isTrue);
    expect(decoded.modelConfigs['gpt-4o']?.contextWindow, 128000);
  });

  test('includeKey=false 时编码不含密钥', () {
    final text = ProviderShareCodec.encode(makeProvider(), includeKey: false);
    expect(text, isNot(contains('sk-test-123')));
    final decoded = ProviderShareCodec.decode(text);
    expect(decoded!.apiKey, '');
  });

  test('不同协议 kind 编码后解码保持', () {
    for (final kind in ['anthropic', 'gemini', 'auto']) {
      final decoded = ProviderShareCodec.decode(
        ProviderShareCodec.encode(makeProvider(kind: kind)),
      );
      expect(decoded!.kind.name, kind);
    }
  });

  test('解码带前后空白的文本', () {
    final text = ProviderShareCodec.encode(makeProvider());
    final decoded = ProviderShareCodec.decode('  $text\n');
    expect(decoded, isNotNull);
  });

  test('非法输入返回 null', () {
    expect(ProviderShareCodec.decode(''), isNull);
    expect(ProviderShareCodec.decode('random text'), isNull);
    expect(ProviderShareCodec.decode('ai-provider:v2:aaaa'), isNull);
    expect(
      ProviderShareCodec.decode('ai-provider:v1:!!!not-base64!!!'),
      isNull,
    );
    // 合法编码但缺 baseUrl → null
    final noUrl = ProviderShareCodec.encode(
      ChatProvider(id: 'x', name: 'N', baseUrl: '', modelIds: []),
    );
    expect(ProviderShareCodec.decode(noUrl), isNull);
  });

  test('编码文本带统一前缀且可被识别', () {
    final text = ProviderShareCodec.encode(makeProvider());
    expect(text, startsWith('ai-provider:v1:'));
    expect(ProviderShareCodec.decode(text), isNotNull);
  });
}

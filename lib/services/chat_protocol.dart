import 'dart:convert';

export 'protocol/anthropic_adapter.dart' show AnthropicAdapter;
export 'protocol/gemini_adapter.dart' show GeminiAdapter;
export 'protocol/openai_adapter.dart' show OpenAiAdapter;
export 'protocol/protocol_adapter.dart' show ProtocolAdapter, StreamDelta;
export 'protocol/protocol_factory.dart'
    show ProviderKind, ProtocolFactory, detectProviderKind;

/// 解析 SSE `data:` 负载为 JSON；失败返回 null。
Map<String, dynamic>? decodeSseData(String data) {
  try {
    final decoded = jsonDecode(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

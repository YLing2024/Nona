import 'anthropic_adapter.dart';
import 'gemini_adapter.dart';
import 'openai_adapter.dart';
import 'openai_responses_adapter.dart';
import 'protocol_adapter.dart';

/// 服务商协议类型。
///
/// [auto]：按 Base URL 自动探测（Anthropic / Google 域名 → 对应协议，
/// 其余按 OpenAI 兼容处理）。
enum ProviderKind {
  auto,
  openai,
  anthropic,
  gemini;

  static ProviderKind fromName(String? name) {
    for (final v in ProviderKind.values) {
      if (v.name == name) return v;
    }
    return ProviderKind.auto;
  }
}

/// 按 Base URL 探测协议类型（auto 时使用）。
ProviderKind detectProviderKind(String baseUrl) {
  final u = baseUrl.toLowerCase();
  if (u.contains('anthropic') || u.contains('claude')) {
    return ProviderKind.anthropic;
  }
  if (u.contains('googleapis') ||
      u.contains('generativelanguage') ||
      u.contains('aiplatform') ||
      u.contains('vertex')) {
    return ProviderKind.gemini;
  }
  return ProviderKind.openai;
}

/// 协议适配器工厂：按 [ProviderKind] 返回（缓存的）适配器实例。
class ProtocolFactory {
  ProtocolFactory._();

  static final Map<ProviderKind, ProtocolAdapter> _cache = {};

  /// 按协议类型取适配器（auto 在实际请求前应已被 [detectProviderKind] 解析，
  /// 此处按 OpenAI 兼容处理兜底）。
  ///
  /// 注意：返回的 Anthropic/Gemini 实例为共享缓存，含流式工具块缓冲状态，
  /// 仅用于不需要解析流（测速/请求体构建）的场景；实际聊天请求一律走
  /// [resolve] 获取独立实例。
  static ProtocolAdapter forKind(ProviderKind kind) {
    return _cache.putIfAbsent(kind, () {
      switch (kind) {
        case ProviderKind.openai:
        case ProviderKind.auto:
          return const OpenAiAdapter();
        case ProviderKind.anthropic:
          return AnthropicAdapter();
        case ProviderKind.gemini:
          return GeminiAdapter();
      }
    });
  }

  /// 按设置的协议名解析适配器：auto 时按 Base URL 探测。
  ///
  /// Anthropic/Gemini 适配器持有流式工具块缓冲状态（每次请求独立实例，
  /// 避免并发请求共享缓存实例导致块状态串扰）；OpenAI 无状态走缓存。
  /// [useResponseApi] 为 true 且协议为 OpenAI 时返回 Responses 适配器
  /// （C-01：o1/o3/o4/gpt-5 系列）。[vertexProject] 非空且协议为 Gemini
  /// 时返回 Vertex 模式适配器（C-02）。
  static ProtocolAdapter resolve(
    String? kindName,
    String baseUrl, {
    bool useResponseApi = false,
    String? vertexProject,
    String? vertexRegion,
  }) {
    final kind = ProviderKind.fromName(kindName);
    final resolved = kind == ProviderKind.auto
        ? detectProviderKind(baseUrl)
        : kind;
    if (resolved == ProviderKind.anthropic) {
      return AnthropicAdapter();
    }
    if (resolved == ProviderKind.gemini) {
      return GeminiAdapter(
        vertexProject: vertexProject,
        vertexRegion: vertexRegion,
      );
    }
    if (useResponseApi) {
      return const OpenAiResponsesAdapter();
    }
    return forKind(resolved);
  }
}

import '../models/chat_provider.dart';

/// 模型解析结果：命中的服务商与可用模型（可能为 null）。
class ModelResolution {
  final ChatProvider? provider;
  final String? modelId;

  const ModelResolution({this.provider, this.modelId});
}

/// 解析「当前应使用的服务商 + 模型」：
///
/// 1. 优先按 [providerId] 精确匹配服务商；
/// 2. 未命中时回退到「第一个已配置模型」的服务商（跳过空占位）；
/// 3. 服务商确定后：模型优先用 [modelId]（须在服务商模型列表中），
///    否则 [autoSelect] 时取第一个模型。
///
/// composer_toolbar / chat_composer / chat_view 三处共用，
/// 避免各写一份「服务商回退 + 模型解析」逻辑。
ModelResolution resolveFirstAvailable(
  List<ChatProvider> providers, {
  String? providerId,
  String? modelId,
  bool autoSelect = true,
}) {
  ChatProvider? provider;
  for (final p in providers) {
    if (p.id == providerId) {
      provider = p;
      break;
    }
  }
  // 默认选择第一个已配置模型的服务商（跳过空的 OpenAI 占位）
  provider ??= providers
          .where((p) => p.modelIds.isNotEmpty)
          .firstOrNull ??
      providers.firstOrNull;
  if (provider == null) return const ModelResolution();
  if (provider.modelIds.isEmpty) {
    return ModelResolution(provider: provider);
  }
  final model = modelId;
  if (model != null && provider.modelIds.contains(model)) {
    return ModelResolution(provider: provider, modelId: model);
  }
  if (!autoSelect) return ModelResolution(provider: provider);
  return ModelResolution(provider: provider, modelId: provider.modelIds.first);
}

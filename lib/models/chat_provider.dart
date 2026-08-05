/// 一个服务商（OpenAI 或兼容接口的第三方）。
class ChatProvider {
  final String id;
  String name;

  /// 接口基础地址，例如 https://api.openai.com/v1
  String baseUrl;
  String apiKey;

  /// 已启用的模型 id 列表。
  List<String> modelIds;

  /// 模型级能力配置（多模态 / 推理），key 为模型 id。
  Map<String, ModelConfig> modelConfigs;

  ChatProvider({
    required this.id,
    required this.name,
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.modelIds = const [],
    this.modelConfigs = const {},
  });

  factory ChatProvider.fromJson(Map<String, dynamic> json) {
    final rawConfigs = json['modelConfigs'] as Map<String, dynamic>? ?? const {};
    return ChatProvider(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名',
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      modelIds: (json['modelIds'] as List<dynamic>? ?? []).cast<String>(),
      modelConfigs: rawConfigs.map(
        (k, v) => MapEntry(k, ModelConfig.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'modelIds': modelIds,
    'modelConfigs': modelConfigs.map((k, v) => MapEntry(k, v.toJson())),
  };
}

/// 单个模型的附加能力配置。
class ModelConfig {
  /// 是否支持多模态（图片、文件等非文本输入）。
  final bool multimodal;

  /// 是否推理模型（支持深度推理与思考参数）。
  final bool reasoning;

  const ModelConfig({
    this.multimodal = false,
    this.reasoning = false,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
    multimodal: json['multimodal'] as bool? ?? false,
    reasoning: json['reasoning'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'multimodal': multimodal,
    'reasoning': reasoning,
  };

  ModelConfig copyWith({bool? multimodal, bool? reasoning}) => ModelConfig(
    multimodal: multimodal ?? this.multimodal,
    reasoning: reasoning ?? this.reasoning,
  );
}

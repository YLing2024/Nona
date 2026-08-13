import '../services/chat_protocol.dart' show ProviderKind;

/// 一个服务商（OpenAI 兼容 / Anthropic / Gemini 原生协议）。
class ChatProvider {
  final String id;
  String name;

  /// 接口基础地址，例如 https://api.openai.com/v1
  String baseUrl;
  String apiKey;

  /// 多 Key 轮换（F2-3）：为空时回退 [apiKey]。
  List<String> apiKeys;

  /// 协议类型：auto 时按 Base URL 自动探测。
  ProviderKind kind;

  /// 自定义请求头（如额外的鉴权/追踪字段），发送时合并。
  Map<String, String> customHeaders;

  /// 自定义请求体字段（JSON 对象，发送时合并进请求体）。
  Map<String, dynamic>? customBody;

  /// 余额查询路径（F2-4）：相对 baseUrl 的接口路径，默认 `{base}/credits`。
  String balancePath;

  /// 余额提取 JSON 路径表达式（支持 `data.total_usage`、数组下标 `[0]`、
  /// 减法 `a - b`）；空时用默认值（OpenRouter `data.total_credits - data.total_usage`）。
  String balanceResultPath;

  /// 已启用的模型 id 列表。
  List<String> modelIds;

  /// 模型级能力配置（多模态 / 推理），key 为模型 id。
  Map<String, ModelConfig> modelConfigs;

  /// C-01：是否使用 OpenAI Responses API（/responses，面向 o1/o3/o4/gpt-5）。
  final bool useResponseApi;

  /// C-03：服务商分组 id（null = 未分组）。
  String? groupId;

  /// C-02：认证方式（apiKey / serviceAccount）。
  final String authMode;

  /// C-02：Service Account JSON（粘贴或选文件导入）。
  final String saJson;

  /// C-02：Vertex Project ID / Region。
  final String vertexProject;
  final String vertexRegion;

  ChatProvider({
    required this.id,
    required this.name,
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.apiKeys = const [],
    this.kind = ProviderKind.auto,
    this.customHeaders = const {},
    this.customBody,
    this.balancePath = '',
    this.balanceResultPath = '',
    this.modelIds = const [],
    this.modelConfigs = const {},
    this.useResponseApi = false,
    this.groupId,
    this.authMode = 'apiKey',
    this.saJson = '',
    this.vertexProject = '',
    this.vertexRegion = 'us-central1',
  });

  factory ChatProvider.fromJson(Map<String, dynamic> json) {
    final rawConfigs = json['modelConfigs'] as Map<String, dynamic>? ?? const {};
    final rawHeaders = json['customHeaders'];
    return ChatProvider(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed',
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      apiKeys: (json['apiKeys'] as List<dynamic>? ?? []).cast<String>(),
      kind: ProviderKind.fromName(json['kind'] as String?),
      customHeaders: rawHeaders is Map
          ? {
              for (final e in rawHeaders.entries)
                e.key.toString(): e.value.toString(),
            }
          : const {},
      customBody: json['customBody'] as Map<String, dynamic>?,
      balancePath: json['balancePath'] as String? ?? '',
      balanceResultPath: json['balanceResultPath'] as String? ?? '',
      modelIds: (json['modelIds'] as List<dynamic>? ?? []).cast<String>(),
      modelConfigs: rawConfigs.map(
        (k, v) => MapEntry(k, ModelConfig.fromJson(v as Map<String, dynamic>)),
      ),
      useResponseApi: json['useResponseApi'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      authMode: json['authMode'] as String? ?? 'apiKey',
      saJson: json['saJson'] as String? ?? '',
      vertexProject: json['vertexProject'] as String? ?? '',
      vertexRegion: json['vertexRegion'] as String? ?? 'us-central1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'apiKeys': apiKeys,
    'kind': kind.name,
    'customHeaders': customHeaders,
    if (customBody != null) 'customBody': customBody,
    'balancePath': balancePath,
    'balanceResultPath': balanceResultPath,
    'modelIds': modelIds,
    'modelConfigs': modelConfigs.map((k, v) => MapEntry(k, v.toJson())),
    'useResponseApi': useResponseApi,
    if (groupId != null) 'groupId': groupId,
    'authMode': authMode,
    if (saJson.isNotEmpty) 'saJson': saJson,
    'vertexProject': vertexProject,
    'vertexRegion': vertexRegion,
  };
}

/// 单个模型的附加能力配置。
class ModelConfig {
  /// 是否支持多模态（图片、文件等非文本输入）。
  final bool multimodal;

  /// 是否推理模型（支持深度推理与思考参数）。
  final bool reasoning;

  /// 模型上下文窗口大小（tokens）；未知时为 null。
  final int? contextWindow;

  /// 是否支持图片生成（F1-4）。
  final bool imageGen;

  const ModelConfig({
    this.multimodal = false,
    this.reasoning = false,
    this.contextWindow,
    this.imageGen = false,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
    multimodal: json['multimodal'] as bool? ?? false,
    reasoning: json['reasoning'] as bool? ?? false,
    contextWindow: json['contextWindow'] as int?,
    imageGen: json['imageGen'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'multimodal': multimodal,
    'reasoning': reasoning,
    if (contextWindow != null) 'contextWindow': contextWindow,
    'imageGen': imageGen,
  };

  ModelConfig copyWith({
    bool? multimodal,
    bool? reasoning,
    int? contextWindow,
    bool? imageGen,
  }) => ModelConfig(
    multimodal: multimodal ?? this.multimodal,
    reasoning: reasoning ?? this.reasoning,
    contextWindow: contextWindow ?? this.contextWindow,
    imageGen: imageGen ?? this.imageGen,
  );
}

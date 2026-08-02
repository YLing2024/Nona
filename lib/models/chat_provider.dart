/// 一个服务商（OpenAI 或兼容接口的第三方）。
class ChatProvider {
  final String id;
  String name;

  /// 接口基础地址，例如 https://api.openai.com/v1
  String baseUrl;
  String apiKey;

  /// 已启用的模型 id 列表。
  List<String> modelIds;

  ChatProvider({
    required this.id,
    required this.name,
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.modelIds = const [],
  });

  factory ChatProvider.fromJson(Map<String, dynamic> json) {
    return ChatProvider(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名',
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      modelIds: (json['modelIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'modelIds': modelIds,
  };
}

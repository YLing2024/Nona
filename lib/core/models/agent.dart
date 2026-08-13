import 'chat_options.dart';

/// 一个 Agent：命名的一组会话上下文预设。
class Agent {
  final String id;
  String name;
  ChatOptions options;

  /// 是否为默认 Agent（全局唯一，用于单击新建会话时自动套用）。
  bool isDefault;

  /// 长期记忆条目（发送时注入系统提示词）。
  List<String> memories;

  /// 绑定的知识库 id 列表（F4-1：检索域 = Agent 绑定库 ∪ 全局库）。
  List<String> kbIds;

  Agent({
    required this.id,
    required this.name,
    this.options = const ChatOptions(),
    this.isDefault = false,
    this.memories = const [],
    this.kbIds = const [],
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed',
      options: ChatOptions.fromJson(json['options'] as Map<String, dynamic>?),
      isDefault: json['isDefault'] as bool? ?? false,
      memories: (json['memories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      kbIds: (json['kbIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'options': options.toJson(),
    'isDefault': isDefault,
    'memories': memories,
    'kbIds': kbIds,
  };
}

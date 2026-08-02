import 'chat_options.dart';

/// 一个 Agent：命名的一组会话上下文预设。
class Agent {
  final String id;
  String name;
  ChatOptions options;

  /// 是否为默认 Agent（全局唯一，用于单击新建会话时自动套用）。
  bool isDefault;

  Agent({
    required this.id,
    required this.name,
    this.options = const ChatOptions(),
    this.isDefault = false,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名',
      options: ChatOptions.fromJson(json['options'] as Map<String, dynamic>?),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'options': options.toJson(),
    'isDefault': isDefault,
  };
}

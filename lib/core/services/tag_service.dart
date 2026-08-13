import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// G-06：会话标签。
class ChatTag {
  final String id;
  String name;

  /// ARGB 色值（0 = 默认色）。
  int color;

  ChatTag({required this.id, required this.name, this.color = 0});

  factory ChatTag.fromJson(Map<String, dynamic> json) => ChatTag(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    color: json['color'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
}

/// G-06：标签存储（prefs JSON 数组，损坏自愈）。
class TagService {
  static const _kPrefsKey = 'chat_tags';

  Future<List<ChatTag>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in decoded)
          if (e is Map<String, dynamic>) ChatTag.fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ChatTag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      jsonEncode(tags.map((t) => t.toJson()).toList()),
    );
  }

  Future<ChatTag> add(String name, {int color = 0}) async {
    final tags = await load();
    final tag = ChatTag(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
    tags.add(tag);
    await save(tags);
    return tag;
  }

  Future<void> remove(String id) async {
    final tags = await load()..removeWhere((t) => t.id == id);
    await save(tags);
  }

  Future<void> rename(String id, String name) async {
    final tags = await load();
    for (final t in tags) {
      if (t.id == id) t.name = name;
    }
    await save(tags);
  }

  /// 标签 id → 名称（空返回）。
  Future<String> nameOf(String id) async {
    final tags = await load();
    return tags.where((t) => t.id == id).firstOrNull?.name ?? '';
  }
}

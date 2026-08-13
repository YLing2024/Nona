import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// C-03：服务商分组。
class ProviderGroup {
  final String id;
  String name;

  /// 排序序号（越小越靠前）。
  int sortOrder;

  /// 组色（ARGB int；0 表示未设置）。
  int color;

  ProviderGroup({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.color = 0,
  });

  factory ProviderGroup.fromJson(Map<String, dynamic> json) => ProviderGroup(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Unnamed',
    sortOrder: json['sortOrder'] as int? ?? 0,
    color: json['color'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'color': color,
  };
}

/// C-03：服务商分组的存储与 CRUD（prefs JSON 数组，损坏自愈）。
class ProviderGroupService {
  static const _kPrefsKey = 'provider_groups';

  /// 加载全部分组（损坏时返回空列表，不抛异常）。
  Future<List<ProviderGroup>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map<String, dynamic>)
            ProviderGroup.fromJson(e)
          else if (e is Map)
            ProviderGroup.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ProviderGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  Future<ProviderGroup> add(String name, {int color = 0}) async {
    final groups = await load();
    final group = ProviderGroup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      sortOrder: groups.length,
      color: color,
    );
    groups.add(group);
    await save(groups);
    return group;
  }

  Future<void> rename(String id, String name) async {
    final groups = await load();
    for (final g in groups) {
      if (g.id == id) g.name = name;
    }
    await save(groups);
  }

  Future<void> remove(String id) async {
    final groups = await load()..removeWhere((g) => g.id == id);
    await save(groups);
  }
}

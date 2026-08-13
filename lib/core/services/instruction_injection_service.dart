import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import '../utils/logger.dart';

/// 指令注入（G-05）：用户自定义的系统提示词片段。
class InstructionInjection {
  final String id;
  String title;
  String prompt;
  String? groupName;
  bool enabled;

  InstructionInjection({
    required this.id,
    required this.title,
    required this.prompt,
    this.groupName,
    this.enabled = true,
  });

  factory InstructionInjection.fromRow(InstructionInjectionRow r) =>
      InstructionInjection(
        id: r.id,
        title: r.title,
        prompt: r.prompt,
        groupName: r.groupName,
        enabled: r.enabled,
      );
}

/// 指令注入服务（G-05）：CRUD + Agent 激活集 + 注入文本组装。
class InstructionInjectionService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  static const _kActiveKey = 'instruction_injections_active';

  InstructionInjectionService({NonaAppDatabase? database})
      : _explicitDb = database;

  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  /// 全部注入项。
  Future<List<InstructionInjection>> list() async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await (db.select(db.instructionInjections)
            ..orderBy([
              (t) => OrderingTerm.asc(t.groupName),
              (t) => OrderingTerm.asc(t.title),
            ]))
          .get();
      return [for (final r in rows) InstructionInjection.fromRow(r)];
    } catch (e) {
      Logger.error('ii', 'list failed', e);
      return const [];
    }
  }

  Future<void> save(InstructionInjection item) async {
    final db = await _db;
    if (db == null) return;
    final id = item.id.isEmpty
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : item.id;
    try {
      await db.into(db.instructionInjections).insertOnConflictUpdate(
        InstructionInjectionsCompanion.insert(
          id: id,
          title: item.title,
          prompt: item.prompt,
          groupName: Value(item.groupName),
          enabled: Value(item.enabled),
        ),
      );
    } catch (e) {
      Logger.error('ii', 'save failed', e);
    }
  }

  Future<void> delete(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      await (db.delete(db.instructionInjections)
            ..where((t) => t.id.equals(id)))
          .go();
    } catch (_) {}
  }

  // ---------------- 激活集（agent → id 列表，全局兜底） ----------------

  static const String kGlobalKey = '__global__';

  /// 某 Agent 的激活注入 id 列表（无记录时用全局兜底）。
  Future<List<String>> activeIds(String? agentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActiveKey);
    Map<String, dynamic>? data;
    if (raw != null && raw.isNotEmpty) {
      try {
        data = (jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final list = data?[agentId ?? kGlobalKey];
    if (list is List) return list.map((e) => e.toString()).toList();
    final global = data?[kGlobalKey];
    if (global is List) return global.map((e) => e.toString()).toList();
    return const [];
  }

  /// 设置某 Agent 的激活集。
  Future<void> setActiveIds(String? agentId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActiveKey);
    Map<String, dynamic> data;
    if (raw != null && raw.isNotEmpty) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        data = {};
      }
    } else {
      data = {};
    }
    data[agentId ?? kGlobalKey] = ids;
    await prefs.setString(_kActiveKey, jsonEncode(data));
  }

  // ---------------- 注入组装 ----------------

  /// 组装激活注入项的提示词文本（`<instruction>` 包裹，按标题标号）。
  Future<String> buildInjection(String? agentId) async {
    final items = await list();
    if (items.isEmpty) return '';
    final active = await activeIds(agentId);
    final enabled = <InstructionInjection>[];
    for (final id in active) {
      for (final item in items) {
        if (item.id == id && item.enabled) {
          enabled.add(item);
          break;
        }
      }
    }
    if (enabled.isEmpty) return '';
    final parts = <String>[];
    for (final item in enabled) {
      final prompt = item.prompt.trim();
      if (prompt.isEmpty) continue;
      parts.add('<instruction title="${item.title}">\n$prompt\n</instruction>');
    }
    return parts.join('\n\n');
  }
}

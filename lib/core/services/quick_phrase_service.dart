import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import '../utils/logger.dart';

/// 快捷短语（G-04）。
class QuickPhrase {
  final String id;
  String title;
  String content;
  bool isGlobal;
  String? agentId;
  int sortOrder;

  QuickPhrase({
    required this.id,
    required this.title,
    required this.content,
    this.isGlobal = true,
    this.agentId,
    this.sortOrder = 0,
  });

  factory QuickPhrase.fromRow(QuickPhraseRow r) => QuickPhrase(
    id: r.id,
    title: r.title,
    content: r.content,
    isGlobal: r.isGlobal,
    agentId: r.agentId,
    sortOrder: r.sortOrder,
  );
}

/// 快捷短语服务（G-04）：CRUD + 按 Agent 过滤 + 变量展开。
class QuickPhraseService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  QuickPhraseService({NonaAppDatabase? database}) : _explicitDb = database;

  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  /// 全部短语（全局优先，按 sort_order）。
  Future<List<QuickPhrase>> list({String? agentId}) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final query = db.select(db.quickPhrases)
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.title),
        ]);
      if (agentId != null) {
        query.where(
          (t) => t.isGlobal.equals(true) | t.agentId.equals(agentId),
        );
      }
      final rows = await query.get();
      return [for (final r in rows) QuickPhrase.fromRow(r)];
    } catch (e) {
      Logger.error('qp', 'list failed', e);
      return const [];
    }
  }

  Future<void> save(QuickPhrase phrase) async {
    final db = await _db;
    if (db == null) return;
    final id = phrase.id.isEmpty
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : phrase.id;
    try {
      await db.into(db.quickPhrases).insertOnConflictUpdate(
        QuickPhrasesCompanion.insert(
          id: id,
          title: phrase.title,
          content: phrase.content,
          isGlobal: Value(phrase.isGlobal),
          agentId: Value(phrase.agentId),
          sortOrder: Value(phrase.sortOrder),
        ),
      );
    } catch (e) {
      Logger.error('qp', 'save failed', e);
    }
  }

  Future<void> delete(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      await (db.delete(db.quickPhrases)..where((t) => t.id.equals(id))).go();
    } catch (_) {}
  }

  /// 展开变量（复用 PromptVariables 语法，见 PromptVariables.resolve）。
  static String expandVariables(String raw, Map<String, String> vars) {
    return raw.replaceAllMapped(
      RegExp(r'\{\{\s*([\w.-]+)\s*\}\}'),
      (m) => vars[m.group(1)] ?? m.group(0)!,
    );
  }
}

/// 快捷短语存储 JSON 导出/导入（诊断/分享）。
String quickPhrasesToJson(List<QuickPhrase> phrases) => jsonEncode([
  for (final p in phrases)
    {
      'id': p.id,
      'title': p.title,
      'content': p.content,
      'isGlobal': p.isGlobal,
      'agentId': p.agentId,
      'sortOrder': p.sortOrder,
    },
]);

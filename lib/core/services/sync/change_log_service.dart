import 'dart:convert';

import 'package:drift/drift.dart';

import '../../database/nona_app_database.dart';
import '../../database/nona_db_factory.dart';
import '../../utils/logger.dart';

/// 变更日志服务（X-04）：在写路径统一记录 change_log。
///
/// 实体类型：session / settings / provider / agent；
/// op：upsert / delete。
class ChangeLogService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  ChangeLogService({NonaAppDatabase? database}) : _explicitDb = database;

  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  /// 记录一次变更（幂等去重：同 entity+id 最近变更覆盖旧 seq 标记）。
  Future<void> record({
    required String entity,
    required String entityId,
    required String op,
  }) async {
    final db = await _db;
    if (db == null) return;
    try {
      await db.into(db.changeLog).insert(
        ChangeLogCompanion.insert(
          entityType: entity,
          entityId: entityId,
          op: op,
          tsMicros: DateTime.now().microsecondsSinceEpoch,
          payloadHash: Value(_hash('$entity:$entityId:$op')),
        ),
      );
      // 修剪：单实体仅保留最近 200 条（推送后由远端 head 收敛）
      final rows = await db
          .customSelect(
            'SELECT seq FROM change_log WHERE entity_type = ? '
            'ORDER BY seq DESC LIMIT -1 OFFSET 200',
            variables: [Variable.withString(entity)],
          )
          .get();
      for (final r in rows) {
        await (db.delete(db.changeLog)
              ..where((t) => t.seq.equals(r.data['seq'] as int)))
            .go();
      }
    } catch (e) {
      Logger.warn('sync', 'change log record failed: $e');
    }
  }

  /// 自 [afterSeq] 之后的全部变更（按 seq 升序）。
  Future<List<ChangeLogEntry>> entriesAfter(int afterSeq, {int limit = 500}) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await (db.select(db.changeLog)
            ..where((t) => t.seq.isBiggerThanValue(afterSeq))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .get();
      return [for (final r in rows) ChangeLogEntry.fromRow(r)];
    } catch (_) {
      return const [];
    }
  }

  /// 当前最大 seq（远端 head 比较用）。
  Future<int> maxSeq() async {
    final db = await _db;
    if (db == null) return 0;
    try {
      final row = await (db.selectOnly(db.changeLog)
            ..addColumns([db.changeLog.seq.max()]))
          .get();
      return row.first.read(db.changeLog.seq.max()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String _hash(String raw) {
    var h = 0;
    for (final rune in raw.runes) {
      h = (h * 31 + rune) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }
}

/// 一条变更记录。
class ChangeLogEntry {
  final int seq;
  final String entityType;
  final String entityId;
  final String op;
  final int tsMicros;
  final String? payloadHash;

  const ChangeLogEntry({
    required this.seq,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.tsMicros,
    this.payloadHash,
  });

  factory ChangeLogEntry.fromRow(ChangeLogRow r) => ChangeLogEntry(
    seq: r.seq,
    entityType: r.entityType,
    entityId: r.entityId,
    op: r.op,
    tsMicros: r.tsMicros,
    payloadHash: r.payloadHash,
  );

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'entity': entityType,
    'id': entityId,
    'op': op,
    'ts': tsMicros,
  };

  static ChangeLogEntry fromJson(Map<String, dynamic> json) => ChangeLogEntry(
    seq: json['seq'] as int,
    entityType: json['entity'] as String,
    entityId: json['id'] as String,
    op: json['op'] as String,
    tsMicros: json['ts'] as int,
  );

  /// JSONL 序列化。
  String toJsonLine() => jsonEncode(toJson());
}

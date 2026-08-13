import 'package:drift/drift.dart';

import '../nona_app_database.dart';

/// 生成运行状态机 DAO（B-06 checkpoint 持久化）。
///
/// state: preparing → requesting → streaming ⇄ waiting_tool → 终态
/// (completed / failed / cancelled / interrupted)。
/// 乐观并发：transition 带 expectedStateRevision，更新行数为 0 即冲突。
class GenerationRunDao {
  final NonaAppDatabase db;

  GenerationRunDao(this.db);

  /// 创建一条运行记录（state=preparing，revision=0）。
  Future<String> create({
    String? sessionId,
    String? messageId,
  }) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.generationRuns).insert(
      GenerationRunsCompanion.insert(
        id: id,
        sessionId: Value(sessionId),
        messageId: Value(messageId),
        state: const Value('preparing'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  static int _counter = 0;

  /// 状态迁移（乐观并发）：期望 revision 匹配才更新，否则返回 false。
  Future<bool> transition(
    String id,
    String newState, {
    int? expectedStateRevision,
    String? errorCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final table = db.generationRuns;
    final affected = await (db.update(table)
          ..where(
            (t) => t.id.equals(id) &
                (expectedStateRevision == null
                    ? const Constant(true)
                    : t.stateRevision.equals(expectedStateRevision)),
          ))
      .write(
        GenerationRunsCompanion(
          state: Value(newState),
          errorCode: Value(errorCode),
          updatedAt: Value(now),
        ),
      );
    if (affected == 0) return false;
    // 乐观并发校验通过后递增 revision（表达式更新走原始 SQL）
    await db.customStatement(
      'UPDATE generation_runs SET state_revision = state_revision + 1 '
      'WHERE id = ?',
      [id],
    );
    return true;
  }

  /// checkpoint：递增 checkpoint_seq（供日志/恢复定位）。
  Future<void> checkpoint(String id, {int seq = -1}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (seq >= 0) {
      await (db.update(db.generationRuns)
            ..where((t) => t.id.equals(id)))
          .write(
        GenerationRunsCompanion(
          checkpointSeq: Value(seq),
          updatedAt: Value(now),
        ),
      );
      return;
    }
    await db.customStatement(
      'UPDATE generation_runs SET checkpoint_seq = checkpoint_seq + 1, '
      'updated_at = ? WHERE id = ?',
      [now, id],
    );
  }

  /// 按 id 读取。
  Future<GenerationRunRow?> byId(String id) async {
    final rows = await (db.select(db.generationRuns)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 列出未达终态的运行（启动恢复用）。
  Future<List<GenerationRunRow>> activeRuns() async {
    return (db.select(db.generationRuns)
          ..where(
            (t) => t.state.isIn(const ['preparing', 'requesting', 'streaming']),
          ))
        .get();
  }

  /// 启动恢复：把遗留 active run 全部置 interrupted（error_code=app_restart）。
  ///
  /// 返回被重置的运行（含 session/message 定位，供消息回填）。
  Future<List<GenerationRunRow>> resetStale() async {
    final stale = await activeRuns();
    if (stale.isEmpty) return stale;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      for (final run in stale) {
        await (db.update(db.generationRuns)..where((t) => t.id.equals(run.id)))
            .write(
          GenerationRunsCompanion(
            state: const Value('interrupted'),
            errorCode: const Value('app_restart'),
            updatedAt: Value(now),
          ),
        );
      }
    });
    return stale;
  }

  /// 删除运行记录。
  Future<void> delete(String id) async {
    await (db.delete(db.generationRuns)..where((t) => t.id.equals(id))).go();
  }
}

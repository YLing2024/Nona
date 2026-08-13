import 'dart:convert';

import 'package:drift/drift.dart';

import '../../database/nona_app_database.dart';
import '../../database/nona_db_factory.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import 'price_service.dart';

/// 单日用量聚合。
class DailyUsage {
  final String date; // yyyy-MM-dd
  final int promptTokens;
  final int completionTokens;
  final int calls;

  const DailyUsage({
    required this.date,
    required this.promptTokens,
    required this.completionTokens,
    required this.calls,
  });
}

/// 单模型用量聚合。
class ModelUsage {
  final String modelId;
  final String providerName;
  final int promptTokens;
  final int completionTokens;
  final int calls;

  const ModelUsage({
    required this.modelId,
    required this.providerName,
    required this.promptTokens,
    required this.completionTokens,
    required this.calls,
  });
}

/// 会话级用量聚合。
class SessionUsageStat {
  final String sessionId;
  final String title;
  final int promptTokens;
  final int completionTokens;

  const SessionUsageStat({
    required this.sessionId,
    required this.title,
    required this.promptTokens,
    required this.completionTokens,
  });
}

/// 用量统计服务（F3-2）。
///
/// - SQLite 可用时走 `usage_daily` 预聚合表（冗余更新 + 一次性回填）；
/// - SQLite 不可用（Web）时扫描内存会话聚合，结果等价。
class UsageStatsService {
  final NonaAppDatabase? _explicitDb;
  final PriceService priceService;
  Future<NonaAppDatabase?>? _cachedDb;

  UsageStatsService({NonaAppDatabase? database, PriceService? priceService})
      : _explicitDb = database,
        priceService = priceService ?? PriceService.instance;

  /// 解析数据库（实例内缓存：测试环境每次打开独立内存库，需保持同实例一致）。
  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  static String _dateOf(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  /// 冗余更新：写入会话后把消息用量 upsert 进 usage_daily。
  Future<void> recordSessions(List<ChatSession> sessions) async {
    final db = await _db;
    if (db == null) return;
    try {
      await db.transaction(() async {
        for (final s in sessions) {
          for (final m in s.messages) {
            await _upsertMessage(db, s, m);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _upsertMessage(
    NonaAppDatabase db,
    ChatSession session,
    ChatMessage m,
  ) async {
    final prompt = m.promptTokens ?? 0;
    final completion = m.completionTokens ?? 0;
    if (prompt <= 0 && completion <= 0) return;
    final date = _dateOf(
      m.sentAt ?? session.updatedAt,
    );
    final modelId = m.modelId ?? session.modelId ?? '';
    final providerName = m.providerName ?? session.providerId ?? '';
    await db.customStatement(
      'INSERT INTO usage_daily '
      '(model_id, provider_name, date, prompt_tokens, completion_tokens, calls) '
      'VALUES (?, ?, ?, ?, ?, 1) '
      'ON CONFLICT(model_id, provider_name, date) DO UPDATE SET '
      'prompt_tokens = prompt_tokens + excluded.prompt_tokens, '
      'completion_tokens = completion_tokens + excluded.completion_tokens, '
      'calls = calls + 1',
      [modelId, providerName, date, prompt, completion],
    );
  }

  /// D-02：搜索用量统计（search_daily 表，按日/引擎聚合）。
  Future<void> recordSearch({
    required String engine,
    int calls = 1,
    int tokens = 0,
  }) async {
    final db = await _db;
    if (db == null) return;
    try {
      await db.customStatement(
        'CREATE TABLE IF NOT EXISTS search_daily '
        '(engine TEXT NOT NULL, date TEXT NOT NULL, '
        'calls INTEGER NOT NULL DEFAULT 0, tokens INTEGER NOT NULL DEFAULT 0, '
        'PRIMARY KEY (engine, date))',
      );
      await db.customStatement(
        'INSERT INTO search_daily (engine, date, calls, tokens) '
        'VALUES (?, ?, ?, ?) '
        'ON CONFLICT(engine, date) DO UPDATE SET '
        'calls = calls + excluded.calls, '
        'tokens = tokens + excluded.tokens',
        [engine, _dateOf(DateTime.now()), calls, tokens],
      );
    } catch (_) {}
  }

  /// D-02：搜索用量（近 [days] 天按引擎聚合）。
  Future<List<({String engine, String date, int calls, int tokens})>>
  searchDaily({int days = 30}) async {
    final db = await _db;
    if (db == null) return [];
    try {
      final rows = await db.customSelect(
        'SELECT engine, date, calls, tokens FROM search_daily '
        'WHERE date >= ? ORDER BY date DESC, calls DESC',
        variables: [
          Variable.withString(
            _dateOf(DateTime.now().subtract(Duration(days: days - 1))),
          ),
        ],
      ).get();
      return [
        for (final r in rows)
          (
            engine: r.data['engine'] as String? ?? '',
            date: r.data['date'] as String? ?? '',
            calls: r.data['calls'] as int? ?? 0,
            tokens: r.data['tokens'] as int? ?? 0,
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /// 每日用量（近 [days] 天，含今天）。
  Future<List<DailyUsage>> daily({int days = 30}) async {
    final db = await _db;
    if (db != null && await _usageTableHasData(db)) {
      final rows = await db
          .customSelect(
            'SELECT date, SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c, '
            'SUM(calls) AS n FROM usage_daily '
            'WHERE date >= ? GROUP BY date ORDER BY date',
            variables: [
              Variable.withString(
                _dateOf(DateTime.now().subtract(Duration(days: days - 1))),
              ),
            ],
          )
          .get();
      return [
        for (final r in rows)
          DailyUsage(
            date: r.data['date'] as String,
            promptTokens: r.data['p'] as int? ?? 0,
            completionTokens: r.data['c'] as int? ?? 0,
            calls: r.data['n'] as int? ?? 0,
          ),
      ];
    }
    // Web / 无预聚合：扫描内存会话
    final sessions = await _loadSessions();
    final byDate = <String, DailyUsage>{};
    for (final s in sessions) {
      for (final m in s.messages) {
        final prompt = m.promptTokens ?? 0;
        final completion = m.completionTokens ?? 0;
        if (prompt <= 0 && completion <= 0) continue;
        final date = _dateOf(m.sentAt ?? s.updatedAt);
        final agg = byDate.putIfAbsent(
          date,
          () => DailyUsage(date: date, promptTokens: 0, completionTokens: 0, calls: 0),
        );
        byDate[date] = DailyUsage(
          date: date,
          promptTokens: agg.promptTokens + prompt,
          completionTokens: agg.completionTokens + completion,
          calls: agg.calls + 1,
        );
      }
    }
    final keys = byDate.keys.toList()..sort();
    return [for (final k in keys) byDate[k]!];
  }

  Future<bool> _usageTableHasData(NonaAppDatabase db) async {
    try {
      final row = (await db.customSelect('SELECT COUNT(*) AS n FROM usage_daily').get())
          .first;
      return (row.data['n'] as int? ?? 0) > 0;
    } catch (_) {
      return false;
    }
  }

  /// H-01：活跃热力图——近 [days] 天每日消息数（自然日，今天往前）。
  Future<Map<String, int>> heatmap({int days = 365}) async {
    final db = await _db;
    if (db != null) {
      try {
        final since = _dateOf(
          DateTime.now().subtract(Duration(days: days - 1)),
        );
        final rows = await db.customSelect(
          'SELECT date, COUNT(*) AS n FROM messages '
          'WHERE sent_at IS NOT NULL AND date(sent_at / 1000, \'unixepoch\') >= ? '
          'GROUP BY date',
          variables: [Variable.withString(since)],
        ).get();
        return {
          for (final r in rows)
            r.data['date'] as String: (r.data['n'] as int? ?? 0),
        };
      } catch (_) {
        // 表结构/时间列不可用时回退会话内存扫描
      }
    }
    final result = <String, int>{};
    for (final s in await _loadSessions()) {
      for (final m in s.messages) {
        final t = m.sentAt ?? s.updatedAt;
        if (t.isBefore(DateTime.now().subtract(Duration(days: days - 1)))) {
          continue;
        }
        final d = _dateOf(t);
        result[d] = (result[d] ?? 0) + 1;
      }
    }
    return result;
  }

  /// H-01：服务商用量排行（近 [days] 天）。
  Future<List<({String provider, int tokens, int calls})>> rankProviders({
    int days = 30,
  }) async {
    final db = await _db;
    if (db != null && await _usageTableHasData(db)) {
      try {
        final since = _dateOf(DateTime.now().subtract(Duration(days: days - 1)));
        final rows = await db.customSelect(
          'SELECT provider_name, SUM(prompt_tokens + completion_tokens) AS t, '
          'SUM(calls) AS n FROM usage_daily WHERE date >= ? '
          'GROUP BY provider_name ORDER BY t DESC',
          variables: [Variable.withString(since)],
        ).get();
        return [
          for (final r in rows)
            (
              provider: r.data['provider_name'] as String? ?? '',
              tokens: r.data['t'] as int? ?? 0,
              calls: r.data['n'] as int? ?? 0,
            ),
        ];
      } catch (_) {}
    }
    return [];
  }

  /// 模型 TopN。
  Future<List<ModelUsage>> topModels({int limit = 10}) async {
    final db = await _db;
    if (db != null && await _usageTableHasData(db)) {
      final rows = await db
          .customSelect(
            'SELECT model_id, provider_name, SUM(prompt_tokens) AS p, '
            'SUM(completion_tokens) AS c, SUM(calls) AS n FROM usage_daily '
            'GROUP BY model_id, provider_name ORDER BY (p + c) DESC LIMIT ?',
            variables: [Variable.withInt(limit)],
          )
          .get();
      return [
        for (final r in rows)
          ModelUsage(
            modelId: r.data['model_id'] as String,
            providerName: r.data['provider_name'] as String,
            promptTokens: r.data['p'] as int? ?? 0,
            completionTokens: r.data['c'] as int? ?? 0,
            calls: r.data['n'] as int? ?? 0,
          ),
      ];
    }
    final sessions = await _loadSessions();
    final byModel = <String, ModelUsage>{};
    for (final s in sessions) {
      for (final m in s.messages) {
        final prompt = m.promptTokens ?? 0;
        final completion = m.completionTokens ?? 0;
        if (prompt <= 0 && completion <= 0) continue;
        final key = '${m.modelId ?? s.modelId ?? ''}|${m.providerName ?? s.providerId ?? ''}';
        final agg = byModel.putIfAbsent(
          key,
          () => ModelUsage(
            modelId: m.modelId ?? s.modelId ?? '',
            providerName: m.providerName ?? s.providerId ?? '',
            promptTokens: 0,
            completionTokens: 0,
            calls: 0,
          ),
        );
        byModel[key] = ModelUsage(
          modelId: agg.modelId,
          providerName: agg.providerName,
          promptTokens: agg.promptTokens + prompt,
          completionTokens: agg.completionTokens + completion,
          calls: agg.calls + 1,
        );
      }
    }
    final list = byModel.values.toList()
      ..sort((a, b) =>
          (b.promptTokens + b.completionTokens).compareTo(a.promptTokens + a.completionTokens));
    return list.take(limit).toList();
  }

  /// 会话 TopN（按 token 总量）。
  Future<List<SessionUsageStat>> topSessions({int limit = 10}) async {
    final sessions = await _loadSessions();
    final list = <SessionUsageStat>[];
    for (final s in sessions) {
      var prompt = 0;
      var completion = 0;
      for (final m in s.messages) {
        prompt += m.promptTokens ?? 0;
        completion += m.completionTokens ?? 0;
      }
      if (prompt <= 0 && completion <= 0) continue;
      list.add(
        SessionUsageStat(
          sessionId: s.id,
          title: s.title,
          promptTokens: prompt,
          completionTokens: completion,
        ),
      );
    }
    list.sort((a, b) =>
        (b.promptTokens + b.completionTokens).compareTo(a.promptTokens + a.completionTokens));
    return list.take(limit).toList();
  }

  /// 累计 token 与成本（美元）。
  Future<(int prompt, int completion, double cost)> totals() async {
    final db = await _db;
    int prompt = 0;
    int completion = 0;
    if (db != null && await _usageTableHasData(db)) {
      final row = (await db
              .customSelect(
                'SELECT SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c '
                'FROM usage_daily',
              )
              .get())
          .first;
      prompt = row.data['p'] as int? ?? 0;
      completion = row.data['c'] as int? ?? 0;
    } else {
      final sessions = await _loadSessions();
      for (final s in sessions) {
        for (final m in s.messages) {
          prompt += m.promptTokens ?? 0;
          completion += m.completionTokens ?? 0;
        }
      }
    }
    final models = await topModels(limit: 500);
    var cost = 0.0;
    for (final m in models) {
      cost += await priceService.costFor(
        m.modelId,
        m.promptTokens,
        m.completionTokens,
      );
    }
    return (prompt, completion, cost);
  }

  /// 本月成本（预算检查用）。
  Future<double> monthCost() async {
    final db = await _db;
    if (db != null && await _usageTableHasData(db)) {
      final month = _dateOf(DateTime.now()).substring(0, 7);
      final rows = await db
          .customSelect(
            'SELECT model_id, SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c '
            'FROM usage_daily WHERE date LIKE ? GROUP BY model_id',
            variables: [Variable.withString('$month%')],
          )
          .get();
      var cost = 0.0;
      for (final r in rows) {
        cost += await priceService.costFor(
          r.data['model_id'] as String,
          r.data['p'] as int? ?? 0,
          r.data['c'] as int? ?? 0,
        );
      }
      return cost;
    }
    final (prompt, completion, _) = await totals();
    // 内存回退：本月近似为全部成本（无精确日期数据时）
    return prompt + completion > 0
        ? await _costFromSessionsForMonth()
        : 0;
  }

  Future<double> _costFromSessionsForMonth() async {
    final sessions = await _loadSessions();
    final month = _dateOf(DateTime.now()).substring(0, 7);
    var cost = 0.0;
    for (final s in sessions) {
      for (final m in s.messages) {
        final date = _dateOf(m.sentAt ?? s.updatedAt);
        if (!date.startsWith(month)) continue;
        cost += await priceService.costFor(
          m.modelId ?? s.modelId ?? '',
          m.promptTokens ?? 0,
          m.completionTokens ?? 0,
        );
      }
    }
    return cost;
  }

  Future<List<ChatSession>> _loadSessions() async {
    final db = await _db;
    if (db == null) return [];
    try {
      final rows = await db
          .customSelect(
            'SELECT id, title, updated_at FROM sessions '
            'ORDER BY updated_at DESC LIMIT 2000',
          )
          .get();
      final sessions = <ChatSession>[];
      for (final row in rows) {
        try {
          final messageRows = await db
              .customSelect(
                'SELECT * FROM messages WHERE session_id = ?',
                variables: [Variable.withString(row.data['id'] as String)],
              )
              .get();
          final messages = <ChatMessage>[];
          for (final m in messageRows) {
            messages.add(
              ChatMessage(
                role: m.data['role'] as String,
                content: m.data['content'] as String,
                promptTokens: m.data['prompt_tokens'] as int?,
                completionTokens: m.data['completion_tokens'] as int?,
                sentAt: (m.data['sent_at'] as int?) == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        m.data['sent_at'] as int,
                      ),
              ),
            );
          }
          sessions.add(
            ChatSession(
              id: row.data['id'] as String,
              title: row.data['title'] as String,
              messages: messages,
              createdAt: DateTime.now(),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                row.data['updated_at'] as int,
              ),
            ),
          );
        } catch (_) {}
      }
      return sessions;
    } catch (_) {
      return [];
    }
  }

  /// 从 usage_daily 导出原始 JSON（诊断/分享用）。
  Future<String> exportRawJson() async {
    final db = await _db;
    final entries = <Map<String, dynamic>>[];
    if (db != null) {
      try {
        final rows = await db
            .customSelect(
              'SELECT * FROM usage_daily ORDER BY date DESC LIMIT 500',
            )
            .get();
        for (final r in rows) {
          entries.add({
            'model_id': r.data['model_id'] as String,
            'provider_name': r.data['provider_name'] as String,
            'date': r.data['date'] as String,
            'prompt_tokens': r.data['prompt_tokens'] as int? ?? 0,
            'completion_tokens': r.data['completion_tokens'] as int? ?? 0,
            'calls': r.data['calls'] as int? ?? 0,
          });
        }
      } catch (_) {}
    }
    return jsonEncode(entries);
  }
}

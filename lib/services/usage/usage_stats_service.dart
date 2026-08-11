import 'dart:convert';

import '../../db/db.dart' show Database;
import '../../db/nona_database.dart';import '../../models/chat_message.dart';
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
  final NonaDatabase database;
  final PriceService priceService;

  UsageStatsService({NonaDatabase? database, PriceService? priceService})
      : database = database ?? NonaDatabase(),
        priceService = priceService ?? PriceService.instance;

  static String _dateOf(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  /// 冗余更新：写入会话后把消息用量 upsert 进 usage_daily。
  Future<void> recordSessions(List<ChatSession> sessions) async {
    final db = await database.open();
    if (db == null) return;
    try {
      db.execute('BEGIN TRANSACTION');
      for (final s in sessions) {
        for (final m in s.messages) {
          _upsertMessage(db, s, m);
        }
      }
      db.execute('COMMIT');
    } catch (_) {
      try {
        db.execute('ROLLBACK');
      } catch (_) {}
    }
  }

  void _upsertMessage(Database db, ChatSession session, ChatMessage m) {
    final prompt = m.promptTokens ?? 0;
    final completion = m.completionTokens ?? 0;
    if (prompt <= 0 && completion <= 0) return;
    final date = _dateOf(
      m.sentAt ?? session.updatedAt,
    );
    final modelId = m.modelId ?? session.modelId ?? '';
    final providerName = m.providerName ?? session.providerId ?? '';
    db.execute(
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

  /// 每日用量（近 [days] 天，含今天）。
  Future<List<DailyUsage>> daily({int days = 30}) async {
    final db = await database.open();
    if (db != null && _usageTableHasData(db)) {
      final rows = db.select(
        'SELECT date, SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c, '
        'SUM(calls) AS n FROM usage_daily '
        'WHERE date >= ? GROUP BY date ORDER BY date',
        [_dateOf(DateTime.now().subtract(Duration(days: days - 1)))],
      );
      return [
        for (final r in rows)
          DailyUsage(
            date: r['date'] as String,
            promptTokens: r['p'] as int? ?? 0,
            completionTokens: r['c'] as int? ?? 0,
            calls: r['n'] as int? ?? 0,
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

  bool _usageTableHasData(Database db) {
    try {
      final row = db.select('SELECT COUNT(*) AS n FROM usage_daily').first;
      return (row['n'] as int? ?? 0) > 0;
    } catch (_) {
      return false;
    }
  }

  /// 模型 TopN。
  Future<List<ModelUsage>> topModels({int limit = 10}) async {
    final db = await database.open();
    if (db != null && _usageTableHasData(db)) {
      final rows = db.select(
        'SELECT model_id, provider_name, SUM(prompt_tokens) AS p, '
        'SUM(completion_tokens) AS c, SUM(calls) AS n FROM usage_daily '
        'GROUP BY model_id, provider_name ORDER BY (p + c) DESC LIMIT ?',
        [limit],
      );
      return [
        for (final r in rows)
          ModelUsage(
            modelId: r['model_id'] as String,
            providerName: r['provider_name'] as String,
            promptTokens: r['p'] as int? ?? 0,
            completionTokens: r['c'] as int? ?? 0,
            calls: r['n'] as int? ?? 0,
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
    final db = await database.open();
    int prompt = 0;
    int completion = 0;
    if (db != null && _usageTableHasData(db)) {
      final row = db.select(
        'SELECT SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c '
        'FROM usage_daily',
      ).first;
      prompt = row['p'] as int? ?? 0;
      completion = row['c'] as int? ?? 0;
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
    final db = await database.open();
    if (db != null && _usageTableHasData(db)) {
      final month = _dateOf(DateTime.now()).substring(0, 7);
      final rows = db.select(
        'SELECT model_id, SUM(prompt_tokens) AS p, SUM(completion_tokens) AS c '
        'FROM usage_daily WHERE date LIKE ? GROUP BY model_id',
        ['$month%'],
      );
      var cost = 0.0;
      for (final r in rows) {
        cost += await priceService.costFor(
          r['model_id'] as String,
          r['p'] as int? ?? 0,
          r['c'] as int? ?? 0,
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
    final rows = await database.open();
    if (rows == null) return [];
    try {
      final result = rows
          .select(
            'SELECT id, title, updated_at FROM sessions '
            'ORDER BY updated_at DESC LIMIT 2000',
          )
          .toList();
      final sessions = <ChatSession>[];
      for (final row in result) {
        try {
          final messageRows = rows.select(
            'SELECT * FROM messages WHERE session_id = ?',
            [row['id']],
          );
          final messages = <ChatMessage>[];
          for (final m in messageRows) {
            messages.add(
              ChatMessage(
                role: m['role'] as String,
                content: m['content'] as String,
                promptTokens: m['prompt_tokens'] as int?,
                completionTokens: m['completion_tokens'] as int?,
                sentAt: (m['sent_at'] as int?) == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        m['sent_at'] as int,
                      ),
              ),
            );
          }
          sessions.add(
            ChatSession(
              id: row['id'] as String,
              title: row['title'] as String,
              messages: messages,
              createdAt: DateTime.now(),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                row['updated_at'] as int,
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
    final db = await database.open();
    final entries = <Map<String, dynamic>>[];
    if (db != null) {
      try {
        final rows = db.select(
          'SELECT * FROM usage_daily ORDER BY date DESC LIMIT 500',
        );
        for (final r in rows) {
          entries.add({
            'model_id': r['model_id'] as String,
            'provider_name': r['provider_name'] as String,
            'date': r['date'] as String,
            'prompt_tokens': r['prompt_tokens'] as int? ?? 0,
            'completion_tokens': r['completion_tokens'] as int? ?? 0,
            'calls': r['calls'] as int? ?? 0,
          });
        }
      } catch (_) {}
    }
    return jsonEncode(entries);
  }
}

import 'dart:convert';
import 'dart:math' show log;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../db/db.dart' show Database, Row;
import '../../db/nona_database.dart';
import '../../models/chat_session.dart';
import '../../utils/logger.dart';
import '../../utils/token_counter.dart';
import '../agent_service.dart';
import '../chat_service.dart';
import '../settings_service.dart';
import '../search_service.dart' show bigrams;

/// 记忆作用域。
enum MemoryScope {
  global('global'),
  agent('agent'),
  session('session');

  final String name;
  const MemoryScope(this.name);
}

/// 记忆优先级：核心（手动/置顶，始终注入）或自动（提取）。
enum MemoryPriority {
  core('core'),
  auto('auto');

  final String name;
  const MemoryPriority(this.name);
}

/// 一条历史版本（冲突更新/纠正时保留旧内容可回溯）。
class MemoryVersion {
  final String content;
  final DateTime ts;

  const MemoryVersion({required this.content, required this.ts});

  factory MemoryVersion.fromJson(Map<String, dynamic> json) => MemoryVersion(
    content: json['content']?.toString() ?? '',
    ts: DateTime.fromMillisecondsSinceEpoch(
      (json['ts'] as num?)?.toInt() ?? 0,
    ),
  );

  Map<String, dynamic> toJson() => {
    'content': content,
    'ts': ts.millisecondsSinceEpoch,
  };
}

/// 一条记忆。
class Memory {
  final String id;
  final MemoryScope scope;
  final String? scopeRef;
  String content;
  String category;
  bool pinned;
  final String? sourceMessageId;
  final DateTime createdAt;
  DateTime updatedAt;

  /// v2：标签（偏好/身份/工作/生活…）。
  List<String> tags;

  /// v2：优先级（core 始终注入 / auto 按相关性注入）。
  MemoryPriority priority;

  /// v2：使用次数（注入/检索命中时 +1）。
  int useCount;

  /// v2：最近使用时间。
  DateTime? lastUsedAt;

  /// v2：历史版本（纠正覆盖前保留旧内容）。
  List<MemoryVersion> history;

  Memory({
    required this.id,
    required this.scope,
    this.scopeRef,
    required this.content,
    this.category = 'fact',
    this.pinned = false,
    this.sourceMessageId,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.priority = MemoryPriority.auto,
    this.useCount = 0,
    this.lastUsedAt,
    this.history = const [],
  });

  factory Memory.fromRow(Row r) {
    List<String> parseTags() {
      try {
        final v = jsonDecode(r['tags_json'] as String? ?? '[]');
        if (v is List) return [for (final e in v) e.toString()];
      } catch (_) {}
      return const [];
    }

    List<MemoryVersion> parseHistory() {
      try {
        final v = jsonDecode(r['history_json'] as String? ?? '[]');
        if (v is List) {
          return [
            for (final e in v)
              if (e is Map<String, dynamic>) MemoryVersion.fromJson(e),
          ];
        }
      } catch (_) {}
      return const [];
    }

    final lastUsedRaw = r['last_used_at'] as int?;
    return Memory(
      id: r['id'] as String,
      scope: MemoryScope.values.firstWhere(
        (s) => s.name == r['scope'],
        orElse: () => MemoryScope.global,
      ),
      scopeRef: r['scope_ref'] as String?,
      content: r['content'] as String,
      category: r['category'] as String? ?? 'fact',
      pinned: (r['pinned'] as int? ?? 0) == 1,
      sourceMessageId: r['source_message_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      tags: parseTags(),
      priority: MemoryPriority.values.firstWhere(
        (p) => p.name == r['priority'],
        orElse: () => MemoryPriority.auto,
      ),
      useCount: r['use_count'] as int? ?? 0,
      lastUsedAt: lastUsedRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastUsedRaw),
      history: parseHistory(),
    );
  }
}

/// 注入统计（供 UI 显示记忆占用）。
class MemoryInjectionStats {
  final int injectedCount;
  final int injectedTokens;
  final int totalItems;
  final int capacity;

  const MemoryInjectionStats({
    required this.injectedCount,
    required this.injectedTokens,
    required this.totalItems,
    required this.capacity,
  });
}

/// v2 记忆空间预算配置（memory_spaces 表）。
///
/// 预算 4 项：总量 / 注入 token / 单条字数 / 提取间隔，全部可配置。
class MemorySpaceConfig {
  final MemoryScope scope;
  final String scopeRef;

  /// 记忆库总容量（默认 200 条，超限提示清理最久未用）。
  final int maxItems;

  /// 每次注入 token 预算（默认 800）。
  final int maxInjectTokens;

  /// 单条记忆最大字数（默认 100，提取时精简/拆分）。
  final int maxItemChars;

  /// 自动提取间隔（轮数，默认 10）。
  final int extractionInterval;

  const MemorySpaceConfig({
    required this.scope,
    this.scopeRef = '',
    this.maxItems = 200,
    this.maxInjectTokens = 800,
    this.maxItemChars = 100,
    this.extractionInterval = 10,
  });

  factory MemorySpaceConfig.fromRow(Row r) => MemorySpaceConfig(
    scope: MemoryScope.values.firstWhere(
      (s) => s.name == r['scope'],
      orElse: () => MemoryScope.global,
    ),
    scopeRef: r['scope_ref'] as String? ?? '',
    maxItems: r['max_items'] as int? ?? 200,
    maxInjectTokens: r['max_inject_tokens'] as int? ?? 800,
    maxItemChars: r['max_item_chars'] as int? ?? 100,
    extractionInterval: r['extraction_interval'] as int? ?? 10,
  );

  factory MemorySpaceConfig.fromJson(Map<String, dynamic> json) =>
      MemorySpaceConfig(
        scope: MemoryScope.values.firstWhere(
          (s) => s.name == json['scope'],
          orElse: () => MemoryScope.global,
        ),
        scopeRef: json['scope_ref'] as String? ?? '',
        maxItems: json['max_items'] as int? ?? 200,
        maxInjectTokens: json['max_inject_tokens'] as int? ?? 800,
        maxItemChars: json['max_item_chars'] as int? ?? 100,
        extractionInterval: json['extraction_interval'] as int? ?? 10,
      );

  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'scope_ref': scopeRef,
    'max_items': maxItems,
    'max_inject_tokens': maxInjectTokens,
    'max_item_chars': maxItemChars,
    'extraction_interval': extractionInterval,
  };
}

/// P2 分级提取候选（本地规则路与 LLM 输出共用）。
///
/// - [priority]：提取信号级 'P0'（偏好/纠正，高信号）或 'P1'（身份/事实）；
/// - [category]：'preference' | 'correction' | 'fact' | 'identity'；
/// - [correction]：纠正标记，为 true 时经 [MemoryService.add] 覆盖旧条目并保留历史；
/// - [targetId]：纠正时定位旧记忆，null 交由语义合并判定。
class ExtractionCandidate {
  final String priority;
  final String category;
  final String content;
  final bool correction;
  final String? targetId;

  const ExtractionCandidate({
    this.priority = 'P1',
    this.category = 'fact',
    required this.content,
    this.correction = false,
    this.targetId,
  });

  factory ExtractionCandidate.fromJson(Map<String, dynamic> json) =>
      ExtractionCandidate(
        priority: json['priority']?.toString() == 'P0' ? 'P0' : 'P1',
        category: _normalizeCategory(json['category']?.toString()),
        content: (json['content']?.toString() ?? '').trim(),
        correction: json['correction'] == true,
        targetId: json['targetId']?.toString(),
      );

  static String _normalizeCategory(String? c) {
    const allowed = {'preference', 'correction', 'identity'};
    return c != null && allowed.contains(c) ? c : 'fact';
  }

  Map<String, dynamic> toJson() => {
    'priority': priority,
    'category': category,
    'content': content,
    'correction': correction,
    'targetId': targetId,
  };
}

/// 记忆服务（F4-3）：自动提取 + 语义筛选注入 + 工具对齐。
///
/// - 作用域：全局 / Agent / 会话（会话级存 sessions.memory 兼容旧字段）；
/// - 自动提取：每 N 轮调用模型总结新增记忆（增量合并去重）；
/// - 注入：context_builder 组装 `<memories>`（会话 → Agent → 全局）；
/// - memory_tool：模型可主动写记忆。
///
/// P2 提取层：分级提取（P0 偏好/纠正 → P1 身份/事实），本地规则路先行，
/// 命中候选经 [add] 合并/纠正写入；未命中返回空，LLM 兜底留 P3 接入。
class MemoryService {
  final NonaDatabase database;
  final ChatService chatService;
  final SettingsService settingsService;

  static const int kMaxMemories = 50;

  /// v1→v2 迁移完成标记（成功即置位，幂等）。
  static const _kV1Migrated = 'memory_v1_migrated';

  MemoryService({
    NonaDatabase? database,
    ChatService? chatService,
    SettingsService? settingsService,
  }) : database = database ?? NonaDatabase(),
       chatService = chatService ?? ChatService(),
       settingsService = settingsService ?? SettingsService();

  Future<Database?> get _db => database.open();

  // ---------------- CRUD ----------------

  /// 按作用域列出记忆。
  Future<List<Memory>> list({
    MemoryScope? scope,
    String? scopeRef,
  }) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = scope == null
          ? db.select(
              'SELECT * FROM memories ORDER BY pinned DESC, updated_at DESC',
            )
          : scopeRef == null
          ? db.select(
              'SELECT * FROM memories WHERE scope = ? '
              'ORDER BY pinned DESC, updated_at DESC',
              [scope.name],
            )
          : db.select(
              'SELECT * FROM memories WHERE scope = ? AND scope_ref = ? '
              'ORDER BY pinned DESC, updated_at DESC',
              [scope.name, scopeRef],
            );
      return [for (final r in rows) Memory.fromRow(r)];
    } catch (_) {
      return const [];
    }
  }

  /// 新增/更新记忆（同语义内容覆盖，其余追加）。
  Future<Memory?> add({
    required MemoryScope scope,
    String? scopeRef,
    required String content,
    String category = 'fact',
    String? sourceMessageId,
    List<String> tags = const [],
    MemoryPriority priority = MemoryPriority.auto,
  }) async {
    final db = await _db;
    if (db == null) return null;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;
    final now = DateTime.now();
    try {
      // 同语义覆盖：与现有条目 bigram 相似度 > 0.5 视为同一记忆，
      // 覆盖时保留旧内容为历史版本；优先级取更高者（core 不被自动降级）。
      final existing = await list(scope: scope, scopeRef: scopeRef);
      for (final m in existing) {
        if (_similar(trimmed, m.content) >= 0.5) {
          final history = [...m.history];
          if (m.content != trimmed) {
            history.add(MemoryVersion(content: m.content, ts: m.updatedAt));
          }
          final mergedPriority =
              m.priority == MemoryPriority.core || priority == MemoryPriority.core
              ? MemoryPriority.core
              : priority;
          db.execute(
            'UPDATE memories SET content = ?, category = ?, tags_json = ?, '
            'priority = ?, history_json = ?, updated_at = ? WHERE id = ?',
            [
              trimmed,
              category,
              jsonEncode(tags),
              mergedPriority.name,
              jsonEncode([for (final h in history) h.toJson()]),
              now.millisecondsSinceEpoch,
              m.id,
            ],
          );
          return Memory.fromRow(
            db.select('SELECT * FROM memories WHERE id = ?', [m.id]).first,
          );
        }
      }
      // 上限：删除最旧的未置顶条目
      if (existing.length >= kMaxMemories) {
        final toDrop = existing
            .where((m) => !m.pinned)
            .toList()
            .reversed
            .firstOrNull;
        if (toDrop != null) {
          db.execute('DELETE FROM memories WHERE id = ?', [toDrop.id]);
        }
      }
      final id = '${now.microsecondsSinceEpoch}-${_idCounter++}';
      db.execute(
        'INSERT INTO memories '
        '(id, scope, scope_ref, content, category, pinned, source_message_id, '
        ' tags_json, priority, use_count, last_used_at, history_json, '
        ' created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, 0, NULL, '
        ' ?, ?, ?)',
        [
          id,
          scope.name,
          scopeRef,
          trimmed,
          category,
          sourceMessageId,
          jsonEncode(tags),
          priority.name,
          jsonEncode(const []),
          now.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
        ],
      );
      return Memory.fromRow(
        db.select('SELECT * FROM memories WHERE id = ?', [id]).first,
      );
    } catch (_) {
      return null;
    }
  }

  static int _idCounter = 0;

  Future<void> remove(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute('DELETE FROM memories WHERE id = ?', [id]);
    } catch (_) {}
  }

  Future<void> togglePin(String id, bool pinned) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute(
        'UPDATE memories SET pinned = ?, updated_at = ? WHERE id = ?',
        [pinned ? 1 : 0, DateTime.now().millisecondsSinceEpoch, id],
      );
    } catch (_) {}
  }

  Future<void> update(
    String id,
    String content,
    String category, {
    List<String>? tags,
    MemoryPriority? priority,
  }) async {
    final db = await _db;
    if (db == null) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    try {
      final existing = db
          .select('SELECT * FROM memories WHERE id = ?', [id])
          .firstOrNull;
      final old = existing == null ? null : Memory.fromRow(existing);
      final history = [
        ...?old?.history,
        if (old != null && old.content != trimmed)
          MemoryVersion(content: old.content, ts: old.updatedAt),
      ];
      db.execute(
        'UPDATE memories SET content = ?, category = ?, tags_json = ?, '
        'priority = ?, history_json = ?, updated_at = ? WHERE id = ?',
        [
          trimmed,
          category,
          jsonEncode(tags ?? old?.tags ?? const <String>[]),
          (priority ?? old?.priority ?? MemoryPriority.auto).name,
          jsonEncode([for (final h in history) h.toJson()]),
          DateTime.now().millisecondsSinceEpoch,
          id,
        ],
      );
    } catch (_) {}
  }

  /// 记录一次记忆使用（注入/检索命中时调用）：use_count +1 并刷新 last_used_at。
  Future<void> recordUse(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute(
        'UPDATE memories SET use_count = use_count + 1, last_used_at = ? '
        'WHERE id = ?',
        [DateTime.now().millisecondsSinceEpoch, id],
      );
    } catch (_) {}
  }

  // ---------------- 会话级记忆（sessions.memory 兼容） ----------------

  /// 写入会话级记忆（text，追加语义覆盖）。
  Future<void> setSessionMemory(ChatSession session, String text) async {
    session.memory = text;
    await _persistSessionMemory(session);
  }

  Future<void> _persistSessionMemory(ChatSession session) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute(
        'UPDATE sessions SET memory = ? WHERE id = ?',
        [session.memory, session.id],
      );
    } catch (_) {}
  }

  // ---------------- v1→v2 迁移 ----------------

  /// v1→v2 一次性迁移（首启时调用）：把 Agent.memories（prefs 里的字符串列表）
  /// 写入 memories 表（scope=agent, priority=core）。
  ///
  /// 幂等：迁移完成即置位 [_kV1Migrated]，失败保留 prefs 下次重试。
  Future<void> migrateV1Memories() async {
    final db = await _db;
    if (db == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kV1Migrated) ?? false) return;
      final agents = await AgentService().load();
      for (final agent in agents) {
        for (final content in agent.memories) {
          final trimmed = content.trim();
          if (trimmed.isEmpty) continue;
          await add(
            scope: MemoryScope.agent,
            scopeRef: agent.id,
            content: trimmed,
            category: 'fact',
            priority: MemoryPriority.core,
          );
        }
      }
      await prefs.setBool(_kV1Migrated, true);
    } catch (e) {
      Logger.error('memory', 'v1→v2 memory migration failed (kept prefs)', e);
    }
  }

  // ---------------- 自动提取 ----------------

  /// 每 [interval] 轮（可配，默认 10）或手动触发：
  /// 用模型总结最新对话增量，合并进 Agent 级记忆。
  ///
  /// 返回新增/更新的记忆条数；模型失败返回 -1。
  Future<int> extractAndMerge(
    ChatSession session, {
    String? agentId,
    AppSettings? settings,
    String Function()? prompt,
    int maxTurns = 200,
  }) async {
    if (session.messages.length < 4) return 0;
    final s = settings;
    if (s == null || s.apiKey.isEmpty || s.model.isEmpty) return 0;
    final messages = session.messages.length > maxTurns
        ? session.messages.sublist(session.messages.length - maxTurns)
        : session.messages;
    final transcript = messages
        .where((m) => m.content.trim().isNotEmpty)
        .map((m) => '${m.role == 'user' ? '用户' : '助手'}: ${m.content.trim()}')
        .join('\n');
    if (transcript.length < 40) return 0;
    final p = prompt != null
        ? prompt()
        : '从以下对话中提取值得长期记忆的事实与用户偏好，输出 JSON 数组 '
              '[{"category": "fact|preference|todo", "content": "..."}]，'
              '只输出 JSON，不要解释。\n\n$transcript';
    try {
      final result = await chatService.sendSimple(
        settings: s,
        userMessage: p,
        maxTokens: 400,
      );
      return await _mergeExtracted(result, agentId: agentId);
    } catch (_) {
      return -1;
    }
  }

  /// 解析模型输出 JSON 并增量合并（去重）。
  @visibleForTesting
  static List<Map<String, String>> parseExtraction(String raw) => _parseExtraction(raw);
  Future<int> _mergeExtracted(String raw, {String? agentId}) async {
    final items = _parseExtraction(raw);
    var merged = 0;
    for (final item in items) {
      final m = await add(
        scope: MemoryScope.agent,
        scopeRef: agentId,
        content: item['content'] ?? '',
        category: item['category'] ?? 'fact',
      );
      if (m != null) merged++;
    }
    return merged;
  }

  static List<Map<String, String>> _parseExtraction(String raw) {
    final result = <Map<String, String>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final e in decoded) {
          if (e is! Map<String, dynamic>) continue;
          final content = e['content']?.toString().trim() ?? '';
          if (content.isEmpty) continue;
          var category = e['category']?.toString() ?? 'fact';
          if (!const {'fact', 'preference', 'todo'}.contains(category)) {
            category = 'fact';
          }
          result.add({'content': content, 'category': category});
        }
      }
    } catch (_) {
      // 非 JSON：按行尝试提取「- 内容」
      for (final line in raw.split('\n')) {
        final trimmed = line.trim().replaceFirst(RegExp(r'^[-*•\d.]+'), '').trim();
        if (trimmed.length >= 4) {
          result.add({'content': trimmed, 'category': 'fact'});
        }
      }
    }
    return result;
  }

  // ---------------- P2 分级提取（本地规则路） ----------------

  /// P0 偏好规则：明确偏好/习惯表达。
  static const _kPreferencePatterns = [
    '我喜欢',
    '我习惯',
    '请以后',
    '以后都',
    '以后别',
    '不要',
    '别用',
  ];

  /// P0 纠正规则：用户纠正自己此前说法。
  static const _kCorrectionPatterns = ['不对', '其实我是', '更正', '应该是'];

  /// P2 提取入口：对单条用户消息做分级提取。
  ///
  /// 先走本地规则路（正则命中 P0 偏好 / 纠正），命中候选经 [add] 写入，
  /// add 内部做同语义合并/覆盖（纠正内容覆盖旧条目并保留历史版本）；
  /// 未命中规则返回 0（LLM 兜底为 no-op 桩，P3 接入 orchestrator）。
  /// [enabled] 开关为 false 时直接返回，不提取不落库。
  Future<int> extractMessage({
    required String text,
    required MemoryScope scope,
    String? scopeRef,
    String? sourceMessageId,
    bool enabled = true,
  }) async {
    if (!enabled) return 0;
    final candidates = extractCandidates(text);
    if (candidates.isEmpty) return 0;
    var merged = 0;
    for (final c in candidates) {
      final m = await add(
        scope: scope,
        scopeRef: scopeRef,
        content: c.content,
        category: c.category,
        tags: _tagsFor(c),
        sourceMessageId: sourceMessageId,
      );
      if (m != null) merged++;
    }
    return merged;
  }

  /// 本地规则提取：命中返回候选列表，未命中返回空（LLM 兜底 no-op）。
  @visibleForTesting
  static List<ExtractionCandidate> extractCandidates(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    final result = <ExtractionCandidate>[];
    final pref = _firstMatchAt(trimmed, _kPreferencePatterns);
    if (pref != null) {
      result.add(
        ExtractionCandidate(
          priority: 'P0',
          category: 'preference',
          content: _clipSentence(trimmed, pref.$2),
        ),
      );
    }
    final corr = _firstMatchAt(trimmed, _kCorrectionPatterns);
    if (corr != null) {
      result.add(
        ExtractionCandidate(
          priority: 'P0',
          category: 'correction',
          correction: true,
          content: _normalizeCorrection(_clipSentence(trimmed, corr.$2)),
        ),
      );
    }
    return result;
  }

  /// 取首个命中的规则及其匹配位置，未命中返回 null。
  static (String, int)? _firstMatchAt(String text, List<String> patterns) {
    for (final p in patterns) {
      final m = RegExp(p).firstMatch(text);
      if (m != null) return (p, m.start);
    }
    return null;
  }

  /// 取命中位置所在的一句话（句末标点/换行切分），并截断到 ≤100 字。
  static String _clipSentence(String text, int matchStart) {
    var start = matchStart;
    for (var i = matchStart - 1; i >= 0; i--) {
      if (RegExp(r'[。！？!?；;\n]').hasMatch(text[i])) {
        start = i + 1;
        break;
      }
    }
    var end = text.length;
    for (var i = matchStart; i < text.length; i++) {
      if (RegExp(r'[。！？!?；;\n]').hasMatch(text[i])) {
        end = i;
        break;
      }
    }
    var content = text.substring(start, end).trim();
    if (content.length > 100) {
      content = content.substring(0, 100);
    }
    return content;
  }

  /// 纠正句去头：去掉「不对，」「更正：」等引导语，保留纠正后的陈述。
  static String _normalizeCorrection(String content) {
    return content
        .replaceFirst(RegExp(r'^不对[\s,，。！!]*'), '')
        .replaceFirst(RegExp(r'^更正[\s:：,，。]*'), '')
        .trim();
  }

  static List<String> _tagsFor(ExtractionCandidate c) {
    if (c.correction || c.category == 'correction') return const ['纠正'];
    if (c.priority == 'P0' || c.category == 'preference') {
      return const ['偏好'];
    }
    return const ['身份'];
  }

  /// 读取分级提取 prompt（assets/prompts/extraction.txt），失败回落内置默认。
  @visibleForTesting
  Future<String> loadExtractionPrompt() async {
    try {
      return await rootBundle.loadString('assets/prompts/extraction.txt');
    } catch (_) {
      return '从以下消息中提取值得长期记住的记忆，输出 JSON 数组'
          '[{"priority":"P0|P1","category":"preference|correction|fact|identity",'
          '"content":"...","correction":true|false,"targetId":"..."}]，'
          'content≤100字，只输出 JSON。';
    }
  }

  /// P2 LLM 兜底路（no-op 桩）：P3 接入 orchestrator 时实现，
  /// 当前规则路未命中时直接返回 0，不发起模型调用。
  Future<int> extractWithLLM(String text, {bool enabled = true}) async {
    if (!enabled) return 0;
    return 0;
  }

  /// 注入统计（供 UI 显示占用）。
  MemoryInjectionStats? _lastStats;
  List<int> _lastInjectedIds = const [];

  MemoryInjectionStats? get lastInjectionStats => _lastStats;

  /// 注入文本组装：会话 → Agent → 全局，评分打分 + token 预算截断（v2）。
  /// 注入的条目 id 记录在 [_lastInjectedIds]，调用 [recordUseLast] 更新使用统计。
  String buildInjection({
    required String sessionMemory,
    required List<Memory> agentMemories,
    required List<Memory> globalMemories,
    String? query,
    int tokenBudget = 800,
  }) {
    final parts = <String>[];
    final injected = <int>[];
    var usedTokens = 0;
    if (sessionMemory.trim().isNotEmpty) {
      parts.add('会话记忆：${sessionMemory.trim()}');
      usedTokens += TokenCounter.estimate(sessionMemory.trim());
    }
    final all = <(double, Memory)>[];
    final agentTop = _selectTop(agentMemories, query, 5);
    for (final m in agentTop) {
      var score = 0.0;
      if (m.priority == MemoryPriority.core || m.pinned) score += 5;
      score += _similar(query ?? '', m.content) * 3;
      score += m.useCount > 0 ? (1 + log(m.useCount)) : 0;
      all.add((score, m));
    }
    final globalTop = _selectTop(globalMemories, query, 5);
    for (final m in globalTop) {
      var score = 0.0;
      if (m.priority == MemoryPriority.core || m.pinned) score += 4;
      score += _similar(query ?? '', m.content) * 2;
      all.add((score, m));
    }
    all.sort((a, b) => b.$1.compareTo(a.$1));
    final memoryLines = <String>[];
    for (final (_, m) in all.take(5)) {
      final line = '[${m.priority == MemoryPriority.core ? '核心' : '自动'}·${m.category}] ${m.content} <mem:${m.id}>';
      final cost = TokenCounter.estimate(line);
      if (usedTokens + cost > tokenBudget && memoryLines.isNotEmpty) break;
      usedTokens += cost;
      memoryLines.add(line);
      if (m.id.isNotEmpty) injected.add(int.tryParse(m.id) ?? -1);
    }
    if (memoryLines.isNotEmpty) {
      parts.add('关于用户与助手的长期记忆：');
      parts.addAll(memoryLines);
    }
    _lastInjectedIds = injected.where((id) => id > 0).toList();
    _lastStats = MemoryInjectionStats(
      injectedCount: injected.length,
      injectedTokens: usedTokens,
      totalItems: agentMemories.length + globalMemories.length,
      capacity: tokenBudget,
    );
    return parts.join('\n');
  }

  /// fire-and-forget：记录上一次注入命中的记忆使用次数。
  Future<void> recordUseLast() async {
    final ids = _lastInjectedIds;
    if (ids.isEmpty) return;
    final db = await _db;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      for (final id in ids) {
        db.execute(
          'UPDATE memories SET use_count = use_count + 1, last_used_at = ? WHERE id = ?',
          [now, id],
        );
      }
    } catch (_) {
      // fire-and-forget，失败静默
    }
  }

  /// bigram 打分取 topK（>15 条时生效；否则全部）。
  static List<Memory> _selectTop(
    List<Memory> memories,
    String? query,
    int topK,
  ) {
    if (memories.isEmpty) return const [];
    if (query == null || query.length < 2 || memories.length <= 15) {
      return memories.take(topK).toList();
    }
    final qb = bigrams(query.toLowerCase()).toSet();
    final scored = <(double, Memory)>[
      for (final m in memories)
        (
          qb
                  .where(
                    (bg) => m.content.toLowerCase().contains(bg),
                  )
                  .length /
              (qb.isEmpty ? 1 : qb.length),
          m,
        ),
    ];
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.take(topK).map((e) => e.$2).toList();
  }

  /// 两条文本的 bigram 相似度（0~1）。
  static double _similar(String a, String b) {
    final ba = bigrams(a.toLowerCase()).toSet();
    final bb = bigrams(b.toLowerCase()).toSet();
    if (ba.isEmpty || bb.isEmpty) return 0;
    final inter = ba.intersection(bb).length;
    return inter / (ba.length < bb.length ? ba.length : bb.length);
  }

  // ---------- P2 提取层：本地规则路（不耗模型） ----------

  static final RegExp _prefRe = RegExp(
    r'(我喜欢|我习惯|请以后|以后都|以后别|以后不要|不要|别用|别给我)',
  );
  static final RegExp _correctRe = RegExp(
    r'(不对|其实我是|更正|应该是|我不是这个意思)',
  );
  static final RegExp _identityRe = RegExp(
    r'(我是|我在|我住在|我在.*工作|我常|我是做)',
  );

  /// 从最新一条用户消息提取高信号记忆（本地规则路，不调用模型）。
  /// [enabled] 为 false 时直接返回（开关关闭）。
  /// 命中规则生成候选后走 [add]（自动触发语义合并/纠正覆盖）。
  /// 返回本轮新增/更新的记忆数量。
  Future<int> extractFromMessages({
    required MemoryScope scope,
    String? scopeRef,
    required String userText,
    bool enabled = true,
  }) async {
    if (!enabled) return 0;
    final text = userText.trim();
    if (text.isEmpty) return 0;

    final candidates = <({String content, String category, MemoryPriority priority})>[];

    // P0 纠正：优先（反义表达 → 走 add 的语义覆盖）
    if (_correctRe.hasMatch(text)) {
      final snippet = text.length > 60 ? text.substring(0, 60) : text;
      candidates.add((
        content: '用户纠正：$snippet',
        category: 'correction',
        priority: MemoryPriority.core,
      ));
    }
    // P0 偏好
    if (_prefRe.hasMatch(text)) {
      final snippet = text.length > 60 ? text.substring(0, 60) : text;
      candidates.add((
        content: '用户偏好：$snippet',
        category: 'preference',
        priority: MemoryPriority.core,
      ));
    }
    // P1 身份/事实
    if (_identityRe.hasMatch(text)) {
      final snippet = text.length > 60 ? text.substring(0, 60) : text;
      candidates.add((
        content: '用户事实：$snippet',
        category: 'identity',
        priority: MemoryPriority.auto,
      ));
    }

    // 每轮 ≤3 条（P0 优先：core 在前），单条 ≤100 字
    candidates.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    var saved = 0;
    for (final c in candidates.take(3)) {
      var content = c.content;
      if (content.length > 100) content = content.substring(0, 100);
      final added = await add(
        scope: scope,
        scopeRef: scopeRef,
        content: content,
        category: c.category,
        priority: c.priority,
      );
      if (added != null) saved++;
    }
    return saved;
  }
}

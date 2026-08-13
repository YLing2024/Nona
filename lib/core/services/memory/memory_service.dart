import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../database/nona_app_database.dart';
import '../../database/nona_db_factory.dart';
import '../../models/chat_session.dart';
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
  });

  factory Memory.fromRow(MemoryRow r) => Memory(
    id: r.id,
    scope: MemoryScope.values.firstWhere(
      (s) => s.name == r.scope,
      orElse: () => MemoryScope.global,
    ),
    scopeRef: r.scopeRef,
    content: r.content,
    category: r.category,
    pinned: r.pinned,
    sourceMessageId: r.sourceMessageId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );
}

/// 记忆服务（F4-3）：自动提取 + 语义筛选注入 + 工具对齐。
///
/// - 作用域：全局 / Agent / 会话（会话级存 sessions.memory 兼容旧字段）；
/// - 自动提取：每 N 轮调用模型总结新增记忆（增量合并去重）；
/// - 注入：context_builder 组装 `<memories>`（会话 → Agent → 全局）；
/// - memory_tool：模型可主动写记忆。
class MemoryService {
  final NonaAppDatabase? _explicitDb;
  final ChatService chatService;
  final SettingsService settingsService;
  Future<NonaAppDatabase?>? _cachedDb;

  static const int kMaxMemories = 50;

  MemoryService({
    NonaAppDatabase? database,
    ChatService? chatService,
    SettingsService? settingsService,
  }) : _explicitDb = database,
       chatService = chatService ?? ChatService(),
       settingsService = settingsService ?? SettingsService();

  /// 解析数据库（实例内缓存：测试环境每次打开独立内存库，需保持同实例一致）。
  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  // ---------------- CRUD ----------------

  /// 按作用域列出记忆。
  Future<List<Memory>> list({
    MemoryScope? scope,
    String? scopeRef,
  }) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final query = db.select(db.memories)
        ..orderBy([
          (t) => OrderingTerm.desc(t.pinned),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]);
      if (scope != null) {
        query.where((t) => t.scope.equals(scope.name));
        if (scopeRef != null) {
          query.where((t) => t.scopeRef.equals(scopeRef));
        }
      }
      final rows = await query.get();
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
  }) async {
    final db = await _db;
    if (db == null) return null;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;
    final now = DateTime.now();
    try {
      // 同语义覆盖：与现有条目 bigram 相似度 > 0.5 视为同一记忆
      final existing = await list(scope: scope, scopeRef: scopeRef);
      for (final m in existing) {
        if (_similar(trimmed, m.content) >= 0.5) {
          await (db.update(db.memories)..where((t) => t.id.equals(m.id)))
              .write(
            MemoriesCompanion(
              content: Value(trimmed),
              category: Value(category),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
          return Memory.fromRow(
            (await (db.select(db.memories)..where((t) => t.id.equals(m.id)))
                    .get())
                .first,
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
          await (db.delete(db.memories)..where((t) => t.id.equals(toDrop.id)))
              .go();
        }
      }
      final id = '${now.microsecondsSinceEpoch}-${_idCounter++}';
      await db.into(db.memories).insert(
        MemoriesCompanion.insert(
          id: id,
          scope: scope.name,
          scopeRef: Value(scopeRef),
          content: trimmed,
          category: Value(category),
          pinned: const Value(false),
          sourceMessageId: Value(sourceMessageId),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      return Memory.fromRow(
        (await (db.select(db.memories)..where((t) => t.id.equals(id))).get())
            .first,
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
      await (db.delete(db.memories)..where((t) => t.id.equals(id))).go();
    } catch (_) {}
  }

  Future<void> togglePin(String id, bool pinned) async {
    final db = await _db;
    if (db == null) return;
    try {
      await (db.update(db.memories)..where((t) => t.id.equals(id)))
          .write(
        MemoriesCompanion(
          pinned: Value(pinned),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    } catch (_) {}
  }

  Future<void> update(String id, String content, String category) async {
    final db = await _db;
    if (db == null) return;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    try {
      await (db.update(db.memories)..where((t) => t.id.equals(id)))
          .write(
        MemoriesCompanion(
          content: Value(trimmed),
          category: Value(category),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
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
      await (db.update(db.sessions)..where((t) => t.id.equals(session.id)))
          .write(SessionsCompanion(memory: Value(session.memory)));
    } catch (_) {}
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

  /// 注入文本组装：会话 → Agent → 全局，>15 条时 bigram 打分取 top5。
  String buildInjection({
    required String sessionMemory,
    required List<Memory> agentMemories,
    required List<Memory> globalMemories,
    String? query,
  }) {
    final parts = <String>[];
    if (sessionMemory.trim().isNotEmpty) {
      parts.add('会话记忆：${sessionMemory.trim()}');
    }
    final memories = _selectTop(agentMemories, query, 5);
    if (memories.isNotEmpty) {
      parts.add('关于用户与助手的长期记忆：');
      for (final m in memories) {
        parts.add('- ${m.content}');
      }
    }
    if (globalMemories.isNotEmpty && parts.length < 8) {
      final globals = _selectTop(globalMemories, query, 3);
      for (final m in globals) {
        parts.add('- ${m.content}');
      }
    }
    return parts.join('\n');
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
}

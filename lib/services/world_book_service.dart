import 'dart:async';
import 'dart:convert';

import '../../db/db.dart' show Database, Row;
import '../../db/nona_database.dart';
import '../../models/chat_message.dart';
import '../../utils/logger.dart';

/// 世界书条目。
class WorldBookEntry {
  final String id;
  String title;
  List<String> keywords;
  String content;
  int priority;
  int scanDepth;
  bool caseSensitive;
  String injectionPosition; // before_system_prompt / after_system_prompt / top_of_chat / bottom_of_chat / at_depth
  String role; // user / assistant
  bool constantActive;
  bool enabled;

  WorldBookEntry({
    required this.id,
    required this.title,
    this.keywords = const [],
    this.content = '',
    this.priority = 100,
    this.scanDepth = 1,
    this.caseSensitive = false,
    this.injectionPosition = 'top_of_chat',
    this.role = 'user',
    this.constantActive = false,
    this.enabled = true,
  });

  factory WorldBookEntry.fromRow(Row r) => WorldBookEntry(
    id: r['id'] as String,
    title: r['title'] as String,
    keywords: (jsonDecode(r['keywords_json'] as String) as List<dynamic>)
        .map((e) => e.toString())
        .toList(),
    content: r['content'] as String,
    priority: r['priority'] as int? ?? 100,
    scanDepth: r['scan_depth'] as int? ?? 1,
    caseSensitive: (r['case_sensitive'] as int? ?? 0) == 1,
    injectionPosition: r['injection_position'] as String? ?? 'top_of_chat',
    role: r['role'] as String? ?? 'user',
    constantActive: (r['constant_active'] as int? ?? 0) == 1,
    enabled: (r['enabled'] as int? ?? 1) == 1,
  );

  factory WorldBookEntry.fromJson(Map<String, dynamic> json) => WorldBookEntry(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    keywords: (json['keywords'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    content: json['content'] as String? ?? '',
    priority: json['priority'] as int? ?? 100,
    scanDepth: json['scanDepth'] as int? ?? 1,
    caseSensitive: json['caseSensitive'] as bool? ?? false,
    injectionPosition: json['injectionPosition'] as String? ?? 'top_of_chat',
    role: json['role'] as String? ?? 'user',
    constantActive: json['constantActive'] as bool? ?? false,
    enabled: json['enabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'keywords': keywords,
    'content': content,
    'priority': priority,
    'scanDepth': scanDepth,
    'caseSensitive': caseSensitive,
    'injectionPosition': injectionPosition,
    'role': role,
    'constantActive': constantActive,
    'enabled': enabled,
  };
}

/// 一次请求的注入结果：系统提示词片段 + 消息数组插入项。
class WorldBookInjection {
  final String systemPromptAdd;

  /// (角色, 文本) 插入消息数组。
  final List<(String, String)> messageInserts;

  const WorldBookInjection({
    this.systemPromptAdd = '',
    this.messageInserts = const [],
  });

  bool get isEmpty => systemPromptAdd.isEmpty && messageInserts.isEmpty;
}

/// 世界书服务（F5）：触发检测 → 按 priority 排序 → 注入预算 800 token。
class WorldBookService {
  final NonaDatabase database;

  /// 注入预算（tokens，近似按字符数估算）。
  static const int injectionBudget = 800;

  static const List<String> positions = [
    'before_system_prompt',
    'after_system_prompt',
    'top_of_chat',
    'bottom_of_chat',
    'at_depth',
  ];

  WorldBookService({NonaDatabase? database})
      : database = database ?? NonaDatabase();

  Future<Database?> get _db => database.open();

  // ---------------- CRUD ----------------

  Future<List<WorldBookEntry>> list() async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = db.select(
        'SELECT * FROM world_book_entries ORDER BY priority DESC, title ASC',
      );
      return [for (final r in rows) WorldBookEntry.fromRow(r)];
    } catch (e) {
      Logger.error('wb', 'list failed', e);
      return const [];
    }
  }

  Future<void> save(WorldBookEntry entry) async {
    final db = await _db;
    if (db == null) return;
    final id = entry.id.isEmpty
        ? '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}'
        : entry.id;
    try {
      db.execute(
        'INSERT OR REPLACE INTO world_book_entries '
        '(id, title, keywords_json, content, priority, scan_depth, '
        ' case_sensitive, injection_position, role, constant_active, enabled) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          entry.title,
          jsonEncode(entry.keywords),
          entry.content,
          entry.priority,
          entry.scanDepth,
          entry.caseSensitive ? 1 : 0,
          entry.injectionPosition,
          entry.role,
          entry.constantActive ? 1 : 0,
          entry.enabled ? 1 : 0,
        ],
      );
    } catch (e) {
      Logger.error('wb', 'save failed', e);
    }
  }

  static int _idCounter = 0;

  Future<void> delete(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute('DELETE FROM world_book_entries WHERE id = ?', [id]);
    } catch (_) {}
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final db = await _db;
    if (db == null) return;
    try {
      db.execute(
        'UPDATE world_book_entries SET enabled = ? WHERE id = ?',
        [enabled ? 1 : 0, id],
      );
    } catch (_) {}
  }

  // ---------------- 触发与注入 ----------------

  /// 对最新消息计算注入：触发检测（用户最新 scan_depth 条消息关键词/
  /// 正则匹配）→ priority 排序 → 注入预算内截断。
  WorldBookInjection buildInjection(List<ChatMessage> messages) {
    final entries = _matchEntries(messages);
    if (entries.isEmpty) return const WorldBookInjection();

    final before = StringBuffer();
    final after = StringBuffer();
    final inserts = <(String, String)>[];
    var budget = injectionBudget;
    for (final e in entries) {
      final text = e.content.trim();
      if (text.isEmpty) continue;
      if (budget <= 0) break;
      budget -= text.length;
      switch (e.injectionPosition) {
        case 'before_system_prompt':
          before.writeln('[世界书·${e.title}] $text');
        case 'after_system_prompt':
          after.writeln('[世界书·${e.title}] $text');
        case 'top_of_chat':
          inserts.insert(0, (e.role, text));
        case 'bottom_of_chat':
          inserts.add((e.role, text));
        case 'at_depth':
          inserts.add((e.role, text));
      }
    }
    return WorldBookInjection(
      systemPromptAdd: [
        before.toString().trim(),
        after.toString().trim(),
      ].where((s) => s.isNotEmpty).join('\n\n'),
      messageInserts: inserts,
    );
  }

  /// 触发检测：常驻条目 + 关键词/正则命中。
  List<WorldBookEntry> _matchEntries(List<ChatMessage> messages) {
    final all = _cachedEntries;
    if (all.isEmpty) return const [];
    final recent = messages.takeLast(8).toList();
    final matched = <WorldBookEntry>[];
    for (final e in all) {
      if (!e.enabled) continue;
      if (e.constantActive) {
        matched.add(e);
        continue;
      }
      // 扫描最近 scan_depth 条用户消息（从最新开始）
      final depth = e.scanDepth.clamp(1, 8);
      final userMessages = recent.where((m) => m.role == 'user').toList();
      final targets = userMessages.length <= depth
          ? userMessages
          : userMessages.sublist(userMessages.length - depth);
      for (final m in targets) {
        if (_matchesEntry(e, m.content)) {
          matched.add(e);
          break;
        }
      }
    }
    matched.sort((a, b) => b.priority.compareTo(a.priority));
    return matched;
  }

  bool _matchesEntry(WorldBookEntry e, String text) {
    if (text.isEmpty) return false;
    final base = e.caseSensitive ? text : text.toLowerCase();
    for (final kw in e.keywords) {
      final keyword = e.caseSensitive ? kw : kw.toLowerCase();
      if (keyword.isEmpty) continue;
      if (base.contains(keyword)) return true;
    }
    return false;
  }

  List<WorldBookEntry> _cachedEntries = [];
  bool _loaded = false;
  Future<void>? _loading;

  /// 加载条目（惰性缓存）。
  Future<List<WorldBookEntry>> ensureLoaded() async {
    if (_loaded) return _cachedEntries;
    final existing = _loading;
    if (existing != null) {
      await existing;
      return _cachedEntries;
    }
    final completer = Completer<void>();
    _loading = completer.future;
    try {
      _cachedEntries = await list();
      _loaded = true;
    } finally {
      completer.complete();
    }
    return _cachedEntries;
  }

  // ---------------- 导入/导出 ----------------

  /// JSON 导入（SillyTavern 风格条目数组），返回导入条数。
  Future<int> importJson(String raw) async {
    try {
      final data = jsonDecode(raw);
      final list = data is List
          ? data
          : (data as Map<String, dynamic>)['entries'] as List<dynamic>;
      var count = 0;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final entry = WorldBookEntry.fromJson(e);
        if (entry.title.isEmpty && entry.content.isEmpty) continue;
        await save(entry);
        count++;
      }
      await reload();
      return count;
    } catch (e) {
      Logger.error('wb', 'import failed', e);
      return 0;
    }
  }

  /// JSON 导出。
  Future<String> exportJson() async {
    final entries = await list();
    return jsonEncode({
      'app': 'nona',
      'type': 'world_book',
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> reload() async {
    _loaded = false;
    _cachedEntries = [];
    await ensureLoaded();
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n
      ? this
      : sublist(length - n);
}

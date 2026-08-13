import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import '../models/chat_message.dart';
import '../utils/logger.dart';

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

  /// v6：正则匹配开关（D-06）。
  bool useRegex;

  /// v6：所属书 id（D-06；null = 默认书）。
  String? bookId;

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
    this.useRegex = false,
    this.bookId,
  });

  factory WorldBookEntry.fromRow(WorldBookEntryRow r) => WorldBookEntry(
    id: r.id,
    title: r.title,
    keywords: _parseList(r.keywordsJson),
    content: r.content,
    priority: r.priority,
    scanDepth: r.scanDepth,
    caseSensitive: r.caseSensitive,
    injectionPosition: r.injectionPosition,
    role: r.role,
    constantActive: r.constantActive,
    enabled: r.enabled,
    useRegex: r.useRegex,
    bookId: r.bookId,
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
    useRegex: json['useRegex'] as bool? ?? false,
    bookId: json['bookId'] as String?,
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
    'useRegex': useRegex,
    'bookId': bookId,
  };
}

/// D-06：世界书（多书容器，条目按 bookId 归属）。
class WorldBook {
  final String id;
  String name;
  String description;
  bool enabled;

  WorldBook({
    required this.id,
    required this.name,
    this.description = '',
    this.enabled = true,
  });

  factory WorldBook.fromJson(Map<String, dynamic> json) => WorldBook(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Unnamed',
    description: json['description'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
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
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  /// 注入预算（tokens，近似按字符数估算）。
  static const int injectionBudget = 800;

  static const List<String> positions = [
    'before_system_prompt',
    'after_system_prompt',
    'top_of_chat',
    'bottom_of_chat',
    'at_depth',
  ];

  WorldBookService({NonaAppDatabase? database}) : _explicitDb = database;

  /// 解析数据库（实例内缓存：测试环境每次打开独立内存库，需保持同实例一致）。
  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  // ---------------- CRUD ----------------

  Future<List<WorldBookEntry>> list() async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await (db.select(db.worldBookEntries)
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.title),
            ]))
          .get();
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
      await db.into(db.worldBookEntries).insertOnConflictUpdate(
        WorldBookEntriesCompanion.insert(
          id: id,
          title: entry.title,
          keywordsJson: Value(jsonEncode(entry.keywords)),
          content: entry.content,
          priority: Value(entry.priority),
          scanDepth: Value(entry.scanDepth),
          caseSensitive: Value(entry.caseSensitive),
          injectionPosition: Value(entry.injectionPosition),
          role: Value(entry.role),
          constantActive: Value(entry.constantActive),
          enabled: Value(entry.enabled),
          useRegex: Value(entry.useRegex),
          bookId: Value(entry.bookId),
        ),
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
      await (db.delete(db.worldBookEntries)..where((t) => t.id.equals(id))).go();
    } catch (_) {}
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final db = await _db;
    if (db == null) return;
    try {
      await (db.update(db.worldBookEntries)..where((t) => t.id.equals(id)))
          .write(WorldBookEntriesCompanion(enabled: Value(enabled)));
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
    // D-06：停用的书整体不参与注入
    final disabledBooks = {
      for (final b in _cachedBooks)
        if (!b.enabled) b.id,
    };
    final effective = [
      for (final e in all)
        if (!disabledBooks.contains(e.bookId)) e,
    ];
    if (effective.isEmpty) return const [];
    final recent = messages.takeLast(8).toList();
    final matched = <WorldBookEntry>[];
    for (final e in effective) {
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
    if (e.useRegex) {
      try {
        return _regexCache
            .putIfAbsent(
              '${e.id}:${e.caseSensitive}:${e.keywords.join('|')}',
              () => RegExp(
                e.keywords.join('|'),
                caseSensitive: e.caseSensitive,
              ),
            )
            .hasMatch(text);
      } catch (_) {
        return false;
      }
    }
    final base = e.caseSensitive ? text : text.toLowerCase();
    for (final kw in e.keywords) {
      final keyword = e.caseSensitive ? kw : kw.toLowerCase();
      if (keyword.isEmpty) continue;
      if (base.contains(keyword)) return true;
    }
    return false;
  }

  /// 正则编译缓存（D-06：编译缓存 + 异常条目跳过）。
  final Map<String, RegExp> _regexCache = {};

  List<WorldBookEntry> _cachedEntries = [];
  final List<WorldBook> _cachedBooks = [];
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
      _cachedBooks
        ..clear()
        ..addAll(await listBooks());
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

  // ---------------- D-06：多书 / 激活 / 命中测试 ----------------

  /// 读取全部书（prefs JSON，损坏自愈）。
  Future<List<WorldBook>> listBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('world_books');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in decoded)
          if (e is Map<String, dynamic>) WorldBook.fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBook(WorldBook book) async {
    final books = await listBooks();
    final index = books.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      books[index] = book;
    } else {
      books.add(book);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'world_books',
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
    await reload();
  }

  Future<void> deleteBook(String id) async {
    final books = await listBooks()..removeWhere((b) => b.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'world_books',
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
    // 清空该书条目的归属（回默认书）
    final entries = await list();
    for (final e in entries) {
      if (e.bookId == id) {
        e.bookId = null;
        await save(e);
      }
    }
    await reload();
  }

  /// 某 Agent 激活的书 id 列表（`__global__` 为全局兜底）。
  Future<List<String>> activeBookIds({String? agentId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('world_books_active_${agentId ?? '__global__'}') ??
        const [];
  }

  Future<void> setActiveBooks({
    String? agentId,
    required List<String> ids,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'world_books_active_${agentId ?? '__global__'}',
      ids,
    );
  }

  /// D-06：命中测试——返回（命中条目, 注入预览）。
  Future<List<({WorldBookEntry entry, String preview})>> hitTest(
    String text,
  ) async {
    await ensureLoaded();
    final userMsg = ChatMessage(role: 'user', content: text);
    final matched = _matchEntries([userMsg]);
    return [
      for (final e in matched)
        (
          entry: e,
          preview: e.content.length > 120
              ? '${e.content.substring(0, 120)}…'
              : e.content,
        ),
    ];
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n
      ? this
      : sublist(length - n);
}

List<String> _parseList(String raw) {
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  } catch (_) {
    return const [];
  }
}

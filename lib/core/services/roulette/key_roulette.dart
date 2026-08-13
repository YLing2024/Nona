import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/fs.dart' show pathSeparator, readTextFile, writeTextFile;

/// 多 Key 轮换器（F2-3）：按 provider 独立 LRU。
///
/// - key 按逗号/换行切分去重；优先「从未用过」→ 最久未用；
/// - 24h 过期重置；失败标记短期不再选中（5 分钟冷却）；
/// - 持久化 `roulette_<providerId>.json`（应用支持目录），Web 回退 prefs；
/// - 文件锁防并发（同一进程内同步队列）。
class KeyRoulette {
  final String providerId;

  static const Duration ttl = Duration(hours: 24);
  static const Duration failureCooldown = Duration(minutes: 5);

  KeyRoulette(this.providerId);

  final List<String> _allKeys = [];
  final Map<String, int> _lastUsed = {}; // key → 单调序号（排序用，杜绝平局）
  final Map<String, int> _lastUsedWall = {}; // key → 墙上时钟 µs（TTL 用）
  final Map<String, int> _failedAt = {}; // key → 失败时间 µs
  bool _loaded = false;
  Future<void>? _loading;
  Future<void>? _writeQueue;

  /// 单调递增序号：Windows 时钟粗粒度下多个 pick 同 tick，
  /// 用序号排序保证 LRU 无平局。
  static int _tick = 0;

  /// JS 可精确表示的最大整数（Web 编译要求，作哨兵）。
  static const int _maxSafeInt = 9007199254740991;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await (_loading ??= _load());
  }

  Future<void> _load() async {
  Map<String, dynamic>? data;
  try {
    final path = await _statePath();
    if (path != null) {
      final raw = await readTextFile(path);
      if (raw != null && raw.isNotEmpty) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      }
    }
  } catch (_) {
    data = null;
  }
    // 无文件（Web / 测试 / 首次）时回退 prefs
    if (data == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_prefsKey);
        if (raw != null && raw.isNotEmpty) {
          data = jsonDecode(raw) as Map<String, dynamic>;
        }
      } catch (_) {
        // 状态损坏：忽略，从零开始
      }
    }
    if (data != null) {
      final keys = (data['keys'] as List<dynamic>? ?? []).cast<String>();
      _allKeys
        ..clear()
        ..addAll(keys);
      (data['lastUsed'] as Map<String, dynamic>? ?? {})
          .forEach((k, v) => _lastUsed[k] = (v as num).toInt());
      (data['lastUsedWall'] as Map<String, dynamic>? ?? {})
          .forEach((k, v) => _lastUsedWall[k] = (v as num).toInt());
      (data['failedAt'] as Map<String, dynamic>? ?? {})
          .forEach((k, v) => _failedAt[k] = (v as num).toInt());
    }
    _loaded = true;
  }

  /// 设置 key 集合（去重），保留使用历史。
  Future<void> setKeys(List<String> keys) async {
    await _ensureLoaded();
    final cleaned = <String>{
      for (final k in keys)
        if (k.trim().isNotEmpty) k.trim(),
    };
    final removed = _allKeys.where((k) => !cleaned.contains(k)).toList();
    _allKeys
      ..clear()
      ..addAll(cleaned);
    for (final k in removed) {
      _lastUsed.remove(k);
      _lastUsedWall.remove(k);
      _failedAt.remove(k);
    }
    await _persist();
  }

  /// 解析多行/逗号分隔的 key 输入。
  static List<String> parseKeys(String raw) => [
    for (final part in raw.split(RegExp(r'[,\n\r;]')))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  /// 选取下一个 key（LRU + 失败冷却 + 24h TTL 重置）。
  Future<String?> next() async {
    await _ensureLoaded();
    if (_allKeys.isEmpty) return null;
    final nowWall = DateTime.now().microsecondsSinceEpoch;
    // 24h 过期：全量重置（按墙上时钟判断）
    final oldestEver = _lastUsedWall.values.isEmpty
        ? nowWall
        : _lastUsedWall.values.reduce((a, b) => a < b ? a : b);
    if (nowWall - oldestEver > ttl.inMicroseconds) {
      _lastUsed.clear();
      _lastUsedWall.clear();
    }
    String? best;
    var bestScore = _maxSafeInt;
    for (final key in _allKeys) {
      final failedAt = _failedAt[key];
      if (failedAt != null && nowWall - failedAt < failureCooldown.inMicroseconds) {
        continue; // 冷却中
      }
      final last = _lastUsed[key] ?? 0;
      // 序号越小越久未用；从未用过（0）最高优先级
      if (last < bestScore) {
        bestScore = last;
        best = key;
      }
    }
    // 全部冷却中：取序号最旧（带失败标记的也放行，避免死锁）
    if (best == null) {
      String? oldestKey;
      var oldest = _maxSafeInt;
      for (final key in _allKeys) {
        final last = _lastUsed[key] ?? 0;
        if (last < oldest) {
          oldest = last;
          oldestKey = key;
        }
      }
      best = oldestKey ?? _allKeys.first;
    }
    _tick++;
    _lastUsed[best] = _tick;
    _lastUsedWall[best] = nowWall;
    await _persist();
    return best;
  }

  /// 标记 key 失败（短期不再选中）。
  Future<void> markFailed(String key) async {
    await _ensureLoaded();
    _failedAt[key] = DateTime.now().microsecondsSinceEpoch;
    await _persist();
  }

  /// 标记 key 成功（清除失败标记）。
  Future<void> markSuccess(String key) async {
    await _ensureLoaded();
    _failedAt.remove(key);
    await _persist();
  }

  Future<void> _persist() {
    final data = jsonEncode({
      'keys': _allKeys,
      'lastUsed': _lastUsed,
      'lastUsedWall': _lastUsedWall,
      'failedAt': _failedAt,
    });
    _writeQueue = (_writeQueue ?? Future.value()).then((_) async {
      try {
        final path = await _statePath();
        if (path != null) {
          await writeTextFile(path, data);
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, data);
      } catch (_) {
        // 持久化失败静默（内存状态仍可用）
      }
    });
    return _writeQueue!;
  }

  Future<String?> _statePath() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return '${dir.path}$pathSeparator$_prefsKey.json';
    } catch (_) {
      return null;
    }
  }

  String get _prefsKey => 'roulette_$providerId';

  /// 当前全部 key（测试/调试用）。
  Future<List<String>> keys() async {
    await _ensureLoaded();
    return List.of(_allKeys);
  }
}

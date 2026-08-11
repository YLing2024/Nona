import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../db/nona_database.dart';
import '../models/chat_session.dart';
import '../utils/logger.dart';
import 'session_persistence.dart';
import 'session_persistence_sqlite.dart';

/// 文件存储实现：会话索引 + 每会话独立文件，支持增量写。
///
/// 目录结构（应用支持目录下）：
/// ```
/// <support>/
/// ├── nona_sessions/
/// │   ├── index.json          # 有序会话 id 列表
/// │   └── sessions/<id>.json  # 单个会话完整数据
/// ```
///
/// 当目录提供器不可用（如 flutter_test 无插件环境、且真实文件 IO 会阻塞
/// fake-async 事件循环）时，自动退化为进程内内存存储，保证应用与测试可用。
class SessionPersistenceIo implements SessionPersistence {
  static const _dirName = 'nona_sessions';

  /// 目录提供器；默认使用 path_provider，测试可注入临时目录。
  final Future<Directory> Function() _directoryProvider;

  /// 已写入的会话 JSON 缓存（按 id），用于跳过内容未变的写盘。
  final Map<String, String> _cache = {};

  Directory? _base;

  /// 内存退化模式的文件内容（key 为虚拟文件名）。
  final Map<String, String> _mem = {};
  bool _memory = false;

  SessionPersistenceIo({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? _defaultDirectoryProvider;

  /// 默认目录提供器：flutter_test 环境下跳过 path_provider 平台调用
  /// （该调用在 fake-async 中不会完成），直接走内存退化模式。
  static Future<Directory> _defaultDirectoryProvider() {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      throw const FileSystemException('test environment, use in-memory storage');
    }
    return getApplicationSupportDirectory();
  }

  Future<Directory> _baseDir() async {
    if (_base != null) return _base!;
    try {
      final root = await _directoryProvider();
      _base = Directory('${root.path}${Platform.pathSeparator}$_dirName');
      await _base!.create(recursive: true);
      return _base!;
    } catch (_) {
      // path_provider 不可用（如单元/组件测试环境）时退化为内存存储
      _memory = true;
      return _base ??= Directory('');
    }
  }

  Future<Directory> _sessionsDir() async {
    final base = await _baseDir();
    final dir = Directory('${base.path}${Platform.pathSeparator}sessions');
    if (!_memory) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _indexFile(Directory base) =>
      File('${base.path}${Platform.pathSeparator}index.json');

  File _sessionFile(Directory sessionsDir, String id) =>
      File('${sessionsDir.path}${Platform.pathSeparator}$id.json');

  // ---------------- 底层读写（文件 / 内存双实现） ----------------

  Future<String?> _read(String key) async {
    if (_memory) return _mem[key];
    final file = File(key);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// 原子写入：先写临时文件再重命名，避免进程中断导致目标文件损坏。
  Future<void> _write(String key, String data) async {
    if (_memory) {
      _mem[key] = data;
      return;
    }
    final file = File(key);
    final tmp = File('$key.tmp');
    try {
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      // 重命名失败（如跨设备/权限）时回退直接写入
      Logger.warn('session', 'atomic write failed, fallback to direct write: ');
      Logger.error('session', 'write failed', e);
      await file.writeAsString(data, flush: true);
      if (await tmp.exists()) {
        try {
          await tmp.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _delete(String key) async {
    if (_memory) {
      _mem.remove(key);
      return;
    }
    final file = File(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ---------------- 接口实现 ----------------

  @override
  Future<List<ChatSession>?> readAll() async {
    final base = await _baseDir();
    final indexKey = _indexKey(base);
    final raw = await _read(indexKey);
    if (raw == null) return null;
    List<String> ids;
    try {
      ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (e) {
      Logger.error('session', 'session index corrupt, treated as empty', e);
      return null;
    }
    final sessionsDir = await _sessionsDir();
    final sessions = <ChatSession>[];
    for (final id in ids) {
      try {
        final key = _sessionKey(sessionsDir, id);
        final content = await _read(key);
        if (content == null) continue;
        sessions.add(
          ChatSession.fromJson(jsonDecode(content) as Map<String, dynamic>),
        );
        _cache[id] = content;
      } catch (e) {
        // 单条会话文件损坏时跳过，不影响其余会话
        Logger.warn('session', 'session file corrupt, skipped: ');
        Logger.error('session', 'parse failed', e);
      }
    }
    return sessions;
  }

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    final base = await _baseDir();
    final sessionsDir = await _sessionsDir();

    // 会话文件：仅重写内容变化的会话
    for (final s in sessions) {
      await _writeSessionFile(sessionsDir, s);
    }

    // 删除本地存在但列表里已不存在的会话文件
    final existing = _cache.keys
        .where((id) => !sessions.any((s) => s.id == id))
        .toList();
    for (final id in existing) {
      await _delete(_sessionKey(sessionsDir, id));
      _cache.remove(id);
    }

    await _writeIndex(base, sessions.map((s) => s.id).toList());
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    final base = await _baseDir();
    final sessionsDir = await _sessionsDir();
    await _writeSessionFile(sessionsDir, session);

    // 新会话需加入索引
    final indexKey = _indexKey(base);
    var ids = <String>[];
    final raw = await _read(indexKey);
    if (raw != null) {
      try {
        ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
      } catch (e) {
        Logger.error('session', 'session index corrupt while writing, rebuild', e);
      }
    }
    if (!ids.contains(session.id)) {
      ids.add(session.id);
      await _write(indexKey, jsonEncode(ids));
    }
  }

  Future<void> _writeSessionFile(
    Directory sessionsDir,
    ChatSession session,
  ) async {
    final json = jsonEncode(session.toJson());
    if (_cache[session.id] == json) return;
    await _write(_sessionKey(sessionsDir, session.id), json);
    _cache[session.id] = json;
  }

  Future<void> _writeIndex(Directory base, List<String> ids) async {
    final indexKey = _indexKey(base);
    final current = await _read(indexKey);
    final json = jsonEncode(ids);
    if (current == json) return;
    await _write(indexKey, json);
  }

  @override
  Future<void> deleteSession(String id) async {
    final base = await _baseDir();
    final sessionsDir = await _sessionsDir();
    await _delete(_sessionKey(sessionsDir, id));
    _cache.remove(id);

    final indexKey = _indexKey(base);
    final raw = await _read(indexKey);
    if (raw == null) return;
    var ids = <String>[];
    try {
      ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (e) {
      Logger.error('session', 'session index corrupt while deleting', e);
      return;
    }
    ids.remove(id);
    await _write(indexKey, jsonEncode(ids));
  }

  String _indexKey(Directory base) =>
      _memory ? 'index.json' : _indexFile(base).path;

  String _sessionKey(Directory sessionsDir, String id) =>
      _memory ? 'sessions/$id.json' : _sessionFile(sessionsDir, id).path;
}

/// 构造文件存储实现。
/// 默认实现：SQLite 优先（会话/消息表 + bigram 搜索索引），
/// SQLite 不可用时由内部回退到本文件存储实现。
SessionPersistence createSessionPersistence() =>
    SessionPersistenceSqlite(NonaDatabase());

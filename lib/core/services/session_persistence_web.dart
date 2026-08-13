import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';
import 'session_persistence.dart';

/// Web 端存储实现：退化为 shared_preferences 全量存储。
///
/// 与旧版本兼容：读写同一个 `chat_sessions` 键，保证数据不丢失。
class SessionPersistenceWeb implements SessionPersistence {
  static const _kSessions = 'chat_sessions';

  @override
  Future<List<ChatSession>?> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessions);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSessions,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    final current = await readAll() ?? [];
    final index = current.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      current[index] = session;
    } else {
      current.add(session);
    }
    await writeAll(current);
  }

  @override
  Future<void> deleteSession(String id) async {
    final current = await readAll() ?? [];
    current.removeWhere((s) => s.id == id);
    await writeAll(current);
  }
}

/// 构造 Web 存储实现。
SessionPersistence createSessionPersistence() => SessionPersistenceWeb();

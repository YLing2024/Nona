import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/network_log.dart';

/// Web 平台：使用浏览器 localStorage 持久化网络日志。
///
/// localStorage 容量有限（约 5MB），写入失败（配额超限）时自动回退为
/// 仅内存记录，避免影响正常使用。
const _kKey = 'network_logs_web';

Future<List<NetworkLog>> readLogs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) NetworkLog.fromJson(e),
    ];
  } catch (_) {
    return [];
  }
}

Future<void> writeLogs(List<NetworkLog> logs) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode([for (final l in logs) l.toJson()]),
    );
  } catch (_) {
    // localStorage 配额不足等：放弃持久化，保持内存记录
  }
}

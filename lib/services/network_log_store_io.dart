import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

import '../models/network_log.dart';

const _kFileName = 'network_logs.json';

/// 日志文件：应用支持目录（Android/iOS 应用私有目录，桌面系统数据目录）。
/// 该目录稳定持久，不会被系统按缓存清理，适合长期保存日志。
Future<File> _logFile() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}${Platform.pathSeparator}$_kFileName');
}

/// 读取已持久化的网络日志；文件不存在或损坏时返回空列表。
Future<List<NetworkLog>> readLogs() async {
  try {
    final file = await _logFile();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) NetworkLog.fromJson(e),
    ];
  } catch (e) {
    debugPrint('[NetworkLog] 读取持久化日志失败: $e');
    return [];
  }
}

/// 将全部日志写入磁盘（最新在前）。
Future<void> writeLogs(List<NetworkLog> logs) async {
  try {
    final file = await _logFile();
    await file.writeAsString(
      jsonEncode([for (final l in logs) l.toJson()]),
      flush: true,
    );
  } catch (e) {
    // 写入失败不阻塞业务，但打印出来便于排查
    debugPrint('[NetworkLog] 持久化失败: $e');
  }
}

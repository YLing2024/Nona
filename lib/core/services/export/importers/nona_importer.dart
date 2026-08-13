import '../../../models/chat_session.dart';
import '../backup_archive.dart';

/// Nona 自家格式解析：新版 `{sessions: [...]}`、旧版会话数组、
/// 以及单会话导出（`{id, messages}`）。
class NonaImporter {
  /// 解析 JSON 数据；无法识别为 Nona 格式时返回 null。
  ///
  /// 会话级逐条容错：单条损坏计入 [BackupImportResult.failedItems]，
  /// 不阻塞其余会话导入。
  static BackupImportResult? tryParse(Object? data) {
    if (data is List) {
      return _parseSessions(data.whereType<Map<String, dynamic>>().toList());
    }
    if (data is! Map<String, dynamic>) return null;

    // Nona 新/旧版备份
    final list = data['sessions'];
    if (list is List) {
      return _parseSessions(list.whereType<Map<String, dynamic>>().toList());
    }
    // 单会话 JSON（exportJsonToFile 产物）
    if (data['id'] is String && data['messages'] is List) {
      try {
        return BackupImportResult(sessions: [ChatSession.fromJson(data)]);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static BackupImportResult _parseSessions(List<Map<String, dynamic>> items) {
    final sessions = <ChatSession>[];
    final failures = <ImportFailure>[];
    for (var i = 0; i < items.length; i++) {
      try {
        sessions.add(ChatSession.fromJson(items[i]));
      } catch (e) {
        failures.add(ImportFailure(index: i, reason: e.toString()));
      }
    }
    return BackupImportResult(sessions: sessions, failedItems: failures);
  }
}

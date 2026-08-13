import '../../models/chat_provider.dart';
import '../../models/chat_session.dart';
import 'backup_archive.dart';

/// 导入质量指标（X-03：报告卡片展示）。
class ImportQuality {
  /// 有时间戳消息占比（0~1）。
  final double timestampCompleteRate;

  /// 多模态内容（图片/文档）是否完整保留。
  final bool multimodalPreserved;

  /// 工具消息（tool_calls/tool_call_id）是否保留。
  final bool toolMessagesPreserved;

  const ImportQuality({
    required this.timestampCompleteRate,
    required this.multimodalPreserved,
    required this.toolMessagesPreserved,
  });

  double get score =>
      (timestampCompleteRate * 0.5 +
          (multimodalPreserved ? 0.25 : 0) +
          (toolMessagesPreserved ? 0.25 : 0));
}

/// 重复会话命中（X-03：stableSessionId 哈希检测）。
class DuplicateHit {
  /// 导入会话 id（stableSessionId 哈希）。
  final String hashSessionId;

  /// 已存在会话的标题。
  final String existingTitle;

  /// 命中数量（同一哈希的重复条数）。
  final int matches;

  const DuplicateHit({
    required this.hashSessionId,
    required this.existingTitle,
    required this.matches,
  });
}

/// 去重动作（X-03：三选一）。
enum DuplicateAction { skip, overwrite, copy }

/// 结构化导入报告（X-03 导入武器化）。
class ImportReport {
  /// 来源格式名（nona/chatbox/cherry/nextchat/openai/nona-backup/sqlite）。
  final String sourceFormat;

  /// 源数据中的会话总数（含重复与损坏）。
  final int sessions;

  /// 消息总数。
  final int messages;

  /// 成功解析的会话数。
  final int succeeded;

  /// 解析失败明细。
  final List<ImportFailure> failures;

  /// 质量指标。
  final ImportQuality quality;

  /// 重复命中（与现有会话 id 集合比对）。
  final List<DuplicateHit> duplicates;

  /// 解析出的全部会话（供预览勾选/合并执行）。
  final List<ChatSession> parsedSessions;

  /// 备份附带的服务商（nona-backup ZIP，可合并）。
  final List<ChatProvider>? providers;

  const ImportReport({
    required this.sourceFormat,
    required this.sessions,
    required this.messages,
    required this.succeeded,
    required this.failures,
    required this.quality,
    required this.duplicates,
    required this.parsedSessions,
    this.providers,
  });

  /// 按去重策略过滤后的待导入会话。
  ///
  /// - skip：跳过重复；
  /// - overwrite：重复会话用导入版本替换（保留原 id）；
  /// - copy：重复会话生成新 id（原样复制保留）。
  List<ChatSession> selectSessions(
    DuplicateAction action, {
    Set<String>? selectedIds,
  }) {
    final duplicateIds = {for (final d in duplicates) d.hashSessionId};
    final result = <ChatSession>[];
    for (final s in parsedSessions) {
      if (selectedIds != null && !selectedIds.contains(s.id)) continue;
      final isDuplicate = duplicateIds.contains(s.id);
      if (isDuplicate && action == DuplicateAction.skip) continue;
      if (isDuplicate && action == DuplicateAction.copy) {
        result.add(_copyWithNewId(s));
        continue;
      }
      // overwrite 与正常会话：保留 id（saveAll 会覆盖同 id）
      result.add(s);
    }
    return result;
  }

  static ChatSession _copyWithNewId(ChatSession s) => s.duplicate(
    copySuffix: '',
  );
}

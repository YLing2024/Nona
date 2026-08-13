import '../../../core/models/chat_session.dart';
import '../../../core/utils/format_time.dart';

/// 会话分组类型（pinned 单独处理，其余按更新时间分桶）。
enum SessionGroupKind { today, yesterday, earlier }

/// 一个分组：类型 + 按更新时间倒序的会话列表。
class SessionGroup {
  final SessionGroupKind kind;
  final List<ChatSession> sessions;

  const SessionGroup(this.kind, this.sessions);
}

/// 会话列表分组纯逻辑：搜索过滤 / 置顶分离 / 时间分桶 / 时间格式化。
///
/// 不依赖 Widget 与本地化文案（分组类型由调用方映射为文案），可脱离 UI 单测。
class SessionGrouper {
  /// 按标题或消息内容过滤会话（大小写不敏感）；空查询返回原列表。
  static List<ChatSession> search(List<ChatSession> sessions, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sessions;
    return sessions.where((s) {
      if (s.title.toLowerCase().contains(q)) return true;
      return s.messages.any(
        (m) => m.content.toLowerCase().contains(q),
      );
    }).toList();
  }

  /// 分组：置顶会话（按更新时间倒序）+ 其余按 今天/昨天/更早 分桶。
  static ({List<ChatSession> pinned, List<SessionGroup> groups}) group(
    List<ChatSession> sessions,
    DateTime now,
  ) {
    final pinned = sessions.where((s) => s.pinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final others = sessions.where((s) => !s.pinned).toList();

    bool isSameDay(DateTime t, DateTime ref) =>
        t.year == ref.year && t.month == ref.month && t.day == ref.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final today = others.where((s) => isSameDay(s.updatedAt, now)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final yest = others.where((s) => isSameDay(s.updatedAt, yesterday)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final older = others
        .where((s) => !isSameDay(s.updatedAt, now) && !isSameDay(s.updatedAt, yesterday))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return (
      pinned: pinned,
      groups: [
        if (today.isNotEmpty) SessionGroup(SessionGroupKind.today, today),
        if (yest.isNotEmpty) SessionGroup(SessionGroupKind.yesterday, yest),
        if (older.isNotEmpty) SessionGroup(SessionGroupKind.earlier, older),
      ],
    );
  }

  /// 会话列表时间显示：当天显示 HH:mm，否则显示 M-d。
  static String formatTime(DateTime t, DateTime now) => formatGroupTime(t, now);
}

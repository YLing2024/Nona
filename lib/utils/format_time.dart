/// 时间显示格式化工具（三屏共用）。
String _two(int n) => n.toString().padLeft(2, '0');

/// HH:mm:ss（网络日志列表行）。
String formatClockTime(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// yyyy-MM-dd HH:mm:ss（网络日志详情）。
String formatFullTime(DateTime t) =>
    '${t.year}-${_two(t.month)}-${_two(t.day)} '
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// 会话列表时间：当天显示 HH:mm，否则显示 M-d。
String formatGroupTime(DateTime t, DateTime now) {
  final sameDay = t.year == now.year &&
      t.month == now.month &&
      t.day == now.day;
  if (sameDay) return '${_two(t.hour)}:${_two(t.minute)}';
  return '${t.month}-${t.day}';
}

import 'package:flutter/material.dart';

/// H-01：GitHub 风格活跃热力图——周列 × 日行，四分位配色。
class StatsHeatmap extends StatelessWidget {
  /// date → 消息数（键 yyyy-MM-dd）。
  final Map<String, int> data;

  /// 展示天数（今天往前）。
  final int days;

  const StatsHeatmap({super.key, required this.data, this.days = 365});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final start = today.subtract(Duration(days: days - 1));
    final daysList = <DateTime>[];
    for (var i = 0; i < days; i++) {
      daysList.add(start.add(Duration(days: i)));
    }
    // 列：从 start 所在周的周一算起，保证每周 7 格对齐
    final firstWeekday = start.weekday; // 1=Mon..7=Sun
    final leading = firstWeekday - 1;
    final weeks = (leading + days + 6) ~/ 7;

    final values = data.values.toList();
    final sorted = [...values]..sort();
    // 四分位断点
    int q(int i) {
      if (sorted.isEmpty) return 0;
      final idx = ((sorted.length - 1) * i / 4).round();
      return sorted[idx];
    }

    final q1 = q(1);
    final q2 = q(2);
    final q3 = q(3);

    Color cellColor(int count) {
      if (count <= 0) return scheme.surfaceContainerHighest;
      if (count <= q1) return scheme.primary.withValues(alpha: 0.25);
      if (count <= q2) return scheme.primary.withValues(alpha: 0.45);
      if (count <= q3) return scheme.primary.withValues(alpha: 0.7);
      return scheme.primary;
    }

    String dateKey(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)}';
    }

    // 月标签行（每列第一天所在月份）
    final monthLabels = <(int col, String label)>[];
    for (var i = 0; i < daysList.length; i++) {
      final d = daysList[i];
      if (d.day <= 7 && (i == 0 || d.month != daysList[i - 1].month)) {
        monthLabels.add(((leading + i) ~/ 7, '${d.month}'));
      }
    }

    final cellSize = 10.0;
    final gap = 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 14,
          child: Row(
            children: [
              for (final (col, label) in monthLabels)
                SizedBox(
                  width: (weeks - col) * (cellSize + gap),
                  child: Text(
                    '$label月',
                    style: TextStyle(
                      fontSize: 9,
                      color: scheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 7 * (cellSize + gap),
          child: Row(
            children: [
              for (var col = 0; col < weeks; col++)
                Column(
                  children: [
                    for (var row = 0; row < 7; row++)
                      Padding(
                        padding: EdgeInsets.all(gap / 2),
                        child: () {
                          final index = col * 7 + row - leading;
                          if (index < 0 || index >= daysList.length) {
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }
                          final count = data[dateKey(daysList[index])] ?? 0;
                          return Tooltip(
                            message: '${daysList[index].month}-'
                                '${daysList[index].day}: $count',
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: cellColor(count),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

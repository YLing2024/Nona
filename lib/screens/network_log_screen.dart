import 'package:flutter/material.dart';

import '../services/network_log_service.dart';
import 'network_log_detail_screen.dart';

/// 网络日志列表页：按天分组展示全部请求日志，点击查看详情。
class NetworkLogScreen extends StatefulWidget {
  const NetworkLogScreen({super.key});

  @override
  State<NetworkLogScreen> createState() => _NetworkLogScreenState();
}

class _NetworkLogScreenState extends State<NetworkLogScreen> {
  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空网络日志'),
        content: const Text('将删除全部已记录的网络日志，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    NetworkLogService.instance.clear();
    setState(() {});
  }

  /// 列表顶部统计文案：条数 + 上限（0 为无限）。
  String _summaryText(int count) {
    final max = NetworkLogService.instance.maxLogs;
    return max > 0 ? '共 $count 条记录 · 最多保留 $max 条' : '共 $count 条记录 · 无限保留';
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (d.year == now.year) return '${d.month}月${d.day}日';
    return '${d.year}年${d.month}月${d.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = NetworkLogService.instance.logs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络日志'),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空日志',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '暂无网络日志',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '回到开发者选项开启「启用网络日志」后自动记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Text(
                      _summaryText(logs.length),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  ..._buildGrouped(logs, theme),
                ],
              ),
      ),
    );
  }

  /// 按天分组：同一分组连续展示，日期变化时插入分组标题。
  List<Widget> _buildGrouped(List<NetworkLog> logs, ThemeData theme) {
    final widgets = <Widget>[];
    String? lastDay;
    for (final log in logs) {
      final day = _dayLabel(log.time);
      if (day != lastDay) {
        lastDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        );
      }
      widgets.add(_LogTile(log: log));
    }
    return widgets;
  }
}

class _LogTile extends StatelessWidget {
  final NetworkLog log;

  const _LogTile({required this.log});

  Color _methodColor(ThemeData theme) =>
      log.method == 'GET' ? theme.colorScheme.tertiary : theme.colorScheme.primary;

  Color _statusColor(ThemeData theme) {
    final scheme = theme.colorScheme;
    if (log.error != null) return scheme.error;
    final code = log.statusCode;
    if (code == null) return scheme.outline;
    if (code < 400) return Colors.green;
    if (code < 500) return Colors.orange;
    return scheme.error;
  }

  String _timeText(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(theme);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NetworkLogDetailScreen(log: log),
          ),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _methodColor(theme).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            log.method,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _methodColor(theme),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                log.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            [
              log.type.label,
              _timeText(log.time),
              if (log.statusCode != null) '${log.statusCode}',
              '${log.durationMs}ms',
              if (log.error != null) '失败',
            ].join(' · '),
            style: TextStyle(fontSize: 11.5, color: statusColor),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
      ),
    );
  }
}

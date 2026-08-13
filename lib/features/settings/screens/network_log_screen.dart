import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/app_routes.dart';
import '../../../core/services/network_log_service.dart';
import '../../../core/services/storage_io_io.dart'
    if (dart.library.js_interop) '../../../core/services/storage_io_stub.dart'
    as storage_io;
import '../../../core/utils/format_time.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../core/utils/l10n_ext.dart';

/// 网络日志列表页：按天分组展示全部请求日志，点击查看详情。
class NetworkLogScreen extends StatefulWidget {
  const NetworkLogScreen({super.key});

  @override
  State<NetworkLogScreen> createState() => _NetworkLogScreenState();
}

class _NetworkLogScreenState extends State<NetworkLogScreen> {
  /// 过滤状态：全部 / 成功 / 失败。
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    // 网络日志在页面打开期间会持续产生，监听服务变更实时刷新
    NetworkLogService.instance.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    NetworkLogService.instance.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) setState(() {});
  }

  List<NetworkLog> get _filtered => switch (_filter) {
    'success' =>
        NetworkLogService.instance.logs.where((l) => l.isSuccess).toList(),
    'failed' =>
        NetworkLogService.instance.logs.where((l) => !l.isSuccess).toList(),
    _ => NetworkLogService.instance.logs,
  };

  Future<void> _export() async {
    final data = jsonEncode({
      'app': 'nona',
      'type': 'network_logs',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': _filtered.length,
      'logs': _filtered.map((l) => l.toJson()).toList(),
    });
    try {
      final path = await storage_io.saveTextFile(
        suggestedName: 'nona-network-logs.json',
        data: data,
        extension: 'json',
        mimeType: 'application/json',
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.networkLogExported)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.homeNetworkError}: $e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.networkLogClearTitle,
      message: context.l10n.networkLogClearConfirm,
      confirmText: context.l10n.commonClear,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    NetworkLogService.instance.clear();
    setState(() {});
  }

  /// 列表顶部统计文案：条数 + 上限（0 为无限）。
  String _summaryText(AppLocalizations l10n, int count) {
    final max = NetworkLogService.instance.maxLogs;
    return max > 0
        ? l10n.networkLogCountLimited(count, max)
        : l10n.networkLogCountUnlimited(count);
  }

  String _dayLabel(AppLocalizations l10n, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.networkLogToday;
    if (diff == 1) return l10n.networkLogYesterday;
    if (d.year == now.year) {
      // 注意生成函数的参数顺序是 (month, day)
      return l10n.networkLogDateToday(d.month, d.day);
    }
    return l10n.networkLogDateFull(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.networkLogTitle),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: context.l10n.networkLogExport,
              onPressed: _export,
            ),
          if (NetworkLogService.instance.logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: context.l10n.networkLogClear,
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (NetworkLogService.instance.logs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'all',
                      label: Text(context.l10n.networkLogFilterAll),
                    ),
                    ButtonSegment(
                      value: 'success',
                      label: Text(context.l10n.networkLogFilterSuccess),
                    ),
                    ButtonSegment(
                      value: 'failed',
                      label: Text(context.l10n.networkLogFilterFailed),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) =>
                      setState(() => _filter = s.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            Expanded(
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
                            context.l10n.networkLogEmpty,
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.networkLogEmptyHint,
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
                            _summaryText(context.l10n, logs.length),
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
      final day = _dayLabel(context.l10n, log.time);
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
    if (code < 400) return AppColors.statusSuccess;
    if (code < 500) return AppColors.statusWarn;
    return scheme.error;
  }

  String _timeText(DateTime t) => formatClockTime(t);

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
          AppRoutes.networkLogDetail(log: log),
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
              log.type.labelOf(context.l10n),
              _timeText(log.time),
              if (log.statusCode != null) '${log.statusCode}',
              '${log.durationMs}ms',
              if (log.error != null) context.l10n.commonFailed,
            ].join(' · '),
            style: TextStyle(fontSize: 11.5, color: statusColor),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
      ),
    );
  }
}

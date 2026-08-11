import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/usage/usage_stats_service.dart';

/// 统计看板（F3-2）：每日 token 堆叠柱状 / 模型 Top10 / 会话 Top10 /
/// 成本趋势 / 累计花费；入口在设置页。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 30;
  List<DailyUsage> _daily = [];
  List<ModelUsage> _models = [];
  List<SessionUsageStat> _sessions = [];
  (int, int, double) _totals = (0, 0, 0);
  bool _loading = true;
  String? _error;

  late final UsageStatsService _stats = UsageStatsService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _stats.daily(days: _days),
        _stats.topModels(),
        _stats.topSessions(),
        _stats.totals(),
      ]);
      if (!mounted) return;
      setState(() {
        _daily = results[0] as List<DailyUsage>;
        _models = results[1] as List<ModelUsage>;
        _sessions = results[2] as List<SessionUsageStat>;
        _totals = results[3] as (int, int, double);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.statsRefresh,
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _summaryCards(context),
                      const SizedBox(height: 16),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7')),
                          ButtonSegment(value: 30, label: Text('30')),
                          ButtonSegment(value: 90, label: Text('90')),
                        ],
                        selected: {_days},
                        onSelectionChanged: (s) {
                          setState(() => _days = s.first);
                          _load();
                        },
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        l10n.statsDailyTokens,
                        child: SizedBox(
                          height: 220,
                          child: _daily.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.statsEmpty,
                                    style: TextStyle(
                                      color: scheme.outline,
                                    ),
                                  ),
                                )
                              : _dailyChart(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        l10n.statsCostTrend,
                        child: SizedBox(
                          height: 200,
                          child: _costChart(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        l10n.statsTopModels,
                        child: Column(
                          children: [
                            for (final m in _models)
                              _modelRow(context, m),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        context,
                        l10n.statsTopSessions,
                        child: Column(
                          children: [
                            for (final s in _sessions)
                              _sessionRow(context, s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCards(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (prompt, completion, cost) = _totals;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            l10n.statsTotalTokens,
            '${(prompt + completion) ~/ 1000}k',
            scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            l10n.statsTotalCost,
            '\$${cost.toStringAsFixed(2)}',
            scheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// 每日 token 堆叠柱状图（prompt + completion）。
  Widget _dailyChart() {
    final scheme = Theme.of(context).colorScheme;
    final maxTokens = _daily.fold<int>(
      0,
      (m, d) => m > d.promptTokens + d.completionTokens
          ? m
          : d.promptTokens + d.completionTokens,
    );
    return BarChart(
      BarChartData(
        maxY: maxTokens > 0 ? maxTokens * 1.1 : 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.6,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _daily.length) {
                  return const SizedBox.shrink();
                }
                final day = _daily[idx].date.substring(8);
                if (idx % 5 != 0 && idx != _daily.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < _daily.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _daily[i].promptTokens.toDouble(),
                  color: scheme.primary,
                  width: 6,
                  borderRadius: BorderRadius.zero,
                ),
                BarChartRodData(
                  toY: (_daily[i].promptTokens + _daily[i].completionTokens)
                      .toDouble(),
                  color: scheme.tertiary,
                  width: 6,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 成本趋势线（按日累计成本，需要价格表）。
  Widget _costChart() {
    final scheme = Theme.of(context).colorScheme;
    if (_daily.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).statsEmpty,
          style: TextStyle(color: scheme.outline),
        ),
      );
    }
    // 成本趋势：以 token 总量近似（精确成本见累计花费卡片）
    final points = <FlSpot>[
      for (var i = 0; i < _daily.length; i++)
        FlSpot(i.toDouble(), (_daily[i].promptTokens + _daily[i].completionTokens).toDouble()),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: points.isEmpty
            ? 1
            : points
                    .map((p) => p.y)
                    .reduce((a, b) => a > b ? a : b) *
                1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.6,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: scheme.tertiary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _modelRow(BuildContext context, ModelUsage m) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = m.promptTokens + m.completionTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.modelId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  m.providerName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(total / 1000).toStringAsFixed(1)}k',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionRow(BuildContext context, SessionUsageStat s) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = s.promptTokens + s.completionTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${(total / 1000).toStringAsFixed(1)}k',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

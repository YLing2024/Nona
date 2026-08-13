import 'package:flutter/material.dart';

import '../../../core/services/model_router_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../l10n/app_localizations.dart';

/// 模型路由面板（X-02）：自动路由开关 + 每任务最近统计。
class ModelRouterScreen extends StatefulWidget {
  const ModelRouterScreen({super.key});

  @override
  State<ModelRouterScreen> createState() => _ModelRouterScreenState();
}

class _ModelRouterScreenState extends State<ModelRouterScreen> {
  final SettingsService _settingsService = SettingsService();
  final ModelRouterService _router = ModelRouterService();
  AppSettings _settings = const AppSettings();
  List<RouteEventStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    final stats = await _router.stats();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _stats = stats;
    });
    _router.autoRoutingEnabled = settings.autoModelRouting;
  }

  Future<void> _toggleRouting(bool value) async {
    setState(() => _settings = _settings.copyWith(autoModelRouting: value));
    await _settingsService.save(_settings);
    _router.autoRoutingEnabled = value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final byTask = <String, List<RouteEventStat>>{};
    for (final s in _stats) {
      byTask.putIfAbsent(s.task, () => []).add(s);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                l10n.routerEnable,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l10n.routerEnableHint,
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              value: _settings.autoModelRouting,
              onChanged: _toggleRouting,
            ),
          ),
          if (byTask.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.routerNoData,
                style: TextStyle(color: scheme.outline),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(l10n.routerRecentStats, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final entry in byTask.entries) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _taskLabel(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      for (final stat in entry.value.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '· ${stat.modelId} — '
                            '${stat.calls} 次'
                            '${stat.avgMs != null ? ' · ${stat.avgMs!.toStringAsFixed(0)}ms' : ''}'
                            '${stat.totalCost > 0 ? ' · \$${stat.totalCost.toStringAsFixed(4)}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  String _taskLabel(String task) => switch (task) {
    'chat' => '聊天',
    'summary' => '摘要',
    'title' => '标题生成',
    'translate' => '翻译',
    'ocr' => 'OCR',
    'embedding' => '嵌入',
    'imageGen' => '图片生成',
    _ => task,
  };
}

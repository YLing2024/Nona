import 'package:flutter/material.dart';

import '../services/agent_service.dart';
import '../services/export_service.dart';
import '../services/provider_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import 'agent_list_screen.dart';
import 'model_config_screen.dart';
import 'preferences_screen.dart';
import 'provider_list_screen.dart';
import 'theme_settings_screen.dart';

/// 设置主页：分组卡片式入口 + 数据管理。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _agentService = AgentService();
  final _providerService = ProviderService();
  final _sessionService = SessionService();
  AppSettings _settings = const AppSettings();
  int _agentCount = 0;
  int _providerCount = 0;
  int _modelCount = 0;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    final agents = await _agentService.load();
    final providers = await _providerService.load();
    final sessions = await _sessionService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _agentCount = agents.length;
      _providerCount = providers.length;
      _modelCount = providers.fold<int>(0, (sum, p) => sum + p.modelIds.length);
      _sessionCount = sessions.length;
    });
  }

  Future<void> _openThemeSettings() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ThemeSettingsScreen(initialThemeMode: _settings.themeMode),
      ),
    );
    if (result != null && mounted) {
      setState(() => _settings = _settings.copyWith(themeMode: result));
    }
  }

  Future<void> _openAgentList() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AgentListScreen()));
    final agents = await _agentService.load();
    if (!mounted) return;
    setState(() => _agentCount = agents.length);
  }

  Future<void> _openProviderList() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProviderListScreen()));
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() {
      _providerCount = providers.length;
      _modelCount = providers.fold<int>(0, (sum, p) => sum + p.modelIds.length);
    });
  }

  Future<void> _exportAll() async {
    final sessions = await _sessionService.load();
    if (sessions.isEmpty) {
      _snack('还没有可导出的会话');
      return;
    }
    try {
      final path = await ExportService.exportAllToFile(sessions);
      if (path != null && mounted) _snack('已导出全部会话到 $path');
    } catch (e) {
      _snack('导出失败：$e');
    }
  }

  Future<void> _importAll() async {
    final imported = await ExportService.importAllFromFile();
    if (imported == null || imported.isEmpty) {
      if (mounted) _snack('导入失败：文件格式不正确');
      return;
    }
    final sessions = await _sessionService.load();
    final existingIds = sessions.map((s) => s.id).toSet();
    var added = 0;
    for (final s in imported) {
      if (existingIds.contains(s.id)) continue;
      sessions.add(s);
      existingIds.add(s.id);
      added++;
    }
    if (added == 0) {
      if (mounted) _snack('所有会话已存在，无新增');
      return;
    }
    await _sessionService.save(sessions);
    if (!mounted) return;
    setState(() => _sessionCount = sessions.length);
    _snack('成功导入 $added 个会话');
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部会话'),
        content: Text('将删除本地保存的全部 $_sessionCount 个会话，此操作不可恢复。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _sessionService.save([]);
    if (!mounted) return;
    setState(() => _sessionCount = 0);
    _snack('已清空全部会话');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionLabel('服务与内容'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.dns_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: '服务商',
                  subtitle: _providerCount == 0
                      ? '未配置，添加服务商并获取模型'
                      : '$_providerCount 个服务商 · $_modelCount 个模型',
                  onTap: _openProviderList,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.smart_toy_outlined,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: 'Agent 配置',
                  subtitle: '$_agentCount 个预设，新建会话时一键套用',
                  onTap: _openAgentList,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.model_training_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: '模型配置',
                  subtitle: '新建 Agent 的默认模型等',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ModelConfigScreen(),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          _SectionLabel('外观'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.secondary,
                title: '主题',
                subtitle: themeModeLabel(_settings.themeMode),
                onTap: _openThemeSettings,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel('偏好'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.tune_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
                title: '偏好设置',
                subtitle: _settings.sendOnEnter
                    ? 'Enter 发送 · 浅色主题等'
                    : 'Enter 换行 · 发送键行为',
                onTap: () async {
                  await Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const PreferencesScreen()));
                  final settings = await _settingsService.load();
                  if (!mounted) return;
                  setState(() => _settings = settings);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel('数据'),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.save_alt_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: '导出全部会话',
                  subtitle: '备份为 JSON 文件，可随时恢复',
                  onTap: _exportAll,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.file_upload_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: '导入会话',
                  subtitle: '从备份文件恢复会话记录',
                  onTap: _importAll,
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: '清空全部会话',
                  subtitle: _sessionCount == 0
                      ? '当前没有保存的会话'
                      : '共 $_sessionCount 个会话，操作不可恢复',
                  danger: true,
                  onTap: _sessionCount == 0 ? null : _clearAll,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Nona · 本地优先，所有数据仅保存在本机',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : null;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

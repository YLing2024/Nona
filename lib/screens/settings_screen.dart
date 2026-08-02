import 'package:flutter/material.dart';

import '../services/agent_service.dart';
import '../services/provider_service.dart';
import '../services/settings_service.dart';
import '../services/theme_controller.dart';
import 'agent_list_screen.dart';
import 'provider_list_screen.dart';
import 'theme_settings_screen.dart';

/// 设置主页：以列表形式展示各项设置入口。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _agentService = AgentService();
  final _providerService = ProviderService();
  AppSettings _settings = const AppSettings();
  int _agentCount = 0;
  int _providerCount = 0;
  int _modelCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    final agents = await _agentService.load();
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _agentCount = agents.length;
      _providerCount = providers.length;
      _modelCount = providers.fold<int>(0, (sum, p) => sum + p.modelIds.length);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Agent 配置'),
            subtitle: Text('$_agentCount 个预设，可快捷套用到会话'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openAgentList,
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题配置'),
            subtitle: Text(themeModeLabel(_settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openThemeSettings,
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('服务商'),
            subtitle: Text(
              _providerCount == 0
                  ? '未配置'
                  : '$_providerCount 个服务商 / $_modelCount 个模型',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openProviderList,
          ),
        ],
      ),
    );
  }
}

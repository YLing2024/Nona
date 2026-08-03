import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// 偏好设置页：对话相关的行为偏好。
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _settingsService = SettingsService();
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _update(bool? sendOnEnter) async {
    if (sendOnEnter == null) return;
    setState(() => _settings = _settings.copyWith(sendOnEnter: sendOnEnter));
    await _settingsService.save(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('偏好设置')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PreferenceTile(
              icon: Icons.keyboard_return_outlined,
              iconColor: theme.colorScheme.primary,
              title: 'Enter 发送消息',
              subtitle: _settings.sendOnEnter
                  ? '按 Enter 发送，Shift+Enter 换行'
                  : '按 Enter 换行，Ctrl+Enter 发送',
              trailing: Switch(
                value: _settings.sendOnEnter,
                onChanged: _update,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '关闭后，输入法右下角的「换行」键将插入换行，而不会直接发送消息。',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PreferenceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

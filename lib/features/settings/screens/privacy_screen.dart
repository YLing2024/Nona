import 'package:flutter/material.dart';

import '../../../core/services/settings_service.dart';
import '../../../l10n/app_localizations.dart';

/// 隐私/离线页（X-05）：离线模式开关 + 各能力离线状态清单。
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final SettingsService _settingsService = SettingsService();
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

  Future<void> _toggleOffline(bool value) async {
    setState(() => _settings = _settings.copyWith(offlineMode: value));
    await _settingsService.save(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                l10n.offlineMode,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l10n.offlineModeHint,
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              value: _settings.offlineMode,
              onChanged: _toggleOffline,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.offlineCapabilities, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _CapabilityTile(
            icon: Icons.data_object_rounded,
            title: l10n.offlineCapEmbedding,
            status: _settings.offlineMode
                ? l10n.offlineStatusLocal
                : l10n.offlineStatusCloud,
            color: _settings.offlineMode ? scheme.primary : scheme.outline,
          ),
          _CapabilityTile(
            icon: Icons.manage_search_rounded,
            title: l10n.offlineCapKbSearch,
            status: l10n.offlineStatusLocal,
            color: scheme.primary,
          ),
          _CapabilityTile(
            icon: Icons.search_rounded,
            title: l10n.offlineCapWebSearch,
            status: _settings.offlineMode
                ? l10n.offlineStatusOff
                : l10n.offlineStatusCloud,
            color: _settings.offlineMode ? scheme.outline : scheme.primary,
          ),
          _CapabilityTile(
            icon: Icons.record_voice_over_rounded,
            title: l10n.offlineCapTts,
            status: l10n.offlineStatusSystem,
            color: scheme.primary,
          ),
          _CapabilityTile(
            icon: Icons.mic_rounded,
            title: l10n.offlineCapAsr,
            status: l10n.offlineStatusNeedsDownload,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.offlineNote,
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final Color color;

  const _CapabilityTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: color),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: Text(
          status,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ),
    );
  }
}

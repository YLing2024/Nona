import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/agent.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';
import '../../../shared/widgets/settings_tiles.dart';
import '../../../core/services/agent_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/theme_controller.dart';
import '../../../shared/app_routes.dart';
import '../../../core/theme/app_theme.dart';

/// 设置主页：分组卡片式入口 + 数据管理。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService =
      context.read<SettingsService>();
  late final AgentService _agentService = context.read<AgentService>();
  late final ProviderService _providerService =
      context.read<ProviderService>();
  late final SessionService _sessionService = context.read<SessionService>();
  AppSettings _settings = const AppSettings();
  int _agentCount = 0;
  int _providerCount = 0;
  int _modelCount = 0;
  int _sessionCount = 0;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await loadGuarded(
      () => Future.wait([
        _settingsService.load(),
        _agentService.load(),
        _providerService.load(),
        _sessionService.load(),
      ]),
      label: 'settings',
    );
    if (!mounted) return;
    setState(() {
      if (results != null) {
        _settings = results[0] as AppSettings;
        final agents = results[1] as List<Agent>;
        final providers = results[2] as List<ChatProvider>;
        final sessions = results[3] as List<ChatSession>;
        _agentCount = agents.length;
        _providerCount = providers.length;
        _modelCount = providers
            .fold<int>(0, (sum, p) => sum + p.modelIds.length);
        _sessionCount = sessions.length;
      }
      _loadFailed = results == null;
    });
  }

  Future<void> _openThemeSettings() async {
    final result = await Navigator.of(context).push<String>(
      AppRoutes.themeSettings(initialThemeMode: _settings.themeMode),
    );
    if (result != null && mounted) {
      setState(() => _settings = _settings.copyWith(themeMode: result));
    }
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push(AppRoutes.about());
    // 关于页内可切换开发者模式，返回后刷新以更新「开发者选项」入口
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _openAgentList() async {
    await Navigator.of(context).push(AppRoutes.agentList());
    final agents = await _agentService.load();
    if (!mounted) return;
    setState(() => _agentCount = agents.length);
  }

  Future<void> _openProviderList() async {
    await Navigator.of(context).push(AppRoutes.providerList());
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() {
      _providerCount = providers.length;
      _modelCount = providers.fold<int>(0, (sum, p) => sum + p.modelIds.length);
    });
  }

  Future<void> _exportAll() async {
    final sessions = await _sessionService.load();
    final providers = await _providerService.load();
    final agents = await _agentService.load();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (sessions.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsNoExportable)),
      );
      return;
    }
    try {
      final path = await ExportService.exportAllZipToFile(
        sessions: sessions,
        providers: providers,
        agents: agents,
      );
      if (path != null && mounted) {
        showAppSnack(context, l10n.settingsExportedAll(path));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed(e.toString()))),
      );
    }
  }

  Future<void> _importAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final imported = await ExportService.importAllFromFile();
    if (imported == null ||
        (imported.sessions.isEmpty &&
            (imported.providers == null || imported.providers!.isEmpty) &&
            (imported.agents == null || imported.agents!.isEmpty))) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportFailed)));
      }
      return;
    }
    var sessions = await _sessionService.load();
    final existingIds = sessions.map((s) => s.id).toSet();
    var added = 0;
    for (final s in imported.sessions) {
      if (existingIds.contains(s.id)) continue;
      sessions.add(s);
      existingIds.add(s.id);
      added++;
    }

    // ZIP 备份含服务商 / Agent：按 id 合并去重
    if (imported.providers != null) {
      final existing = await _providerService.load();
      final existingIds = existing.map((p) => p.id).toSet();
      for (final p in imported.providers!) {
        if (existingIds.contains(p.id)) continue;
        existing.add(p);
      }
      await _providerService.save(existing);
    }
    if (imported.agents != null) {
      final existing = await _agentService.load();
      final existingIds = existing.map((a) => a.id).toSet();
      for (final a in imported.agents!) {
        if (existingIds.contains(a.id)) continue;
        existing.add(a);
      }
      await _agentService.save(existing);
    }

    if (added == 0) {
      if (mounted) showAppSnack(context, context.l10n.settingsAllExist);
      return;
    }
    await _sessionService.saveAll(sessions);
    if (!mounted) return;
    setState(() => _sessionCount = sessions.length);
    showAppSnack(context, context.l10n.settingsImported(added));
  }

  Future<void> _clearAll() async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.settingsClearConfirmTitle,
      message: context.l10n.settingsClearConfirmContent(_sessionCount),
      confirmText: context.l10n.commonClear,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _sessionService.saveAll([]);
    if (!mounted) return;
    setState(() => _sessionCount = 0);
    showAppSnack(context, context.l10n.settingsCleared);
  }


  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  SettingsSectionLabel(l10n.settingsSectionServices),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.dns_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.settingsProviders,
                  subtitle: _providerCount == 0
                      ? l10n.settingsProvidersSubtitleEmpty
                      // 生成函数的参数顺序是 (providers, models)
                      : l10n.settingsProvidersSubtitle(
                          _providerCount, _modelCount),
                  onTap: _openProviderList,
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.smart_toy_outlined,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: l10n.settingsAgents,
                  subtitle: l10n.settingsAgentsSubtitle(_agentCount),
                  onTap: _openAgentList,
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.extension_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.mcpTitle,
                  subtitle: l10n.settingsMcpSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.mcpServers(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.cloud_sync_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.syncTitle,
                  subtitle: l10n.settingsSyncSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.sync()
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.input_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.importTitle,
                  subtitle: l10n.settingsImportSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.importWizard(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.bolt_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.quickPhrasesTitle,
                  subtitle: l10n.settingsQuickPhrasesSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.quickPhrases(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.text_snippet_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.iiTitle,
                  subtitle: l10n.settingsIiSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.instructionInjections(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.bolt_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.wfTitle,
                  subtitle: l10n.settingsWfSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.workflows(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.route_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.routerTitle,
                  subtitle: l10n.settingsRouterSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.modelRouter(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.offline_bolt_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.privacyTitle,
                  subtitle: l10n.settingsPrivacySubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.privacy(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.image_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.imgGenTitle,
                  subtitle: l10n.settingsImgGenSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.imgGen(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.compare_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.compareTitle,
                  subtitle: l10n.settingsCompareSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.compare()
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.menu_book_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.kbTitle,
                  subtitle: l10n.settingsKbSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.knowledgeBase(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.statsTitle,
                  subtitle: l10n.settingsStatsSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.stats(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.psychology_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.memoryTitle,
                  subtitle: l10n.settingsMemorySubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.memory(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.auto_stories_outlined,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.wbTitle,
                  subtitle: l10n.settingsWbSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.worldBook(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: l10n.translatorTitle,
                  subtitle: l10n.settingsTranslatorSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.translator(),
                  ),
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.model_training_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.settingsModelConfig,
                  subtitle: l10n.settingsModelConfigSubtitle,
                  onTap: () => Navigator.of(context).push(
                    AppRoutes.modelConfig(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          SettingsSectionLabel(l10n.settingsSectionAppearance),
          SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.secondary,
                title: l10n.settingsTheme,
                subtitle: themeModeLabel(_settings.themeMode, l10n),
                onTap: _openThemeSettings,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSectionLabel(l10n.settingsSectionPreferences),
          SettingsCard(
            children: [
                SettingsTile(
                  icon: Icons.tune_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.settingsPreferences,
                  subtitle: _settings.sendOnEnter
                      ? l10n.settingsPreferencesEnterSend
                      : l10n.settingsPreferencesEnterNewline,
                  onTap: () async {
                  await Navigator.of(
                    context,
                  ).push(AppRoutes.preferences());
                  final settings = await _settingsService.load();
                  if (!mounted) return;
                  setState(() => _settings = settings);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSectionLabel(l10n.settingsSectionData),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.save_alt_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.settingsExportAll,
                  subtitle: l10n.settingsExportAllSubtitle,
                  onTap: _exportAll,
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.file_upload_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.settingsImport,
                  subtitle: l10n.settingsImportSubtitle,
                  onTap: _importAll,
                ),
                const TileDivider(),
                SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: l10n.settingsClearAll,
                  subtitle: _sessionCount == 0
                      ? l10n.settingsClearAllSubtitleEmpty
                      : l10n.settingsClearAllSubtitle(_sessionCount),
                  danger: true,
                  onTap: _sessionCount == 0 ? null : _clearAll,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SettingsSectionLabel(l10n.settingsSectionAbout),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: l10n.settingsAbout,
                  subtitle: l10n.settingsAboutSubtitle,
                  onTap: _openAbout,
                ),
                // 开发者模式开启后显示高级设置入口
                if (_settings.developerMode) ...[
                  const TileDivider(),
                  SettingsTile(
                    icon: Icons.developer_mode_rounded,
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: l10n.settingsDevOptions,
                    subtitle: l10n.settingsDevOptionsSubtitle,
                    onTap: () => Navigator.of(context).push(
                      AppRoutes.developerOptions(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                l10n.settingsFooter,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





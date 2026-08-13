import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/web_search/web_search_service.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/load_failed_banner.dart';

/// 偏好设置页：对话相关的行为偏好。
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final SettingsService _settingsService = context.read<SettingsService>();
  AppSettings _settings = const AppSettings();
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await loadGuarded<AppSettings>(
      _settingsService.load,
      label: 'preferences',
    );
    if (!mounted) return;
    setState(() {
      if (settings != null) _settings = settings;
      _loadFailed = settings == null;
    });
  }

  Future<void> _update(bool? sendOnEnter) async {
    if (sendOnEnter == null) return;
    setState(() => _settings = _settings.copyWith(sendOnEnter: sendOnEnter));
    await _settingsService.save(_settings);
  }

  Future<void> _updateStreamMarkdown(bool? value) async {
    if (value == null) return;
    setState(
      () => _settings = _settings.copyWith(streamMarkdownRender: value),
    );
    await _settingsService.save(_settings);
  }

  Future<void> _updateAutoRetry(bool? value) async {
    if (value == null) return;
    setState(() => _settings = _settings.copyWith(chatAutoRetry: value));
    await _settingsService.save(_settings);
  }

  Future<void> _editTtsRate() async {
    var rate = _settings.ttsRate;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.preferencesTtsRate),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rate.toStringAsFixed(1),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              Slider(
                value: rate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: rate.toStringAsFixed(1),
                onChanged: (v) => setDialogState(() => rate = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(rate),
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _settings = _settings.copyWith(ttsRate: result));
    await _settingsService.save(_settings);
  }

  Future<void> _updateTtsLanguage(String? value) async {
    if (value == null || !mounted) return;
    setState(() => _settings = _settings.copyWith(ttsLanguage: value));
    await _settingsService.save(_settings);
  }

  String _ttsLanguageLabel(AppLocalizations l10n, String lang) {
    switch (lang) {
      case 'zh-CN':
        return l10n.preferencesTtsLanguageZh;
      case 'en-US':
        return l10n.preferencesTtsLanguageEn;
      case 'ja-JP':
        return l10n.preferencesTtsLanguageJa;
      default:
        return lang;
    }
  }

  Future<void> _updateWebSearch(bool? value) async {
    if (value == null) return;
    setState(() => _settings = _settings.copyWith(webSearchEnabled: value));
    await _settingsService.save(_settings);
  }

  Future<void> _updateWebSearchEngine(String? value) async {
    if (value == null) return;
    setState(() => _settings = _settings.copyWith(webSearchEngine: value));
    await _settingsService.save(_settings);
  }

  Future<void> _editWebSearchText({
    required String title,
    required String initial,
    required AppSettings Function(AppSettings, String) apply,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onTapOutside: unfocusOnTap,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() => _settings = apply(_settings, result));
    await _settingsService.save(_settings);
  }

  /// 编辑「文本文档阈值」：超过该字数的消息折叠为文档入口，0 表示不折叠。
  Future<void> _editDocumentThreshold() async {
    final controller = TextEditingController(
      text: _settings.documentThreshold > 0
          ? '${_settings.documentThreshold}'
          : '0',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.preferencesDocumentThresholdTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onTapOutside: unfocusOnTap,
          decoration: InputDecoration(
            labelText: ctx.l10n.preferencesDocumentThresholdLabel,
            hintText: ctx.l10n.preferencesDocumentThresholdExample,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final value = int.tryParse(result) ?? -1;
    if (value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.preferencesDocumentThresholdInvalid)),
      );
      return;
    }
    setState(() => _settings = _settings.copyWith(documentThreshold: value));
    await _settingsService.save(_settings);
  }

  Future<void> _updateLocale(String value) async {
    setState(() => _settings = _settings.copyWith(locale: value));
    await _settingsService.save(_settings);
    localeNotifier.value = localeFromSetting(value);
  }

  String _localeLabel(AppLocalizations l10n, String value) =>
      switch (value) {
        'zh' => l10n.preferencesLanguageZh,
        'en' => l10n.preferencesLanguageEn,
        _ => l10n.preferencesLanguageSystem,
      };

  String _engineLabel(AppLocalizations l10n, String value) =>
      switch (value) {
        'bing' => l10n.searchEngineBing,
        'duckduckgo' => l10n.searchEngineDuckduckgo,
        'tavily' => l10n.searchEngineTavily,
        'bocha' => l10n.searchEngineBocha,
        'searxng' => l10n.searchEngineSearxng,
        _ => value,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _PreferenceTile(
              icon: Icons.keyboard_return_outlined,
              iconColor: theme.colorScheme.primary,
              title: l10n.preferencesEnterSend,
              subtitle: _settings.sendOnEnter
                  ? l10n.preferencesEnterSendOn
                  : l10n.preferencesEnterSendOff,
              trailing: Switch(
                value: _settings.sendOnEnter,
                onChanged: _update,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.preferencesEnterSendHint,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            _PreferenceTile(
              icon: Icons.language_rounded,
              iconColor: theme.colorScheme.secondary,
              title: l10n.preferencesLanguage,
              subtitle: _localeLabel(l10n, _settings.locale),
              trailing: PopupMenuButton<String>(
                initialValue: _settings.locale,
                onSelected: _updateLocale,
                itemBuilder: (context) => [
                  for (final v in const ['system', 'zh', 'en'])
                    PopupMenuItem(
                      value: v,
                      child: Text(_localeLabel(l10n, v)),
                    ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.expand_more, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PreferenceTile(
              icon: Icons.auto_awesome_outlined,
              iconColor: theme.colorScheme.tertiary,
              title: l10n.preferencesStreamMarkdown,
              subtitle: l10n.preferencesStreamMarkdownHint,
              trailing: Switch(
                value: _settings.streamMarkdownRender,
                onChanged: _updateStreamMarkdown,
              ),
            ),
            const SizedBox(height: 12),
            _PreferenceTile(
              icon: Icons.sync_rounded,
              iconColor: theme.colorScheme.tertiary,
              title: l10n.preferencesAutoRetry,
              subtitle: l10n.preferencesAutoRetryHint,
              trailing: Switch(
                value: _settings.chatAutoRetry,
                onChanged: _updateAutoRetry,
              ),
            ),
            const SizedBox(height: 12),
            _PreferenceTile(
              icon: Icons.record_voice_over_outlined,
              iconColor: theme.colorScheme.tertiary,
              title: l10n.preferencesTtsRate,
              subtitle: _settings.ttsRate.toStringAsFixed(1),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              onTap: _editTtsRate,
            ),
            const SizedBox(height: 12),
            _PreferenceTile(
              icon: Icons.travel_explore_rounded,
              iconColor: theme.colorScheme.primary,
              title: l10n.preferencesWebSearch,
              subtitle: l10n.preferencesWebSearchHint,
              trailing: Switch(
                value: _settings.webSearchEnabled,
                onChanged: _updateWebSearch,
              ),
            ),
            if (_settings.webSearchEnabled) ...[
              const SizedBox(height: 12),
              _PreferenceTile(
                icon: Icons.search_rounded,
                iconColor: theme.colorScheme.primary,
                title: l10n.preferencesWebSearchEngine,
                subtitle: _engineLabel(l10n, _settings.webSearchEngine),
                trailing: PopupMenuButton<String>(
                  initialValue: _settings.webSearchEngine,
                  onSelected: _updateWebSearchEngine,
                  itemBuilder: (context) => [
                    for (final name in WebSearchService.engineNames)
                      PopupMenuItem(
                        value: name,
                        child: Text(
                          _engineLabel(l10n, name),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.expand_more, size: 18),
                  ),
                ),
              ),
              if (_settings.webSearchEngine == 'tavily' ||
                  _settings.webSearchEngine == 'bocha') ...[
                const SizedBox(height: 12),
                _PreferenceTile(
                  icon: Icons.key_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: l10n.preferencesWebSearchApiKey,
                  subtitle: _settings.webSearchApiKey.isEmpty
                      ? l10n.preferencesWebSearchApiKeyHint
                      : '••••••••',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: () => _editWebSearchText(
                    title: l10n.preferencesWebSearchApiKey,
                    initial: _settings.webSearchApiKey,
                    apply: (s, v) => s.copyWith(webSearchApiKey: v),
                  ),
                ),
              ],
              if (_settings.webSearchEngine == 'searxng') ...[
                const SizedBox(height: 12),
                _PreferenceTile(
                  icon: Icons.dns_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: l10n.preferencesWebSearchBaseUrl,
                  subtitle: _settings.webSearchBaseUrl.isEmpty
                      ? l10n.preferencesWebSearchBaseUrlHint
                      : _settings.webSearchBaseUrl,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: () => _editWebSearchText(
                    title: l10n.preferencesWebSearchBaseUrl,
                    initial: _settings.webSearchBaseUrl,
                    apply: (s, v) => s.copyWith(webSearchBaseUrl: v),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            _PreferenceTile(
              icon: Icons.language_rounded,
              iconColor: theme.colorScheme.secondary,
              title: l10n.preferencesTtsLanguage,
              subtitle: _ttsLanguageLabel(l10n, _settings.ttsLanguage),
              trailing: PopupMenuButton<String>(
                initialValue: _settings.ttsLanguage,
                onSelected: _updateTtsLanguage,
                itemBuilder: (context) => [
                  for (final v in const ['zh-CN', 'en-US', 'ja-JP'])
                    PopupMenuItem(
                      value: v,
                      child: Text(_ttsLanguageLabel(l10n, v)),
                    ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.expand_more, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PreferenceTile(
              icon: Icons.description_outlined,
              iconColor: theme.colorScheme.primary,
              title: l10n.preferencesDocumentThreshold,
              subtitle: _settings.documentThreshold > 0
                  ? l10n.preferencesDocumentThresholdValue(
                      _settings.documentThreshold,
                    )
                  : l10n.preferencesDocumentThresholdOff,
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              onTap: _editDocumentThreshold,
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

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PreferenceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}

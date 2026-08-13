import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';

/// 模型配置页：全局模型默认值（聊天模型、Agent 模型等）。
class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  late final SettingsService _settingsService =
      context.read<SettingsService>();
  late final ProviderService _providerService =
      context.read<ProviderService>();
  AppSettings _settings = const AppSettings();
  List<ChatProvider> _providers = [];
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
        _providerService.load(),
      ]),
      label: 'model_config',
    );
    if (!mounted) return;
    setState(() {
      if (results != null) {
        _settings = results[0] as AppSettings;
        _providers = results[1] as List<ChatProvider>;
      }
      _loadFailed = results == null;
    });
  }

  Future<void> _save({String? chatModel, String? titleModel, String? translatorModel}) async {
    final next = _settings.copyWith(
      chatModel: chatModel ?? _settings.chatModel,
      titleModel: titleModel ?? _settings.titleModel,
      translatorModel: translatorModel ?? _settings.translatorModel,
    );
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() => _settings = next);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.modelConfigSaved)));
    }
  }

  Future<void> _reset(String field) async {
    final isChat = field == 'chat';
    final isTitle = field == 'title';
    final title = isChat
        ? context.l10n.modelConfigResetChatTitle
        : isTitle
            ? context.l10n.modelConfigResetTitleTitle
            : context.l10n.modelConfigResetTranslatorTitle;
    final content = isChat
        ? context.l10n.modelConfigResetChatContent
        : isTitle
            ? context.l10n.modelConfigResetTitleContent
            : context.l10n.modelConfigResetTranslatorContent;
    final confirmed = await confirmAction(
      context,
      title: title,
      message: content,
      confirmText: context.l10n.commonReset,
    );
    if (!confirmed) return;
    if (isChat) {
      await _save(chatModel: '');
    } else if (isTitle) {
      await _save(titleModel: '');
    } else {
      await _save(translatorModel: '');
    }
  }

  String? _findProviderName(String modelId) {
    for (final p in _providers) {
      if (p.modelIds.contains(modelId)) return p.name;
    }
    return null;
  }

  void _showModelPicker({bool forTitle = false, bool forTranslator = false}) async {
    final filtered = _providers.where((p) => p.modelIds.isNotEmpty).toList();
    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.modelConfigNoModels)),
        );
      }
      return;
    }

    final current = forTitle
        ? _settings.titleModel
        : forTranslator
            ? _settings.translatorModel
            : _settings.chatModel;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _ModelPickerSheet(
        providers: _providers,
        current: current,
        title: forTitle
            ? context.l10n.modelConfigPickTitle
            : forTranslator
                ? context.l10n.modelConfigPickTranslator
                : context.l10n.modelConfigPickChat,
      ),
    );
    if (selected == null) return;
    if (forTitle) {
      await _save(titleModel: selected);
    } else if (forTranslator) {
      await _save(translatorModel: selected);
    } else {
      await _save(chatModel: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final hasModel = _settings.chatModel.isNotEmpty;
    final hasTitleModel = _settings.titleModel.isNotEmpty;
    final hasTranslatorModel = _settings.translatorModel.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.modelConfigTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _ConfigCard(
              icon: Icons.chat_outlined,
              iconColor: scheme.primary,
              title: l10n.modelConfigChatModel,
              hasValue: hasModel,
              value: hasModel ? _settings.chatModel : null,
              subtitle: hasModel ? _findProviderName(_settings.chatModel) : null,
              onSelect: () => _showModelPicker(forTitle: false),
              onReset: hasModel ? () => _reset('chat') : null,
              description: l10n.modelConfigChatModelDesc,
            ),
            const SizedBox(height: 16),
            _ConfigCard(
              icon: Icons.title_outlined,
              iconColor: scheme.secondary,
              title: l10n.modelConfigTitleModel,
              hasValue: hasTitleModel,
              value: hasTitleModel ? _settings.titleModel : null,
              subtitle: hasTitleModel
                  ? _findProviderName(_settings.titleModel)
                  : null,
              onSelect: () => _showModelPicker(forTitle: true),
              onReset: hasTitleModel ? () => _reset('title') : null,
              description: l10n.modelConfigTitleModelDesc,
            ),
            const SizedBox(height: 16),
            _ConfigCard(
              icon: Icons.translate_rounded,
              iconColor: scheme.tertiary,
              title: l10n.modelConfigTranslatorModel,
              hasValue: hasTranslatorModel,
              value: hasTranslatorModel ? _settings.translatorModel : null,
              subtitle: hasTranslatorModel
                  ? _findProviderName(_settings.translatorModel)
                  : null,
              onSelect: () => _showModelPicker(forTranslator: true),
              onReset: hasTranslatorModel ? () => _reset('translator') : null,
              description: l10n.modelConfigTranslatorModelDesc,
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

/// 底部弹出模型选择面板。
class _ModelPickerSheet extends StatelessWidget {
  final List<ChatProvider> providers;
  final String current;
  final String title;

  const _ModelPickerSheet({
    required this.providers,
    required this.current,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filtered = providers.where((p) => p.modelIds.isNotEmpty).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in filtered) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                  for (final m in p.modelIds)
                    ListTile(
                      dense: true,
                      selected: m == current,
                      leading: Icon(
                        m == current
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: m == current ? scheme.primary : scheme.outline,
                      ),
                      title: Text(m, style: const TextStyle(fontSize: 13)),
                      onTap: () => Navigator.of(context).pop(m),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool hasValue;
  final String? value;
  final String? subtitle;
  final VoidCallback onSelect;
  final VoidCallback? onReset;
  final String description;

  const _ConfigCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.hasValue,
    this.value,
    this.subtitle,
    required this.onSelect,
    this.onReset,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onReset != null)
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.commonReset,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasValue && value != null
                                ? value!
                                : context.l10n.modelConfigUnset,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: hasValue ? scheme.onSurface : scheme.outline,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.expand_more, size: 18, color: scheme.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: scheme.outline, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
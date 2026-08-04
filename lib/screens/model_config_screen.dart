import 'package:flutter/material.dart';

import '../models/chat_provider.dart';
import '../services/provider_service.dart';
import '../services/settings_service.dart';

/// 模型配置页：全局模型默认值（聊天模型、Agent 模型等）。
class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  final _settingsService = SettingsService();
  final _providerService = ProviderService();
  AppSettings _settings = const AppSettings();
  List<ChatProvider> _providers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _settingsService.load(),
      _providerService.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _settings = results[0] as AppSettings;
      _providers = results[1] as List<ChatProvider>;
    });
  }

  Future<void> _save(String? chatModel) async {
    await _settingsService.save(
      _settings.copyWith(chatModel: chatModel ?? ''),
    );
    if (!mounted) return;
    setState(() => _settings = _settings.copyWith(chatModel: chatModel ?? ''));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存')));
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置聊天默认模型'),
        content: const Text(
          '重置后，新建会话将不再自动选择模型，每次需手动选择。确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(null);
  }

  String? _findProviderName(String modelId) {
    for (final p in _providers) {
      if (p.modelIds.contains(modelId)) return p.name;
    }
    return null;
  }

  void _showModelPicker() async {
    final filtered = _providers.where((p) => p.modelIds.isNotEmpty).toList();
    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无已配置的模型，请先在服务商中添加')),
        );
      }
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _ModelPickerSheet(
        providers: _providers,
        current: _settings.chatModel,
      ),
    );
    if (selected != null) _save(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasModel = _settings.chatModel.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('模型配置')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ConfigCard(
              icon: Icons.chat_outlined,
              iconColor: scheme.primary,
              title: '聊天模型',
              hasValue: hasModel,
              value: hasModel ? _settings.chatModel : null,
              subtitle: hasModel ? _findProviderName(_settings.chatModel) : null,
              onSelect: _showModelPicker,
              onReset: hasModel ? _reset : null,
              description: '每次新建会话时默认使用此模型。重置后新建会话需手动选择。',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '模型配置将在后续版本中扩展到 Agent 默认模型、绘画默认模型等',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.outline, height: 1.5),
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

  const _ModelPickerSheet({
    required this.providers,
    required this.current,
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
              '选择聊天模型',
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
                    child: const Text('重置', style: TextStyle(fontSize: 12.5)),
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
                            hasValue && value != null ? value! : '未设置',
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
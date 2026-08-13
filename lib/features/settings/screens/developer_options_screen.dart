import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/model_capability_service.dart';
import '../../../core/services/network_log_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../shared/app_routes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/settings_tiles.dart';

/// 开发者选项页：仅供高级用户使用的高级设置。
class DeveloperOptionsScreen extends StatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  late final SettingsService _settingsService = context.read<SettingsService>();
  late final ModelCapabilityService _capabilityService = context.read<ModelCapabilityService>();

  late final TextEditingController _testPromptController;
  AppSettings _settings = const AppSettings();

  /// 模型能力映射表更新时间与数据来源（内置表 / 联网缓存）。
  String? _capabilityVersion;
  bool _capabilityFromNetwork = false;
  bool _updatingCapability = false;
  bool _autoUpdateCapabilities = false;
  bool _crashReportingEnabled = false;

  @override
  void initState() {
    super.initState();
    _testPromptController = TextEditingController();
    // 网络日志数量实时刷新（本页显示日志条数入口）
    NetworkLogService.instance.addListener(_onLogsChanged);
    _load();
  }

  @override
  void dispose() {
    NetworkLogService.instance.removeListener(_onLogsChanged);
    _testPromptController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _crashReportingEnabled =
        prefs.getBool('crash_reporting_enabled') ?? false;
    final settings = await _settingsService.load();
    final info = await _capabilityService.info();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _testPromptController.text = settings.testPrompt;
      _capabilityVersion = info.version;
      _capabilityFromNetwork = info.fromNetwork;
      _autoUpdateCapabilities = settings.autoUpdateModelCapabilities;
    });
    // 与持久化设置保持同步，确保记录开关即时生效
    NetworkLogService.instance.setEnabled(settings.networkLogEnabled);
    NetworkLogService.instance.setMaxLogs(settings.networkLogMaxLogs);
  }

  Future<void> _onTestPromptChanged(String value) async {
    _settings = _settings.copyWith(testPrompt: value);
    await _settingsService.save(_settings);
  }

  Future<void> _onAutoUpdateChanged(bool value) async {
    setState(() => _autoUpdateCapabilities = value);
    _settings = _settings.copyWith(autoUpdateModelCapabilities: value);
    await _settingsService.save(_settings);
  }

  Future<void> _onNetworkLogEnabledChanged(bool value) async {
    setState(() => _settings = _settings.copyWith(networkLogEnabled: value));
    NetworkLogService.instance.setEnabled(value);
    await _settingsService.save(_settings);
  }

  Future<void> _openNetworkLogs() async {
    await Navigator.of(
      context,
    ).push(AppRoutes.networkLogs());
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editMaxLogs() async {
    final controller = TextEditingController(
      text: _settings.networkLogMaxLogs > 0 ? '${_settings.networkLogMaxLogs}' : '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.devMaxLogsTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onTapOutside: unfocusOnTap,
          decoration: InputDecoration(
            labelText: ctx.l10n.devMaxLogsLabel,
            hintText: ctx.l10n.devMaxLogsExample,
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
    // 非数字输入按非法处理并提示，而不是静默当成 0（无限）
    final value = int.tryParse(result.trim());
    if (value == null || value < 0) {
      showAppSnack(context, context.l10n.devMaxLogsInvalid);
      return;
    }
    setState(() => _settings = _settings.copyWith(networkLogMaxLogs: value));
    NetworkLogService.instance.setMaxLogs(value);
    await _settingsService.save(_settings);
  }

  Future<void> _updateCapability() async {
    if (_updatingCapability) return;
    setState(() => _updatingCapability = true);
    try {
      final version = await _capabilityService.updateFromNetwork();
      if (!mounted) return;
      setState(() {
        _updatingCapability = false;
        _capabilityVersion = version;
        _capabilityFromNetwork = true;
      });
      showAppSnack(context, context.l10n.devUpdated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingCapability = false);
      showAppSnack(context, context.l10n.devUpdateFailed(e));
    }
  }

  /// 映射表状态文案：联网缓存显示更新时间（精确到秒），内置表显示版本。
  String get _capabilityStatusText {
    final version = _capabilityVersion;
    if (version == null) return context.l10n.devNoBuiltinTable;
    if (_capabilityFromNetwork) return context.l10n.devUpdatedAt(version);
    return context.l10n.devBuiltinVersion(version);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.devTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // 风险提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.devWarning,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SettingsSectionLabel(context.l10n.devConnectivitySection),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.devTestPrompt,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.devTestPromptHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testPromptController,
                    minLines: 2,
                    maxLines: 4,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: _onTestPromptChanged,
                    decoration: InputDecoration(
                      hintText: context.l10n.devTestPromptExample,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SettingsSectionLabel(context.l10n.devCapabilitySection),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.devCapabilityTitle,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.devCapabilityDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _updatingCapability
                              ? context.l10n.devUpdating
                              : _capabilityStatusText,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _updatingCapability ? null : _updateCapability,
                        icon: _updatingCapability
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_download_outlined, size: 16),
                        label: Text(
                          _updatingCapability
                              ? context.l10n.devUpdatingShort
                              : context.l10n.devUpdateFromNetwork,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      context.l10n.devAutoUpdate,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      context.l10n.devAutoUpdateHint,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    value: _autoUpdateCapabilities,
                    onChanged: _onAutoUpdateChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SettingsSectionLabel(context.l10n.devNetworkLogSection),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 19,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      context.l10n.devNetworkLogEnable,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      context.l10n.devNetworkLogEnableHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    value: _settings.networkLogEnabled,
                    onChanged: _onNetworkLogEnabledChanged,
                  ),
                  const TileDivider(),
                  // J-01：崩溃上报开关（隐私友好，默认关）
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      context.l10n.devCrashReporting,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      context.l10n.devCrashReportingHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    value: _crashReportingEnabled,
                    onChanged: (v) async {
                      setState(() => _crashReportingEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('crash_reporting_enabled', v);
                    },
                  ),
                  const TileDivider(),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.list_alt_rounded,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      context.l10n.devNetworkLog,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _settings.networkLogEnabled
                          ? context.l10n.devNetworkLogCount(
                              NetworkLogService.instance.logs.length,
                            )
                          : context.l10n.devNetworkLogDisabled,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    onTap: _openNetworkLogs,
                  ),
                  const TileDivider(),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.data_object_rounded,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      context.l10n.devMaxLogs,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _settings.networkLogMaxLogs > 0
                          ? context.l10n.devMaxLogsSubtitle(
                              _settings.networkLogMaxLogs,
                            )
                          : context.l10n.devMaxLogsUnlimited,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    onTap: _editMaxLogs,
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



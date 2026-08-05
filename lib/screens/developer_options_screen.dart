import 'package:flutter/material.dart';

import '../services/model_capability_service.dart';
import '../services/network_log_service.dart';
import '../services/settings_service.dart';
import 'network_log_screen.dart';

/// 开发者选项页：仅供高级用户使用的高级设置。
class DeveloperOptionsScreen extends StatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  final _settingsService = SettingsService();
  final _capabilityService = ModelCapabilityService();

  late final TextEditingController _testPromptController;
  AppSettings _settings = const AppSettings();

  /// 模型能力映射表更新时间与数据来源（内置表 / 联网缓存）。
  String? _capabilityVersion;
  bool _capabilityFromNetwork = false;
  bool _updatingCapability = false;
  bool _autoUpdateCapabilities = false;

  @override
  void initState() {
    super.initState();
    _testPromptController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _testPromptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
    ).push(MaterialPageRoute(builder: (_) => const NetworkLogScreen()));
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
        title: const Text('最大保留条数'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: const InputDecoration(
            labelText: '条数（留空为无限）',
            hintText: '例如：1000',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final value = int.tryParse(result) ?? 0;
    if (value < 0) {
      _snack('请输入非负整数');
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
      _snack('模型能力表更新完成');
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingCapability = false);
      _snack('更新失败：$e');
    }
  }

  /// 映射表状态文案：联网缓存显示更新时间（精确到秒），内置表显示版本。
  String get _capabilityStatusText {
    if (_capabilityVersion == null) return '无内置映射表';
    if (_capabilityFromNetwork) return '更新时间：$_capabilityVersion';
    return '内置映射表 · 版本 $_capabilityVersion';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('开发者选项')),
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
                      '开发者选项包含高风险设置，仅建议高级用户使用，请谨慎修改。',
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
            const _SectionLabel('连通性设置'),
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
                    '连通性测试提示词',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '模型连通性测试时发送给模型的最小请求内容',
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
                    decoration: const InputDecoration(
                      hintText: '例如：ping',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('模型能力映射表'),
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
                    '模型能力映射表',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '内置静态表（离线兜底）+ 联网更新缓存，用于按模型 id 自动填充「多模态 / 推理」配置',
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
                              ? '正在更新…'
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
                        label: Text(_updatingCapability ? '更新中' : '从网络更新'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '启动时自动更新',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '应用启动时静默从网络更新映射表，失败不影响使用',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    value: _autoUpdateCapabilities,
                    onChanged: _onAutoUpdateChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('网络日志'),
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
                    title: const Text(
                      '启用网络日志',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '记录应用内全部网络请求（含聊天、测速、拉取模型等）',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    value: _settings.networkLogEnabled,
                    onChanged: _onNetworkLogEnabledChanged,
                  ),
                  const _TileDivider(),
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
                    title: const Text(
                      '网络日志',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _settings.networkLogEnabled
                          ? '共 ${NetworkLogService.instance.logs.length} 条记录'
                          : '未启用记录，开启后自动捕获请求',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    onTap: _openNetworkLogs,
                  ),
                  const _TileDivider(),
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
                    title: const Text(
                      '最大保留条数',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _settings.networkLogMaxLogs > 0
                          ? '超过 ${_settings.networkLogMaxLogs} 条时自动清理最旧记录'
                          : '无限，全部记录保留',
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

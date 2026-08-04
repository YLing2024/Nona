import 'package:flutter/material.dart';

import '../models/chat_provider.dart';
import '../services/provider_service.dart';
import '../services/settings_service.dart';
import '../widgets/add_model_dialog.dart';

/// 服务商详情页：基础配置 + 已添加模型列表（可添加/移除）。
class ProviderEditScreen extends StatefulWidget {
  final ChatProvider? provider;

  const ProviderEditScreen({super.key, this.provider});

  @override
  State<ProviderEditScreen> createState() => _ProviderEditScreenState();
}

class _ProviderEditScreenState extends State<ProviderEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  final List<String> _modelIds = [];
  final Map<String, ModelTestResult?> _testResults = {};
  final Set<String> _testingModels = {};
  bool _testingAll = false;

  /// 模型级配置（多模态/推理等），后续可持久化。
  final Map<String, Map<String, dynamic>> _modelConfig = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _baseUrlController = TextEditingController(
      text: widget.provider?.baseUrl ?? '',
    );
    _apiKeyController = TextEditingController(
      text: widget.provider?.apiKey ?? '',
    );
    if (widget.provider != null) {
      _modelIds.addAll(widget.provider!.modelIds);
    }
    _loadTestResults();
  }

  Future<void> _loadTestResults() async {
    final pid = widget.provider?.id;
    if (pid == null) return;
    final results = await TestResultStorage.load(pid);
    if (!mounted) return;
    setState(() => _testResults.addAll(results));
  }

  void _persistTestResults() {
    final pid = widget.provider?.id;
    if (pid == null) return;
    TestResultStorage.save(pid, _testResults);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  ChatProvider _buildProvider() {
    return ChatProvider(
      id:
          widget.provider?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelIds: List.of(_modelIds),
    );
  }

  Future<void> _openAddModelDialog() async {
    final added = await showAddModelDialog(
      context,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      existing: _modelIds.toSet(),
    );
    if (added == null || added.isEmpty || !mounted) return;
    setState(() => _modelIds.addAll(added.where((m) => !_modelIds.contains(m))));
  }

  ChatProvider _currentProvider() => ChatProvider(
        id: 'temp',
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        modelIds: List.of(_modelIds),
      );

  Future<ModelTestResult?> _testSingle(String model) async {
    if (_testingModels.contains(model)) return null;
    final settings = await SettingsService().load();
    final prompt = settings.testPrompt.isEmpty ? 'ping' : settings.testPrompt;
    if (!mounted) return null;
    setState(() {
      _testingModels.add(model);
      _testResults.remove(model);
    });
    ModelTestResult? result;
    try {
      result = await ProviderService().testModel(
        _currentProvider(),
        model,
        prompt: prompt,
      );
      if (!mounted) return null;
      setState(() => _testResults[model] = result);
    } catch (e) {
      if (!mounted) return null;
      result = ModelTestResult(
        success: false,
        elapsedMs: 0,
        error: e.toString(),
      );
      setState(() => _testResults[model] = result);
    } finally {
      if (mounted) {
        setState(() => _testingModels.remove(model));
        _persistTestResults();
      }
    }
    return result;
  }

  Future<void> _testAll() async {
    if (_testingAll || _modelIds.isEmpty) return;
    final settings = await SettingsService().load();
    final prompt = settings.testPrompt.isEmpty ? 'ping' : settings.testPrompt;
    final models = List.of(_modelIds);
    if (!mounted) return;
    setState(() {
      _testingAll = true;
      for (final m in models) {
        _testingModels.add(m);
        _testResults.remove(m);
      }
    });

    await Future.wait(models.map((m) async {
      try {
        final result = await ProviderService().testModel(
          _currentProvider(),
          m,
          prompt: prompt,
        );
        if (mounted) setState(() => _testResults[m] = result);
      } catch (e) {
        if (mounted) {
          setState(
            () => _testResults[m] = ModelTestResult(
              success: false,
              elapsedMs: 0,
              error: e.toString(),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _testingModels.remove(m));
      }
    }));

    if (mounted) {
      setState(() => _testingAll = false);
      _persistTestResults();
    }
  }

  Widget _buildLatencyLabel(String model) {
    final scheme = Theme.of(context).colorScheme;
    if (_testingModels.contains(model)) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final result = _testResults[model];
    if (result != null) {
      if (result.success) {
        Color color;
        if (result.elapsedMs < 1000) {
          color = Colors.green;
        } else if (result.elapsedMs < 3000) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }
        return Text(
          '${result.elapsedMs}ms',
          style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w500),
        );
      }
      return Text(
        '-1ms',
        style: TextStyle(fontSize: 11.5, color: scheme.error, fontWeight: FontWeight.w500),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmDelete(String model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除模型'),
        content: Text('确定移除「$model」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _modelIds.remove(model));
  }

  void _openModelSettingsDialog(String model) {
    final config = _modelConfig.putIfAbsent(model, () => {
      'multimodal': false,
      'reasoning': false,
    });

    showDialog(
      context: context,
      builder: (ctx) => _ModelSettingsDialog(
        model: model,
        config: config,
        onConfigChanged: (key, value) {
          setState(() => config[key] = value);
        },
        onReTest: () => _testSingle(model),
        testResult: _testResults[model],
        isTesting: _testingModels.contains(model),
      ),
    );
  }

  Future<void> _openSettingsDialog() async {
    final settings = await SettingsService().load();
    if (!mounted) return;
    final controller = TextEditingController(text: settings.testPrompt);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务商设置'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '连通性测试提示词',
            hintText: '例如：ping',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    await SettingsService().save(settings.copyWith(testPrompt: result));
  }

  void _save() {
    final name = _nameController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    if (name.isEmpty || baseUrl.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写服务商名称、Base URL 和 API Key')),
      );
      return;
    }
    Navigator.of(context).pop(_buildProvider());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider == null ? '添加服务商' : '服务商设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: '设置',
            onPressed: _openSettingsDialog,
          ),
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          TextField(
            controller: _nameController,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: '服务商名称',
              hintText: '例如：OpenAI',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            autocorrect: false,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            autocorrect: false,
            enableSuggestions: false,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('模型', style: theme.textTheme.titleMedium)),
              if (_modelIds.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _testingAll ? null : _testAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_testingAll)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(_testingAll ? '测试中…' : '测试'),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _openAddModelDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加模型'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_modelIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '尚未添加模型，点击「添加模型」\n可手动填写模型 ID 或从 /models 列表获取',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _modelIds.removeAt(oldIndex);
                  _modelIds.insert(newIndex, item);
                });
              },
              children: [
                for (final model in _modelIds)
                  ReorderableDelayedDragStartListener(
                    key: ValueKey(model),
                    index: _modelIds.indexOf(model),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.drag_indicator, size: 18, color: scheme.outlineVariant),
                          const SizedBox(width: 4),
                          const Icon(Icons.model_training_outlined, size: 18),
                        ],
                      ),
                      title: Text(model, style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLatencyLabel(model),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            tooltip: '模型设置',
                            onPressed: () => _openModelSettingsDialog(model),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: '移除',
                            onPressed: () => _confirmDelete(model),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
        ),
      ),
    );
  }
}

/// 模型设置弹窗：基础设置 + 高级设置（TabBar），内容列表可滚动。
class _ModelSettingsDialog extends StatefulWidget {
  final String model;
  final Map<String, dynamic> config;
  final void Function(String key, dynamic value) onConfigChanged;
  final Future<ModelTestResult?> Function() onReTest;
  final ModelTestResult? testResult;
  final bool isTesting;

  const _ModelSettingsDialog({
    required this.model,
    required this.config,
    required this.onConfigChanged,
    required this.onReTest,
    this.testResult,
    required this.isTesting,
  });

  @override
  State<_ModelSettingsDialog> createState() => _ModelSettingsDialogState();
}

class _ModelSettingsDialogState extends State<_ModelSettingsDialog> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.model,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            // Tab 按钮行（固定高度）
            Row(
              children: [
                _TabButton(
                  label: '基础设置',
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: '高级设置',
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
            const Divider(height: 1),
            // 内容列表（可滚动）
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: _selectedTab == 0
                    ? _buildBasicSettings(theme, scheme)
                    : _buildAdvancedSettings(theme, scheme),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  List<Widget> _buildBasicSettings(ThemeData theme, ColorScheme scheme) {
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('多模态', style: TextStyle(fontSize: 14)),
        subtitle: Text(
          '支持图片、文件等非文本输入',
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        value: widget.config['multimodal'] ?? false,
        onChanged: (v) => widget.onConfigChanged('multimodal', v),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('推理', style: TextStyle(fontSize: 14)),
        subtitle: Text(
          '启用深度推理能力（如 o1、o3 系列）',
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        value: widget.config['reasoning'] ?? false,
        onChanged: (v) => widget.onConfigChanged('reasoning', v),
      ),
    ];
  }

  List<Widget> _buildAdvancedSettings(ThemeData theme, ColorScheme scheme) {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.speed, size: 20),
        title: const Text('延迟记录', style: TextStyle(fontSize: 14)),
        subtitle: _buildLatencySubtitle(scheme),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () => _showLatencyDetail(theme, scheme),
      ),
      const Divider(height: 1, indent: 40),
    ];
  }

  Widget? _buildLatencySubtitle(ColorScheme scheme) {
    if (widget.isTesting) {
      return Text('测试中…', style: TextStyle(fontSize: 12, color: scheme.outline));
    }
    final result = widget.testResult;
    if (result == null) {
      return Text('尚未测试', style: TextStyle(fontSize: 12, color: scheme.outline));
    }
    if (result.success) {
      Color color;
      if (result.elapsedMs < 1000) {
        color = Colors.green;
      } else if (result.elapsedMs < 3000) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      return Text(
        '${result.elapsedMs}ms',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      );
    }
    return Text(
      '测试失败: ${result.error ?? "未知错误"}',
      style: TextStyle(fontSize: 12, color: scheme.error),
    );
  }

  void _showLatencyDetail(ThemeData theme, ColorScheme scheme) {
    ModelTestResult? displayResult = widget.testResult;
    bool isReTesting = widget.isTesting;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('延迟记录', style: TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isReTesting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (displayResult != null)
                  _buildLatencyDetailContent(displayResult!, theme, scheme)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('尚未测试', style: TextStyle(color: scheme.outline)),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('关闭'),
            ),
            FilledButton.icon(
              onPressed: isReTesting
                  ? null
                  : () async {
                      setDialogState(() => isReTesting = true);
                      final result = await widget.onReTest();
                      if (ctx.mounted) {
                        setDialogState(() {
                          isReTesting = false;
                          displayResult = result;
                        });
                      }
                    },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(isReTesting ? '测试中…' : '重新测试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatencyDetailContent(ModelTestResult result, ThemeData theme, ColorScheme scheme) {
    if (result.success) {
      Color color;
      if (result.elapsedMs < 1000) {
        color = Colors.green;
      } else if (result.elapsedMs < 3000) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${result.elapsedMs}ms',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.elapsedMs < 1000
                  ? '优秀'
                  : result.elapsedMs < 3000
                      ? '一般'
                      : '较慢',
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            '测试失败',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.error,
            ),
          ),
          if (result.error != null) ...[
            const SizedBox(height: 4),
            Text(
              result.error!,
              style: TextStyle(fontSize: 12, color: scheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? scheme.onPrimaryContainer : scheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
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

  /// 服务商 id：编辑已有服务商时沿用原 id，新增时立即生成。
  late final String _providerId;

  final List<String> _modelIds = [];
  final Map<String, ModelTestResult?> _testResults = {};
  final Set<String> _testingModels = {};
  bool _testingAll = false;

  /// 模型级配置（多模态/推理等），随服务商一起持久化。
  final Map<String, ModelConfig> _modelConfig = {};

  /// 持久化串行链，避免并发读改写丢更新。
  Future<void>? _persistChain;

  @override
  void initState() {
    super.initState();
    _providerId =
        widget.provider?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _baseUrlController = TextEditingController(
      text: widget.provider?.baseUrl ?? '',
    );
    _apiKeyController = TextEditingController(
      text: widget.provider?.apiKey ?? '',
    );
    if (widget.provider != null) {
      _modelIds.addAll(widget.provider!.modelIds);
      _modelConfig.addAll(widget.provider!.modelConfigs);
    }
    _loadTestResults();
  }

  Future<void> _loadTestResults() async {
    final results = await TestResultStorage.load(_providerId);
    if (!mounted) return;
    setState(() => _testResults.addAll(results));
  }

  void _persistTestResults() {
    TestResultStorage.save(_providerId, _testResults);
  }

  /// 将当前编辑内容写回持久化存储；修改即生效。
  Future<void> _persist() async {
    try {
      final providers = await ProviderService().load();
      final index = providers.indexWhere((p) => p.id == _providerId);
      final current = _buildProvider();
      if (index >= 0) {
        providers[index] = current;
      } else {
        providers.add(current);
      }
      await ProviderService().save(providers);
    } catch (e) {
      // 写入失败不阻塞操作，但打印出来便于排查
      debugPrint('[ProviderEdit] 保存失败: $e');
    }
  }

  void _schedulePersist() {
    _persistChain = (_persistChain ?? Future.value()).then((_) => _persist());
  }

  /// 离开页面时调用：等待队列中所有实时修改落盘，避免返回后丢失。
  Future<void> _flushPending() => _persistChain ?? Future.value();

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  ChatProvider _buildProvider() {
    return ChatProvider(
      id: _providerId,
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelIds: List.of(_modelIds),
      // 联动兜底：只持久化当前模型列表内模型的配置，避免残留孤儿配置
      modelConfigs: Map.of(_modelConfig)
        ..removeWhere((model, _) => !_modelIds.contains(model)),
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
    setState(() {
      for (final (model, config) in added) {
        if (_modelIds.contains(model)) continue;
        _modelIds.add(model);
        _modelConfig[model] = config;
      }
    });
    _schedulePersist();
  }

  ChatProvider _currentProvider() => ChatProvider(
        id: 'temp',
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        modelIds: List.of(_modelIds),
        modelConfigs: Map.of(_modelConfig),
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
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final result = _testResults[model];
    // 未测试过的模型显示占位文案，点击可发起测试
    if (result == null) {
      return Tooltip(
        message: '点击测试',
        child: InkWell(
          onTap: () => _testSingle(model),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '未测试',
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.outline,
              ),
            ),
          ),
        ),
      );
    }
    final Color color;
    final String text;
    if (result.success) {
      color = result.elapsedMs < 1000
          ? Colors.green
          : result.elapsedMs < 3000
              ? Colors.orange
              : Colors.red;
      text = '${result.elapsedMs}ms';
    } else {
      color = scheme.error;
      text = '-1ms';
    }
    // 点击毫秒数重新测试该模型连通性
    return Tooltip(
      message: '点击重新测试',
      child: InkWell(
        onTap: () => _testSingle(model),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 模型能力标签列表（多模态 / 推理），无标签时返回空列表。
  List<Widget> _buildModelBadges(String model, ColorScheme scheme) {
    final config = _modelConfig[model];
    return [
      if (config?.multimodal == true)
        _CapabilityBadge(
          label: '多模态',
          color: scheme.tertiary,
        ),
      if (config?.reasoning == true)
        _CapabilityBadge(
          label: '推理',
          color: scheme.primary,
        ),
    ];
  }

  /// 模型行：名称可换行完整展示，能力标签与延迟状态放次行，操作按钮置右。
  Widget _buildModelItem(String model, ColorScheme scheme) {
    final badges = _buildModelBadges(model, scheme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 18, color: scheme.outlineVariant),
          const SizedBox(width: 4),
          const Icon(Icons.model_training_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (badges.isNotEmpty)
                      ...badges
                    else
                      // 无能力标签时给个占位，避免第二行左侧空荡
                      Text(
                        '无',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.outline,
                        ),
                      ),
                    const Spacer(),
                    _buildLatencyLabel(model),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: '模型设置',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openModelSettingsDialog(model),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: '移除',
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmDelete(model),
          ),
        ],
      ),
    );
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
    if (confirmed == true) {
      setState(() {
        _modelIds.remove(model);
        // 联动清理：模型被移除后，其能力配置与延迟测试结果一并清除
        _modelConfig.remove(model);
        _testResults.remove(model);
      });
      _schedulePersist();
      _persistTestResults();
      // 等待写入完成，再清理指向该模型的全局默认配置
      await _persistChain;
      await ProviderService().clearStaleDefaultModels();
    }
  }

  void _openModelSettingsDialog(String model) {
    final config = _modelConfig.putIfAbsent(model, () => const ModelConfig());

    showDialog(
      context: context,
      builder: (ctx) => _ModelSettingsDialog(
        model: model,
        config: config,
        onConfigChanged: (c) {
          setState(() => _modelConfig[model] = c);
          _schedulePersist();
        },
        onReTest: () => _testSingle(model),
        testResult: _testResults[model],
        isTesting: _testingModels.contains(model),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      // 返回前先把队列里所有实时修改落盘，避免丢改动
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        _flushPending().then((_) {
          if (mounted) navigator.pop();
        });
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.provider == null ? '添加服务商' : '服务商设置'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          TextField(
            controller: _nameController,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (_) => _schedulePersist(),
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
            onChanged: (_) => _schedulePersist(),
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
            onChanged: (_) => _schedulePersist(),
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
                _schedulePersist();
              },
              children: [
                for (final model in _modelIds)
                  ReorderableDelayedDragStartListener(
                    key: ValueKey(model),
                    index: _modelIds.indexOf(model),
                    child: _buildModelItem(model, scheme),
                  ),
              ],
            ),
        ],
        ),
      ),
      ),
    );
  }
}

/// 模型设置弹窗：基础设置 + 高级设置（TabBar），内容列表可滚动。
class _ModelSettingsDialog extends StatefulWidget {
  final String model;
  final ModelConfig config;
  final void Function(ModelConfig config) onConfigChanged;
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
  late ModelConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _setConfig(ModelConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

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
        value: _config.multimodal,
        onChanged: (v) => _setConfig(_config.copyWith(multimodal: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('推理', style: TextStyle(fontSize: 14)),
        subtitle: Text(
          '启用深度推理能力（如 o1、o3 系列）',
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        value: _config.reasoning,
        onChanged: (v) => _setConfig(_config.copyWith(reasoning: v)),
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

/// 模型能力小标签（多模态 / 推理）。
class _CapabilityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CapabilityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
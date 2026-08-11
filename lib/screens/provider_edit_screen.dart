import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_provider.dart';
import '../services/chat_protocol.dart';
import '../services/provider_service.dart';
import '../services/settings_service.dart';
import '../utils/l10n_ext.dart';
import '../utils/logger.dart';
import '../widgets/add_model_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/model_settings_dialog.dart';
import '../widgets/provider_form_fields.dart';

/// 服务商详情页：基础配置 + 已添加模型列表（可添加/移除）。
///
/// 表单区委托 [ProviderFormFields]，模型区委托 [ProviderModelTable]，
/// 模型设置弹窗为独立文件 [ModelSettingsDialog]；本页保留状态与持久化。
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
  late final TextEditingController _customHeadersController;
  late final TextEditingController _customBodyController;

  /// 协议类型（auto 按 Base URL 自动探测）。
  late ProviderKind _providerKind;
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
    _providerKind = widget.provider?.kind ?? ProviderKind.auto;
    _customHeadersController = TextEditingController(
      text: (widget.provider?.customHeaders ?? const {})
          .entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
    );
    _customBodyController = TextEditingController(
      text: widget.provider?.customBody == null
          ? ''
          : const JsonEncoder.withIndent('  ').convert(widget.provider!.customBody),
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

  /// 解析「Key: Value」每行一个的自定义请求头。
  static Map<String, String> _parseHeaders(String text) {
    final headers = <String, String>{};
    for (final line in text.split('\n')) {
      final colon = line.indexOf(':');
      if (colon > 0) {
        headers[line.substring(0, colon).trim()] =
            line.substring(colon + 1).trim();
      }
    }
    return headers;
  }

  /// 解析自定义请求体 JSON；非法时返回 null（不合并）。
  static Map<String, dynamic>? _parseBody(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// 将当前编辑内容写回持久化存储；修改即生效。
  Future<void> _persist() async {
    final providerService = context.read<ProviderService>();
    try {
      final providers = await providerService.load();
      final index = providers.indexWhere((p) => p.id == _providerId);
      final current = _buildProvider();
      if (index >= 0) {
        providers[index] = current;
      } else {
        providers.add(current);
      }
      await providerService.save(providers);
    } catch (e) {
      // 写入失败不阻塞输入节奏，但记录日志并提示（连续失败才提示，见 _schedulePersist）
      Logger.error('provider_edit', '保存失败', e);
    }
  }

  /// 连续写入失败计数：仅在第 2 次起提示，避免打断打字节奏。
  int _persistFailStreak = 0;

  void _schedulePersist() {
    _persistChain = (_persistChain ?? Future.value()).then((_) async {
      try {
        await _persist();
        _persistFailStreak = 0;
      } catch (e) {
        _persistFailStreak++;
        if (_persistFailStreak >= 2 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.providerSaveFailed)),
          );
        }
      }
    });
  }

  /// 离开页面时调用：等待队列中所有实时修改落盘，避免返回后丢失。
  Future<void> _flushPending() => _persistChain ?? Future.value();

  /// 防重入：连续按两次返回只弹一次（首次 pop 前有落盘 await 窗口）。
  bool _popping = false;

  /// 校验会被静默丢弃的字段；有问题的项返回本地化提示文案。
  List<String> _fieldIssues() {
    final l10n = context.l10n;
    final issues = <String>[];
    final body = _customBodyController.text.trim();
    if (body.isNotEmpty && _parseBody(body) == null) {
      issues.add(l10n.providerCustomBodyInvalid);
    }
    final hasBadHeaderLine = _customHeadersController.text.split('\n').any(
          (l) => l.trim().isNotEmpty && l.indexOf(':') <= 0,
        );
    if (hasBadHeaderLine) {
      issues.add(l10n.providerCustomHeadersInvalid);
    }
    return issues;
  }

  /// 返回确认：自定义请求体/请求头非法时确认丢弃（默认阻止静默丢数据）。
  Future<void> _handlePop() async {
    if (_popping) return;
    final issues = _fieldIssues();
    if (issues.isNotEmpty && mounted) {
      final confirmed = await confirmAction(
        context,
        title: context.l10n.commonWarning,
        message: issues.join('\n'),
        confirmText: context.l10n.commonDiscard,
      );
      if (!confirmed || !mounted) return;
    }
    _popping = true;
    final navigator = Navigator.of(context);
    await _flushPending();
    if (mounted) navigator.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _customHeadersController.dispose();
    _customBodyController.dispose();
    super.dispose();
  }

  ChatProvider _buildProvider() {
    return ChatProvider(
      id: _providerId,
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      kind: _providerKind,
      customHeaders: _parseHeaders(_customHeadersController.text),
      customBody: _parseBody(_customBodyController.text),
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
    final settings = await context.read<SettingsService>().load();
    final prompt = settings.testPrompt.isEmpty ? 'ping' : settings.testPrompt;
    if (!mounted) return null;
    setState(() {
      _testingModels.add(model);
      _testResults.remove(model);
    });
    ModelTestResult? result;
    try {
      result = await context.read<ProviderService>().testModel(
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
    final settings = await context.read<SettingsService>().load();
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
        final result = await context.read<ProviderService>().testModel(
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

  Future<void> _confirmDelete(String model) async {
    final providerService = context.read<ProviderService>();
    final confirmed = await confirmAction(
      context,
      title: context.l10n.providerRemoveModelTitle,
      message: context.l10n.providerRemoveModelConfirm(model),
      confirmText: context.l10n.commonRemove,
      danger: true,
    );
    if (confirmed) {
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
      await providerService.clearStaleDefaultModels();
    }
  }
  void _openModelSettingsDialog(String model) {
    final config = _modelConfig.putIfAbsent(model, () => const ModelConfig());

    showDialog(
      context: context,
      builder: (ctx) => ModelSettingsDialog(
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
    return PopScope(
      // 返回前先把队列里所有实时修改落盘，避免丢改动
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.provider == null
                ? context.l10n.providerAdd
                : context.l10n.providerEdit,
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProviderFormFields(
                nameController: _nameController,
                baseUrlController: _baseUrlController,
                apiKeyController: _apiKeyController,
                customHeadersController: _customHeadersController,
                customBodyController: _customBodyController,
                kind: _providerKind,
                obscureApiKey: _obscureApiKey,
                onToggleObscure: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
                onKindChanged: (kind) {
                  setState(() => _providerKind = kind);
                  _schedulePersist();
                },
                onChanged: _schedulePersist,
              ),
              const SizedBox(height: 24),
              ProviderModelTable(
                modelIds: _modelIds,
                modelConfigs: _modelConfig,
                testResults: _testResults,
                testingModels: _testingModels,
                testingAll: _testingAll,
                onAddModel: _openAddModelDialog,
                onTestAll: _testAll,
                onTestSingle: _testSingle,
                onRemove: _confirmDelete,
                onOpenSettings: _openModelSettingsDialog,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _modelIds.removeAt(oldIndex);
                    _modelIds.insert(newIndex, item);
                  });
                  _schedulePersist();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

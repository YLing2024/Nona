import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/chat_provider.dart';
import '../../../core/services/chat_protocol.dart';
import '../../../core/services/protocol/vertex_auth.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/add_model_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/model_settings_dialog.dart';
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

  /// C-01：Responses API 开关。
  late bool _useResponseApi;

  /// C-03：服务商分组 id。
  String? _groupId;

  /// C-02：Vertex 认证字段。
  late String _authMode;
  late String _saJson;
  late String _vertexProject;
  late String _vertexRegion;

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
    _useResponseApi = widget.provider?.useResponseApi ?? false;
    _groupId = widget.provider?.groupId;
    _authMode = widget.provider?.authMode ?? 'apiKey';
    _saJson = widget.provider?.saJson ?? '';
    _vertexProject = widget.provider?.vertexProject ?? '';
    _vertexRegion = widget.provider?.vertexRegion ?? 'us-central1';
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
      useResponseApi: _useResponseApi,
      groupId: _groupId,
      authMode: _authMode,
      saJson: _saJson,
      vertexProject: _vertexProject,
      vertexRegion: _vertexRegion,
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
        useResponseApi: _useResponseApi,
        authMode: _authMode,
        saJson: _saJson,
        vertexProject: _vertexProject,
        vertexRegion: _vertexRegion,
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
                useResponseApi: _useResponseApi,
                onUseResponseApiChanged: (v) {
                  _useResponseApi = v;
                },
                onChanged: _schedulePersist,
              ),
              // C-02：Vertex Service Account 认证区（仅 Gemini 协议显示）
              if (_providerKind == ProviderKind.gemini) ...[
                const SizedBox(height: 16),
                _VertexAuthSection(
                  authMode: _authMode,
                  saConfigured: _saJson.isNotEmpty,
                  projectId: _vertexProject,
                  region: _vertexRegion,
                  onAuthModeChanged: (mode) {
                    setState(() => _authMode = mode);
                    _schedulePersist();
                  },
                  onImportSa: () async {
                    final imported = await _importSaJson();
                    if (imported != null) {
                      setState(() => _saJson = imported);
                      _schedulePersist();
                    }
                  },
                  onClearSa: () {
                    setState(() => _saJson = '');
                    _schedulePersist();
                  },
                  onProjectChanged: (v) {
                    _vertexProject = v;
                  },
                  onRegionChanged: (v) {
                    _vertexRegion = v;
                  },
                  onChanged: _schedulePersist,
                ),
              ],
              const SizedBox(height: 24),              ProviderModelTable(
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

  /// C-02：导入 Service Account JSON（粘贴或选文件），校验后返回内容。
  Future<String?> _importSaJson() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.providerSaKeyPaste),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controller,
            maxLines: 8,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: '{ "type": "service_account", ... }',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || !mounted) return null;
    try {
      VertexServiceAccountAuth.parseServiceAccountJson(result);
      return result;
    } catch (e) {
      if (!mounted) return null;
      showAppSnack(context, l10n.providerSaInvalid);
      return null;
    }
  }
}

/// C-02：Vertex Service Account 认证设置区。
class _VertexAuthSection extends StatelessWidget {
  final String authMode;
  final bool saConfigured;
  final String projectId;
  final String region;
  final ValueChanged<String> onAuthModeChanged;
  final VoidCallback onImportSa;
  final VoidCallback onClearSa;
  final ValueChanged<String> onProjectChanged;
  final ValueChanged<String> onRegionChanged;
  final VoidCallback onChanged;

  const _VertexAuthSection({
    required this.authMode,
    required this.saConfigured,
    required this.projectId,
    required this.region,
    required this.onAuthModeChanged,
    required this.onImportSa,
    required this.onClearSa,
    required this.onProjectChanged,
    required this.onRegionChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSa = authMode == 'serviceAccount';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.providerAuthMode,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              DropdownButton<String>(
                value: authMode,
                onChanged: (v) {
                  if (v != null) onAuthModeChanged(v);
                },
                items: [
                  DropdownMenuItem(
                    value: 'apiKey',
                    child: Text(context.l10n.providerAuthApiKey),
                  ),
                  DropdownMenuItem(
                    value: 'serviceAccount',
                    child: Text(context.l10n.providerAuthServiceAccount),
                  ),
                ],
              ),
            ],
          ),
          if (isSa) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.providerVertexHint,
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onImportSa,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: Text(
                      saConfigured
                          ? context.l10n.providerSaKeyFile
                          : context.l10n.providerSaKeyPaste,
                    ),
                  ),
                ),
                if (saConfigured) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: context.l10n.commonDelete,
                    onPressed: onClearSa,
                  ),
                ],
              ],
            ),
            if (saConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.providerAuthorized,
                  style: TextStyle(fontSize: 12, color: scheme.primary),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: projectId),
              autocorrect: false,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (v) {
                onProjectChanged(v.trim());
                onChanged();
              },
              decoration: InputDecoration(
                labelText: context.l10n.providerSaProjectId,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: region),
              autocorrect: false,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (v) {
                onRegionChanged(v.trim());
                onChanged();
              },
              decoration: InputDecoration(
                labelText: context.l10n.providerSaRegion,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

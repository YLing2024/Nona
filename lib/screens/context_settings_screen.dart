import 'package:flutter/material.dart';

import '../models/agent.dart';
import '../models/chat_options.dart';
import '../models/chat_provider.dart';
import '../services/agent_service.dart';
import '../services/provider_service.dart';
import '../widgets/chat_options_form.dart';

/// 会话上下文保存结果：参数 + 来源 Agent（null 为自定义）+ 模型选择。
class ContextSettingsResult {
  final ChatOptions options;
  final String? agentId;
  final String? providerId;
  final String? modelId;

  const ContextSettingsResult({
    required this.options,
    this.agentId,
    this.providerId,
    this.modelId,
  });
}

/// 会话上下文设置页：可选用 Agent 快捷填充、选择模型，或自定义配置。
class ContextSettingsScreen extends StatefulWidget {
  final ChatOptions initial;
  final String? initialAgentId;
  final String? initialProviderId;
  final String? initialModelId;

  const ContextSettingsScreen({
    super.key,
    required this.initial,
    this.initialAgentId,
    this.initialProviderId,
    this.initialModelId,
  });

  @override
  State<ContextSettingsScreen> createState() => _ContextSettingsScreenState();
}

class _ContextSettingsScreenState extends State<ContextSettingsScreen> {
  final _agentService = AgentService();
  final _providerService = ProviderService();
  final _formKey = GlobalKey<ChatOptionsFormState>();

  List<Agent> _agents = [];
  late String _selected; // 'custom' 或 agent id

  List<ChatProvider> _providers = [];
  String? _providerId;
  String? _modelId;

  @override
  void initState() {
    super.initState();
    _selected = 'custom';
    _loadAgents();
    _loadProviders();
  }

  Future<void> _loadAgents() async {
    final agents = await _agentService.load();
    if (!mounted) return;
    setState(() {
      _agents = agents;
      // 还原会话上次使用的 Agent
      if (widget.initialAgentId != null &&
          agents.any((a) => a.id == widget.initialAgentId)) {
        _selected = widget.initialAgentId!;
      }
    });
    if (_selected != 'custom') {
      final match = _agents.where((a) => a.id == _selected).firstOrNull;
      if (match != null) {
        _formKey.currentState?.fill(match.options);
        _formKey.currentState?.setReadOnly(true);
      }
    }
  }

  Future<void> _loadProviders() async {
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _resolveProviderModel();
    });
  }

  /// 根据会话记录还原服务商与模型；未记录或无效时回退到默认服务商。
  void _resolveProviderModel() {
    final valid = _providers.any((p) => p.id == widget.initialProviderId);
    _providerId = valid ? widget.initialProviderId : _providers.firstOrNull?.id;
    final provider = _currentProvider();
    if (provider == null) {
      _modelId = null;
      return;
    }
    final hasModel =
        widget.initialModelId != null &&
        provider.modelIds.contains(widget.initialModelId);
    _modelId = hasModel ? widget.initialModelId : provider.modelIds.firstOrNull;
  }

  ChatProvider? _currentProvider() {
    for (final p in _providers) {
      if (p.id == _providerId) return p;
    }
    return null;
  }

  void _onAgentSelected(String? value) {
    if (value == null) return;
    final form = _formKey.currentState;
    setState(() => _selected = value);
    if (value == 'custom') {
      // 自定义模式：允许编辑
      form?.setReadOnly(false);
      return;
    }
    final agent = _agents.where((a) => a.id == value).firstOrNull;
    if (agent != null) {
      form?.fill(agent.options);
      // 快捷配置模式：只读，不允许编辑
      form?.setReadOnly(true);
    }
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null) return;
    Navigator.of(context).pop(
      ContextSettingsResult(
        options: form.value,
        agentId: _selected == 'custom' ? null : _selected,
        providerId: _providerId,
        modelId: _modelId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = _currentProvider();
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话上下文'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('参数随会话保存，仅对当前会话生效。')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: '快捷配置',
              prefixIcon: Icon(Icons.smart_toy_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final a in _agents)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
              const DropdownMenuItem(value: 'custom', child: Text('自定义（手动配置）')),
            ],
            onChanged: _onAgentSelected,
          ),
          if (_agents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '还没有 Agent，可到「设置 → Agent 配置」中创建预设，方便快速套用。',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _modelId,
            decoration: const InputDecoration(
              labelText: '模型',
              prefixIcon: Icon(Icons.model_training),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final m in provider?.modelIds ?? const <String>[])
                DropdownMenuItem(
                  value: m,
                  child: Text(
                    _providers.length > 1 ? '${provider?.name} · $m' : m,
                  ),
                ),
            ],
            onChanged: _providers.isEmpty
                ? null
                : (v) => setState(() => _modelId = v),
          ),
          if (_providers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '还没有服务商，可到「设置 → 服务商」中配置并选择模型。',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          ChatOptionsForm(key: _formKey, initial: widget.initial),
        ],
      ),
    );
  }
}

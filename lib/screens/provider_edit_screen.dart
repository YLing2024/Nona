import 'package:flutter/material.dart';

import '../models/chat_provider.dart';
import '../services/provider_service.dart';

/// 服务商详情页：基础配置 + 拉取模型列表并多选启用。
class ProviderEditScreen extends StatefulWidget {
  /// 传入已有服务商则为编辑，null 为新建。
  final ChatProvider? provider;

  const ProviderEditScreen({super.key, this.provider});

  @override
  State<ProviderEditScreen> createState() => _ProviderEditScreenState();
}

class _ProviderEditScreenState extends State<ProviderEditScreen> {
  final _providerService = ProviderService();
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  List<String> _availableModels = [];
  final Set<String> _selected = {};
  bool _loadingModels = false;

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
      _selected.addAll(widget.provider!.modelIds);
    }
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
      modelIds: _selected.toList(),
    );
  }

  Future<void> _fetchModels() async {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }
    setState(() => _loadingModels = true);
    try {
      final models = await _providerService.fetchModels(
        ChatProvider(id: 'temp', name: '', baseUrl: baseUrl, apiKey: apiKey),
      );
      if (!mounted) return;
      setState(() {
        _availableModels = models;
        _selected.retainWhere(models.contains);
      });
      if (models.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该接口未返回任何模型')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider == null ? '添加服务商' : '服务商设置'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
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
              TextButton.icon(
                onPressed: _loadingModels ? null : _fetchModels,
                icon: _loadingModels
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(_loadingModels ? '获取中…' : '获取模型列表'),
              ),
            ],
          ),
          const Text(
            '基于当前 Base URL 与 API Key 调用 /models 接口获取可用模型，勾选启用。',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_availableModels.isEmpty && !_loadingModels)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '尚未获取模型，点击右上角「获取模型列表」',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ),
            )
          else
            for (final model in _availableModels)
              CheckboxListTile(
                value: _selected.contains(model),
                title: Text(model),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(model);
                    } else {
                      _selected.remove(model);
                    }
                  });
                },
              ),
        ],
      ),
    );
  }
}

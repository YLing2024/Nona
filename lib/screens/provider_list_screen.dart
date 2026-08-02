import 'package:flutter/material.dart';

import '../models/chat_provider.dart';
import '../services/provider_service.dart';
import 'provider_edit_screen.dart';

/// 服务商管理页：分组展示各服务商及其配置的模型。
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final _providerService = ProviderService();
  List<ChatProvider> _providers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final providers = await _providerService.load();
    if (!mounted) return;
    setState(() => _providers = providers);
  }

  Future<void> _persist() => _providerService.save(_providers);

  Future<void> _openEditor([ChatProvider? provider]) async {
    final result = await Navigator.of(context).push<ChatProvider>(
      MaterialPageRoute(builder: (_) => ProviderEditScreen(provider: provider)),
    );
    if (result != null) {
      setState(() {
        final index = _providers.indexWhere((p) => p.id == result.id);
        if (index >= 0) {
          _providers[index] = result;
        } else {
          _providers.add(result);
        }
      });
      await _persist();
    }
  }

  Future<void> _delete(ChatProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务商'),
        content: Text('确定删除「${provider.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _providers.removeWhere((p) => p.id == provider.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务商'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加服务商',
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: _providers.isEmpty
          ? const Center(child: Text('暂无服务商，点右上角添加'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final p = _providers[index];
                return _buildProviderGroup(p);
              },
            ),
    );
  }

  Widget _buildProviderGroup(ChatProvider provider) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(provider.name.characters.first)),
            title: Text(provider.name),
            subtitle: Text(
              '${provider.baseUrl}\n${provider.modelIds.length} 个模型',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                  onPressed: () => _openEditor(provider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: () => _delete(provider),
                ),
              ],
            ),
            onTap: () => _openEditor(provider),
          ),
          if (provider.modelIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final model in provider.modelIds)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        model,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '未配置模型',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
    // 编辑页内修改即保存，返回后重载列表即可
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderEditScreen(provider: provider)),
    );
    await _load();
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
    // 联动清理：服务商被删除后，清除指向其模型的全局默认配置
    await _providerService.clearStaleDefaultModels();
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
      body: SafeArea(
        top: false,
        child: _providers.isEmpty
            ? const Center(child: Text('暂无服务商，点右上角添加'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(12),
                buildDefaultDragHandles: false,
                itemCount: _providers.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final p = _providers.removeAt(oldIndex);
                    _providers.insert(newIndex, p);
                  });
                  _persist();
                },
                itemBuilder: (context, index) {
                  final p = _providers[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(p.id),
                    index: index,
                    child: _buildProviderGroup(p),
                  );
                },
              ),
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
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                provider.name.isEmpty ? '?' : provider.name.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    provider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (provider.id == ProviderService.debugProviderId)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '调试',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${provider.baseUrl}\n${provider.modelIds.length} 个模型',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_indicator, size: 20, color: theme.colorScheme.outlineVariant),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final model in provider.modelIds)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            model,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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

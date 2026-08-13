import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/chat_provider.dart';
import '../../../core/services/provider_group_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';
import '../widgets/provider_share_dialog.dart';
import 'qr_scan_screen.dart';
import '../../../shared/app_routes.dart';

/// 服务商管理页：按分组（C-03）展示各服务商及其配置的模型；
/// 每服务商可进入多 Key 管理页（C-04）。
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late final ProviderService _providerService = context.read<ProviderService>();
  final ProviderGroupService _groupService = ProviderGroupService();
  List<ChatProvider> _providers = [];
  List<ProviderGroup> _groups = [];
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final providers = await loadGuarded<List<ChatProvider>>(
      _providerService.load,
      label: 'providers',
    );
    final groups = await loadGuarded<List<ProviderGroup>>(
      _groupService.load,
      label: 'provider_groups',
    );
    if (!mounted) return;
    setState(() {
      if (providers != null) _providers = providers;
      if (groups != null) _groups = groups;
      _loadFailed = providers == null;
    });
  }

  Future<void> _persist() => _providerService.save(_providers);

  Future<void> _shareProvider(ChatProvider provider) {
    return showProviderShareDialog(context, provider);
  }

  Future<void> _importProvider() async {
    final imported = await showProviderImportDialog(context);
    if (imported == null || !mounted) return;
    setState(() => _providers = [..._providers, imported]);
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsImported(1))),
    );
  }

  /// G-02：扫码导入（相机）。
  Future<void> _scanProvider() async {
    final imported = await Navigator.of(context).push<ChatProvider>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (imported == null || !mounted) return;
    setState(() => _providers = [..._providers, imported]);
    await _persist();
    if (!mounted) return;
    showAppSnack(context, context.l10n.scanQrProviderImported);
  }

  Future<void> _openEditor([ChatProvider? provider]) async {
    // 编辑页内修改即保存，返回后重载列表即可
    await Navigator.of(context).push(
      AppRoutes.providerEdit(provider: provider),
    );
    await _load();
  }

  /// C-04：多 Key 管理页。
  Future<void> _openKeys(ChatProvider provider) async {
    await Navigator.of(context).push(
      AppRoutes.providerKeys(provider: provider),
    );
    await _load();
  }

  /// C-03：新建分组。
  Future<void> _addGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.providerGroupAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            labelText: ctx.l10n.providerGroupName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await _groupService.add(name);
    await _load();
  }

  /// C-03：分组长按 → 重命名/删除。
  Future<void> _manageGroup(ProviderGroup group) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l10n.providerGroupRename),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.providerGroupDelete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      final confirmed = await confirmAction(
        context,
        title: l10n.providerGroupDelete,
        message: l10n.providerGroupDelete,
        confirmText: l10n.commonDelete,
        danger: true,
      );
      if (!confirmed || !mounted) return;
      await _groupService.remove(group.id);
      // 组内服务商回到「未分组」
      for (final p in _providers) {
        if (p.groupId == group.id) p.groupId = null;
      }
      await _persist();
    } else {
      final controller = TextEditingController(text: group.name);
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.providerGroupRename),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
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
      if (name == null || name.isEmpty || !mounted) return;
      await _groupService.rename(group.id, name);
    }
    await _load();
  }

  /// C-03：把服务商移动到指定分组。
  Future<void> _assignGroup(ChatProvider provider) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.cleaning_services_outlined,
                color: provider.groupId == null
                    ? Theme.of(ctx).colorScheme.primary
                    : null,
              ),
              title: Text(
                l10n.providerGroupUngrouped,
                style: TextStyle(
                  fontWeight: provider.groupId == null
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final g in _groups)
              ListTile(
                leading: Icon(
                  Icons.folder_rounded,
                  color: provider.groupId == g.id
                      ? Theme.of(ctx).colorScheme.primary
                      : null,
                ),
                title: Text(
                  g.name,
                  style: TextStyle(
                    fontWeight: provider.groupId == g.id
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, g.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    provider.groupId = selected.isEmpty ? null : selected;
    await _persist();
    setState(() {});
  }

  Future<void> _delete(ChatProvider provider) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.providerDeleteTitle,
      message: context.l10n.providerDeleteConfirm(provider.name),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _providers.removeWhere((p) => p.id == provider.id));
    await _persist();
    // 联动清理：服务商被删除后，清除指向其模型的全局默认配置
    await _providerService.clearStaleDefaultModels();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grouped = <String?, List<ChatProvider>>{};
    for (final p in _providers) {
      // groupId 为 null/空 统一归「未分组」（key 用 null）
      grouped.putIfAbsent(p.groupId == null || p.groupId!.isEmpty ? null : p.groupId, () => []).add(p);
    }
    final sortedGroups = [..._groups]..sort((a, b) => a.sortOrder - b.sortOrder);
    // 渲染顺序：分组（按 sortOrder）→ 未分组（null）
    final groupIds = <String?>[
      for (final g in sortedGroups) g.id,
      null,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_rounded),
            tooltip: l10n.providerGroupAdd,
            onPressed: _addGroup,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: l10n.scanQrTitle,
            onPressed: _scanProvider,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.providerImportTitle,
            onPressed: () => _importProvider(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.providerAdd,
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: _providers.isEmpty
                  ? Center(child: Text(l10n.providerEmpty))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final gid in groupIds)
                          if (grouped[gid]?.isNotEmpty ?? false) ...[
                            _GroupHeader(
                              title: gid == null
                                  ? l10n.providerGroupUngrouped
                                  : _groups
                                        .where((g) => g.id == gid)
                                        .firstOrNull
                                        ?.name ??
                                      l10n.providerGroupUngrouped,
                              onLongPress: gid == null
                                  ? null
                                  : () => _manageGroup(
                                        _groups.firstWhere((g) => g.id == gid),
                                      ),
                            ),
                            for (final p in grouped[gid]!)
                              _buildProviderCard(p),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ChatProvider provider) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () => _openEditor(provider),
            onLongPress: () => _shareProvider(provider),
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
                      context.l10n.providerDebug,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${provider.baseUrl}\n'
              '${context.l10n.providerModelsCount(provider.modelIds.length)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_outlined),
                  tooltip: context.l10n.providerGroupName,
                  onPressed: () => _assignGroup(provider),
                ),
                // C-04：多 Key 管理
                IconButton(
                  icon: const Icon(Icons.key_rounded),
                  tooltip: context.l10n.providerKeysTitle,
                  onPressed: () => _openKeys(provider),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: context.l10n.commonEdit,
                  onPressed: () => _openEditor(provider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.l10n.commonDelete,
                  onPressed: () => _delete(provider),
                ),
              ],
            ),
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
                context.l10n.providerUnconfiguredModel,
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

/// C-03：分组标题（长按管理）。
class _GroupHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onLongPress;

  const _GroupHeader({required this.title, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 16, color: scheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: scheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

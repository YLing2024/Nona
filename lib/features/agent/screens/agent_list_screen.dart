import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/agent.dart';
import '../../../core/services/agent_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';
import '../../../shared/app_routes.dart';


/// Agent 管理页：查看、添加、编辑、删除 Agent 预设。
class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  late final AgentService _agentService = context.read<AgentService>();
  List<Agent> _agents = [];
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final agents = await loadGuarded<List<Agent>>(
      _agentService.load,
      label: 'agents',
    );
    if (!mounted) return;
    setState(() {
      if (agents != null) _agents = agents;
      _loadFailed = agents == null;
    });
  }

  Future<void> _persist() => _agentService.save(_agents);

  Future<void> _openEditor([Agent? agent]) async {
    final result = await Navigator.of(context).push<Agent>(
      AppRoutes.agentEdit(agent: agent),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _agents.indexWhere((a) => a.id == result.id);
      if (index >= 0) {
        _agents[index] = result;
      } else {
        _agents.insert(0, result);
      }
      // 默认 Agent 全局唯一
      if (result.isDefault) {
        for (final a in _agents) {
          if (a.id != result.id) a.isDefault = false;
        }
      }
    });
    await _persist();
  }

  Future<void> _delete(Agent agent) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.agentDeleteTitle,
      message: context.l10n.agentDeleteConfirm(agent.name),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed) return;
    setState(() => _agents.removeWhere((a) => a.id == agent.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agentConfigTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.agentAdd,
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
              child: _agents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 44,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.agentEmpty,
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _agents.length,
                itemBuilder: (context, index) {
                  final a = _agents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: a.isDefault
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.smart_toy_outlined,
                          size: 20,
                          color: a.isDefault
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (a.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.agentDefault,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        a.options.systemPrompt.isEmpty
                            ? l10n.agentDefaultParams
                            : a.options.systemPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                        onPressed: () => _delete(a),
                      ),
                      onTap: () => _openEditor(a),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

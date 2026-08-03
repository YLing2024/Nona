import 'package:flutter/material.dart';

import '../models/agent.dart';
import '../services/agent_service.dart';
import 'agent_edit_screen.dart';

/// Agent 管理页：查看、添加、编辑、删除 Agent 预设。
class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  final _agentService = AgentService();
  List<Agent> _agents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final agents = await _agentService.load();
    if (!mounted) return;
    setState(() => _agents = agents);
  }

  Future<void> _persist() => _agentService.save(_agents);

  Future<void> _openEditor([Agent? agent]) async {
    final result = await Navigator.of(context).push<Agent>(
      MaterialPageRoute(builder: (_) => AgentEditScreen(agent: agent)),
    );
    if (result != null) {
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
  }

  Future<void> _delete(Agent agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除 Agent'),
        content: Text('确定删除「${agent.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _agents.removeWhere((a) => a.id == agent.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent 配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加 Agent',
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
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
                      '暂无 Agent，点右上角添加',
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
                                '默认',
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
                            ? '默认参数'
                            : a.options.systemPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '删除',
                        onPressed: () => _delete(a),
                      ),
                      onTap: () => _openEditor(a),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

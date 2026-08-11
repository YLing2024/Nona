import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/memory/memory_service.dart';
import '../widgets/confirm_dialog.dart';

/// 记忆管理页（F4-3）：按作用域查看/编辑/删除/置顶记忆。
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late final MemoryService _service = MemoryService();
  List<Memory> _memories = [];
  MemoryScope _scope = MemoryScope.global;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final memories = await _service.list(scope: _scope);
    if (!mounted) return;
    setState(() {
      _memories = memories;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).memoryAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: AppLocalizations.of(ctx).memoryContentHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).commonConfirm),
          ),
        ],
      ),
    );
    if (content == null || content.isEmpty || !mounted) return;
    await _service.add(scope: _scope, content: content);
    await _load();
  }

  Future<void> _edit(Memory m) async {
    final controller = TextEditingController(text: m.content);
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).memoryEdit),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).commonSave),
          ),
        ],
      ),
    );
    if (content == null || content.isEmpty || !mounted) return;
    await _service.update(m.id, content, m.category);
    await _load();
  }

  Future<void> _delete(Memory m) async {
    final confirmed = await confirmAction(
      context,
      title: AppLocalizations.of(context).commonDelete,
      message: AppLocalizations.of(context).memoryDeleteConfirm,
      confirmText: AppLocalizations.of(context).commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _service.remove(m.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.memoryAdd,
            onPressed: _add,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<MemoryScope>(
              segments: [
                ButtonSegment(
                  value: MemoryScope.global,
                  label: Text(l10n.memoryScopeGlobal),
                ),
                ButtonSegment(
                  value: MemoryScope.agent,
                  label: Text(l10n.memoryScopeAgent),
                ),
                ButtonSegment(
                  value: MemoryScope.session,
                  label: Text(l10n.memoryScopeSession),
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (s) {
                setState(() => _scope = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _memories.isEmpty
                ? Center(
                    child: Text(
                      l10n.memoryEmpty,
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _memories.length,
                    itemBuilder: (context, index) {
                      final m = _memories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            m.pinned
                                ? Icons.push_pin_rounded
                                : Icons.lightbulb_outline_rounded,
                            color: m.pinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            size: 20,
                          ),
                          title: Text(
                            m.content,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          subtitle: Text(
                            m.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.push_pin_outlined,
                                    size: 18),
                                tooltip: l10n.memoryPin,
                                onPressed: () async {
                                  await _service.togglePin(m.id, !m.pinned);
                                  await _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: l10n.memoryEdit,
                                onPressed: () => _edit(m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                tooltip: l10n.commonDelete,
                                onPressed: () => _delete(m),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/memory/memory_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// 记忆管理页 v2：占用横幅、搜索+标签过滤、优先级/类别/使用次数、历史版本、一键清空。
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
  String _query = '';
  String? _categoryFilter;

  static const _categories = [
    'preference',
    'correction',
    'fact',
    'identity',
    'work',
    'life',
    'other',
  ];

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

  List<Memory> get _filtered {
    var list = _memories;
    if (_categoryFilter != null) {
      list = list.where((m) => m.category == _categoryFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where((m) =>
              m.content.toLowerCase().contains(q) ||
              m.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  Future<void> _add() async {
    final controller = TextEditingController();
    String category = 'preference';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).memoryAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(ctx).memoryContentHint,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => category = v ?? category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '类别',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).commonConfirm),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final content = controller.text.trim();
    if (content.isEmpty) return;
    await _service.add(
      scope: _scope,
      content: content,
      category: category,
      priority: MemoryPriority.core,
    );
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

  Future<void> _clearAll() async {
    final confirmed = await confirmAction(
      context,
      title: '清空记忆',
      message: '确定清空当前作用域的全部记忆？此操作不可恢复。',
      confirmText: '清空',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    for (final m in _memories) {
      await _service.remove(m.id);
    }
    await _load();
  }

  void _showHistory(Memory m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('历史版本'),
        content: SizedBox(
          width: double.maxFinite,
          child: m.history.isEmpty
              ? const Text('暂无历史版本')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: m.history.length,
                  itemBuilder: (ctx, i) {
                    final h = m.history[m.history.length - 1 - i];
                    return ListTile(
                      dense: true,
                      title: Text(h.content, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        h.ts.toLocal().toString().substring(0, 16),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.memoryAdd,
            onPressed: _add,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空当前作用域',
            onPressed: _memories.isEmpty ? null : _clearAll,
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
          // 占用横幅
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.memory_rounded, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '记忆占用：${_memories.length} 条 / 200 条（注入预算 800 tokens）',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: '搜索记忆',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() => _categoryFilter = null),
                  ),
                ),
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(c),
                      selected: _categoryFilter == c,
                      onSelected: (_) => setState(() => _categoryFilter = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      _memories.isEmpty ? l10n.memoryEmpty : '没有匹配的记忆',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            m.priority == MemoryPriority.core || m.pinned
                                ? Icons.push_pin_rounded
                                : Icons.lightbulb_outline_rounded,
                            color: m.priority == MemoryPriority.core || m.pinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            size: 20,
                          ),
                          title: Text(
                            m.content,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          subtitle: Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              _chip(
                                m.priority == MemoryPriority.core ? '核心' : '自动',
                                primary: m.priority == MemoryPriority.core,
                              ),
                              _chip(m.category),
                              for (final t in m.tags) _chip(t),
                              if (m.useCount > 0)
                                Text(
                                  '使用 ${m.useCount} 次',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history, size: 18),
                                tooltip: '历史版本',
                                onPressed: () => _showHistory(m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: l10n.memoryEdit,
                                onPressed: () => _edit(m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
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

  Widget _chip(String text, {bool primary = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: primary
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

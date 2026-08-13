import 'package:flutter/material.dart';

import '../../../core/services/instruction_injection_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// 指令注入管理页（G-05）：列表 / 新增 / 编辑 / 删除 / 激活勾选。
class InstructionInjectionsScreen extends StatefulWidget {
  const InstructionInjectionsScreen({super.key});

  @override
  State<InstructionInjectionsScreen> createState() =>
      _InstructionInjectionsScreenState();
}

class _InstructionInjectionsScreenState
    extends State<InstructionInjectionsScreen> {
  final InstructionInjectionService _service = InstructionInjectionService();
  List<InstructionInjection> _items = [];
  List<String> _activeIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.list();
    final active = await _service.activeIds(null);
    if (!mounted) return;
    setState(() {
      _items = items;
      _activeIds = active;
    });
  }

  Future<void> _add() async => _edit(null);

  Future<void> _edit(InstructionInjection? existing) async {
    final controllerTitle =
        TextEditingController(text: existing?.title ?? '');
    final controllerPrompt =
        TextEditingController(text: existing?.prompt ?? '');
    final controllerGroup =
        TextEditingController(text: existing?.groupName ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(existing == null ? l10n.iiAdd : l10n.iiEdit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllerTitle,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.iiTitle,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controllerPrompt,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: l10n.iiPrompt,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controllerGroup,
                  decoration: InputDecoration(
                    labelText: l10n.iiGroup,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
    controllerTitle.dispose();
    controllerPrompt.dispose();
    controllerGroup.dispose();
    if (saved != true || !mounted) return;
    final title = controllerTitle.text.trim();
    final prompt = controllerPrompt.text.trim();
    if (title.isEmpty || prompt.isEmpty) return;
    await _service.save(
      InstructionInjection(
        id: existing?.id ?? '',
        title: title,
        prompt: prompt,
        groupName: controllerGroup.text.trim().isEmpty
            ? null
            : controllerGroup.text.trim(),
        enabled: existing?.enabled ?? true,
      ),
    );
    await _load();
  }

  Future<void> _delete(InstructionInjection item) async {
    final ok = await confirmAction(
      context,
      title: AppLocalizations.of(context).iiDeleteTitle,
      message: AppLocalizations.of(context).iiDeleteBody(item.title),
      confirmText: AppLocalizations.of(context).chatDelete,
      danger: true,
    );
    if (!ok || !mounted) return;
    await _service.delete(item.id);
    await _load();
  }

  Future<void> _toggleActive(String id, bool active) async {
    final next = List<String>.from(_activeIds);
    if (active) {
      if (!next.contains(id)) next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _activeIds = next);
    await _service.setActiveIds(null, next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.iiTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.iiAdd),
      ),
      body: _items.isEmpty
          ? Center(
              child: Text(
                l10n.iiEmpty,
                style: TextStyle(color: scheme.outline),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = _items[i];
                final active = _activeIds.contains(item.id);
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Checkbox(
                      value: active,
                      onChanged: (v) => _toggleActive(item.id, v ?? false),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.outline,
                          ),
                        ),
                        if (item.groupName != null)
                          Text(
                            item.groupName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l10n.iiEdit,
                          onPressed: () => _edit(item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          tooltip: l10n.chatDelete,
                          onPressed: () => _delete(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/services/tag_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';

/// G-06：标签管理页（设置 → 标签）：CRUD。
class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final TagService _service = TagService();
  List<ChatTag> _tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tags = await _service.load();
    if (!mounted) return;
    setState(() => _tags = tags);
  }

  Future<void> _add() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tagsAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: l10n.tagsName,
            border: const OutlineInputBorder(),
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
    await _service.add(name);
    await _load();
  }

  Future<void> _rename(ChatTag tag) async {
    final controller = TextEditingController(text: tag.name);
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tagsManage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
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
    await _service.rename(tag.id, name);
    await _load();
  }

  Future<void> _delete(ChatTag tag) async {
    await _service.remove(tag.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.tagsAdd,
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _tags.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 40,
                      color: scheme.outlineVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.tagsNone,
                      style: TextStyle(color: scheme.outline),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _add,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.tagsAdd),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: scheme.surfaceContainerLow,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: tag.color == 0
                            ? scheme.primary
                            : Color(tag.color),
                      ),
                      title: Text(tag.name, style: const TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: l10n.commonEdit,
                            onPressed: () => _rename(tag),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            tooltip: l10n.commonDelete,
                            onPressed: () => _delete(tag),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

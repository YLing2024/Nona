import 'package:file_selector/file_selector.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/storage_io_io.dart'
    if (dart.library.js_interop) '../../../core/services/storage_io_stub.dart'
    as storage_io;
import '../../../core/services/world_book_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// 世界书管理页（F5）：条目 CRUD + JSON 导入/导出。
class WorldBookScreen extends StatefulWidget {
  const WorldBookScreen({super.key});

  @override
  State<WorldBookScreen> createState() => _WorldBookScreenState();
}

class _WorldBookScreenState extends State<WorldBookScreen> {
  late final WorldBookService _service = WorldBookService();
  List<WorldBookEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _edit([WorldBookEntry? entry]) async {
    final result = await showDialog<WorldBookEntry>(
      context: context,
      builder: (ctx) => _EntryEditDialog(entry: entry),
    );
    if (result == null || !mounted) return;
    await _service.save(result);
    await _service.reload();
    await _load();
  }

  Future<void> _delete(WorldBookEntry entry) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.wbDeleteConfirm(entry.title),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _service.delete(entry.id);
    await _service.reload();
    await _load();
  }

  Future<void> _import() async {
    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null || !mounted) return;
    try {
      final raw = await file.readAsString();
      final count = await _service.importJson(raw);
      if (mounted) {
        showAppSnack(context, context.l10n.wbImported(count));
        await _load();
      }
    } catch (_) {
      if (mounted) showAppSnack(context, context.l10n.wbImportFailed);
    }
  }

  Future<void> _export() async {
    final raw = await _service.exportJson();
    await storage_io.saveTextFile(
      suggestedName: 'world-book-${DateTime.now().millisecondsSinceEpoch}.json',
      data: raw,
      extension: 'json',
      mimeType: 'application/json',
    );
  }

  // ---------------- D-06：多书管理 ----------------

  Future<void> _openBookManager() async {
    final books = await _service.listBooks();
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.worldBookNewBook),
        children: [
          for (final b in books)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'toggle:${b.id}'),
              child: Row(
                children: [
                  Icon(
                    b.enabled
                        ? Icons.book_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${b.name}${b.description.isEmpty ? '' : ' — ${b.description}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch.adaptive(
                    value: b.enabled,
                    onChanged: (v) {
                      b.enabled = v;
                      unawaited(_service.saveBook(b));
                      Navigator.pop(ctx, 'refresh');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: ctx.l10n.commonDelete,
                    onPressed: () => Navigator.pop(ctx, 'delete:${b.id}'),
                  ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'add'),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(ctx.l10n.worldBookNewBook),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'add') {
      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.worldBookNewBook),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: ctx.l10n.worldBookName,
              border: const OutlineInputBorder(),
            ),
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
      await _service.saveBook(
        WorldBook(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
        ),
      );
    } else if (action.startsWith('delete:')) {
      final id = action.substring('delete:'.length);
      await _service.deleteBook(id);
    }
    await _load();
  }

  // ---------------- D-06：命中测试 ----------------

  Future<void> _openHitTest() async {
    final controller = TextEditingController();
    if (!mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.worldBookHitTest),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: ctx.l10n.worldBookHitTestInput,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(ctx.l10n.wbAdd),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    final hits = await _service.hitTest(text.trim());
    if (!mounted) return;
    final chars = hits.fold<int>(0, (sum, h) => sum + h.entry.content.length);
    final hitCount = hits.length;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            ctx.l10n.worldBookHitTestHit('$hitCount', '$chars'),
          ),
        content: SizedBox(
          width: 420,
          child: hits.isEmpty
              ? Text(
                  ctx.l10n.worldBookHitTestNoHit,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.outline),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: hits.length,
                  itemBuilder: (context, index) {
                    final h = hits[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        h.entry.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        h.preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        'P${h.entry.priority}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(ctx).colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonClose),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wbTitle),
        actions: [
          // D-06：命中测试
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: l10n.worldBookHitTest,
            onPressed: () => _openHitTest(),
          ),
          // D-06：多书管理
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: l10n.worldBookNewBook,
            onPressed: () => _openBookManager(),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.wbImport,
            onPressed: _import,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: l10n.wbExport,
            onPressed: _export,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.wbAdd,
            onPressed: () => _edit(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 42,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.wbEmpty,
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Switch(
                      value: e.enabled,
                      onChanged: (v) async {
                        await _service.toggleEnabled(e.id, v);
                        await _service.reload();
                        await _load();
                      },
                    ),
                    title: Text(e.title, style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(
                      '${e.keywords.join(' / ')}\n${e.content.length > 60 ? '${e.content.substring(0, 60)}…' : e.content}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l10n.commonEdit,
                          onPressed: () => _edit(e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: l10n.commonDelete,
                          onPressed: () => _delete(e),
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

class _EntryEditDialog extends StatefulWidget {
  final WorldBookEntry? entry;

  const _EntryEditDialog({this.entry});

  @override
  State<_EntryEditDialog> createState() => _EntryEditDialogState();
}

class _EntryEditDialogState extends State<_EntryEditDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.entry?.title ?? '');
  late final TextEditingController _keywords = TextEditingController(
    text: widget.entry?.keywords.join('、') ?? '',
  );
  late final TextEditingController _content =
      TextEditingController(text: widget.entry?.content ?? '');
  late final TextEditingController _priority =
      TextEditingController(text: '${widget.entry?.priority ?? 100}');
  late final TextEditingController _scanDepth =
      TextEditingController(text: '${widget.entry?.scanDepth ?? 1}');
  late String _position =
      widget.entry?.injectionPosition ?? 'top_of_chat';
  late bool _caseSensitive = widget.entry?.caseSensitive ?? false;
  late bool _constantActive = widget.entry?.constantActive ?? false;

  @override
  void dispose() {
    _title.dispose();
    _keywords.dispose();
    _content.dispose();
    _priority.dispose();
    _scanDepth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.entry == null ? l10n.wbAdd : l10n.wbEdit),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.wbTitleField,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _keywords,
                decoration: InputDecoration(
                  labelText: l10n.wbKeywordsField,
                  hintText: l10n.wbKeywordsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _content,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.wbContentField,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priority,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.wbPriorityField,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _scanDepth,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.wbScanDepthField,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _position,
                decoration: InputDecoration(
                  labelText: l10n.wbPositionField,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final p in WorldBookService.positions)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => _position = v ?? _position),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.wbCaseSensitive),
                value: _caseSensitive,
                onChanged: (v) => setState(() => _caseSensitive = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.wbConstantActive),
                value: _constantActive,
                onChanged: (v) => setState(() => _constantActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final entry = widget.entry ?? WorldBookEntry(id: '', title: '');
            Navigator.pop(
              context,
              WorldBookEntry(
                id: entry.id,
                title: _title.text.trim().isEmpty
                    ? l10n.wbUntitled
                    : _title.text.trim(),
                keywords: _keywords.text
                    .split(RegExp(r'[、,，;；]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                content: _content.text.trim(),
                priority: int.tryParse(_priority.text) ?? 100,
                scanDepth: int.tryParse(_scanDepth.text) ?? 1,
                caseSensitive: _caseSensitive,
                injectionPosition: _position,
                role: 'user',
                constantActive: _constantActive,
                enabled: entry.enabled,
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/document_extractor.dart';
import '../services/knowledge_base_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/l10n_ext.dart';
import '../utils/load_guarded.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/load_failed_banner.dart';

/// 知识库管理页（F4-1 多库）：库选择 + 文档管理 + 对话注入。
class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  late final KnowledgeBaseService _service = context.read<KnowledgeBaseService>();
  List<KnowledgeLibrary> _libraries = [];
  List<String> _docs = [];
  String _selectedLibId = KnowledgeBaseService.globalLibraryId;
  bool _busy = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final libs = await loadGuarded<List<KnowledgeLibrary>>(
      _service.listLibraries,
      label: 'kb_libraries',
    );
    if (!mounted) return;
    setState(() {
      if (libs != null) _libraries = libs;
      _loadFailed = libs == null;
      if (!_libraries.any((l) => l.id == _selectedLibId)) {
        _selectedLibId = KnowledgeBaseService.globalLibraryId;
      }
    });
    await _loadDocs();
  }

  Future<void> _loadDocs() async {
    final docs = await loadGuarded<List<String>>(
      () => _service.listDocs(libraryId: _selectedLibId),
      label: 'kb_docs',
    );
    if (!mounted) return;
    setState(() {
      if (docs != null) _docs = docs;
    });
  }

  Future<void> _add() async {
    const typeGroup = XTypeGroup(
      label: 'Document',
      extensions: ['txt', 'md', 'json', 'csv', 'log'],
      mimeTypes: ['text/plain'],
    );
    final files = await openFiles(acceptedTypeGroups: const [typeGroup]);
    if (files.isEmpty || !mounted) return;
    setState(() => _busy = true);
    var added = 0;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final text = await DocumentExtractor.extract(
          fileName: file.name,
          bytes: bytes,
        );
        if (text == null || text.trim().isEmpty) continue;
        await _service.addText(file.name, text, libraryId: _selectedLibId);
        added++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (added > 0) {
      await _load();
      if (mounted) showAppSnack(context, context.l10n.kbAdded(added));
    } else if (mounted) {
      showAppSnack(context, context.l10n.kbAddFailed);
    }
  }

  Future<void> _remove(String name) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.kbDeleteConfirm(name),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _service.remove(name);
    await _load();
    if (mounted) showAppSnack(context, context.l10n.commonDeleted);
  }

  Future<void> _createLibrary() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.kbCreateLibrary),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: context.l10n.kbLibraryNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final id = await _service.createLibrary(name);
    if (id != null) {
      setState(() => _selectedLibId = id);
      await _load();
    }
  }

  Future<void> _renameLibrary(KnowledgeLibrary lib) async {
    final controller = TextEditingController(text: lib.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.kbRenameLibrary),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    await _service.renameLibrary(lib.id, name);
    await _load();
  }

  Future<void> _deleteLibrary(KnowledgeLibrary lib) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.kbDeleteLibrary,
      message: context.l10n.kbDeleteLibraryConfirm(lib.name),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _service.deleteLibrary(lib.id);
    setState(() => _selectedLibId = KnowledgeBaseService.globalLibraryId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kbTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: l10n.kbCreateLibrary,
            onPressed: _busy ? null : _createLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.kbAdd,
            onPressed: _busy ? null : _add,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            // 库选择条
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  for (final lib in _libraries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${lib.name} (${lib.docCount})'),
                        selected: lib.id == _selectedLibId,
                        onSelected: (_) {
                          setState(() => _selectedLibId = lib.id);
                          _loadDocs();
                        },
                      ),
                    ),
                ],
              ),
            ),
            // 当前库操作
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _libraries
                          .where((l) => l.id == _selectedLibId)
                          .map((l) => l.name)
                          .firstOrNull ??
                          '',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  if (_selectedLibId != KnowledgeBaseService.globalLibraryId)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: l10n.kbRenameLibrary,
                      onPressed: () {
                        final lib = _libraries
                            .where((l) => l.id == _selectedLibId)
                            .firstOrNull;
                        if (lib != null) _renameLibrary(lib);
                      },
                    ),
                  if (_selectedLibId != KnowledgeBaseService.globalLibraryId)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      tooltip: l10n.kbDeleteLibrary,
                      onPressed: () {
                        final lib = _libraries
                            .where((l) => l.id == _selectedLibId)
                            .firstOrNull;
                        if (lib != null) _deleteLibrary(lib);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _docs.isEmpty
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
                            l10n.kbEmpty,
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.kbEmptyHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Text(
                            l10n.kbHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        for (final name in _docs)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.description_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.commonDelete,
                                onPressed: () => _remove(name),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

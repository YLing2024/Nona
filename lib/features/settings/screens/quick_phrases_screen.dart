import 'package:flutter/material.dart';

import '../../../core/services/quick_phrase_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// 快捷短语管理页（G-04）：列表 / 新增 / 编辑 / 删除（全局 or Agent）。
class QuickPhrasesScreen extends StatefulWidget {
  const QuickPhrasesScreen({super.key});

  @override
  State<QuickPhrasesScreen> createState() => _QuickPhrasesScreenState();
}

class _QuickPhrasesScreenState extends State<QuickPhrasesScreen> {
  final QuickPhraseService _service = QuickPhraseService();
  List<QuickPhrase> _phrases = [];
  final bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phrases = await _service.list();
    if (!mounted) return;
    setState(() => _phrases = phrases);
  }

  Future<void> _add() async => _edit(null);

  Future<void> _edit(QuickPhrase? existing) async {
    final controllerTitle =
        TextEditingController(text: existing?.title ?? '');
    final controllerContent =
        TextEditingController(text: existing?.content ?? '');
    var isGlobal = existing?.isGlobal ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null
              ? AppLocalizations.of(ctx).quickPhrasesAdd
              : AppLocalizations.of(ctx).quickPhrasesEdit,
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerTitle,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx).quickPhrasesTitle,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controllerContent,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx).quickPhrasesContent,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(AppLocalizations.of(ctx).quickPhrasesGlobal),
                value: isGlobal,
                onChanged: (v) =>
                    setDialogState(() => isGlobal = v ?? true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx).commonSave),
          ),
        ],
      ),
    );
    controllerTitle.dispose();
    controllerContent.dispose();
    if (saved != true || !mounted) return;
    final title = controllerTitle.text.trim();
    final content = controllerContent.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    await _service.save(
      QuickPhrase(
        id: existing?.id ?? '',
        title: title,
        content: content,
        isGlobal: isGlobal,
        agentId: existing?.agentId,
        sortOrder: existing?.sortOrder ?? _phrases.length,
      ),
    );
    await _load();
  }

  Future<void> _delete(QuickPhrase phrase) async {
    final ok = await confirmAction(
      context,
      title: AppLocalizations.of(context).quickPhrasesDeleteTitle,
      message: AppLocalizations.of(context).quickPhrasesDeleteBody(phrase.title),
      confirmText: AppLocalizations.of(context).chatDelete,
      danger: true,
    );
    if (!ok || !mounted) return;
    await _service.delete(phrase.id);
    await _load();
    if (mounted) {
      showAppSnack(context, AppLocalizations.of(context).quickPhrasesDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickPhrasesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.quickPhrasesAdd),
      ),
      body: _phrases.isEmpty
          ? Center(
              child: Text(
                l10n.quickPhrasesEmpty,
                style: TextStyle(color: scheme.outline),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _phrases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = _phrases[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      p.isGlobal
                          ? Icons.public_rounded
                          : Icons.person_outline_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    title: Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      p.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l10n.quickPhrasesEdit,
                          onPressed: () => _edit(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          tooltip: l10n.chatDelete,
                          onPressed: () => _delete(p),
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

import 'package:flutter/material.dart';

import '../../../core/models/chat_session.dart';
import '../../../core/services/tag_service.dart';
import '../../../l10n/app_localizations.dart';

/// G-06：会话打标签对话框——多选标签 + 新建。返回新的标签 id 列表。
Future<List<String>> showTagPicker(
  BuildContext context,
  ChatSession session,
) async {
  final service = TagService();
  final allTags = await service.load();
  if (!context.mounted) return session.tags;
  final selected = <String>{...session.tags};
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.tagsApply),
        content: SizedBox(
          width: 320,
          child: allTags.isEmpty
              ? Text(
                  l10n.tagsNone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in allTags)
                      FilterChip(
                        label: Text(tag.name),
                        selected: selected.contains(tag.id),
                        onSelected: (v) => setState(() {
                          if (v) {
                            selected.add(tag.id);
                          } else {
                            selected.remove(tag.id);
                          }
                        }),
                      ),
                  ],
                ),
        ),
        actions: [
          // 新建标签
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.tagsAdd),
            onPressed: () async {
              final controller = TextEditingController();
              final name = await showDialog<String>(
                context: ctx,
                builder: (c) => AlertDialog(
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
                      onPressed: () => Navigator.pop(c),
                      child: Text(l10n.commonCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, controller.text.trim()),
                      child: Text(l10n.commonSave),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (name == null || name.isEmpty) return;
              final tag = await service.add(name);
              if (ctx.mounted) {
                setState(() => selected.add(tag.id));
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    ),
  );
  return selected.toList();
}

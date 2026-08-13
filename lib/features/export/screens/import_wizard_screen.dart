import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/services/export/import_report.dart';
import '../../../core/services/export/import_service.dart';
import '../../../core/services/export/importers/sqlite_importers.dart' as sqlite_importers;
import '../../../core/services/provider_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/logger.dart';

/// 导入向导（F6-1 + X-03 武器化）：选文件 → 质量报告与去重预览 →
/// 去重策略 + 勾选会话 → 合并执行（会话 + 服务商）。
class ImportWizardScreen extends StatefulWidget {
  const ImportWizardScreen({super.key});

  @override
  State<ImportWizardScreen> createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends State<ImportWizardScreen> {
  String? _fileName;
  ImportReport? _report;
  DuplicateAction _action = DuplicateAction.skip;
  Set<String> _selectedIds = {};
  bool _busy = false;
  String? _resultText;

  Future<void> _pick() async {
    const typeGroup = XTypeGroup(
      label: 'Backup',
      extensions: ['zip', 'json', 'db', 'sqlite', 'sqlite3'],
      mimeTypes: ['application/zip', 'application/json', 'application/octet-stream'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null || !mounted) return;
    setState(() {
      _fileName = file.name;
      _report = null;
      _resultText = null;
    });
    try {
      final bytes = await file.readAsBytes();
      // X-03：分析（只解析不落库）→ 报告 + 重复检测
      final existing = await SessionService().load();
      final report = _analyze(bytes, file.name, existing);
      if (!mounted) return;
      setState(() {
        _report = report;
        _selectedIds = report == null
            ? {}
            : {for (final s in report.parsedSessions) s.id};
      });
    } catch (e) {
      Logger.error('import', 'sniff failed', e);
    }
  }

  ImportReport? _analyze(
    Uint8List bytes,
    String name,
    List<ChatSession> existing,
  ) {
    final lower = name.toLowerCase();
    // SQLite 文件（RikkaHub/Kelivo）直接落盘嗅探（io 平台；Web 返回 null）
    if (lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.sqlite3')) {
      final result = sqlite_importers.importSqliteBytes(bytes);
      if (result == null) return null;
      return ImportService.buildReport(
        result,
        sourceFormat: 'sqlite',
        existingIds: {for (final s in existing) s.id},
      );
    }
    return ImportService.analyze(
      bytes,
      fileName: name,
      existingIds: {for (final s in existing) s.id},
    );
  }

  Future<void> _confirm() async {
    final report = _report;
    if (report == null || report.sessions == 0 || !mounted) return;
    setState(() => _busy = true);
    try {
      // X-03：按策略选择会话（skip 去重 / overwrite 覆盖 / copy 复制）
      final toImport = report.selectSessions(_action, selectedIds: _selectedIds);
      final existing = await SessionService().load();
      final byId = {for (final s in existing) s.id: s};
      var added = 0;
      for (final s in toImport) {
        if (byId.containsKey(s.id)) {
          // overwrite：同 id 覆盖
          final idx = existing.indexWhere((e) => e.id == s.id);
          existing[idx] = s;
        } else {
          existing.add(s);
          byId[s.id] = s;
          added++;
        }
      }
      await SessionService().saveAll(existing);
      // X-03：服务商合并（同名按 baseUrl 合并模型列表，key 保留本地）
      if (report.providers != null && report.providers!.isNotEmpty) {
        try {
          final providerService = ProviderService();
          final local = await providerService.load();
          final merged = ImportService.mergeProviders(
            local,
            report.providers!,
          );
          if (merged.length != local.length) {
            await providerService.save(merged);
          }
        } catch (e) {
          Logger.warn('import', 'provider merge skipped: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _resultText = _resultSummary(
          AppLocalizations.of(context),
          added,
          report.failures.length,
        );
      });
      showAppSnack(context, _resultText!);
    } catch (e) {
      Logger.error('import', 'import failed', e);
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, AppLocalizations.of(context).importFailed);
    }
  }

  String _resultSummary(AppLocalizations l10n, int added, int failed) {
    if (failed > 0) {
      return l10n.importResultPartial(added, failed);
    }
    return l10n.importResultOk(added);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName ?? l10n.importPickHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (report != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.importFormat(report.sourceFormat),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.importPreview(report.sessions, report.messages),
                      style: TextStyle(fontSize: 13, color: scheme.outline),
                    ),
                  ],
                  if (_resultText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _resultText!,
                      style: TextStyle(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (report != null) ...[
            const SizedBox(height: 12),
            _QualityCard(report: report),
            if (report.duplicates.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DuplicateCard(
                report: report,
                action: _action,
                onActionChanged: (a) => setState(() => _action = a),
              ),
            ],
            if (report.failures.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FailuresCard(report: report),
            ],
            const SizedBox(height: 12),
            // X-03：可勾选会话列表
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            l10n.importSelectSessions,
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              final all = {
                                for (final s in report.parsedSessions) s.id,
                              };
                              _selectedIds =
                                  _selectedIds.length == all.length ? {} : all;
                            }),
                            child: Text(l10n.importToggleAll),
                          ),
                        ],
                      ),
                    ),
                    for (final s in report.parsedSessions)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${s.messages.length} 条消息'
                          '${_selectedIds.contains(s.id) && report.duplicates.any((d) => d.hashSessionId == s.id) ? ' · 重复' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _selectedIds.contains(s.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedIds.add(s.id);
                          } else {
                            _selectedIds.remove(s.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(l10n.importPick),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: (report != null &&
                    report.sessions > 0 &&
                    _selectedIds.isNotEmpty &&
                    !_busy)
                ? _confirm
                : null,
            icon: const Icon(Icons.playlist_add_rounded, size: 18),
            label: Text(l10n.importConfirm),
          ),
        ],
      ),
    );
  }
}

/// 质量报告卡（X-03）。
class _QualityCard extends StatelessWidget {
  final ImportReport report;

  const _QualityCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = report.quality;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导入质量',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QualityItem(
                  label: '时间戳完整率',
                  value:
                      '${(q.timestampCompleteRate * 100).toStringAsFixed(0)}%',
                  color: q.timestampCompleteRate > 0.8
                      ? scheme.primary
                      : scheme.error,
                ),
                const SizedBox(width: 24),
                _QualityItem(
                  label: '多模态',
                  value: q.multimodalPreserved ? '保留' : '缺失',
                  color: q.multimodalPreserved
                      ? scheme.primary
                      : scheme.error,
                ),
                const SizedBox(width: 24),
                _QualityItem(
                  label: '工具消息',
                  value: q.toolMessagesPreserved ? '保留' : '缺失',
                  color: q.toolMessagesPreserved
                      ? scheme.primary
                      : scheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '成功 ${report.succeeded} / ${report.sessions} · '
              '失败 ${report.failures.length} · '
              '重复 ${report.duplicates.length}',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QualityItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 重复处理策略卡（X-03 三选一）。
class _DuplicateCard extends StatelessWidget {
  final ImportReport report;
  final DuplicateAction action;
  final ValueChanged<DuplicateAction> onActionChanged;

  const _DuplicateCard({
    required this.report,
    required this.action,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '发现 ${report.duplicates.length} 个重复会话',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.tertiary,
              ),
            ),
            const SizedBox(height: 4),
            for (final d in report.duplicates.take(3))
              Text(
                '· ${d.existingTitle}（命中 ${d.matches} 次）',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            const SizedBox(height: 8),
            RadioGroup<DuplicateAction>(
              groupValue: action,
              onChanged: (v) {
                if (v != null) onActionChanged(v);
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<DuplicateAction>(
                    dense: true,
                    value: DuplicateAction.skip,
                    title: Text('跳过重复（推荐）'),
                  ),
                  RadioListTile<DuplicateAction>(
                    dense: true,
                    value: DuplicateAction.overwrite,
                    title: Text('覆盖为导入版本'),
                  ),
                  RadioListTile<DuplicateAction>(
                    dense: true,
                    value: DuplicateAction.copy,
                    title: Text('保留两份'),
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

/// 失败明细卡（X-03）。
class _FailuresCard extends StatelessWidget {
  final ImportReport report;

  const _FailuresCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.failures.length} 条记录解析失败（已跳过）',
              style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: 4),
            for (final f in report.failures.take(3))
              Text(
                '· #${f.index} ${f.reason}',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

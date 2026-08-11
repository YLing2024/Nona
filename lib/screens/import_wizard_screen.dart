import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_session.dart';
import '../services/export/backup_archive.dart';
import '../services/export/importers/importer_factory.dart';
import '../services/export/importers/sqlite_importers.dart' as sqlite_importers;
import '../services/session_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/logger.dart';

/// 导入向导（F6-1）：选文件 → 嗅探预览 → 确认 → 进度 → 结果报告。
class ImportWizardScreen extends StatefulWidget {
  const ImportWizardScreen({super.key});

  @override
  State<ImportWizardScreen> createState() => _ImportWizardScreenState();
}

class _ImportWizardScreenState extends State<ImportWizardScreen> {
  String? _fileName;
  String? _format;
  int? _sessionCount;
  int? _messageCount;
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
      _format = null;
      _sessionCount = null;
      _messageCount = null;
      _resultText = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final (format, sessions) = _sniff(bytes, file.name);
      if (!mounted) return;
      setState(() {
        _format = format;
        _sessionCount = sessions.length;
        var total = 0;
        for (final s in sessions) {
          total += s.messages.length;
        }
        _messageCount = total;
      });
    } catch (e) {
      Logger.error('import', 'sniff failed', e);
    }
  }

  /// 嗅探并预解析（结果缓存到内存供确认后直接导入）。
  BackupImportResult? _cachedResult;

  (String?, List<ChatSession>) _sniff(Uint8List bytes, String name) {
    _cachedResult = null;
    // SQLite 文件（RikkaHub/Kelivo）：需要临时落盘读取
    final lower = name.toLowerCase();
    if (lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.sqlite3')) {
      return _sniffSqlite(bytes);
    }
    if (ImporterFactory.isZipBytes(bytes)) {
      final result = BackupArchive.importFromZipBytes(bytes);
      if (result != null) {
        _cachedResult = result;
        return ('nona-backup', result.sessions);
      }
      return (null, const []);
    }
    final data = ImporterFactory.decodeJson(bytes);
    final format = ImporterFactory.sniffJson(data);
    if (format == null) return (null, const []);
    final result = ImporterFactory.importJson(data);
    _cachedResult = result;
    return (format, result.sessions);
  }

  (String?, List<ChatSession>) _sniffSqlite(Uint8List bytes) {
    // 临时落盘后嗅探（io 平台；Web 返回 null）
    final result = sqlite_importers.importSqliteBytes(bytes);
    if (result == null) return (null, const []);
    _cachedResult = result;
    return ('sqlite', result.sessions);
  }

  Future<void> _confirm() async {
    final result = _cachedResult;
    if (result == null || result.sessions.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final existing = await SessionService().load();
      final byId = {for (final s in existing) s.id: s};
      var added = 0;
      for (final s in result.sessions) {
        if (byId.containsKey(s.id)) continue;
        existing.add(s);
        byId[s.id] = s;
        added++;
      }
      await SessionService().saveAll(existing);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _resultText = _resultSummary(
          AppLocalizations.of(context),
          added,
          result.failedItems.length,
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (_format != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.importFormat(_format!),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_sessionCount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.importPreview(_sessionCount!, _messageCount ?? 0),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.outline,
                        ),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(l10n.importPick),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: (_sessionCount ?? 0) > 0 && !_busy
                  ? _confirm
                  : null,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: Text(l10n.importConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

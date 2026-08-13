import 'package:flutter/material.dart';

import '../../../core/services/sync/sync_clients.dart';
import '../../../core/services/sync/sync_engine.dart';
import '../../../core/services/sync/sync_exception.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';

/// 云同步页：WebDAV / S3 配置 + 备份上传/列表/恢复。
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncConfig _config = const SyncConfig();
  List<RemoteBackupFile> _backups = [];
  bool _busy = false;
  String? _error;
  bool _loadFailed = false;

  final _webDavUrl = TextEditingController();
  final _webDavUser = TextEditingController();
  final _webDavPass = TextEditingController();
  final _s3Endpoint = TextEditingController();
  final _s3Access = TextEditingController();
  final _s3Secret = TextEditingController();
  final _s3Bucket = TextEditingController();
  final _s3Region = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadSyncState();
  }

  @override
  void dispose() {
    _webDavUrl.dispose();
    _webDavUser.dispose();
    _webDavPass.dispose();
    _s3Endpoint.dispose();
    _s3Access.dispose();
    _s3Secret.dispose();
    _s3Bucket.dispose();
    _s3Region.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await loadGuarded<SyncConfig>(
      SyncService.loadConfig,
      label: 'sync_config',
    );
    if (!mounted) return;
    setState(() {
      if (config != null) {
        _config = config;
        _webDavUrl.text = config.webDavUrl;
        _webDavUser.text = config.webDavUser;
        _webDavPass.text = config.webDavPass;
        _s3Endpoint.text = config.s3Endpoint;
        _s3Access.text = config.s3Access;
        _s3Secret.text = config.s3Secret;
        _s3Bucket.text = config.s3Bucket;
        _s3Region.text = config.s3Region;
      }
      _loadFailed = config == null;
    });
  }

  Future<void> _saveConfig() async {
    final config = SyncConfig(
      type: _config.type,
      webDavUrl: _webDavUrl.text.trim(),
      webDavUser: _webDavUser.text.trim(),
      webDavPass: _webDavPass.text,
      s3Endpoint: _s3Endpoint.text.trim(),
      s3Access: _s3Access.text.trim(),
      s3Secret: _s3Secret.text,
      s3Bucket: _s3Bucket.text.trim(),
      s3Region: _s3Region.text.trim().isEmpty
          ? 'us-east-1'
          : _s3Region.text.trim(),
    );
    try {
      await SyncService.saveConfig(config);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _config = config;
      _error = null;
    });
    showAppSnack(context, context.l10n.commonSaved);
  }

  Future<void> _upload() async {
    await _guard(() async {
      final name = await SyncService.uploadBackup();
      if (mounted) showAppSnack(context, context.l10n.syncUploaded(name));
      await _refresh();
    });
  }

  // X-04：增量同步
  final SyncEngine _engine = SyncEngine();
  List<Map<String, dynamic>> _conflicts = [];
  DateTime? _lastSyncAt;

  Future<void> _incrementalSync() async {
    await _guard(() async {
      final result = await _engine.sync();
      if (mounted) {
        setState(() {
          _lastSyncAt = DateTime.now();
        });
        showAppSnack(
          context,
          context.l10n.syncIncrementalDone(result.pushed, result.pulled),
        );
      }
    });
  }

  Future<void> _loadSyncState() async {
    final conflicts = await _engine.conflicts();
    final lastSyncAt = await _engine.lastSyncAt();
    if (!mounted) return;
    setState(() {
      _conflicts = conflicts;
      _lastSyncAt = lastSyncAt;
    });
  }

  Future<void> _refresh() async {
    await _guard(() async {
      final backups = await SyncService.listBackups();
      if (mounted) setState(() => _backups = backups);
    }, showSuccess: false);
  }

  Future<void> _restore(RemoteBackupFile file) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.syncRestoreTitle,
      message: context.l10n.syncRestoreConfirm(file.name),
      confirmText: context.l10n.commonRestore,
    );
    if (!confirmed || !mounted) return;
    await _guard(() async {
      final added = await SyncService.restoreBackup(file.name);
      if (mounted) showAppSnack(context, context.l10n.syncRestored(added));
    });
  }

  Future<void> _delete(RemoteBackupFile file) async {
    await _guard(() async {
      await SyncService.deleteBackup(file.name);
      if (mounted) setState(() => _backups.removeWhere((b) => b.name == file.name));
      if (mounted) showAppSnack(context, context.l10n.commonDeleted);
    });
  }

  Future<void> _guard(Future<void> Function() action,
      {bool showSuccess = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on SyncException catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        final message = switch (e.kind) {
          'auth' => l10n.syncErrorAuth,
          'network' => l10n.syncErrorNetwork,
          'storage' => l10n.syncErrorStorage,
          _ => e.message,
        };
        setState(() => _error = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isWebDav = _config.type == 'webdav';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.commonRefresh,
            onPressed: _busy ? null : _refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'webdav', label: Text(l10n.syncTypeWebDav)),
                ButtonSegment(value: 's3', label: Text(l10n.syncTypeS3)),
              ],
              selected: {_config.type},
              onSelectionChanged: (s) => setState(() {
                final type = s.first;
                _config = SyncConfig(
                  type: type,
                  webDavUrl: _webDavUrl.text.trim(),
                  webDavUser: _webDavUser.text.trim(),
                  webDavPass: _webDavPass.text,
                  s3Endpoint: _s3Endpoint.text.trim(),
                  s3Access: _s3Access.text.trim(),
                  s3Secret: _s3Secret.text,
                  s3Bucket: _s3Bucket.text.trim(),
                  s3Region: _s3Region.text.trim().isEmpty
                      ? 'us-east-1'
                      : _s3Region.text.trim(),
                );
              }),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 16),
            if (isWebDav) ...[
              _field(_webDavUrl, l10n.syncWebDavUrl, hint: 'https://dav.example.com/'),
              _field(_webDavUser, l10n.syncWebDavUser),
              _field(_webDavPass, l10n.syncWebDavPass, obscure: true),
            ] else ...[
              _field(_s3Endpoint, l10n.syncS3Endpoint, hint: 'https://s3.example.com'),
              _field(_s3Access, l10n.syncS3Access),
              _field(_s3Secret, l10n.syncS3Secret, obscure: true),
              _field(_s3Bucket, l10n.syncS3Bucket),
              _field(_s3Region, l10n.syncS3Region, hint: 'us-east-1'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(l10n.syncUpload),
                    onPressed: _busy ? null : _upload,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _saveConfig,
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // X-04：增量同步
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.syncIncrementalTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastSyncAt != null
                          ? l10n.syncLastAt(
                              _lastSyncAt!.toLocal().toString().substring(0, 19),
                            )
                          : l10n.syncIncrementalHint,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _incrementalSync,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(l10n.syncIncrementalNow),
                    ),
                    if (_conflicts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.syncConflicts(_conflicts.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.syncBackupList,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_backups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    l10n.syncEmpty,
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              )
            else
              for (final backup in _backups)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      backup.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      formatBytes(backup.size),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_backup_restore),
                          tooltip: l10n.commonRestore,
                          onPressed: _busy ? null : () => _restore(backup),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.commonDelete,
                          onPressed: _busy ? null : () => _delete(backup),
                        ),
                      ],
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

  Widget _field(TextEditingController controller, String label,
      {String? hint, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        onTapOutside: unfocusOnTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

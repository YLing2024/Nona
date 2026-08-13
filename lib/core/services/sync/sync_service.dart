import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../agent_service.dart';
import '../export_service.dart';
import '../provider_service.dart';
import '../session_service.dart';
import 'sync_clients.dart';
import 'sync_exception.dart';

/// 同步目标配置。
class SyncConfig {
  final String type; // 'webdav' | 's3'
  final String webDavUrl;
  final String webDavUser;
  final String webDavPass;
  final String s3Endpoint;
  final String s3Access;
  final String s3Secret;
  final String s3Bucket;
  final String s3Region;

  const SyncConfig({
    this.type = 'webdav',
    this.webDavUrl = '',
    this.webDavUser = '',
    this.webDavPass = '',
    this.s3Endpoint = '',
    this.s3Access = '',
    this.s3Secret = '',
    this.s3Bucket = '',
    this.s3Region = 'us-east-1',
  });

  bool get isComplete {
    if (type == 'webdav') return webDavUrl.isNotEmpty;
    return s3Endpoint.isNotEmpty &&
        s3Access.isNotEmpty &&
        s3Secret.isNotEmpty &&
        s3Bucket.isNotEmpty;
  }
}

/// 云同步服务：WebDAV / S3 备份上传、列出、下载恢复。
class SyncService {
  static const _kSyncType = 'sync_type';
  static const _kWebDavUrl = 'sync_webdav_url';
  static const _kWebDavUser = 'sync_webdav_user';
  static const _kWebDavPass = 'sync_webdav_pass';
  static const _kS3Endpoint = 'sync_s3_endpoint';
  static const _kS3Access = 'sync_s3_access';
  static const _kS3Secret = 'sync_s3_secret';
  static const _kS3Bucket = 'sync_s3_bucket';
  static const _kS3Region = 'sync_s3_region';

  static Future<SyncConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return SyncConfig(
      type: prefs.getString(_kSyncType) ?? 'webdav',
      webDavUrl: prefs.getString(_kWebDavUrl) ?? '',
      webDavUser: prefs.getString(_kWebDavUser) ?? '',
      webDavPass: prefs.getString(_kWebDavPass) ?? '',
      s3Endpoint: prefs.getString(_kS3Endpoint) ?? '',
      s3Access: prefs.getString(_kS3Access) ?? '',
      s3Secret: prefs.getString(_kS3Secret) ?? '',
      s3Bucket: prefs.getString(_kS3Bucket) ?? '',
      s3Region: prefs.getString(_kS3Region) ?? 'us-east-1',
    );
  }

  static Future<void> saveConfig(SyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSyncType, config.type);
    await prefs.setString(_kWebDavUrl, config.webDavUrl);
    await prefs.setString(_kWebDavUser, config.webDavUser);
    await prefs.setString(_kWebDavPass, config.webDavPass);
    await prefs.setString(_kS3Endpoint, config.s3Endpoint);
    await prefs.setString(_kS3Access, config.s3Access);
    await prefs.setString(_kS3Secret, config.s3Secret);
    await prefs.setString(_kS3Bucket, config.s3Bucket);
    await prefs.setString(_kS3Region, config.s3Region);
  }

  static Object _clientFor(SyncConfig config) {
    if (config.type == 's3') {
      return S3Client(
        endpoint: config.s3Endpoint,
        accessKey: config.s3Access,
        secretKey: config.s3Secret,
        bucket: config.s3Bucket,
        region: config.s3Region,
      );
    }
    return WebDavClient(
      baseUrl: config.webDavUrl,
      username: config.webDavUser,
      password: config.webDavPass,
    );
  }

  /// 生成当前数据的备份字节。
  static Future<Uint8List> _buildBackupBytes() async {
    final sessions = await SessionService().load();
    final providers = await ProviderService().load();
    final agents = await AgentService().load();
    return ExportService.buildAllZipBytes(
      sessions: sessions,
      providers: providers,
      agents: agents,
    );
  }

  /// 边界包装：底层网络/协议/存储异常统一重包为带 kind 的 [SyncException]。
  ///
  /// [localKind] 为本地操作（备份打包等）失败时的类别，默认 storage。
  static Future<T> _wrap<T>(
    Future<T> Function() action, {
    String localKind = 'storage',
  }) async {
    try {
      return await action();
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('Sync failed', kind: localKind, cause: e);
    }
  }

  /// 上传备份到云端，返回文件名。
  static Future<String> uploadBackup() => _wrap(() async {
    final config = await loadConfig();
    if (!config.isComplete) throw const SyncException('Sync config incomplete');
    final bytes = await _wrap(() => _buildBackupBytes(), localKind: 'storage');
    final client = _clientFor(config);
    final kind = config.type == 's3' ? 's3' : 'webdav';
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    final now = DateTime.now();
    // 精确到毫秒并加随机序号，避免同秒两次上传互相覆盖
    final name =
        'nona-backup-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}'
        '${three(now.millisecond)}-${_suffix++}.zip';
    return _wrap(() async {
      if (client is WebDavClient) {
        await client.put('backups/$name', bytes);
      } else {
        await (client as S3Client).put('backups/$name', bytes);
      }
      return name;
    }, localKind: kind);
  });

  static int _suffix = 0;

  /// 列出云端备份。
  static Future<List<RemoteBackupFile>> listBackups() => _wrap(() async {
    final config = await loadConfig();
    if (!config.isComplete) throw const SyncException('Sync config incomplete');
    final client = _clientFor(config);
    final kind = config.type == 's3' ? 's3' : 'webdav';
    return _wrap(() async {
      if (client is WebDavClient) {
        return client.list('backups/');
      }
      return (client as S3Client).list(prefix: 'backups/');
    }, localKind: kind);
  });

  /// 下载并恢复指定备份（合并会话/服务商/Agent）。
  static Future<int> restoreBackup(String name) => _wrap(() async {
    final config = await loadConfig();
    if (!config.isComplete) throw const SyncException('Sync config incomplete');
    final client = _clientFor(config);
    final kind = config.type == 's3' ? 's3' : 'webdav';
    final Uint8List bytes = await _wrap(() async {
      if (client is WebDavClient) {
        return client.get('backups/$name');
      }
      return (client as S3Client).get('backups/$name');
    }, localKind: kind);
    return _wrap(() async {
      final result = ExportService.importFromZipBytes(bytes);
      if (result == null || result.sessions.isEmpty) {
        throw const SyncException('Backup file cannot be parsed');
      }

      var added = 0;
      var updated = 0;
      final sessions = await SessionService().load();
      final byId = {for (final s in sessions) s.id: s};
      for (final s in result.sessions) {
        final existing = byId[s.id];
        if (existing == null) {
          sessions.add(s);
          byId[s.id] = s;
          added++;
        } else {
          // 恢复语义：备份中的同名会话覆盖本地版本（含修改过的会话）
          final idx = sessions.indexOf(existing);
          sessions[idx] = s;
          byId[s.id] = s;
          updated++;
        }
      }
      if (added > 0 || updated > 0) await SessionService().saveAll(sessions);

      if (result.providers != null) {
        final existing = await ProviderService().load();
        final ids = existing.map((p) => p.id).toSet();
        for (final p in result.providers!) {
          if (ids.contains(p.id)) continue;
          existing.add(p);
        }
        await ProviderService().save(existing);
      }
      if (result.agents != null) {
        final existing = await AgentService().load();
        final ids = existing.map((a) => a.id).toSet();
        for (final a in result.agents!) {
          if (ids.contains(a.id)) continue;
          existing.add(a);
        }
        await AgentService().save(existing);
      }
      return added + updated;
    }, localKind: 'storage');
  });

  /// 删除云端备份。
  static Future<void> deleteBackup(String name) => _wrap(() async {
    final config = await loadConfig();
    if (!config.isComplete) throw const SyncException('Sync config incomplete');
    final client = _clientFor(config);
    final kind = config.type == 's3' ? 's3' : 'webdav';
    return _wrap(() async {
      if (client is WebDavClient) {
        await client.delete('backups/$name');
      } else {
        await (client as S3Client).delete('backups/$name');
      }
    }, localKind: kind);
  });
}


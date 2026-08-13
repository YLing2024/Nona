import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger.dart';
import '../agent_service.dart';
import '../provider_service.dart';
import '../session_service.dart';
import '../settings_service.dart';
import 'change_log_service.dart';
import 'sync_clients.dart';
import 'sync_exception.dart';
import 'sync_service.dart';

/// 多设备增量同步引擎（X-04，无服务器约束：WebDAV/S3 作传输层）。
///
/// 远端协议（`sync/` 前缀）：
/// ```
/// sync/meta.json                  {"schema":1,"devices":{"dev-a":{"lastSeq":42}}}
/// sync/<device>/changes-<seq>.jsonl   # JSONL，每文件 ≤200 条
/// ```
/// 合并规则：同 entity+id 按 ts_micros last-write-wins；本地 head 之后
/// 远端已读指针记录在 prefs（`sync_read_` + deviceId）。
class SyncEngine {
  /// 变更日志（可注入：测试环境数据库每次全新打开，需显式传入同一实例）。
  final ChangeLogService _log;

  SyncEngine({ChangeLogService? changeLog}) : _log = changeLog ?? ChangeLogService();

  static const _kHeadKey = 'sync_self_head';
  static const _kDeviceIdKey = 'sync_device_id';
  static const _kConflictKey = 'sync_conflicts';
  static const _kReadPrefix = 'sync_read_';
  static const _kLastSyncKey = 'sync_last_sync_at';
  static const int kBatchSize = 200;

  String get _deviceId =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// 本设备标识（prefs 持久化）。
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _deviceId;
    await prefs.setString(_kDeviceIdKey, id);
    return id;
  }

  Object _clientFor(SyncConfig config) {
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

  Future<void> _put(Object client, String path, String content) async {
    if (client is WebDavClient) {
      await client.put(path, Uint8List.fromList(utf8.encode(content)));
    } else {
      await (client as S3Client).put(path, Uint8List.fromList(utf8.encode(content)));
    }
  }

  Future<String?> _get(Object client, String path) async {
    final bytes = client is WebDavClient
        ? await client.get(path)
        : await (client as S3Client).get(path);
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// 同步一次：push 本地变更 → pull 远端变更 → 应用。
  Future<SyncResult> sync() async {
    final config = await SyncService.loadConfig();
    if (!config.isComplete) {
      return const SyncResult(success: false, message: 'Sync config incomplete');
    }
    final client = _clientFor(config);
    try {
      final pushed = await _push(client);
      final pulled = await _pull(client);
      await SharedPreferences.getInstance().then(
        (p) => p.setString(_kLastSyncKey, DateTime.now().toIso8601String()),
      );
      return SyncResult(
        success: true,
        pushed: pushed,
        pulled: pulled,
      );
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('Sync failed', kind: 'storage', cause: e);
    }
  }

  // ---------------- push ----------------

  Future<int> _push(Object client) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await deviceId();
    final head = prefs.getInt(_kHeadKey) ?? 0;
    final entries = await _log.entriesAfter(head);
    if (entries.isEmpty) return 0;
    var written = 0;
    for (var i = 0; i < entries.length; i += kBatchSize) {
      final batch = entries.sublist(
        i,
        i + kBatchSize > entries.length ? entries.length : i + kBatchSize,
      );
      final firstSeq = batch.first.seq;
      final lines = batch.map((e) => e.toJsonLine()).join('\n');
      await _put(client, 'sync/$id/changes-$firstSeq.jsonl', lines);
      written += batch.length;
    }
    final lastSeq = entries.last.seq;
    await _put(client, 'sync/$id/head.json', jsonEncode({'lastSeq': lastSeq}));
    await prefs.setInt(_kHeadKey, lastSeq);
    await _updateMeta(client, id, lastSeq);
    return written;
  }

  Future<void> _updateMeta(Object client, String deviceId, int lastSeq) async {
    String content;
    try {
      final raw = await _get(client, 'sync/meta.json');
      content = raw ?? '{}';
    } catch (_) {
      content = '{}';
    }
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      meta = {};
    }
    final devices = (meta['devices'] as Map<String, dynamic>?) ?? {};
    devices[deviceId] = {'lastSeq': lastSeq};
    meta['devices'] = devices;
    await _put(client, 'sync/meta.json', jsonEncode(meta));
  }

  // ---------------- pull ----------------

  Future<int> _pull(Object client) async {
    final prefs = await SharedPreferences.getInstance();
    final id = await deviceId();
    String metaRaw;
    try {
      metaRaw = await _get(client, 'sync/meta.json') ?? '';
    } catch (_) {
      return 0; // 远端无数据
    }
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(metaRaw) as Map<String, dynamic>;
    } catch (_) {
      return 0;
    }
    final devices = (meta['devices'] as Map<String, dynamic>?) ?? {};
    var applied = 0;
    for (final e in devices.entries) {
      final otherId = e.key;
      if (otherId == id) continue;
      final deviceMeta = e.value as Map<String, dynamic>? ?? const {};
      final remoteSeq = deviceMeta['lastSeq'] as int? ?? 0;
      final readSeq = prefs.getInt('$_kReadPrefix$otherId') ?? 0;
      if (remoteSeq <= readSeq) continue;
      // 枚举 changes 文件：从 readSeq+1 起，按序号步进读取
      var cursor = readSeq;
      while (true) {
        final fileName = 'sync/$otherId/changes-${cursor + 1}.jsonl';
        String? content;
        try {
          content = await _get(client, fileName);
        } catch (_) {
          break; // 该文件不存在 → 已到尾部
        }
        if (content == null || content.isEmpty) break;
        final lines = content
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        for (final line in lines) {
          try {
            final entry = ChangeLogEntry.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            );
            await _applyEntry(entry, otherId);
            applied++;
          } catch (_) {
            Logger.warn('sync', 'skip invalid change line: $line');
          }
        }
        cursor += lines.length;
        if (lines.length < kBatchSize) break;
      }
      await prefs.setInt('$_kReadPrefix$otherId', cursor);
    }
    return applied;
  }

  /// 应用远端变更（last-write-wins；冲突写入冲突日志）。
  Future<void> _applyEntry(ChangeLogEntry entry, String sourceDevice) async {
    final local = await _log.entriesAfter(0);
    final localLatest = local
        .where((l) => l.entityType == entry.entityType && l.entityId == entry.entityId)
        .toList()
        .reversed
        .firstOrNull;
    if (localLatest != null && localLatest.tsMicros > entry.tsMicros) {
      // 本地更新：记录冲突（保留双版本信息）
      await _recordConflict(entry, localLatest, sourceDevice);
      return;
    }
    switch (entry.entityType) {
      case 'session':
        await _applySession(entry);
      case 'settings':
        await _applySettings(entry);
      case 'provider':
        await _applyProvider(entry);
      case 'agent':
        await _applyAgent(entry);
    }
  }

  Future<void> _applySession(ChangeLogEntry entry) async {
    final service = SessionService();
    final sessions = await service.load();
    final idx = sessions.indexWhere((s) => s.id == entry.entityId);
    if (entry.op == 'delete') {
      if (idx >= 0) {
        sessions.removeAt(idx);
        await service.saveAll(sessions);
      }
      return;
    }
    // upsert：重新加载远端会话快照（简化：以本地会话为基底，删除时处理）
    // 完整实现需远端保存 payload；当前以「存在即保留、删除即移除」收敛，
    // 会话内容的双向合并依赖下一版 payload 快照。
    if (idx < 0) {
      // 远端新增但本地无 → 尝试从备份恢复兜底（调用方负责）
      Logger.warn('sync', 'remote session ${entry.entityId} not found locally');
    }
  }

  Future<void> _applySettings(ChangeLogEntry entry) async {
    final service = SettingsService();
    final settings = await service.load();
    await service.save(settings); // 触发本地 change_log（防回环：读取指针已推进）
  }

  Future<void> _applyProvider(ChangeLogEntry entry) async {
    final service = ProviderService();
    final providers = await service.load();
    if (entry.op == 'delete') {
      providers.removeWhere((p) => p.id == entry.entityId);
      await service.save(providers);
      return;
    }
    Logger.warn('sync', 'remote provider ${entry.entityId} upsert skipped (payload needed)');
  }

  Future<void> _applyAgent(ChangeLogEntry entry) async {
    final service = AgentService();
    if (entry.op == 'delete') {
      final agents = await service.load();
      agents.removeWhere((a) => a.id == entry.entityId);
      await service.save(agents);
      return;
    }
    Logger.warn('sync', 'remote agent ${entry.entityId} upsert skipped (payload needed)');
  }

  Future<void> _recordConflict(
    ChangeLogEntry remote,
    ChangeLogEntry local,
    String sourceDevice,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kConflictKey);
    List<Map<String, dynamic>> conflicts;
    try {
      conflicts = (jsonDecode(raw ?? '[]') as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      conflicts = [];
    }
    conflicts.add({
      'entity': remote.entityType,
      'id': remote.entityId,
      'localTs': local.tsMicros,
      'remoteTs': remote.tsMicros,
      'remoteDevice': sourceDevice,
      'at': DateTime.now().toIso8601String(),
    });
    if (conflicts.length > 100) {
      conflicts = conflicts.sublist(conflicts.length - 100);
    }
    await prefs.setString(_kConflictKey, jsonEncode(conflicts));
  }

  /// 冲突列表（UI 展示）。
  Future<List<Map<String, dynamic>>> conflicts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kConflictKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  /// 上次同步时间（UI 展示）。
  Future<DateTime?> lastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

/// 同步结果。
class SyncResult {
  final bool success;
  final String? message;
  final int pushed;
  final int pulled;

  const SyncResult({
    this.success = true,
    this.message,
    this.pushed = 0,
    this.pulled = 0,
  });
}

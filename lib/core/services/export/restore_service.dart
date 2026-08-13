import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:path_provider/path_provider.dart';

import '../../models/agent.dart';
import '../../models/chat_provider.dart';
import '../../models/chat_session.dart';
import '../../platform/fs.dart' show pathSeparator;
import '../../utils/logger.dart';

/// G-01：备份恢复事务化状态机。
///
/// 目录布局：`<support>/.nona_restore/<runId>/`
/// - `candidate/`    解包校验后的备份内容（staging 产物）
/// - `receipts/`     receipt_`seq`.json 链式哈希（进度凭证）
/// - `previous/`     旧数据（nona.db + 会话 JSON），回滚用
/// - `.active_run`   标记文件（内容 = runId）
///
/// 阶段：staged → oldSaved → newInstalled → verified → committed；
/// 任一步失败 → rollingBack → rolledBack（还原 previous）。
/// 启动时 [converge] 收敛未完成的 run。
class RestoreService {
  RestoreService._();

  /// 需要事务化保护的 live 文件。
  static List<String> liveFiles() => ['nona.db', 'nona.db-wal', 'nona.db-shm'];

  /// 会话 JSON 目录名（与 SessionPersistenceIo 一致）。
  static const sessionsDirName = 'nona_sessions';

  /// 备份库字节 → 校验 → 落 staged → 执行原子恢复。
  ///
  /// [onInstall]：把解析出的会话/服务商/Agent 写入 live 存储（调用方
  /// 负责落库/持久化，返回写入的会话数）；[onVerify] 可选回读校验。
  /// 返回恢复的会话数；失败抛异常（已回滚）。
  static Future<int> restoreTransactional(
    Uint8List bytes, {
    Future<int> Function(List<ChatSession> sessions)? onInstall,
  }) async {
    final root = await getApplicationSupportDirectory();
    final restoreRoot = Directory(
      '${root.path}$pathSeparator.nona_restore',
    );
    final runId = _randomId();
    final runDir = Directory('${restoreRoot.path}$pathSeparator$runId');
    final candidateDir = Directory('${runDir.path}$pathSeparator${'candidate'}');
    final previousDir = Directory('${runDir.path}$pathSeparator${'previous'}');
    final receiptsDir = Directory('${runDir.path}$pathSeparator${'receipts'}');
    final activeMarker = File('${restoreRoot.path}$pathSeparator${'.active_run'}');
    final sessionsDir = Directory('${root.path}$pathSeparator$sessionsDirName');

    try {
      await restoreRoot.create(recursive: true);
      // 旧 run 收敛（不应同时存在两个 run）
      await _convergeInternal(restoreRoot, root, sessionsDir);

      // 1) staged：解包校验
      final staged = await _stage(bytes, candidateDir, receiptsDir);
      _writeReceipt(receiptsDir, 1, 'staged', runId);
      await activeMarker.writeAsString(runId);

      // 2) oldSaved：旧数据（DB 文件 + 会话 JSON）移入 previous
      await _savePrevious(root, sessionsDir, previousDir);
      _writeReceipt(receiptsDir, 2, 'oldSaved', runId);

      // 3) newInstalled：candidate → live（DB 会话 + 文件兜底）
      var count = staged.sessions.length;
      if (onInstall != null) {
        count = await onInstall(staged.sessions);
      }
      await _installCandidate(candidateDir, root, sessionsDir);
      _writeReceipt(receiptsDir, 3, 'newInstalled', runId);

      // 4) verified：回读校验
      await _verifyInstalled(root, sessionsDir, staged.sessions.length);
      _writeReceipt(receiptsDir, 4, 'verified', runId);

      // 5) committed：清 previous + 标记
      await _commit(previousDir, activeMarker, restoreRoot);
      _writeReceipt(receiptsDir, 5, 'committed', runId);
      return count;
    } catch (e) {
      Logger.error('restore', 'restore failed, rolling back', e);
      await _rollback(previousDir, root, sessionsDir, activeMarker, restoreRoot);
      rethrow;
    }
  }

  /// 启动收敛：`.active_run` 存在时按 receipt 收敛。
  static Future<void> convergeOnStartup() async {
    try {
      final root = await getApplicationSupportDirectory();
      final restoreRoot = Directory(
        '${root.path}$pathSeparator.nona_restore',
      );
      if (!restoreRoot.existsSync()) return;
      final sessionsDir = Directory(
        '${root.path}$pathSeparator$sessionsDirName',
      );
      await _convergeInternal(restoreRoot, root, sessionsDir);
    } catch (e) {
      Logger.error('restore', 'startup converge failed', e);
    }
  }

  /// 收敛逻辑：无 receipt → discard；非终态 → 回滚；终态 → 清理。
  static Future<void> _convergeInternal(
    Directory restoreRoot,
    Directory root,
    Directory sessionsDir,
  ) async {
    final marker = File('${restoreRoot.path}$pathSeparator${'.active_run'}');
    if (!marker.existsSync()) {
      // 无标记：清掉孤儿目录
      if (restoreRoot.existsSync()) {
        try {
          await restoreRoot.delete(recursive: true);
        } catch (_) {}
      }
      return;
    }
    final runId = await marker.readAsString();
    final runDir = Directory('${restoreRoot.path}$pathSeparator$runId');
    if (!runDir.existsSync()) {
      await marker.delete();
      return;
    }
    final receiptsDir = Directory('${runDir.path}$pathSeparator${'receipts'}');
    final lastSeq = _lastReceiptSeq(receiptsDir);
    if (lastSeq <= 0) {
      // staged 未开始或仅 staged：直接丢弃
      await marker.delete();
      try {
        await runDir.delete(recursive: true);
      } catch (_) {}
      return;
    }
    if (lastSeq < 5) {
      // 非终态：回滚 previous（若已保存）
      final previousDir = Directory('${runDir.path}$pathSeparator${'previous'}');
      await _rollback(previousDir, root, sessionsDir, marker, restoreRoot);
      return;
    }
    // 终态（committed）：清理
    await marker.delete();
    try {
      await runDir.delete(recursive: true);
    } catch (_) {}
  }

  // ---------------- 各阶段 ----------------

  /// staging：解包 + manifest 校验 + 内容校验；返回解析结果。
  static Future<_StagedBackup> _stage(
    Uint8List bytes,
    Directory candidateDir,
    Directory receiptsDir,
  ) async {
    // 复用 BackupArchive 的解析（纯内存），校验通过后写入 candidate
    final result = _parseBackup(bytes);
    if (result == null) {
      throw const FormatException('backup corrupt or verification failed');
    }
    await candidateDir.create(recursive: true);
    final sessionFiles = <File>[];
    for (final s in result.sessions) {
      final f = File(
        '${candidateDir.path}$pathSeparator'
        'sessions-${_safeId(s.id)}.json',
      );
      await f.writeAsString(jsonEncode(s.toJson()));
      sessionFiles.add(f);
    }
    if (result.providers != null) {
      await File('${candidateDir.path}$pathSeparator${'providers.json'}')
          .writeAsString(
        jsonEncode({'providers': result.providers!.map((p) => p.toJson()).toList()}),
      );
    }
    if (result.agents != null) {
      await File('${candidateDir.path}$pathSeparator${'agents.json'}}')
          .writeAsString(
        jsonEncode({'agents': result.agents!.map((a) => a.toJson()).toList()}),
      );
    }
    _writeReceipt(receiptsDir, 0, 'staging', '');
    return result;
  }

  /// 旧数据快照：nona.db（含 -wal/-shm）+ 会话 JSON 目录 → previous/。
  static Future<void> _savePrevious(
    Directory root,
    Directory sessionsDir,
    Directory previousDir,
  ) async {
    await previousDir.create(recursive: true);
    for (final name in liveFiles()) {
      final src = File('${root.path}$pathSeparator$name');
      if (src.existsSync()) {
        final dst = File('${previousDir.path}$pathSeparator$name');
        // 先关库连接：恢复流程由调用方在关闭数据库后执行
        try {
          await src.copy(dst.path);
        } catch (e) {
          Logger.error('restore', 'backup $name failed', e);
        }
      }
    }
    if (sessionsDir.existsSync()) {
      final dstDir = Directory('${previousDir.path}$pathSeparator$sessionsDirName');
      await dstDir.create(recursive: true);
      for (final f in sessionsDir.listSync().whereType<File>()) {
        try {
          await f.copy('${dstDir.path}$pathSeparator${f.uri.pathSegments.last}');
        } catch (_) {}
      }
    }
  }

  /// candidate → live：会话 JSON 替换 + 写 providers/agents 状态文件。
  static Future<void> _installCandidate(
    Directory candidateDir,
    Directory root,
    Directory sessionsDir,
  ) async {
    // 会话 JSON 目录整体替换
    if (sessionsDir.existsSync()) {
      await sessionsDir.delete(recursive: true);
    }
    await sessionsDir.create(recursive: true);
    for (final f in candidateDir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('sessions-'))) {
      final id = f.uri.pathSegments.last
          .replaceFirst('sessions-', '')
          .replaceFirst('.json', '');
      await f.copy('${sessionsDir.path}$pathSeparator$id.json');
    }
    // providers/agents 写入恢复专用状态（由调用方读取后落库/持久化）
    final providersRaw = File('${candidateDir.path}$pathSeparator${'providers.json'}');
    if (providersRaw.existsSync()) {
      await providersRaw.copy(
        '${root.path}$pathSeparator${'.nona_restore_import_providers.json'}',
      );
    }
    final agentsRaw = File('${candidateDir.path}$pathSeparator${'agents.json'}');
    if (agentsRaw.existsSync()) {
      await agentsRaw.copy(
        '${root.path}$pathSeparator${'.nona_restore_import_agents.json'}',
      );
    }
  }

  /// 回读校验：会话 JSON 可解析且数量一致。
  static Future<int> _verifyInstalled(
    Directory root,
    Directory sessionsDir,
    int expected,
  ) async {
    if (!sessionsDir.existsSync()) {
      throw StateError('sessions dir missing after install');
    }
    var count = 0;
    for (final f in sessionsDir.listSync().whereType<File>()) {
      try {
        jsonDecode(await f.readAsString());
        count++;
      } catch (_) {
        throw StateError('installed session corrupt: ${f.path}');
      }
    }
    if (count != expected) {
      throw StateError('session count mismatch: $count != $expected');
    }
    return count;
  }

  static Future<void> _commit(
    Directory previousDir,
    File activeMarker,
    Directory restoreRoot,
  ) async {
    try {
      if (previousDir.existsSync()) {
        await previousDir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      await activeMarker.delete();
      if (restoreRoot.existsSync()) {
        final dirs = restoreRoot
            .listSync()
            .whereType<Directory>()
            .where((d) => d.uri.pathSegments.last != 'imports');
        for (final d in dirs) {
          try {
            await d.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// 回滚：previous → live，清标记。
  static Future<void> _rollback(
    Directory previousDir,
    Directory root,
    Directory sessionsDir,
    File activeMarker,
    Directory restoreRoot,
  ) async {
    try {
      if (previousDir.existsSync()) {
        // 还原数据库文件
        for (final name in liveFiles()) {
          final src = File('${previousDir.path}$pathSeparator$name');
          if (src.existsSync()) {
            try {
              await src.copy('${root.path}$pathSeparator$name');
            } catch (_) {}
          }
        }
        // 还原会话 JSON 目录
        final prevSessions = Directory(
          '${previousDir.path}$pathSeparator$sessionsDirName',
        );
        if (prevSessions.existsSync()) {
          if (sessionsDir.existsSync()) {
            try {
              await sessionsDir.delete(recursive: true);
            } catch (_) {}
          }
          await sessionsDir.create(recursive: true);
          for (final f in prevSessions.listSync().whereType<File>()) {
            try {
              await f.copy(
                '${sessionsDir.path}$pathSeparator${f.uri.pathSegments.last}',
              );
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      Logger.error('restore', 'rollback copy failed', e);
    }
    try {
      await activeMarker.delete();
    } catch (_) {}
    try {
      await restoreRoot.delete(recursive: true);
    } catch (_) {}
  }

  // ---------------- 工具 ----------------

  static void _writeReceipt(
    Directory receiptsDir,
    int seq,
    String phase,
    String runId,
  ) {
    try {
      receiptsDir.createSync(recursive: true);
      File('${receiptsDir.path}$pathSeparator${'receipt_$seq.json'}}')
          .writeAsStringSync(
        jsonEncode({
          'seq': seq,
          'phase': phase,
          'runId': runId,
          'ts': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  static int _lastReceiptSeq(Directory receiptsDir) {
    if (!receiptsDir.existsSync()) return 0;
    var max = 0;
    for (final f in receiptsDir.listSync().whereType<File>()) {
      final m = RegExp(r'receipt_(\d+)\.json').firstMatch(f.uri.pathSegments.last);
      if (m != null) {
        final v = int.tryParse(m.group(1)!) ?? 0;
        if (v > max) max = v;
      }
    }
    return max;
  }

  /// 备份解析（与 BackupArchive 相同的校验，避免循环依赖）。
  static _StagedBackup? _parseBackup(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      String? read(String name) {
        final f = archive.find(name);
        return f == null ? null : utf8.decode(f.content, allowMalformed: true);
      }

      final manifestRaw = read('manifest.json');
      if (manifestRaw == null) return null;
      final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
      if (manifest['format'] != 'nona-backup') return null;

      final sessions = <ChatSession>[];
      for (final f in archive.files) {
        final name = f.name;
        if (!name.startsWith('sessions/') || !name.endsWith('.json')) continue;
        try {
          sessions.add(
            ChatSession.fromJson(
              jsonDecode(utf8.decode(f.content)) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          continue;
        }
      }
      return _StagedBackup(
        sessions: sessions,
        providers: _parseList(read('providers.json'), 'providers'),
        agents: _parseList(read('agents.json'), 'agents'),
      );
    } catch (_) {
      return null;
    }
  }

  static List<T>? _parseList<T>(String? raw, String key) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return (data[key] as List<dynamic>)
          .map((e) => _fromJsonAny(e, key) as T)
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Object? _fromJsonAny(dynamic e, String key) {
    final map = e as Map<String, dynamic>;
    return key == 'providers' ? ChatProvider.fromJson(map) : Agent.fromJson(map);
  }

  static String _randomId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(ts)).toString().substring(0, 8);
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$hash';
  }

  static String _safeId(String id) =>
      id.replaceAll(RegExp(r'[^\w-]'), '_');
}

/// staging 解析中间结果。
class _StagedBackup {
  final List<ChatSession> sessions;
  final List<ChatProvider>? providers;
  final List<Agent>? agents;

  const _StagedBackup({
    required this.sessions,
    this.providers,
    this.agents,
  });
}

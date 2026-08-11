import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import '../../models/agent.dart';
import '../../models/chat_provider.dart';
import '../../models/chat_session.dart';
import '../storage_io_io.dart'
    if (dart.library.js_interop) '../storage_io_stub.dart'
    as storage_io;

/// 一条导入失败记录（导入器逐条容错时收集）。
class ImportFailure {
  final int index;
  final String reason;

  const ImportFailure({required this.index, required this.reason});
}

/// 备份/导入的完整结果：会话 + 可选的服务商与 Agent + 失败条目。
class BackupImportResult {
  final List<ChatSession> sessions;
  final List<ChatProvider>? providers;
  final List<Agent>? agents;
  final List<ImportFailure> failedItems;

  const BackupImportResult({
    required this.sessions,
    this.providers,
    this.agents,
    this.failedItems = const [],
  });
}

/// ZIP 备份打包 / 解包 / 清单 manifest。
///
/// 结构：
/// ```
/// manifest.json        # {app, format: "nona-backup", version, exportedAt, 数量}
/// providers.json       # 服务商配置（可选）
/// agents.json          # Agent 配置（可选）
/// sessions/<id>.json   # 每个会话独立文件
/// ```
class BackupArchive {
  /// 生成全部数据的 ZIP 备份字节（不落盘）。
  static Uint8List buildAllZipBytes({
    required List<ChatSession> sessions,
    List<ChatProvider> providers = const [],
    List<Agent> agents = const [],
  }) {
    final archive = Archive();
    void addJson(String name, Map<String, dynamic> data) {
      archive.addFile(
        ArchiveFile.string(name, jsonEncode(data)),
      );
    }

    addJson('manifest.json', {
      'app': 'nona',
      'format': 'nona-backup',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessionCount': sessions.length,
      'providerCount': providers.length,
      'agentCount': agents.length,
    });
    if (providers.isNotEmpty) {
      addJson(
        'providers.json',
        {'providers': providers.map((p) => p.toJson()).toList()},
      );
    }
    if (agents.isNotEmpty) {
      addJson('agents.json', {'agents': agents.map((a) => a.toJson()).toList()});
    }
    for (final s in sessions) {
      addJson('sessions/${s.id}.json', s.toJson());
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// 导出全部数据为 ZIP 备份（manifest + 会话 + 服务商 + Agent）。
  static Future<String?> exportAllZipToFile({
    required List<ChatSession> sessions,
    List<ChatProvider> providers = const [],
    List<Agent> agents = const [],
  }) async {
    final bytes = buildAllZipBytes(
      sessions: sessions,
      providers: providers,
      agents: agents,
    );
    return storage_io.saveBytesFile(
      suggestedName: 'nona-backup-${_dateStamp()}.zip',
      data: bytes,
      extension: 'zip',
      mimeType: 'application/zip',
    );
  }

  /// 兼容旧版：导出全部会话为 JSON 备份文件。
  static Future<String?> exportAllToFile(List<ChatSession> sessions) async {
    final data = jsonEncode({
      'app': 'nona',
      'version': 1,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
    return storage_io.saveTextFile(
      suggestedName: 'nona-sessions-${_dateStamp()}.json',
      data: data,
      extension: 'json',
      mimeType: 'application/json',
    );
  }

  /// 解析 ZIP 备份字节；无法解析返回 null。
  static BackupImportResult? importFromZipBytes(List<int> bytes) {
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
          continue; // 单条损坏不影响整体
        }
      }

      List<ChatProvider>? providers;
      final providersRaw = read('providers.json');
      if (providersRaw != null) {
        try {
          providers = (jsonDecode(providersRaw) as Map<String, dynamic>)['providers']
              .map<ChatProvider>(
                (e) => ChatProvider.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        } catch (_) {
          providers = null;
        }
      }

      List<Agent>? agents;
      final agentsRaw = read('agents.json');
      if (agentsRaw != null) {
        try {
          agents = (jsonDecode(agentsRaw) as Map<String, dynamic>)['agents']
              .map<Agent>((e) => Agent.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          agents = null;
        }
      }

      return BackupImportResult(
        sessions: sessions,
        providers: providers,
        agents: agents,
      );
    } catch (_) {
      return null;
    }
  }

  static String _dateStamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}';
  }
}

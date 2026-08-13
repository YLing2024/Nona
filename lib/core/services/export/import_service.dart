import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../models/chat_provider.dart';
import '../../models/chat_session.dart';
import 'backup_archive.dart';
import 'import_report.dart';
import 'importers/importer_factory.dart';
import 'importers/sqlite_importers.dart' as sqlite_importers;

/// 导入嗅探分发入口：识别 ZIP 备份 / Nona JSON / Chatbox / Cherry /
/// NextChat / ChatGPT / RikkaHub / Kelivo。
///
/// 新格式接入 = 新增 importer 文件并在 [ImporterFactory] 注册一行。
class ImportService {
  /// 从 JSON 文件恢复会话；解析失败返回 null。
  static Future<ChatSession?> importFromFile() async {
    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return null;
    final raw = await file.readAsString();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ChatSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 从文件导入：自动识别 ZIP 备份 / 各竞品 JSON / SQLite 格式。
  ///
  /// 返回 [BackupImportResult]；无法解析时返回 null。
  static Future<BackupImportResult?> importAllFromFile() async {
    const typeGroup = XTypeGroup(
      label: 'Backup',
      extensions: ['zip', 'json', 'db', 'sqlite', 'sqlite3'],
      mimeTypes: [
        'application/zip',
        'application/json',
        'application/octet-stream',
      ],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return importFromBytes(bytes, fileName: file.name);
  }

  /// 从字节导入（嗅探分发）。
  static BackupImportResult? importFromBytes(
    List<int> bytes, {
    required String fileName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.sqlite3')) {
      // SQLite：临时落盘后嗅探（RikkaHub / Kelivo，io 平台；Web 返回 null）
      return sqlite_importers.importSqliteBytes(Uint8List.fromList(bytes));
    }
    // ZIP 魔数 PK\x03\x04；空 ZIP 为 PK\x05\x06（中央目录为空）
    if (ImporterFactory.isZipBytes(Uint8List.fromList(bytes))) {
      return BackupArchive.importFromZipBytes(bytes);
    }
    final data = ImporterFactory.decodeJson(Uint8List.fromList(bytes));
    if (data == null) return null;
    final result = ImporterFactory.importJson(data);
    return result.sessions.isEmpty && result.failedItems.isEmpty
        ? null
        : result;
  }

  /// 解析 JSON 备份/导出（Nona → Chatbox → Cherry → NextChat → OpenAI）。
  static BackupImportResult? importFromJsonData(Object? data) {
    final result = ImporterFactory.importJson(data);
    return result.sessions.isEmpty && result.failedItems.isEmpty
        ? null
        : result;
  }

  // ---------------- X-03：导入武器化（质量报告/去重/合并） ----------------

  /// 分析导入内容：只解析不落库，产出结构化报告（格式/质量/失败/重复）。
  ///
  /// [existingIds] 为当前库中会话 id 集合（用于重复检测，可空）。
  static ImportReport? analyze(
    List<int> bytes, {
    required String fileName,
    Set<String>? existingIds,
  }) {
    final result = importFromBytes(bytes, fileName: fileName);
    if (result == null) return null;
    return buildReport(
      result,
      sourceFormat: _formatOf(fileName, result),
      existingIds: existingIds,
    );
  }

  /// 由解析结果构建报告（重复检测 + 质量指标）。
  static ImportReport buildReport(
    BackupImportResult result, {
    required String sourceFormat,
    Set<String>? existingIds,
  }) {
    final sessions = result.sessions;
    var messages = 0;
    var timestamped = 0;
    var multimodal = 0;
    var toolMessages = 0;
    for (final s in sessions) {
      for (final m in s.messages) {
        messages++;
        if (m.sentAt != null) timestamped++;
        if (m.images.isNotEmpty || m.documents.isNotEmpty) multimodal++;
        if (m.toolCallId != null || m.toolCallsJson != null) toolMessages++;
      }
    }
    // 重复检测：stableSessionId 哈希 vs 现有会话 id
    final existing = existingIds ?? const <String>{};
    final seen = <String, int>{};
    final duplicateHits = <DuplicateHit>[];
    final titlesById = <String, String>{};
    for (final s in sessions) {
      titlesById[s.id] = s.title;
      if (existing.contains(s.id)) {
        seen[s.id] = (seen[s.id] ?? 0) + 1;
      }
    }
    for (final e in seen.entries) {
      duplicateHits.add(
        DuplicateHit(
          hashSessionId: e.key,
          existingTitle: titlesById[e.key] ?? '',
          matches: e.value,
        ),
      );
    }
    return ImportReport(
      sourceFormat: sourceFormat,
      sessions: sessions.length,
      messages: messages,
      succeeded: sessions.length,
      failures: result.failedItems,
      quality: ImportQuality(
        timestampCompleteRate:
            messages == 0 ? 1.0 : timestamped / messages,
        multimodalPreserved: multimodal == 0 ||
            result.sessions.any(
              (s) => s.messages.any(
                (m) => m.images.isNotEmpty || m.documents.isNotEmpty,
              ),
            ),
        toolMessagesPreserved: toolMessages == 0 ||
            result.sessions.any(
              (s) => s.messages.any(
                (m) => m.toolCallId != null || m.toolCallsJson != null,
              ),
            ),
      ),
      duplicates: duplicateHits,
      parsedSessions: sessions,
      providers: result.providers,
    );
  }

  static String _formatOf(String fileName, BackupImportResult result) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.db') ||
        lower.endsWith('.sqlite') ||
        lower.endsWith('.sqlite3')) {
      return 'sqlite';
    }
    if (ImporterFactory.isZipBytes(_empty)) return 'nona-backup';
    if (result.sessions.isEmpty) return 'unknown';
    return 'nona';
  }

  static final Uint8List _empty = Uint8List(0);

  /// 服务商合并（X-03）：同名（按 baseUrl）服务商追加导入的模型列表，
  /// Key 保留本地现有值。
  static List<ChatProvider> mergeProviders(
    List<ChatProvider> existing,
    List<ChatProvider> imported,
  ) {
    if (imported.isEmpty) return existing;
    final result = List<ChatProvider>.from(existing);
    for (final p in imported) {
      final base = p.baseUrl.trim().toLowerCase();
      final idx = result.indexWhere(
        (e) => e.baseUrl.trim().toLowerCase() == base,
      );
      if (idx < 0) {
        result.add(p);
        continue;
      }
      // 同名：合并模型列表（去重），key 保留本地
      final local = result[idx];
      final merged = <String>{
        ...local.modelIds,
        ...p.modelIds,
      }.toList();
      result[idx] = ChatProvider(
        id: local.id,
        name: local.name,
        baseUrl: local.baseUrl,
        apiKey: local.apiKey,
        apiKeys: local.apiKeys,
        kind: local.kind,
        customHeaders: local.customHeaders,
        customBody: local.customBody,
        balancePath: local.balancePath,
        balanceResultPath: local.balanceResultPath,
        modelIds: merged,
        modelConfigs: local.modelConfigs,
      );
    }
    return result;
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../models/chat_session.dart';
import 'backup_archive.dart';
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
}

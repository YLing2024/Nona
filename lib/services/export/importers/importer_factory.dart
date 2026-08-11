import 'dart:convert';
import 'dart:typed_data';

import '../backup_archive.dart';
import 'chatbox_importer.dart';
import 'cherry_importer.dart';
import 'nextchat_importer.dart';
import 'nona_importer.dart';
import 'openai_importer.dart';
import 'sqlite_importers.dart' as sqlite_importers;

/// 导入进度回调。
typedef ImportProgress = void Function(int done, int total);

/// 导入器工厂（F6-1）：按魔数/JSON 结构特征嗅探分发。
///
/// 新增格式 = 新增 importer 文件并在 [sniff] 注册一行。
class ImporterFactory {
  /// 嗅探识别格式：返回格式名（nona/chatbox/cherry/nextchat/openai），
  /// 无法识别返回 null。SQLite 文件单独走 [detectSqlite]。
  static String? sniffJson(Object? data) {
    if (data is Map<String, dynamic>) {
      if (NonaImporter.tryParse(data) != null) return 'nona';
      if (ChatboxImporter.matches(data)) return 'chatbox';
      if (CherryStudioImporter.matches(data)) return 'cherry';
      if (NextChatImporter.matches(data)) return 'nextchat';
      if (OpenAiImporter.matches(data)) return 'openai';
    }
    if (data is List) {
      if (NonaImporter.tryParse(data) != null) return 'nona';
    }
    return null;
  }

  /// 嗅探 SQLite 文件：RikkaHub / Kelivo（Web 返回 null）。
  static String? sniffSqlite(String path) => sqlite_importers.sniffSqlite(path);

  /// 从 JSON 数据导入（逐条容错，失败计入报告）。
  static BackupImportResult importJson(Object? data) {
    if (data is List) {
      final nona = NonaImporter.tryParse(data);
      if (nona != null) return nona;
      return const BackupImportResult(sessions: []);
    }
    if (data is! Map<String, dynamic>) {
      return const BackupImportResult(sessions: []);
    }
    final nona = NonaImporter.tryParse(data);
    if (nona != null) return nona;
    if (ChatboxImporter.matches(data)) return ChatboxImporter.parse(data);
    if (CherryStudioImporter.matches(data)) {
      return CherryStudioImporter.parse(data);
    }
    if (NextChatImporter.matches(data)) return NextChatImporter.parse(data);
    if (OpenAiImporter.matches(data)) return OpenAiImporter.parse(data);
    return const BackupImportResult(sessions: []);
  }

  /// 从 SQLite 文件导入（Web 返回空）。
  static BackupImportResult importSqlite(String path, String format) =>
      sqlite_importers.importSqlite(path, format);

  /// 是否为 ZIP 备份字节（PK 魔数）。
  static bool isZipBytes(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
          (bytes[2] == 0x05 && bytes[3] == 0x06));

  /// 解码 JSON 字节为对象（失败返回 null）。
  static Object? decodeJson(Uint8List bytes) {
    try {
      return jsonDecode(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }
}

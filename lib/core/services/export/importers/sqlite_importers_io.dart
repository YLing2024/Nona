import 'dart:io';
import 'dart:typed_data';

import '../backup_archive.dart';
import 'kelivo_importer.dart';
import 'rikkahub_importer.dart';

/// 嗅探 SQLite 文件格式（RikkaHub / Kelivo），不识别返回 null。
String? sniffSqlite(String path) {
  if (RikkaHubImporter.matchesFile(path)) return 'rikkahub';
  if (KelivoImporter.matchesFile(path)) return 'kelivo';
  return null;
}

/// 按格式导入 SQLite 文件。
BackupImportResult importSqlite(String path, String format) {
  switch (format) {
    case 'rikkahub':
      return RikkaHubImporter.importFile(path);
    case 'kelivo':
      return KelivoImporter.importFile(path);
    default:
      return const BackupImportResult(sessions: []);
  }
}

/// 从字节导入 SQLite（临时落盘后嗅探导入）；无法识别返回 null。
BackupImportResult? importSqliteBytes(Uint8List bytes) {
  final tempDir = Directory.systemTemp;
  final tmp = File(
    '${tempDir.path}${Platform.pathSeparator}'
    'nona-import-${DateTime.now().microsecondsSinceEpoch}.db',
  );
  try {
    tmp.writeAsBytesSync(bytes);
    final format = sniffSqlite(tmp.path);
    if (format == null) return null;
    return importSqlite(tmp.path, format);
  } catch (_) {
    return null;
  } finally {
    try {
      tmp.deleteSync();
    } catch (_) {}
  }
}

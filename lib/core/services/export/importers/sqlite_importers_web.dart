/// Web 平台 SQLite 导入器存根：Web 无法打开本地 SQLite 文件。
library;

import 'dart:typed_data';

import '../backup_archive.dart';

/// 恒 null（Web 不支持 SQLite 导入）。
String? sniffSqlite(String path) => null;

/// 返回空结果。
BackupImportResult importSqlite(String path, String format) =>
    const BackupImportResult(sessions: []);

/// 恒 null（Web 不支持 SQLite 导入）。
BackupImportResult? importSqliteBytes(Uint8List bytes) => null;

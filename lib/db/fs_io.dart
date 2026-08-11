/// 文件系统访问（io 版）。
library;

import 'dart:io';

/// 路径分隔符。
String get pathSeparator => Platform.pathSeparator;

/// 文件是否存在。
bool fileExists(String path) => File(path).existsSync();

/// 读文本文件（不存在返回 null）。
Future<String?> readTextFile(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsString();
}

/// 写文本文件。
Future<void> writeTextFile(String path, String content) =>
    File(path).writeAsString(content);

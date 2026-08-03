import 'dart:io';

/// 将文本写入指定路径；[path] 为 null 时返回 null。
Future<String?> writeTextToPath(String? path, String data) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  await file.writeAsString(data);
  return path;
}

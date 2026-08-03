import 'dart:convert';

import 'package:file_selector/file_selector.dart';

/// Web 平台兜底：无本地路径，通过浏览器下载保存。
Future<String?> writeTextToPath(String? path, String data) async {
  if (path == null || path.isEmpty) {
    final xf = XFile.fromData(utf8.encode(data), mimeType: 'text/plain');
    await xf.saveTo('');
    return null;
  }
  return null;
}

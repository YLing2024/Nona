import 'dart:convert';

import 'package:file_selector/file_selector.dart';

/// Web 平台兜底：无本地路径，通过浏览器下载保存文本文件。
Future<String?> saveTextFile({
  required String suggestedName,
  required String data,
  required String extension,
  required String mimeType,
}) async {
  final xf = XFile.fromData(
    utf8.encode(data),
    mimeType: mimeType,
    name: suggestedName,
  );
  await xf.saveTo(suggestedName);
  return null;
}

/// Web 平台：无法打开外部编辑器，返回 false。
Future<bool> openInEditor(String filename, String content) async => false;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// 将文本写入指定路径；[path] 为 null 时返回 null。
Future<String?> writeTextToPath(String? path, String data) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  await file.writeAsString(data);
  return path;
}

/// 将字节写入指定路径；[path] 为 null 时返回 null。
Future<String?> writeBytesToPath(String? path, Uint8List data) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  await file.writeAsBytes(data);
  return path;
}

/// 保存字节文件并返回写入路径（行为同 [saveTextFile]：桌面弹保存对话框，
/// 移动端回退写入临时目录）。
Future<String?> saveBytesFile({
  required String suggestedName,
  required Uint8List data,
  required String extension,
  required String mimeType,
}) async {
  final typeGroup = XTypeGroup(
    label: extension.toUpperCase(),
    extensions: [extension],
    mimeTypes: [mimeType],
  );
  if (!Platform.isAndroid && !Platform.isIOS) {
    final file = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [typeGroup],
    );
    if (file == null) return null;
    return writeBytesToPath(file.path, data);
  }
  // 移动端回退：无保存对话框，写入临时目录
  final dir = await Directory.systemTemp.createTemp('nona_export');
  return writeBytesToPath(
    '${dir.path}${Platform.pathSeparator}$suggestedName',
    data,
  );
}

/// 保存文本文件并返回写入路径。
///
/// - 桌面端（Windows/macOS/Linux）：弹出系统保存对话框，取消时返回 null；
/// - 移动端（Android/iOS）：file_selector 不支持保存对话框（会抛
///   UnimplementedError），回退到应用临时目录写入，返回完整路径供提示。
Future<String?> saveTextFile({
  required String suggestedName,
  required String data,
  required String extension,
  required String mimeType,
}) async {
  final typeGroup = XTypeGroup(
    label: extension.toUpperCase(),
    extensions: [extension],
    mimeTypes: [mimeType],
  );
  if (!Platform.isAndroid && !Platform.isIOS) {
    final file = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [typeGroup],
    );
    if (file == null) return null;
    return writeTextToPath(file.path, data);
  }
  // 移动端回退：无保存对话框，写入临时目录
  final dir = await Directory.systemTemp.createTemp('nona_export');
  return writeTextToPath(
    '${dir.path}${Platform.pathSeparator}$suggestedName',
    data,
  );
}

/// 将 [content] 写入临时文件并用系统默认程序打开（用于查看完整日志正文）。
/// 支持 Windows / macOS / Linux；失败时返回 false。
Future<bool> openInEditor(String filename, String content) async {
  try {
    final dir = await Directory.systemTemp.createTemp('nona_log');
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(content);
    final exe = Platform.isWindows
        ? 'cmd'
        : Platform.isMacOS
            ? 'open'
            : 'xdg-open';
    final args = Platform.isWindows
        ? ['/c', 'start', '', '"${file.path}"']
        : [file.path];
    await Process.start(exe, args);
    return true;
  } catch (_) {
    return false;
  }
}

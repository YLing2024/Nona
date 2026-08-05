import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../models/chat_session.dart';
import 'storage_io_io.dart'
    if (dart.library.js_interop) 'storage_io_stub.dart'
    as storage_io;

/// 会话导出 / 导入服务。
class ExportService {
  /// 将会话渲染为 Markdown 文本（含系统提示词与思考内容说明）。
  static String sessionToMarkdown(ChatSession session) {
    final sb = StringBuffer();
    sb.writeln('# ${session.title}');
    sb.writeln();
    sb.writeln('> 导出时间：${_formatDateTime(DateTime.now())}');
    sb.writeln();
    if (session.options.systemPrompt.trim().isNotEmpty) {
      sb.writeln('## 系统提示词');
      sb.writeln();
      sb.writeln('```');
      sb.writeln(session.options.systemPrompt.trim());
      sb.writeln('```');
      sb.writeln();
    }
    sb.writeln('---');
    sb.writeln();
    for (final m in session.messages) {
      if (m.content.trim().isEmpty) continue;
      switch (m.role) {
        case 'user':
          sb.writeln('## 🧑 用户');
          break;
        case 'system':
          sb.writeln('## ⚙️ 系统');
          break;
        default:
          sb.writeln('## 🤖 Nona');
      }
      sb.writeln();
      if (m.reasoningContent.isNotEmpty) {
        sb.writeln('<details>');
        sb.writeln('<summary>思考过程</summary>');
        sb.writeln();
        sb.writeln(m.reasoningContent.trim());
        sb.writeln();
        sb.writeln('</details>');
        sb.writeln();
      }
      sb.writeln(m.content.trim());
      if (m.interrupted) {
        sb.writeln();
        sb.writeln('_（已停止生成）_');
      }
      sb.writeln();
    }
    return sb.toString();
  }

  /// 导出为 .md 文件（桌面端弹出保存对话框）。
  static Future<String?> exportToFile(ChatSession session) async {
    final data = sessionToMarkdown(session);
    return storage_io.saveTextFile(
      suggestedName: '${_safeFileName(session.title)}.md',
      data: data,
      extension: 'md',
      mimeType: 'text/markdown',
    );
  }

  /// 导出为 JSON 文件（可被 [importFromFile] 恢复）。
  static Future<String?> exportJsonToFile(ChatSession session) async {
    final data = jsonEncode(session.toJson());
    return storage_io.saveTextFile(
      suggestedName: '${_safeFileName(session.title)}.json',
      data: data,
      extension: 'json',
      mimeType: 'application/json',
    );
  }

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

  /// 导出全部会话为 JSON 备份文件。
  static Future<String?> exportAllToFile(List<ChatSession> sessions) async {
    final data = jsonEncode({
      'app': 'nona',
      'version': 1,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
    return storage_io.saveTextFile(
      suggestedName: 'nona-sessions-${_dateStamp()}.json',
      data: data,
      extension: 'json',
      mimeType: 'application/json',
    );
  }

  /// 从备份文件导入全部会话；解析失败返回 null。
  static Future<List<ChatSession>?> importAllFromFile() async {
    const typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return null;
    final raw = await file.readAsString();
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final list = data['sessions'] as List<dynamic>?;
        if (list != null) {
          return list
              .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _dateStamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}';
  }

  /// 将会话复制为 Markdown 到剪贴板。
  static Future<void> copyAsMarkdown(ChatSession session) async {
    await Clipboard.setData(ClipboardData(text: sessionToMarkdown(session)));
  }

  static String _safeFileName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    return cleaned.isEmpty ? '会话' : cleaned;
  }

  static String _formatDateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/chat_session.dart';
import '../storage_io_io.dart'
    if (dart.library.js_interop) '../storage_io_stub.dart'
    as storage_io;

/// 单会话文本导出：Markdown / HTML / JSON（及剪贴板复制）。
///
/// 文件落盘通过平台存储抽象（桌面保存对话框 / Web 下载），
/// 与 PDF 导出（[PdfExporter]）分离。
class SessionExporter {
  /// 将会话渲染为 Markdown 文本（含系统提示词与思考内容说明）。
  static String sessionToMarkdown(ChatSession session) {
    final sb = StringBuffer();
    sb.writeln('# ${session.title}');
    sb.writeln();
    sb.writeln('> Exported: ${_formatDateTime(DateTime.now())}');
    sb.writeln();
    if (session.options.systemPrompt.trim().isNotEmpty) {
      sb.writeln('## System Prompt');
      sb.writeln();
      // 提示词内含 ``` 时用更长的围栏包裹，避免破坏 Markdown 结构
      final fence = session.options.systemPrompt.contains('```')
          ? '````'
          : '```';
      sb.writeln(fence);
      sb.writeln(session.options.systemPrompt.trim());
      sb.writeln(fence);
      sb.writeln();
    }
    sb.writeln('---');
    sb.writeln();
    for (final m in session.messages) {
      if (m.content.trim().isEmpty && m.images.isEmpty) continue;
      switch (m.role) {
        case 'user':
          sb.writeln('## User');
          break;
        case 'system':
          sb.writeln('## System');
          break;
        default:
          sb.writeln('## Nona');
      }
      sb.writeln();
      if (m.reasoningContent.isNotEmpty) {
        sb.writeln('<details>');
        sb.writeln('<summary>Reasoning</summary>');
        sb.writeln();
        sb.writeln(m.reasoningContent.trim());
        sb.writeln();
        sb.writeln('</details>');
        sb.writeln();
      }
      if (m.content.trim().isNotEmpty) {
        sb.writeln(m.content.trim());
      }
      // 图片消息：以 Markdown 图片语法导出（data URL 或远程 URL 均可展示）
      if (m.images.isNotEmpty) {
        for (final img in m.images) {
          sb.writeln('![image](img.url)'.replaceFirst('img.url', img.url));
        }
      }
      if (m.interrupted) {
        sb.writeln();
        sb.writeln('_(stopped)_');
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

  /// 渲染为自包含 HTML 文件内容（内嵌样式；代码块 pre 保留格式；思考内容折叠）。
  static String sessionToHtml(ChatSession session) {
    final sb = StringBuffer();
    sb.writeln('<!DOCTYPE html>');
    sb.writeln('<html lang="zh-CN">');
    sb.writeln('<head>');
    sb.writeln('<meta charset="utf-8">');
    sb.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
    sb.writeln('<title>${_escapeHtml(session.title)}</title>');
    sb.writeln('<style>');
    sb.writeln('body{max-width:820px;margin:0 auto;padding:24px 20px;'
        'font-family:"Noto Sans SC","Microsoft YaHei",sans-serif;'
        'line-height:1.7;color:#1f2430;background:#fafbfc}');
    sb.writeln('h1{font-size:22px;border-bottom:1px solid #e5e7eb;padding-bottom:10px}');
    sb.writeln('.meta{color:#6b7280;font-size:12.5px;margin-bottom:24px}');
    sb.writeln('.msg{margin:14px 0;padding:12px 14px;border-radius:10px;'
        'white-space:pre-wrap;word-break:break-word}');
    sb.writeln('.user{background:#eef2ff;border-left:3px solid #6366f1}');
    sb.writeln('.assistant{background:#f3f0ff;border-left:3px solid #8b5cf6}');
    sb.writeln('.role{font-weight:600;font-size:13px;color:#4b5563;margin-bottom:4px}');
    sb.writeln('pre{background:#f4f5f7;border:1px solid #e5e7eb;border-radius:8px;'
        'padding:10px;overflow-x:auto;font-size:13px}');
    sb.writeln('details{margin:6px 0 10px;color:#6b7280;font-size:13px}');
    sb.writeln('summary{cursor:pointer;color:#7c3aed}');
    sb.writeln('</style>');
    sb.writeln('</head>');
    sb.writeln('<body>');
    sb.writeln('<h1>${_escapeHtml(session.title)}</h1>');
    sb.writeln('<div class="meta">Exported: ${_formatDateTime(DateTime.now())}'
        ' · ${session.messages.length} messages</div>');
    if (session.options.systemPrompt.trim().isNotEmpty) {
      sb.writeln('<div class="msg"><div class="role">System Prompt</div>'
          '<pre>${_escapeHtml(session.options.systemPrompt.trim())}</pre></div>');
    }
    for (final m in session.messages) {
      if (m.content.trim().isEmpty && m.images.isEmpty) continue;
      final isUser = m.role == 'user';
      sb.writeln('<div class="msg ${isUser ? 'user' : 'assistant'}">');
      sb.writeln('<div class="role">${isUser ? 'User' : 'Nona'}</div>');
      if (m.reasoningContent.isNotEmpty) {
        sb.writeln('<details><summary>Reasoning</summary>'
            '<pre>${_escapeHtml(m.reasoningContent.trim())}</pre></details>');
      }
      if (m.content.trim().isNotEmpty) {
        sb.writeln(_escapeHtml(m.content.trim()));
      }
      if (m.images.isNotEmpty) {
        // 图片内嵌展示：ChatImage.url 为 data URL（本地）或远程 URL
        for (final img in m.images) {
          sb.writeln('<img src="${_escapeHtml(img.url)}" '
              'style="max-width:320px;border-radius:8px;margin:6px 0">');
        }
      }
      if (m.interrupted) {
        sb.writeln('<div class="meta">(stopped)</div>');
      }
      sb.writeln('</div>');
    }
    sb.writeln('</body>');
    sb.writeln('</html>');
    return sb.toString();
  }

  /// 导出为 HTML 文件（桌面端弹出保存对话框）。
  static Future<String?> exportHtmlToFile(ChatSession session) async {
    final data = sessionToHtml(session);
    return storage_io.saveTextFile(
      suggestedName: '${_safeFileName(session.title)}.html',
      data: data,
      extension: 'html',
      mimeType: 'text/html',
    );
  }

  /// 导出为 JSON 文件（可被 ImportService 恢复）。
  static Future<String?> exportJsonToFile(ChatSession session) async {
    final data = jsonEncode(session.toJson());
    return storage_io.saveTextFile(
      suggestedName: '${_safeFileName(session.title)}.json',
      data: data,
      extension: 'json',
      mimeType: 'application/json',
    );
  }

  /// 将会话复制为 Markdown 到剪贴板。
  static Future<void> copyAsMarkdown(ChatSession session) async {
    await Clipboard.setData(ClipboardData(text: sessionToMarkdown(session)));
  }

  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _safeFileName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    return cleaned.isEmpty ? 'conversation' : cleaned;
  }

  static String _formatDateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/chat_session.dart';
import '../storage_io_io.dart'
    if (dart.library.js_interop) '../storage_io_stub.dart'
    as storage_io;

/// 会话 PDF 导出：构建 PDF 字节与落盘。
class PdfExporter {
  /// 导出为 PDF 文件（桌面端弹出保存对话框 / 移动端回退写入目录）。
  static Future<String?> exportPdfToFile(ChatSession session) async {
    final bytes = await buildSessionPdf(session);
    return storage_io.saveBytesFile(
      suggestedName: '${_safeFileName(session.title)}.pdf',
      data: bytes,
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
  }

  /// 构建会话 PDF 字节（内置 Noto Sans SC 子集字体，中文可正确渲染）。
  static Future<Uint8List> buildSessionPdf(ChatSession session) async {
    final fontData = await rootBundle
        .load('assets/fonts/NotoSansSC-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Text(
          session.title,
          style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            session.title,
            style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Exported: ${_formatDateTime(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          if (session.options.systemPrompt.trim().isNotEmpty) ...[
            _role(font, 'System Prompt'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                session.options.systemPrompt.trim(),
                style: pw.TextStyle(font: font, fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          for (final m in session.messages)
            if (m.content.trim().isNotEmpty || m.images.isNotEmpty) ...[
              // PDF 内置字体无 emoji 字形，角色标签使用纯文本
              _role(font, m.role == 'user' ? 'User' : 'Nona'),
              if (m.reasoningContent.isNotEmpty) ...[
                pw.Text(
                  'Reasoning:',
                  style: pw.TextStyle(font: font, fontSize: 10.5, color: PdfColors.purple600),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, bottom: 6),
                  child: pw.Text(
                    m.reasoningContent.trim(),
                    style: pw.TextStyle(font: font, fontSize: 10.5, color: PdfColors.grey700),
                  ),
                ),
              ],
              if (m.content.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Text(
                    m.content.trim(),
                    style: pw.TextStyle(font: font, fontSize: 11.5, height: 1.6),
                  ),
                ),
              if (m.images.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Text(
                    '[image x${m.images.length}]',
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                  ),
                ),
              pw.SizedBox(height: 12),
            ],
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _role(pw.Font font, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo700,
        ),
      ),
    );
  }

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

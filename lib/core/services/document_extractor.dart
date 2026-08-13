import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:pdfrx/pdfrx.dart';

import '../utils/logger.dart';

/// 一个附加文档（名称 + 提取的文本）。
class ChatDocument {
  final String name;
  final String text;

  const ChatDocument({required this.name, required this.text});
}

/// 文档文本提取器：PDF / DOCX / TXT / Markdown。
class DocumentExtractor {
  /// 单文档最大字节数（防止超大文件撑爆内存；PDF 另有页数上限）。
  static const int maxBytes = 50 * 1024 * 1024;

  /// 按扩展名提取文本；不支持的格式或提取失败返回 null。
  static Future<String?> extract({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (bytes.length > maxBytes) {
      Logger.warn('document', 'document over size limit skipped: ${bytes.length}');
      return null;
    }
    final ext = fileName.split('.').last.toLowerCase();
    try {
      switch (ext) {
        case 'pdf':
          return _extractPdf(bytes);
        case 'docx':
          return _extractDocx(bytes);
        case 'txt':
        case 'md':
        case 'markdown':
        case 'json':
        case 'csv':
        case 'log':
          return _decodeText(bytes);
        default:
          return null;
      }
    } catch (e) {
      Logger.warn('document', 'document extraction failed: $e');
      Logger.error('document', 'extraction error', e);
      return null;
    }
  }

  /// 文本解码：去 UTF-8 BOM → 严格 UTF-8 → GBK 回退（Windows 中文 TXT
  /// 常见编码）→ 宽容解码。
  static String _decodeText(List<int> bytes) {
    var data = bytes;
    if (data.length >= 3 &&
        data[0] == 0xEF &&
        data[1] == 0xBB &&
        data[2] == 0xBF) {
      data = data.sublist(3);
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      try {
        return gbk.decode(data);
      } catch (_) {
        return utf8.decode(data, allowMalformed: true);
      }
    }
  }

  /// PDF 文本提取（pdfrx 纯 Dart 解析，最多前 200 页）。
  static Future<String?> _extractPdf(List<int> bytes) async {
    final doc = await PdfDocument.openData(Uint8List.fromList(bytes));
    try {
      final sb = StringBuffer();
      final pageCount = doc.pages.length.clamp(0, 200);
      for (var i = 0; i < pageCount; i++) {
        final page = await doc.pages[i].ensureLoaded();
        final raw = await page.loadText();
        final text = raw?.fullText ?? '';
        if (text.trim().isNotEmpty) {
          sb.writeln(text);
          sb.writeln('\n--- page ${i + 1} ---\n');
        }
      }
      final result = sb.toString().trim();
      return result.isEmpty ? null : result;
    } finally {
      unawaited(doc.dispose());
    }
  }

  /// DOCX 文本提取：解 zip 读 word/document.xml 的 w:t 节点。
  static String? _extractDocx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.find('word/document.xml');
    if (entry == null) return null;
    final xml = utf8.decode(entry.content as List<int>, allowMalformed: true);
    final sb = StringBuffer();
    // 提取 <w:t>...</w:t> 文本；段落 <w:p> 结束加换行
    // （<w:p> 可能无属性，如最小化生成的 OOXML，不能只匹配 `<w:p `）
    final textRe = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
    final paraRe = RegExp(r'<w:p(?=[\s>])');
    var lastParagraphEnd = -1;
    for (final m in textRe.allMatches(xml)) {
      // 若段落标记 <w:p 出现在该文本之前，补换行
      final paraIdx = xml.lastIndexOf(paraRe, m.start);
      if (paraIdx > lastParagraphEnd && sb.isNotEmpty) {
        sb.writeln();
      }
      if (paraIdx > lastParagraphEnd) lastParagraphEnd = m.end;
      sb.write(_unescapeXml(m.group(1)!));
    }
    final result = sb.toString().trim();
    return result.isEmpty ? null : result;
  }

  static String _unescapeXml(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  /// 是否为支持的文档类型。
  static bool isSupported(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return const {
      'pdf',
      'docx',
      'txt',
      'md',
      'markdown',
      'json',
      'csv',
      'log',
    }.contains(ext);
  }
}

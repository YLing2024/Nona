import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/services/document_extractor.dart';

void main() {
  group('DocumentExtractor', () {
    test('TXT 文本直接解码', () async {
      final text = await DocumentExtractor.extract(
        fileName: 'note.txt',
        bytes: utf8.encode('你好，世界'),
      );
      expect(text, '你好，世界');
    });

    test('MD 文本直接解码', () async {
      final text = await DocumentExtractor.extract(
        fileName: 'readme.md',
        bytes: utf8.encode('# 标题\n正文'),
      );
      expect(text, contains('# 标题'));
    });

    test('DOCX 提取 w:t 文本（含段落换行）', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'word/document.xml',
            '<?xml version="1.0"?>'
            '<w:document xmlns:w="http://schemas.openxmlformats.org/'
            'wordprocessingml/2006/main">'
            '<w:body>'
            '<w:p><w:r><w:t>第一段内容</w:t></w:r></w:p>'
            '<w:p><w:r><w:t>第二段 &amp; 特殊字符</w:t></w:r></w:p>'
            '</w:body></w:document>',
          ),
        );
      final bytes = ZipEncoder().encode(archive);

      final text = await DocumentExtractor.extract(
        fileName: 'doc.docx',
        bytes: bytes,
      );
      expect(text, isNotNull);
      expect(text, contains('第一段内容'));
      expect(text, contains('第二段 & 特殊字符'));
    });

    test('不支持的类型返回 null', () async {
      final text = await DocumentExtractor.extract(
        fileName: 'a.exe',
        bytes: [1, 2, 3],
      );
      expect(text, isNull);
    });

    test('isSupported 判断', () {
      expect(DocumentExtractor.isSupported('a.pdf'), isTrue);
      expect(DocumentExtractor.isSupported('b.docx'), isTrue);
      expect(DocumentExtractor.isSupported('c.md'), isTrue);
      expect(DocumentExtractor.isSupported('d.exe'), isFalse);
      expect(DocumentExtractor.isSupported('e.PDF'), isTrue, reason: '大小写不敏感');
    });
  });
}

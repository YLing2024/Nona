import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/document_extractor.dart';

/// 待发送附件队列：图片 / 文档的选择、提取与增删。
///
/// 持有 [images] / [documents] 两个待发送列表；状态变化通过
/// [onStateChanged] 通知，提示条走 [onSnack]。
class AttachmentManager {
  /// 单张图片体积上限（内存与存储保护，超大图拒绝添加）。
  static const int kMaxImageBytes = 8 * 1024 * 1024;

  /// 待发送的图片附件。
  List<ChatImage> images = [];

  /// 待发送的文档附件。
  List<ChatDocument> documents = [];

  /// 通知宿主刷新界面。
  final VoidCallback? onStateChanged;

  /// 展示提示条。
  final void Function(String message)? onSnack;

  /// 当前本地化文案（宿主每次刷新后取最新值）。
  final AppLocalizations? Function()? l10n;

  AttachmentManager({
    this.onStateChanged,
    this.onSnack,
    this.l10n,
  });

  /// 打开系统文件选择器选取图片（多选），转为 Data URL 加入待发送列表。
  Future<void> pickImages() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
      mimeTypes: ['image/*'],
    );
    final files = await openFiles(acceptedTypeGroups: const [typeGroup]);
    if (files.isEmpty) return;
    final added = <ChatImage>[];
    var skipped = 0;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        // 超大图片拒绝：防止 base64 驻留内存与持久化文件暴涨
        if (bytes.length > kMaxImageBytes) {
          skipped++;
          continue;
        }
        final mime = mimeFromName(file.name);
        final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        added.add(ChatImage(url: dataUrl, mimeType: mime));
      } catch (_) {
        // 跳过读取失败的图片
      }
    }
    if (added.isEmpty) {
      if (skipped > 0) {
        onSnack?.call(
          l10n?.call()?.homeImageTooLargeSkippedAll ?? 'Image over 8MB, skipped',
        );
      }
      return;
    }
    images = [...images, ...added];
    if (skipped > 0) {
      onSnack?.call(
        l10n?.call()?.homeImageTooLargeSkippedSome ?? 'Some images over 8MB, skipped',
      );
    }
    onStateChanged?.call();
  }

  /// 选择并提取文档附件（PDF/DOCX/TXT），提取失败提示。
  Future<void> pickDocuments() async {
    const typeGroup = XTypeGroup(
      label: 'Document',
      extensions: ['pdf', 'docx', 'txt', 'md', 'json', 'csv', 'log'],
      mimeTypes: [
        'application/pdf',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
      ],
    );
    final files = await openFiles(acceptedTypeGroups: const [typeGroup]);
    if (files.isEmpty) return;
    final added = <ChatDocument>[];
    var failed = 0;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final text = await DocumentExtractor.extract(
          fileName: file.name,
          bytes: bytes,
        );
        if (text == null || text.trim().isEmpty) {
          failed++;
          continue;
        }
        added.add(ChatDocument(name: file.name, text: text.trim()));
      } catch (_) {
        failed++;
      }
    }
    if (added.isNotEmpty) {
      documents = [...documents, ...added];
    }
    if (failed > 0) {
      onSnack?.call(
        l10n?.call()?.chatDocumentFailed(failed) ??
            '$failed document(s) failed to parse',
      );
    }
    onStateChanged?.call();
  }

  /// 追加一张待发送图片。
  void addImageUrl(ChatImage image) {
    images = [...images, image];
    onStateChanged?.call();
  }

  /// 移除指定位置的待发送图片（越界安全）。
  void removePendingImage(int index) {
    if (index < 0 || index >= images.length) return;
    images = List.of(images)..removeAt(index);
    onStateChanged?.call();
  }

  /// 移除指定位置的待发送文档（越界安全）。
  void removePendingDocument(int index) {
    if (index < 0 || index >= documents.length) return;
    documents = List.of(documents)..removeAt(index);
    onStateChanged?.call();
  }

  /// 按文件名推断图片 MIME 类型。
  static String mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/*',
    };
  }
}

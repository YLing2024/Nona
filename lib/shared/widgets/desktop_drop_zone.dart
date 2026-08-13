import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/services/document_extractor.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../features/chat/controllers/attachment_manager.dart';

/// A-03：桌面文件拖放（home 壳层包裹）。
///
/// 按扩展名分派：图片 → 待发图片；PDF/DOCX/TXT/MD 等 → 文档附件；
/// `.zip` / `.nona` → 备份恢复（走 [onRestoreBackup]）。
class DesktopDropZone extends StatelessWidget {
  final Widget child;
  final AttachmentManager attachmentManager;

  /// 备份恢复回调（bytes, fileName）；null 时拖入备份仅提示。
  final Future<void> Function(Uint8List bytes, String fileName)?
      onRestoreBackup;

  const DesktopDropZone({
    super.key,
    required this.child,
    required this.attachmentManager,
    this.onRestoreBackup,
  });

  static const _imageExts = {
    'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'svg',
  };
  static const _docExts = {'pdf', 'docx', 'txt', 'md', 'json', 'csv', 'log'};

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) async {
        for (final file in details.files) {
          await _handleFile(context, file);
        }
      },
      child: child,
    );
  }

  Future<void> _handleFile(BuildContext context, XFile file) async {
    final name = file.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : '';
    try {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      if (ext == 'zip' || ext == 'nona') {
        final restore = onRestoreBackup;
        if (restore == null) {
          showAppSnack(
            context,
            AppLocalizations.of(context).dropBackupUnsupported,
          );
          return;
        }
        await restore(bytes, file.name);
        return;
      }
      if (_imageExts.contains(ext)) {
        await _attachImage(context, file, bytes);
        return;
      }
      if (_docExts.contains(ext)) {
        await _attachDocument(context, file, bytes);
        return;
      }
      Logger.warn('drop', 'unsupported file dropped: ${file.name}');
      showAppSnack(context, AppLocalizations.of(context).dropUnsupported);
    } catch (e) {
      Logger.warn('drop', 'drop failed: ${file.name}: $e');
      showAppSnack(context, AppLocalizations.of(context).dropFailed);
    }
  }

  Future<void> _attachImage(
    BuildContext context,
    XFile file,
    Uint8List bytes,
  ) async {
    if (bytes.length > AttachmentManager.kMaxImageBytes) {
      showAppSnack(context, AppLocalizations.of(context).dropImageTooLarge);
      return;
    }
    final mime = AttachmentManager.mimeFromName(file.name);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    attachmentManager.images = [
      ...attachmentManager.images,
      ChatImage(url: dataUrl, mimeType: mime),
    ];
  }

  Future<void> _attachDocument(
    BuildContext context,
    XFile file,
    Uint8List bytes,
  ) async {
    final text = await DocumentExtractor.extract(
      fileName: file.name,
      bytes: bytes,
    );
    if (text == null || text.trim().isEmpty) {
      if (context.mounted) {
        showAppSnack(context, AppLocalizations.of(context).dropExtractFailed);
      }
      return;
    }
    attachmentManager.documents = [
      ...attachmentManager.documents,
      ChatDocument(name: file.name, text: text.trim()),
    ];
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../core/models/chat_provider.dart';
import '../../../core/services/provider_share_codec.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';

/// 服务商分享对话框：分享文本（复制）或 G-02 二维码。
Future<void> showProviderShareDialog(
  BuildContext context,
  ChatProvider provider,
) async {
  final l10n = context.l10n;
  final text = ProviderShareCodec.encode(provider, includeKey: true);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.providerShareTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // G-02：文本 / 二维码 双形态
            DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Text'),
                      Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'QR'),
                    ],
                  ),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.providerShareHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(ctx).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SelectableText(
                                  text,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(l10n.commonCopy),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: text));
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(l10n.networkLogCopiedFull)),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // G-02：二维码
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: PrettyQrView.data(
                              data: text,
                              decoration: const PrettyQrDecoration(
                                shape: PrettyQrSmoothSymbol(
                                  color: Color(0xFF1F2430),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}

/// 从分享文本导入服务商：粘贴文本 → 解析 → 返回配置。
Future<ChatProvider?> showProviderImportDialog(BuildContext context) async {
  final l10n = context.l10n;
  final controller = TextEditingController();
  final result = await showDialog<ChatProvider?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.providerImportTitle),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          onTapOutside: unfocusOnTap,
          decoration: InputDecoration(
            hintText: l10n.providerImportHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final provider = ProviderShareCodec.decode(controller.text);
            if (provider == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.providerImportInvalid)),
              );
              return;
            }
            Navigator.of(ctx).pop(provider);
          },
          child: Text(l10n.commonImport),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// 编码 JSON 便于调试展示。
String prettyJson(Object? data) =>
    const JsonEncoder.withIndent('  ').convert(data);

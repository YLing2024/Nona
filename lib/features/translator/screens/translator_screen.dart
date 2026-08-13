import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_options.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/stream_flusher.dart';

/// AI 翻译页：调用当前默认模型进行流式翻译。
class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _sourceController = TextEditingController();
  String _target = 'en';
  String _result = '';
  bool _translating = false;
  ChatRequestHandle? _handle;

  /// 流式增量帧级批处理：逐 chunk 只累积，每帧最多一次 setState。
  late final StreamFlusher _flusher = StreamFlusher(
    onFlush: (s) {
      if (mounted) setState(() => _result += s);
    },
  );

  /// 目标语言代码 → 本地化显示名（跟随界面语言）。
  String _targetLabel(AppLocalizations l10n, String code) => switch (code) {
    'en' => l10n.translatorLangEn,
    'zh' => l10n.translatorLangZh,
    'ja' => l10n.translatorLangJa,
    'ko' => l10n.translatorLangKo,
    'fr' => l10n.translatorLangFr,
    'de' => l10n.translatorLangDe,
    'es' => l10n.translatorLangEs,
    'ru' => l10n.translatorLangRu,
    _ => code,
  };

  static const _targetCodes = ['en', 'zh', 'ja', 'ko', 'fr', 'de', 'es', 'ru'];

  @override
  void dispose() {
    _handle?.cancel();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final source = _sourceController.text.trim();
    if (source.isEmpty || _translating) return;
    // 同步置位加载态：杜绝 await 窗口内双击并发两个请求
    setState(() {
      _translating = true;
      _result = '';
    });
    try {
      final providerService = context.read<ProviderService>();
      final settingsService = context.read<SettingsService>();
      final chatService = context.read<ChatService>();
      final l10n = context.l10n;
      final providers = await providerService.load();
      final settings = await settingsService.load();
      // 优先使用翻译专用模型，未配置时回退到全局聊天模型
      final modelId = settings.translatorModel.isNotEmpty
          ? settings.translatorModel
          : settings.chatModel;
      final provider = providers
          .where((p) => p.modelIds.contains(modelId))
          .firstOrNull;
      if (provider == null) {
        if (mounted) {
          showAppSnack(context, context.l10n.translatorNoModel);
        }
        return;
      }
      final targetName = _targetLabel(l10n, _target);
      final handle = chatService.sendChat(
        settings: AppSettings(
          apiKey: provider.apiKey,
          baseUrl: provider.baseUrl,
          model: modelId,
          providerKind: provider.kind.name,
        ),
        messages: [
          ChatMessage(
            role: 'user',
            content: l10n.translatorPrompt(targetName, source),
          ),
        ],
        options: const ChatOptions(
          stream: true,
          temperature: 0.3,
        ),
        // 与聊天一致：需要自定义头/请求体的服务商也能在翻译页用
        customHeaders: provider.customHeaders.isEmpty
            ? null
            : provider.customHeaders,
        customBody: provider.customBody,
        onPartial: _flusher.add,
      );
      _handle = handle;
      final result = await handle.result;
      // 冲刷尾部增量（避免 finally 重复追加；随后覆盖为完整内容）
      _flusher.flushNow();
      if (mounted) setState(() => _result = result.content);
    } on ChatCancelledException {
      // 用户主动停止：保留已生成的译文，不提示失败
    } catch (_) {
      if (mounted) {
        showAppSnack(context, context.l10n.translatorFailed);
      }
    } finally {
      // 异常/取消路径：冲刷剩余增量，保留已生成部分
      _flusher.flushNow();
      if (mounted) setState(() => _translating = false);
      _handle = null;
    }
  }

  void _stop() {
    _handle?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translatorTitle),
        actions: [
          if (_result.isNotEmpty && !_translating)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: l10n.commonCopy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result));
                showAppSnack(context, context.l10n.networkLogCopiedFull);
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translatorTarget,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                DropdownButton<String>(
                  value: _target,
                  items: [
                    for (final code in _targetCodes)
                      DropdownMenuItem(
                        value: code,
                        child: Text(_targetLabel(l10n, code)),
                      ),
                  ],
                  onChanged: _translating
                      ? null
                      : (v) => setState(() => _target = v ?? 'en'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceController,
              maxLines: 8,
              onTapOutside: unfocusOnTap,
              decoration: InputDecoration(
                hintText: l10n.translatorSourceHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: _translating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate_rounded, size: 18),
                    label: Text(
                      _translating
                          ? l10n.translatorTranslating
                          : l10n.translatorTranslate,
                    ),
                    onPressed: _translating ? null : _translate,
                  ),
                ),
                if (_translating) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _stop,
                    child: Text(l10n.commonStop),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_result.isNotEmpty) ...[
              Text(
                l10n.translatorResult,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _result,
                  style: const TextStyle(fontSize: 14.5, height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

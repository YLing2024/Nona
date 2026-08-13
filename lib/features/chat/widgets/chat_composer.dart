import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/services/quick_phrase_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/prompt_variables.dart';
import '../../../core/services/document_extractor.dart' show ChatDocument;
import '../../../core/models/chat_options.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/services/model_resolver.dart';
import 'composer_attachment_preview.dart';
import 'composer_buttons.dart';
import 'composer_input_field.dart';
import 'composer_toolbar.dart';

/// 聊天输入区：工具条（模型/思考强度/流式/图片）+ 输入框 + 发送↔停止。
///
/// 各区域委托独立组件：
/// - [ComposerToolbar]：模型 / 思考强度 / 流式 / 附件入口
/// - [ComposerInputField]：输入框 + Enter 发送 + 粘贴图片识别
/// - [AttachmentPreview]：待发图 / 文档预览
/// - [ContextStatsBar]：token 用量统计条
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final List<ChatProvider> providers;
  final String? providerId;
  final String? modelId;
  final ChatOptions options;
  final bool isLoading;

  /// 待发送的图片附件（发送后由父级清空）。
  final List<ChatImage> pendingImages;

  /// 打开系统文件选择器选取图片（多选）。
  final VoidCallback onPickImages;

  /// 通过剪贴板粘贴/外部链接添加单张图片。
  final void Function(ChatImage image) onAddImageUrl;

  /// 移除指定位置的待发送图片。
  final void Function(int index) onRemoveImage;

  /// 待发送文档附件（PDF/DOCX/TXT 提取文本）。
  final List<ChatDocument> pendingDocuments;
  final VoidCallback onPickDocuments;
  final void Function(int index) onRemoveDocument;

  /// 会话估算 token 数（用于上下文用量提示）。
  final int estimatedTokens;

  /// 有效上下文上限（tokens）：显式配置或按模型推断的窗口，null 表示未知。
  final int? contextLimit;

  /// 会话累计上行（发送）token 数。
  final int usagePrompt;

  /// 会话累计下行（生成）token 数。
  final int usageCompletion;

  final void Function(String providerId, String modelId) onModelChanged;
  final void Function(String? reasoningEffort) onEffortChanged;
  final void Function(bool stream) onStreamChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;

  /// 偏好：Enter 是否发送消息（否则 Enter 换行、Ctrl+Enter 发送）。
  final bool sendOnEnter;

  /// G-04：快捷短语加载器（null 时禁用 `/` 菜单）。
  final Future<List<QuickPhrase>> Function(String? agentId)? quickPhrasesLoader;

  /// 当前 Agent id（快捷短语按 Agent 过滤）。
  final String? agentId;

  /// 当 [modelId] 为 null 时是否自动选择第一个模型。
  /// 为 false 时返回 null，显示「未选择模型」。
  final bool autoSelectModel;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.providers,
    required this.providerId,
    required this.modelId,
    required this.options,
    required this.isLoading,
    required this.estimatedTokens,
    this.contextLimit,
    required this.onModelChanged,
    required this.onEffortChanged,
    required this.onStreamChanged,
    required this.onSend,
    required this.onStop,
    required this.sendOnEnter,
    required this.usagePrompt,
    required this.usageCompletion,
    required this.pendingImages,
    required this.onPickImages,
    required this.onAddImageUrl,
    required this.onRemoveImage,
    this.pendingDocuments = const [],
    this.onPickDocuments = _noop,
    this.onRemoveDocument = _noopIndex,
    this.autoSelectModel = true,
    this.quickPhrasesLoader,
    this.agentId,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final GlobalKey _inputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  /// G-04：`/` 触发快捷短语菜单（输入框上方 Popover 风格菜单）。
  Future<void> _showQuickPhrases() async {
    final loader = widget.quickPhrasesLoader;
    if (loader == null) return;
    final phrases = await loader(widget.agentId);
    if (!mounted || phrases.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final inputBox = _inputKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || inputBox == null) return;
    final topLeft = inputBox.localToGlobal(Offset.zero);
    final bottomRight =
        inputBox.localToGlobal(inputBox.size.bottomRight(Offset.zero));
    final selected = await showMenu<QuickPhrase>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final p in phrases)
          PopupMenuItem(
            value: p,
            child: SizedBox(
              width: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    p.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    if (selected == null || !mounted) return;
    // 替换输入：移除「/」前缀后插入短语内容（展开变量）
    final text = widget.controller.text;
    final base = text.startsWith('/')
        ? text.substring(1).trimLeft()
        : text;
    final content = PromptVariables.resolve(selected.content);
    widget.controller.text = base.isEmpty ? content : '$base $content';
    widget.controller.value = widget.controller.value.copyWith(
      text: widget.controller.text,
      selection: TextSelection.collapsed(offset: widget.controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 有效上下文上限：显式配置或模型推断的窗口（由上层传入）
    final contextLimit = widget.contextLimit ??
        (widget.options.maxContextTokens != null &&
                widget.options.maxContextTokens! > 0
            ? widget.options.maxContextTokens
            : null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ComposerToolbar(
              providers: widget.providers,
              providerId: widget.providerId,
              modelId: widget.modelId,
              options: widget.options,
              isLoading: widget.isLoading,
              hasPendingImages: widget.pendingImages.isNotEmpty,
              hasPendingDocuments: widget.pendingDocuments.isNotEmpty,
              onModelChanged: widget.onModelChanged,
              onEffortChanged: widget.onEffortChanged,
              onStreamChanged: widget.onStreamChanged,
              onPickImages: widget.onPickImages,
              onPickDocuments: widget.onPickDocuments,
              autoSelectModel: widget.autoSelectModel,
            ),
          ),
          const SizedBox(height: 6),
          if (widget.pendingDocuments.isNotEmpty ||
              widget.pendingImages.isNotEmpty)
            AttachmentPreview(
              images: widget.pendingImages,
              documents: widget.pendingDocuments,
              onRemoveImage: widget.onRemoveImage,
              onRemoveDocument: widget.onRemoveDocument,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: _inputKey,
                  child: ComposerInputField(
                    controller: widget.controller,
                    enabled: !widget.isLoading,
                    sendOnEnter: widget.sendOnEnter,
                    onSend: () => widget.onSend(),
                    onAddImageUrl: widget.onAddImageUrl,
                    onQuickPhraseTriggered: widget.quickPhrasesLoader == null
                        ? null
                        : _showQuickPhrases,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.controller.text.isNotEmpty)
                ComposerIconButton(
                  icon: Icons.backspace_outlined,
                  tooltip: context.l10n.chatClearInput,
                  onTap: () => widget.controller.clear(),
                ),
              const SizedBox(width: 4),
              if (widget.isLoading)
                StopButton(onTap: widget.onStop)
              else
                SendButton(onTap: widget.onSend, enabled: _modelSelected()),
            ],
          ),
          // 输入框下方的 token 统计信息（横向可滚动、靠左对齐）
          if (widget.estimatedTokens > 0 ||
              widget.usagePrompt > 0 ||
              widget.usageCompletion > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ContextStatsBar(
                estimatedTokens: widget.estimatedTokens,
                contextLimit: contextLimit,
                usagePrompt: widget.usagePrompt,
                usageCompletion: widget.usageCompletion,
              ),
            ),
        ],
      ),
    );
  }

  /// 是否有可发送的模型（与工具栏的模型解析保持一致）。
  bool _modelSelected() {
    final resolution = resolveFirstAvailable(
      widget.providers,
      providerId: widget.providerId,
      modelId: widget.modelId,
      autoSelect: widget.autoSelectModel,
    );
    final provider = resolution.provider;
    if (provider == null || provider.modelIds.isEmpty) return false;
    if (resolution.modelId != null) return true;
    return widget.autoSelectModel;
  }
}

/// 默认空实现（未接线时安全降级）。
void _noop() {}
void _noopIndex(int index) {}

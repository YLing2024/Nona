import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/l10n_ext.dart';
import '../models/chat_message.dart';
import '../services/document_extractor.dart' show ChatDocument;
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import '../services/model_resolver.dart';
import '../theme/app_theme.dart';
import 'chat_composer.dart';
import 'message_list.dart';
import 'summary_card.dart';

/// 聊天主视图：页头 + 消息流 + 输入区。
class ChatView extends StatelessWidget {
  final ChatSession? session;
  final List<ChatProvider> providers;
  final bool isLoading;
  final int? streamingIndex;
  final int estimatedTokens;

  /// 有效上下文上限（显式配置或按模型推断），用于用量展示与超限提示。
  final int? contextLimit;

  /// 会话累计上行/下行 token。
  final (int, int) sessionUsage;

  final bool sendOnEnter;
  final bool autoSelectModel;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final bool showSidebarToggle;
  final VoidCallback onToggleSidebar;
  final VoidCallback onOpenContextSettings;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final Future<void> Function() onExportMarkdown;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onExportHtml;
  final Future<void> Function() onExportPdf;
  final Future<void> Function() onCopyMarkdown;
  final VoidCallback onNewSession;
  final void Function(String providerId, String modelId) onModelChanged;
  final void Function(String? effort) onEffortChanged;
  final void Function(bool stream) onStreamChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;

  /// 待发送图片附件与相关操作。
  final List<ChatImage> pendingImages;
  final VoidCallback onPickImages;
  final List<ChatDocument> pendingDocuments;
  final VoidCallback onPickDocuments;
  final void Function(int index) onRemoveDocument;
  final void Function(ChatImage image) onAddImageUrl;
  final void Function(int index) onRemoveImage;

  /// 正在朗读的消息标识与朗读切换。
  final int? speakingMessageId;
  final void Function(ChatMessage message) onMessageSpeak;

  /// 进入后定位到的消息索引（搜索结果跳转）与完成回调。
  final int? initialScrollIndex;
  final VoidCallback? onScrollTargetHandled;

  final void Function(ChatMessage message) onMessageCopy;
  final void Function(ChatMessage message) onMessageEdit;
  final void Function(ChatMessage message) onMessageRollback;
  final void Function(ChatMessage message) onMessageRollbackVersion;
  final void Function(ChatMessage message) onMessageRegenerate;
  final void Function(ChatMessage message) onMessageDelete;

  /// 打开超长文本消息的文档详情页。
  final void Function(ChatMessage message)? onOpenDocument;

  /// 流式生成期间是否实时渲染 Markdown（设置项，默认开）。
  final bool streamMarkdown;

  /// 超过该字符数的消息折叠为「文本文档」入口；0 表示不折叠。
  final int documentThreshold;

  /// 摘要压缩条（F3-1）：编辑摘要 / 清空压缩记录。
  final void Function(String summary)? onSummaryEdited;
  final VoidCallback? onClearCompaction;

  /// F1-5：图片消息「转为文字」。
  final void Function(ChatMessage message)? onOcr;

  const ChatView({
    super.key,
    required this.session,
    required this.providers,
    required this.isLoading,
    required this.streamingIndex,
    required this.estimatedTokens,
    this.contextLimit,
    required this.sessionUsage,
    required this.sendOnEnter,
    this.autoSelectModel = true,
    required this.scrollController,
    required this.inputController,
    required this.showSidebarToggle,
    required this.onToggleSidebar,
    required this.onOpenContextSettings,
    required this.onRename,
    required this.onDelete,
    required this.onExportMarkdown,
    required this.onExportJson,
    required this.onExportHtml,
    required this.onExportPdf,
    required this.onCopyMarkdown,
    required this.onNewSession,
    required this.onModelChanged,
    required this.onEffortChanged,
    required this.onStreamChanged,
    required this.onSend,
    required this.onStop,
    required this.pendingImages,
    required this.onPickImages,
    this.pendingDocuments = const [],
    this.onPickDocuments = _noopDoc,
    this.onRemoveDocument = _noopDocIndex,
    required this.onAddImageUrl,
    required this.onRemoveImage,
    required this.speakingMessageId,
    required this.onMessageSpeak,
    this.initialScrollIndex,
    this.onScrollTargetHandled,
    required this.onMessageCopy,
    required this.onMessageEdit,
    required this.onMessageRollback,
    required this.onMessageRollbackVersion,
    required this.onMessageRegenerate,
    required this.onMessageDelete,
    this.onOpenDocument,
    this.streamMarkdown = true,
    this.documentThreshold = 40000,
    this.onSummaryEdited,
    this.onClearCompaction,
    this.onOcr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = this.session;

    return Column(
      children: [
        _buildHeader(context, theme, scheme),
        const Divider(height: 1),
        Expanded(
          child: session == null || session.messages.isEmpty
              ? _EmptyState(
                  hasSession: session != null,
                  onNewSession: onNewSession,
                )
              : Column(
                  children: [
                    if (session.summary.trim().isNotEmpty)
                      SummaryCard(
                        session: session,
                        onSummaryEdited: onSummaryEdited,
                        onClear: onClearCompaction,
                      ),
                    Expanded(
                      child: MessageList(
                        // 以消息列表实例作 key：切换会话时重建并重新回到底部
                        key: ValueKey(session.messages),
                        messages: session.messages,
                        streamingIndex: streamingIndex,
                        controller: scrollController,
                        canRegenerate: !isLoading,
                        speakingMessageId: speakingMessageId,
                        initialScrollIndex: initialScrollIndex,
                        onScrollTargetHandled: onScrollTargetHandled,
                        onSpeak: onMessageSpeak,
                        onCopy: onMessageCopy,
                        onEdit: onMessageEdit,
                        onRollback: onMessageRollback,
                        onRollbackVersion: onMessageRollbackVersion,
                        onRegenerate: onMessageRegenerate,
                        onDelete: onMessageDelete,
                        onOpenDocument: onOpenDocument,
                        streamMarkdown: streamMarkdown,
                        documentThreshold: documentThreshold,
                        onOcr: onOcr,
                      ),
                    ),
                  ],
                ),
        ),
        if (session != null)
          ChatComposer(
            controller: inputController,
            providers: providers,
            providerId: session.providerId,
            modelId: session.modelId,
            options: session.options,
            isLoading: isLoading,
            estimatedTokens: estimatedTokens,
            contextLimit: contextLimit,
            usagePrompt: sessionUsage.$1,
            usageCompletion: sessionUsage.$2,
            autoSelectModel: autoSelectModel,
            sendOnEnter: sendOnEnter,
            pendingImages: pendingImages,
            onPickImages: onPickImages,
            pendingDocuments: pendingDocuments,
            onPickDocuments: onPickDocuments,
            onRemoveDocument: onRemoveDocument,
            onAddImageUrl: onAddImageUrl,
            onRemoveImage: onRemoveImage,
            onModelChanged: onModelChanged,
            onEffortChanged: onEffortChanged,
            onStreamChanged: onStreamChanged,
            onSend: onSend,
            onStop: onStop,
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final AppLocalizations l10n = context.l10n;
    final session = this.session;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (showSidebarToggle)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: l10n.chatSessionList,
              onPressed: onToggleSidebar,
            ),
          Expanded(
            child: InkWell(
              onTap: session == null ? null : onRename,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            session?.title ?? l10n.appTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (session != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: scheme.outline,
                          ),
                        ],
                      ],
                    ),
                    if (session != null)
                      Text(
                        _modelLabel(context, session),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: scheme.outline),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (session != null) ...[
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: l10n.chatSessionContext,
              onPressed: onOpenContextSettings,
            ),
            MenuAnchor(
              alignmentOffset: const Offset(0, 6),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.description_outlined, size: 17),
                  onPressed: onExportMarkdown,
                  child: Text(l10n.chatExportMarkdown,
                      style: const TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.html_rounded, size: 17),
                  onPressed: onExportHtml,
                  child: Text(l10n.chatExportHtml,
                      style: const TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  onPressed: onExportPdf,
                  child: Text(l10n.chatExportPdf,
                      style: const TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.data_object_rounded, size: 17),
                  onPressed: onExportJson,
                  child: Text(l10n.chatExportJson,
                      style: const TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.copy_all_outlined, size: 17),
                  onPressed: onCopyMarkdown,
                  child: Text(l10n.chatCopyMarkdown,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
              builder: (context, controller, child) => IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: l10n.chatExport,
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.chatDeleteSession,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  String _modelLabel(BuildContext context, ChatSession session) {
    final resolution = resolveFirstAvailable(
      providers,
      providerId: session.providerId,
      modelId: session.modelId,
    );
    final p = resolution.provider;
    if (p == null) return context.l10n.chatNoProvider;
    final model = resolution.modelId;
    if (model == null) return '${p.name} · ${context.l10n.chatNoModel}';
    return providers.length > 1 ? '${p.name} · $model' : model;
  }
}

/// 空状态：品牌 hero + 快捷入口。
class _EmptyState extends StatelessWidget {
  final bool hasSession;
  final VoidCallback onNewSession;

  const _EmptyState({
    required this.hasSession,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: kBrandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.chatHelloTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.chatHelloSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewSession,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(context.l10n.chatNewSession),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _noopDoc() {}
void _noopDocIndex(int index) {}

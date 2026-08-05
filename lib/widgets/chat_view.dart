import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';
import 'chat_composer.dart';
import 'message_list.dart';

/// 聊天主视图：页头 + 消息流 + 输入区。
class ChatView extends StatelessWidget {
  final ChatSession? session;
  final List<ChatProvider> providers;
  final bool isLoading;
  final int? streamingIndex;
  final int estimatedTokens;

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
  final Future<void> Function() onCopyMarkdown;
  final VoidCallback onNewSession;
  final void Function(String providerId, String modelId) onModelChanged;
  final void Function(String? effort) onEffortChanged;
  final void Function(bool stream) onStreamChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;

  final void Function(ChatMessage message) onMessageCopy;
  final void Function(ChatMessage message) onMessageEdit;
  final void Function(ChatMessage message) onMessageRollback;
  final void Function(ChatMessage message) onMessageRegenerate;
  final void Function(ChatMessage message) onMessageDelete;

  const ChatView({
    super.key,
    required this.session,
    required this.providers,
    required this.isLoading,
    required this.streamingIndex,
    required this.estimatedTokens,
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
    required this.onCopyMarkdown,
    required this.onNewSession,
    required this.onModelChanged,
    required this.onEffortChanged,
    required this.onStreamChanged,
    required this.onSend,
    required this.onStop,
    required this.onMessageCopy,
    required this.onMessageEdit,
    required this.onMessageRollback,
    required this.onMessageRegenerate,
    required this.onMessageDelete,
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
              : MessageList(
                  // 以消息列表实例作 key：切换会话时重建并重新回到底部
                  key: ValueKey(session.messages),
                  messages: session.messages,
                  streamingIndex: streamingIndex,
                  controller: scrollController,
                  canRegenerate: !isLoading,
                  onCopy: onMessageCopy,
                  onEdit: onMessageEdit,
                  onRollback: onMessageRollback,
                  onRegenerate: onMessageRegenerate,
                  onDelete: onMessageDelete,
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
            usagePrompt: sessionUsage.$1,
            usageCompletion: sessionUsage.$2,
            autoSelectModel: autoSelectModel,
            sendOnEnter: sendOnEnter,
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
    final session = this.session;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (showSidebarToggle)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: '会话列表',
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
                            session?.title ?? 'Nona',
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
              tooltip: '会话上下文',
              onPressed: onOpenContextSettings,
            ),
            MenuAnchor(
              alignmentOffset: const Offset(0, 6),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.description_outlined, size: 17),
                  onPressed: onExportMarkdown,
                  child: const Text('导出为 Markdown', style: TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.data_object_rounded, size: 17),
                  onPressed: onExportJson,
                  child: const Text('导出为 JSON', style: TextStyle(fontSize: 13)),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.copy_all_outlined, size: 17),
                  onPressed: onCopyMarkdown,
                  child: const Text('复制为 Markdown', style: TextStyle(fontSize: 13)),
                ),
              ],
              builder: (context, controller, child) => IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: '导出',
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
              tooltip: '删除会话',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  String _modelLabel(BuildContext context, ChatSession session) {
    for (final p in providers) {
      if (p.id == session.providerId && p.modelIds.isNotEmpty) {
        final model = session.modelId ?? p.modelIds.first;
        return providers.length > 1 ? '${p.name} · $model' : model;
      }
    }
    // 默认选择第一个已配置模型的服务商（跳过空的 OpenAI 占位）
    for (final p in providers) {
      if (p.modelIds.isNotEmpty) {
        final model = session.modelId ?? p.modelIds.first;
        return providers.length > 1 ? '${p.name} · $model' : model;
      }
    }
    final first = providers.firstOrNull;
    if (first == null) return '未配置服务商';
    return first.modelIds.isEmpty ? '${first.name} · 未配置模型' : first.modelIds.first;
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
              '你好，我是 Nona',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持多服务商、多模型，开启一段新的对话吧',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewSession,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('新建会话'),
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

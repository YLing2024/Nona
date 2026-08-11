import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../utils/l10n_ext.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/markdown_view.dart';

/// 超长文本（文本文档）消息详情页：全量渲染 Markdown（渲染效果与
/// 气泡内一致），并提供该消息的全部操作：复制 / 朗读 / 编辑 /
/// 回滚（用户消息）/ 重新生成（助手消息）/ 删除。
///
/// 气泡中的文档占位卡只负责入口，朗读与编辑也在本页完成。
class MessageDocumentScreen extends StatefulWidget {
  final ChatMessage message;

  /// 该消息当前是否正在被朗读（进入页面时的状态）。
  final bool speaking;

  final Future<void> Function()? onCopy;
  final Future<void> Function()? onSpeak;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onRollback;
  final Future<void> Function()? onRegenerate;
  final Future<void> Function()? onDelete;

  const MessageDocumentScreen({
    super.key,
    required this.message,
    this.speaking = false,
    this.onCopy,
    this.onSpeak,
    this.onEdit,
    this.onRollback,
    this.onRegenerate,
    this.onDelete,
  });

  @override
  State<MessageDocumentScreen> createState() => _MessageDocumentScreenState();
}

class _MessageDocumentScreenState extends State<MessageDocumentScreen> {
  bool get _isUser => widget.message.role == 'user';

  /// 朗读状态（进入时跟随外部，操作后本地翻转，与 TTS 引擎状态一致）。
  late bool _speaking = widget.speaking;

  /// 执行操作回调；操作可能就地修改消息（编辑/回滚），完成后刷新页面。
  Future<void> _run(Future<void> Function()? action) async {
    await action?.call();
    if (mounted) setState(() {});
  }

  /// 删除会连带删除该消息之后的所有消息，需二次确认（与删除会话一致）。
  Future<void> _confirmDelete() async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.chatDeleteMessageConfirm,
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _run(widget.onDelete);
    if (mounted && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final message = widget.message;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatDocumentTitle),
        actions: [
          // 编辑（用户与助手消息均支持，跳转独立编辑页）
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            onPressed: () => _run(widget.onEdit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.commonDelete,
            color: scheme.error,
            onPressed: () => _confirmDelete(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 正文：与气泡内一致的 MarkdownView 渲染（全量，不截断）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: MarkdownView(
                  data: message.content,
                  maxRenderChars: null,
                ),
              ),
            ),
            // 底部操作栏：复制 / 朗读 / 回滚（用户）/ 重新生成（助手）
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DocAction(
                      icon: Icons.copy_rounded,
                      tooltip: l10n.commonCopy,
                      onTap: () => _run(widget.onCopy),
                    ),
                    _DocAction(
                      icon: _speaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      tooltip: _speaking
                          ? l10n.chatStopSpeaking
                          : l10n.chatSpeak,
                      highlight: _speaking,
                      onTap: () {
                        setState(() => _speaking = !_speaking);
                        _run(widget.onSpeak);
                      },
                    ),
                    if (_isUser && widget.onRollback != null)
                      _DocAction(
                        icon: Icons.undo_rounded,
                        tooltip: l10n.chatRollback,
                        onTap: () async {
                          // 回滚会删除该消息及之后所有消息，
                          // 页面继续展示已删除内容会误导用户，需同步退出
                          await _run(widget.onRollback);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    if (!_isUser && widget.onRegenerate != null)
                      _DocAction(
                        icon: Icons.refresh_rounded,
                        tooltip: message.failed
                            ? l10n.commonRetry
                            : l10n.chatRegenerate,
                        onTap: () async {
                          await _run(widget.onRegenerate);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作栏图标按钮（与气泡内操作图标样式一致）。
class _DocAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlight;

  const _DocAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: highlight ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../utils/focus_utils.dart';
import '../utils/l10n_ext.dart';

/// 消息编辑页。
///
/// 用户消息只编辑正文；助手消息可以同时编辑「思考内容」与「回复内容」。
/// 保存后返回 `(正文, 思考内容)`，由调用方就地写回消息并持久化。
class MessageEditScreen extends StatefulWidget {
  final ChatMessage message;

  const MessageEditScreen({super.key, required this.message});

  @override
  State<MessageEditScreen> createState() => _MessageEditScreenState();
}

class _MessageEditScreenState extends State<MessageEditScreen> {
  late final TextEditingController _contentController;
  late final TextEditingController _reasoningController;

  bool get _isUser => widget.message.role == 'user';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.message.content);
    _reasoningController =
        TextEditingController(text: widget.message.reasoningContent);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _reasoningController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop((
      _contentController.text.trim(),
      _reasoningController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUser ? l10n.messageEditTitle : l10n.messageEditAssistantTitle),
        actions: [
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(l10n.commonSave),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _isUser ? l10n.messageEditNote : l10n.messageEditReasoningNote,
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
            const SizedBox(height: 14),
            if (!_isUser) ...[
              _buildField(
                title: l10n.messageEditReasoningLabel,
                controller: _reasoningController,
                hint: l10n.messageEditReasoningHint,
              ),
              const SizedBox(height: 18),
            ],
            _buildField(
              title: _isUser ? l10n.messageEditUserLabel : l10n.messageEditAssistantLabel,
              controller: _contentController,
              hint: _isUser ? l10n.messageEditUserHint : l10n.messageEditAssistantHint,
              autofocus: _isUser,
              minLines: _isUser ? 5 : 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String title,
    required TextEditingController controller,
    required String hint,
    bool autofocus = false,
    int minLines = 4,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          minLines: minLines,
          maxLines: 18,
          onTapOutside: unfocusOnTap,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

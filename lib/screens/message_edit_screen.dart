import 'package:flutter/material.dart';

import '../models/chat_message.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUser ? '编辑消息' : '编辑助手回复'),
        actions: [
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('保存'),
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
              _isUser
                  ? '修改后将在后续对话中生效'
                  : '思考内容与回复内容均可修改，修改后将用于后续对话上下文',
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
            const SizedBox(height: 14),
            if (!_isUser) ...[
              _buildField(
                title: '思考内容',
                controller: _reasoningController,
                hint: '修改模型生成时的思考过程…',
              ),
              const SizedBox(height: 18),
            ],
            _buildField(
              title: _isUser ? '消息内容' : '回复内容',
              controller: _contentController,
              hint: _isUser ? '修改消息内容…' : '修改回复内容…',
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
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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

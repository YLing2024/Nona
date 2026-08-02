import 'package:flutter/material.dart';

import '../models/agent.dart';
import '../models/chat_options.dart';
import '../widgets/chat_options_form.dart';

/// 新建 / 编辑 Agent：名称 + 会话上下文预设。
class AgentEditScreen extends StatefulWidget {
  /// 传入已有 Agent 则为编辑，null 为新建。
  final Agent? agent;

  const AgentEditScreen({super.key, this.agent});

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();
}

class _AgentEditScreenState extends State<AgentEditScreen> {
  late final TextEditingController _nameController;
  late bool _isDefault;
  final _formKey = GlobalKey<ChatOptionsFormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agent?.name ?? '');
    _isDefault = widget.agent?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写 Agent 名称')));
      return;
    }
    final form = _formKey.currentState;
    if (form == null) return;
    final agent = Agent(
      id: widget.agent?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      options: form.value,
      isDefault: _isDefault,
    );
    Navigator.of(context).pop(agent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent == null ? '新建 Agent' : '编辑 Agent'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '例如：代码助手、翻译官…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('设为默认 Agent'),
            subtitle: const Text('单击「新建会话」时自动套用该配置'),
            value: _isDefault,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          const SizedBox(height: 8),
          ChatOptionsForm(
            key: _formKey,
            initial: widget.agent?.options ?? const ChatOptions(),
          ),
        ],
      ),
    );
  }
}

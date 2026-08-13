import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/agent.dart';
import '../../../core/models/chat_options.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/chat_options_form.dart';

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
  late final TextEditingController _memoriesController;
  late bool _isDefault;
  final _formKey = GlobalKey<ChatOptionsFormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agent?.name ?? '');
    _memoriesController = TextEditingController(
      text: (widget.agent?.memories ?? const []).join('\n'),
    );
    _isDefault = widget.agent?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoriesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.agentNameRequired)));
      return;
    }
    final form = _formKey.currentState;
    if (form == null) return;
    final agent = Agent(
      id: widget.agent?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      options: form.value,
      isDefault: _isDefault,
      memories: _memoriesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    Navigator.of(context).pop(agent);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent == null ? l10n.agentNew : l10n.agentEdit),
        actions: [TextButton(onPressed: _save, child: Text(l10n.commonSave))],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          TextField(
            controller: _nameController,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              labelText: l10n.agentName,
              hintText: l10n.agentNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.agentSetDefault),
            subtitle: Text(l10n.agentDefaultHint),
            value: _isDefault,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoriesController,
            maxLines: 4,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              labelText: l10n.agentMemories,
              hintText: l10n.agentMemoriesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ChatOptionsForm(
            key: _formKey,
            initial: widget.agent?.options ?? const ChatOptions(),
          ),
        ],
        ),
      ),
    );
  }
}

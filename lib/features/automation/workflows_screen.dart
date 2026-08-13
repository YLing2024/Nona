import 'package:flutter/material.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'workflow.dart';
import 'workflow_service.dart';

/// 自动化工作流管理页（X-01）：列表 / 新建 / 试运行 / 历史。
class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  State<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  final WorkflowService _service = WorkflowService();
  List<Workflow> _workflows = [];
  List<WorkflowRunRecord> _history = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final workflows = await _service.list();
    final history = await _service.history(limit: 20);
    if (!mounted) return;
    setState(() {
      _workflows = workflows;
      _history = history;
    });
  }

  Future<void> _add() async {
    final w = await _editWorkflow(null);
    if (w == null || !mounted) return;
    await _service.save(w);
    await _load();
  }

  Future<void> _edit(Workflow w) async {
    final edited = await _editWorkflow(w);
    if (edited == null || !mounted) return;
    await _service.save(edited);
    await _load();
  }

  Future<Workflow?> _editWorkflow(Workflow? existing) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var triggerType = existing?.trigger.type ?? 'manual';
    var cronMinute = (existing?.trigger is ScheduleTrigger)
        ? (existing!.trigger as ScheduleTrigger).cronMinute
        : '*/30';
    var dailyTime = (existing?.trigger is DailyTrigger)
        ? (existing!.trigger as DailyTrigger).time
        : '09:00';
    var eventOn = (existing?.trigger is EventTrigger)
        ? (existing!.trigger as EventTrigger).on
        : 'chat_completed';
    var eventFilter = (existing?.trigger is EventTrigger)
        ? (existing!.trigger as EventTrigger).filter
        : '';
    final textController =
        TextEditingController(
          text: existing?.actions.isEmpty ?? true
              ? ''
              : existing!.actions.first.text,
        );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(existing == null ? l10n.wfAdd : l10n.wfEdit),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.wfName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: triggerType,
                    decoration: const InputDecoration(
                      labelText: '触发器',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'manual', child: Text('手动')),
                      DropdownMenuItem(value: 'schedule', child: Text('每 N 分钟')),
                      DropdownMenuItem(value: 'daily', child: Text('每天定时')),
                      DropdownMenuItem(value: 'event', child: Text('事件（会话完成）')),
                    ],
                    onChanged: (v) => setDialogState(() => triggerType = v ?? 'manual'),
                  ),
                  if (triggerType == 'schedule') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: cronMinute),
                      decoration: const InputDecoration(
                        labelText: '分钟表达式（如 */30）',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => cronMinute = v,
                    ),
                  ],
                  if (triggerType == 'daily') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: dailyTime),
                      decoration: const InputDecoration(
                        labelText: '时间（HH:mm）',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => dailyTime = v,
                    ),
                  ],
                  if (triggerType == 'event') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: eventOn,
                      decoration: const InputDecoration(
                        labelText: '事件',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'chat_completed',
                          child: Text('chat_completed（会话完成）'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => eventOn = v ?? 'chat_completed'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: eventFilter),
                      decoration: const InputDecoration(
                        labelText: '过滤（如 session.title contains 日报，可空）',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => eventFilter = v,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.wfActionText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    textController.dispose();
    if (saved != true) return null;
    final trigger = switch (triggerType) {
      'schedule' => ScheduleTrigger(cronMinute: cronMinute),
      'daily' => DailyTrigger(time: dailyTime),
      'event' => EventTrigger(
        on: eventOn,
        filter: (eventFilter ?? '').trim().isEmpty
            ? null
            : (eventFilter ?? '').trim(),
      ),
      _ => const ManualTrigger(),
    };
    final actions = textController.text.trim().isEmpty
        ? <WorkflowAction>[]
        : [
            WorkflowAction(type: 'send_message', text: textController.text.trim()),
          ];
    if (actions.isEmpty) return null;
    return Workflow(
      id: existing?.id ?? '',
      name: nameController.text.trim().isEmpty ? '未命名' : nameController.text.trim(),
      trigger: trigger,
      actions: actions,
      enabled: existing?.enabled ?? true,
      agentId: existing?.agentId,
    );
  }

  Future<void> _delete(Workflow w) async {
    final ok = await confirmAction(
      context,
      title: AppLocalizations.of(context).wfDeleteTitle,
      message: AppLocalizations.of(context).wfDeleteBody(w.name),
      confirmText: AppLocalizations.of(context).chatDelete,
      danger: true,
    );
    if (!ok || !mounted) return;
    await _service.delete(w.id);
    await _load();
  }

  Future<void> _run(Workflow w) async {
    setState(() => _busy = true);
    final result = await _service.run(w);
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showAppSnack(context, result.isSuccess ? l10n.wfRunSuccess : l10n.wfRunFailed);
  }

  Future<void> _toggleEnabled(Workflow w, bool enabled) async {
    await _service.save(
      Workflow(
        id: w.id,
        name: w.name,
        trigger: w.trigger,
        actions: w.actions,
        enabled: enabled,
        agentId: w.agentId,
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wfTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.wfAdd),
      ),
      body: _workflows.isEmpty && _history.isEmpty
          ? Center(
              child: Text(
                l10n.wfEmpty,
                style: TextStyle(color: scheme.outline),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.wfListTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final w in _workflows) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Switch(
                        value: w.enabled,
                        onChanged: (v) => _toggleEnabled(w, v),
                      ),
                      title: Text(w.name),
                      subtitle: Text(
                        _triggerLabel(w.trigger),
                        style: TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            tooltip: l10n.wfRun,
                            onPressed: _busy ? null : () => _run(w),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: l10n.wfEdit,
                            onPressed: () => _edit(w),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            tooltip: l10n.chatDelete,
                            onPressed: () => _delete(w),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l10n.wfHistoryTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final h in _history.take(10))
                    ListTile(
                      dense: true,
                      leading: Icon(
                        h.status == 'success'
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color: h.status == 'success' ? scheme.primary : scheme.error,
                      ),
                      title: Text(h.workflowId),
                      subtitle: Text(
                        '${h.startedAt.toLocal()}'
                        '${h.error != null ? ' · ${h.error}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: scheme.outline),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  String _triggerLabel(WorkflowTrigger t) => switch (t) {
    ManualTrigger() => '手动',
    ScheduleTrigger(:final cronMinute) => '每 $cronMinute 分钟',
    DailyTrigger(:final time) => '每天 $time',
    EventTrigger(:final on) => '事件：$on',
  };
}

import 'dart:convert';

import '../../core/database/nona_app_database.dart';

/// 工作流触发器（X-01）。
sealed class WorkflowTrigger {
  const WorkflowTrigger();

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'manual' => const ManualTrigger(),
        'schedule' => ScheduleTrigger(
          cronMinute: json['cronMinute'] as String? ?? '*/30',
        ),
        'daily' => DailyTrigger(
          time: json['time'] as String? ?? '09:00',
        ),
        'event' => EventTrigger(
          on: json['on'] as String? ?? 'chat_completed',
          filter: json['filter'] as String?,
        ),
        _ => const ManualTrigger(),
      };

  Map<String, dynamic> toJson() => {'type': type};

  String get type;
}

class ManualTrigger extends WorkflowTrigger {
  const ManualTrigger();

  @override
  String get type => 'manual';
}

class ScheduleTrigger extends WorkflowTrigger {
  final String cronMinute;

  const ScheduleTrigger({this.cronMinute = '*/30'});

  @override
  String get type => 'schedule';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'cronMinute': cronMinute,
  };

  /// 分钟是否命中（支持 */N、具体分钟、列表）。
  bool matches(int minute) {
    final parts = cronMinute.split(',');
    for (final p in parts) {
      final t = p.trim();
      if (t == '*') return true;
      if (t.startsWith('*/')) {
        final n = int.tryParse(t.substring(2));
        if (n != null && n > 0 && minute % n == 0) return true;
      } else {
        final v = int.tryParse(t);
        if (v != null && v == minute) return true;
      }
    }
    return false;
  }
}

class DailyTrigger extends WorkflowTrigger {
  final String time;

  const DailyTrigger({this.time = '09:00'});

  @override
  String get type => 'daily';

  @override
  Map<String, dynamic> toJson() => {'type': type, 'time': time};

  /// 当前时间（HH:mm）是否等于目标（±1 分钟窗口）。
  bool matches(DateTime now) {
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    final diff = (now.hour - h) * 60 + (now.minute - m);
    return diff.abs() <= 1;
  }
}

class EventTrigger extends WorkflowTrigger {
  final String on;
  final String? filter;

  const EventTrigger({this.on = 'chat_completed', this.filter});

  @override
  String get type => 'event';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'on': on,
    if (filter != null) 'filter': filter,
  };

  /// 事件与过滤条件是否命中（filter 为简单子串匹配，如
  /// 「session.title contains 日报」）。
  bool matchesEvent(String eventName, Map<String, String> context) {
    if (on != eventName) return false;
    if (filter == null || filter!.isEmpty) return true;
    final m = RegExp(r'^(\w+)\.(\w+)\s+contains\s+(.+)$')
        .firstMatch(filter!);
    if (m == null) return true;
    final value = context['${m.group(1)}.${m.group(2)}'] ?? '';
    return value.contains(m.group(3)!);
  }
}

/// 工作流动作。
class WorkflowAction {
  final String type;
  final String text;
  final String? serverId;
  final String? tool;
  final Map<String, dynamic>? args;
  final String? model;
  final String? agentId;
  final String? target;
  final String? lang;

  const WorkflowAction({
    required this.type,
    this.text = '',
    this.serverId,
    this.tool,
    this.args,
    this.model,
    this.agentId,
    this.target,
    this.lang,
  });

  factory WorkflowAction.fromJson(Map<String, dynamic> json) => WorkflowAction(
    type: json['type'] as String? ?? 'send_message',
    text: json['text'] as String? ?? '',
    serverId: json['serverId'] as String?,
    tool: json['tool'] as String?,
    args: json['args'] as Map<String, dynamic>?,
    model: json['model'] as String?,
    agentId: json['agentId'] as String?,
    target: json['target'] as String?,
    lang: json['lang'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text.isNotEmpty) 'text': text,
    if (serverId != null) 'serverId': serverId,
    if (tool != null) 'tool': tool,
    if (args != null) 'args': args,
    if (model != null) 'model': model,
    if (agentId != null) 'agentId': agentId,
    if (target != null) 'target': target,
    if (lang != null) 'lang': lang,
  };
}

/// 自动化工作流（X-01）。
class Workflow {
  final String id;
  String name;
  WorkflowTrigger trigger;
  List<WorkflowAction> actions;
  bool enabled;
  String? agentId;
  DateTime updatedAt;

  Workflow({
    required this.id,
    required this.name,
    required this.trigger,
    required this.actions,
    this.enabled = true,
    this.agentId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Workflow.fromRow(WorkflowRow r) => Workflow(
    id: r.id,
    name: r.name,
    trigger: WorkflowTrigger.fromJson(
      jsonDecode(r.triggerJson) as Map<String, dynamic>,
    ),
    actions: [
      for (final a in jsonDecode(r.actionsJson) as List<dynamic>)
        WorkflowAction.fromJson(a as Map<String, dynamic>),
    ],
    enabled: r.enabled,
    agentId: r.agentId,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );
}

/// 工作流运行结果。
class WorkflowRunResult {
  final String status; // success / failed / cancelled
  final String? error;
  final List<String> logs;

  const WorkflowRunResult({
    this.status = 'success',
    this.error,
    this.logs = const [],
  });

  bool get isSuccess => status == 'success';

  Map<String, dynamic> toJson() => {
    'status': status,
    if (error != null) 'error': error,
    'logs': logs,
  };
}

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/nona_app_database.dart';
import '../../core/database/nona_db_factory.dart';
import '../../core/models/chat_options.dart';
import '../../core/models/chat_provider.dart';
import '../../core/models/chat_session.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/export/backup_archive.dart';
import '../../core/services/mcp/mcp_service.dart';
import '../../core/services/provider_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/logger.dart';
import '../../shared/workflow_event_bus.dart';
import 'workflow.dart';

/// 工作流服务（X-01）：CRUD + 分钟级调度 + 事件触发 + 执行器 + 运行历史。
class WorkflowService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  /// 动作依赖（可注入测试替身）。
  ChatService Function()? chatServiceFactory;
  McpService? mcpService;

  Timer? _ticker;
  int? _lastMinute;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  /// 运行历史上限（滚动清理）。
  static const int kMaxHistory = 200;
  static int _runCounter = 0;

  WorkflowService({NonaAppDatabase? database}) : _explicitDb = database;

  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  // ---------------- CRUD ----------------

  Future<List<Workflow>> list() async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await (db.select(db.workflows)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();
      return [for (final r in rows) Workflow.fromRow(r)];
    } catch (e) {
      Logger.error('wf', 'list failed', e);
      return const [];
    }
  }

  Future<void> save(Workflow w) async {
    final db = await _db;
    if (db == null) return;
    final id = w.id.isEmpty
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : w.id;
    try {
      await db.into(db.workflows).insertOnConflictUpdate(
        WorkflowsCompanion.insert(
          id: id,
          name: w.name,
          triggerJson: jsonEncode(w.trigger.toJson()),
          actionsJson: jsonEncode(
            w.actions.map((a) => a.toJson()).toList(),
          ),
          enabled: Value(w.enabled),
          agentId: Value(w.agentId),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      Logger.error('wf', 'save failed', e);
    }
  }

  Future<void> delete(String id) async {
    final db = await _db;
    if (db == null) return;
    try {
      await (db.delete(db.workflows)..where((t) => t.id.equals(id))).go();
    } catch (_) {}
  }

  // ---------------- 调度与事件 ----------------

  /// 启动调度（分钟级 tick + 事件订阅）。
  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => _onTick());
    _eventSub ??= WorkflowEventBus.instance.events.listen(_onEvent);
    _lastMinute = null;
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _eventSub?.cancel();
    _eventSub = null;
  }

  void _onTick() {
    final now = DateTime.now();
    if (now.minute == _lastMinute) return;
    _lastMinute = now.minute;
    unawaited(_maybeRunScheduled(now));
  }

  Future<void> _maybeRunScheduled(DateTime now) async {
    final workflows = await list();
    for (final w in workflows) {
      if (!w.enabled) continue;
      final trigger = w.trigger;
      if (trigger is ScheduleTrigger && trigger.matches(now.minute)) {
        unawaited(run(w));
      } else if (trigger is DailyTrigger && trigger.matches(now)) {
        unawaited(run(w));
      }
    }
  }

  void _onEvent(Map<String, dynamic> payload) {
    final event = payload['event'] as String? ?? '';
    final context = <String, String>{
      for (final e in payload.entries)
        if (e.key != 'event' && e.value is String) e.key: e.value as String,
    };
    unawaited(_maybeRunEvent(event, context));
  }

  Future<void> _maybeRunEvent(String event, Map<String, String> context) async {
    final workflows = await list();
    for (final w in workflows) {
      if (!w.enabled) continue;
      final trigger = w.trigger;
      if (trigger is EventTrigger && trigger.matchesEvent(event, context)) {
        unawaited(run(w, variables: context));
      }
    }
  }

  // ---------------- 执行器 ----------------

  /// 执行工作流：逐动作执行，记录运行历史。
  Future<WorkflowRunResult> run(
    Workflow w, {
    Map<String, String> variables = const {},
  }) async {
    final runId = '${DateTime.now().microsecondsSinceEpoch}-${_runCounter++}';
    final started = DateTime.now();
    await _recordRun(runId, w.id, 'running', started, null, null);
    final logs = <String>[];
    var failed = false;
    var error = '';
    try {
      for (final action in w.actions) {
        final log = await _executeAction(action, w, variables);
        logs.add(log);
        if (log.startsWith('[失败]')) {
          failed = true;
          error = log;
          break;
        }
      }
    } catch (e, s) {
      failed = true;
      error = e.toString();
      logs.add('[失败] $error');
      Logger.error('wf', 'run ${w.name} failed', e, s);
    }
    final status = failed ? 'failed' : 'success';
    await _recordRun(
      runId,
      w.id,
      status,
      started,
      DateTime.now(),
      failed
          ? WorkflowRunResult(status: status, error: error, logs: logs)
          : WorkflowRunResult(status: status, logs: logs),
    );
    return WorkflowRunResult(status: status, error: error, logs: logs);
  }

  Future<String> _executeAction(
    WorkflowAction action,
    Workflow w,
    Map<String, String> variables,
  ) async {
    switch (action.type) {
      case 'send_message':
        return _actionSendMessage(action, variables);
      case 'run_mcp_tool':
        return _actionMcpTool(action);
      case 'export_backup':
        return _actionExportBackup();
      case 'batch_translate':
        return _actionBatchTranslate(action);
      default:
        return '[失败] 未知动作类型: ${action.type}';
    }
  }

  String _expand(String text, Map<String, String> variables) {
    var out = text;
    variables.forEach((k, v) {
      out = out.replaceAll('{{$k}}', v);
    });
    // 内置变量
    final now = DateTime.now();
    out = out.replaceAll('{{cur_date}}', now.toIso8601String().substring(0, 10));
    out = out.replaceAll('{{cur_time}}', '${now.hour}:${now.minute}');
    return out;
  }

  Future<String> _actionSendMessage(
    WorkflowAction action,
    Map<String, String> variables,
  ) async {
    final text = _expand(action.text, variables);
    if (text.trim().isEmpty) return '[失败] send_message 文本为空';
    try {
      final settings = await SettingsService().load();
      if (settings.apiKey.isEmpty) return '[失败] 未配置 API Key';
      final chatService = (chatServiceFactory ?? () => ChatService())();
      final result = await chatService.sendSimple(
        settings: settings,
        userMessage: text,
        maxTokens: 800,
      );
      return 'send_message ✓（${result.length} 字符）';
    } catch (e) {
      return '[失败] send_message: $e';
    }
  }

  Future<String> _actionMcpTool(WorkflowAction action) async {
    final serverId = action.serverId;
    final tool = action.tool;
    if (serverId == null || tool == null) {
      return '[失败] run_mcp_tool 缺少 serverId/tool';
    }
    try {
      final mcp = mcpService ?? McpService();
      final servers = await mcp.load();
      final tools = await mcp.collectTools(servers);
      final result = await mcp.callTool(
        servers,
        tools,
        tool,
        action.args ?? const {},
      );
      return 'run_mcp_tool ✓（${result.content.length} 字符）';
    } catch (e) {
      return '[失败] run_mcp_tool: $e';
    }
  }

  Future<String> _actionExportBackup() async {
    try {
      final bytes = BackupArchive.buildAllZipBytes(
        sessions: await _loadSessions(),
        providers: await _loadProviders(),
      );
      return 'export_backup ✓（${bytes.length} 字节打包完成）';
    } catch (e) {
      return '[失败] export_backup: $e';
    }
  }

  Future<List<ChatSession>> _loadSessions() async {
    final db = await _db;
    if (db == null) return const [];
    final rows = await (db.select(db.sessions)).get();
    final sessions = <ChatSession>[];
    for (final row in rows) {
      sessions.add(
        ChatSession(
          id: row.id,
          title: row.title,
          options: ChatOptions.fromJson(
            jsonDecode(row.optionsJson) as Map<String, dynamic>,
          ),
          providerId: row.providerId,
          modelId: row.modelId,
          agentId: row.agentId,
          pinned: row.pinned,
          messages: const [],
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
        ),
      );
    }
    return sessions;
  }

  Future<List<ChatProvider>> _loadProviders() async {
    try {
      return await ProviderService().load();
    } catch (_) {
      return const [];
    }
  }

  Future<String> _actionBatchTranslate(WorkflowAction action) async {
    return '[跳过] batch_translate（lang=${action.lang ?? 'en'}）需人工确认';
  }

  // ---------------- 运行历史 ----------------

  Future<void> _recordRun(
    String runId,
    String workflowId,
    String status,
    DateTime started,
    DateTime? finished,
    WorkflowRunResult? result,
  ) async {
    final db = await _db;
    if (db == null) return;
    try {
      // 同 runId 存在（running 占位）时更新为终态
      await db.into(db.workflowRuns).insertOnConflictUpdate(
        WorkflowRunsCompanion.insert(
          id: runId,
          workflowId: workflowId,
          status: status,
          startedAt: started.millisecondsSinceEpoch,
          finishedAt: Value(finished?.millisecondsSinceEpoch),
          error: Value(result?.error),
          resultJson: Value(
            result == null ? null : jsonEncode(result.toJson()),
          ),
        ),
      );
      // 滚动清理：仅保留最近 kMaxHistory 条
      final rows = await db
          .customSelect(
            'SELECT id FROM workflow_runs ORDER BY started_at DESC LIMIT -1 '
            'OFFSET ?',
            variables: [Variable.withInt(kMaxHistory)],
          )
          .get();
      for (final r in rows) {
        await (db.delete(db.workflowRuns)
              ..where((t) => t.id.equals(r.data['id'] as String)))
            .go();
      }
    } catch (e) {
      Logger.error('wf', 'record run failed', e);
    }
  }

  /// 运行历史（按时间倒序）。
  Future<List<WorkflowRunRecord>> history({int limit = 50}) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await (db.select(db.workflowRuns)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(limit))
          .get();
      return [for (final r in rows) WorkflowRunRecord.fromRow(r)];
    } catch (_) {
      return const [];
    }
  }
}

/// 运行历史记录。
class WorkflowRunRecord {
  final String id;
  final String workflowId;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? error;
  final Map<String, dynamic>? result;

  const WorkflowRunRecord({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.error,
    this.result,
  });

  factory WorkflowRunRecord.fromRow(WorkflowRunRow r) => WorkflowRunRecord(
    id: r.id,
    workflowId: r.workflowId,
    status: r.status,
    startedAt: DateTime.fromMillisecondsSinceEpoch(r.startedAt),
    finishedAt: r.finishedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(r.finishedAt!),
    error: r.error,
    result: r.resultJson == null
        ? null
        : jsonDecode(r.resultJson!) as Map<String, dynamic>,
  );
}

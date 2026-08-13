import 'package:drift/drift.dart';

import '../database/nona_app_database.dart';
import '../database/nona_db_factory.dart';
import 'model_capability_service.dart';
import 'provider_service.dart';
import 'usage/price_service.dart';
import 'model_router.dart';

/// 模型路由服务（X-02）：组装候选（能力/价格/延迟样本）、决策与埋点。
class ModelRouterService {
  final NonaAppDatabase? _explicitDb;
  Future<NonaAppDatabase?>? _cachedDb;

  /// 是否启用自动路由（设置开关；关闭时任务槽回退手动选择）。
  bool autoRoutingEnabled = false;

  final ModelCapabilityService _capability = ModelCapabilityService();
  final PriceService _price = PriceService.instance;
  final ModelRouter _router = const ModelRouter();

  ModelRouterService({NonaAppDatabase? database}) : _explicitDb = database;

  Future<NonaAppDatabase?> get _db =>
      _cachedDb ??= _explicitDb != null
          ? Future.value(_explicitDb)
          : openNonaDatabase();

  /// 为任务选择模型：自动路由 → 无可行时 null（调用方回退手动槽）。
  Future<ModelRoute?> route(
    RoutingTask task, {
    int inputTokens = 0,
    double costWeight = 0.8,
    Set<String>? providerAllowlist,
    bool requireReasoning = false,
  }) async {
    if (!autoRoutingEnabled) return null;
    final providers = await ProviderService().load();
    if (providers.isEmpty) return null;
    final capabilities = await _capability.load();
    // 价格表：遍历候选模型查询（前缀匹配已内置）
    final priceMap = <String, double>{};
    for (final p in providers) {
      for (final model in p.modelIds) {
        final price = await _price.priceFor(model);
        if (price != null) {
          // 成本按输入输出均价估算
          priceMap[model] = (price.promptPerM + price.completionPerM) / 2;
        }
      }
    }
    final latencyMap = await _avgLatencyByModel(task);
    final candidates = buildCandidates(
      providers,
      capabilities: capabilities,
      pricePerMByModel: priceMap,
      latencyByModel: latencyMap,
    );
    if (candidates.isEmpty) return null;
    return _router.resolve(
      RoutingRequest(
        task: task,
        inputTokens: inputTokens,
        costWeight: costWeight,
        providerAllowlist: providerAllowlist,
        requireReasoning: requireReasoning,
      ),
      ModelRouterContext(candidates: candidates),
    );
  }

  /// 记录一次路由事件（route_events 表，X-02 延迟/成本样本）。
  Future<void> recordRouteEvent({
    required RoutingTask task,
    String? providerId,
    String? modelId,
    required bool success,
    int elapsedMs = 0,
    double cost = 0,
  }) async {
    final db = await _db;
    if (db == null) return;
    try {
      await db.into(db.routeEvents).insert(
        RouteEventsCompanion.insert(
          task: task.name,
          providerId: Value(providerId),
          modelId: Value(modelId),
          success: Value(success),
          elapsedMs: Value(elapsedMs),
          cost: Value(cost),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {}
  }

  /// 各模型在任务上的平均延迟（最近 20 条成功样本）。
  Future<Map<String, int>> _avgLatencyByModel(RoutingTask task) async {
    final db = await _db;
    if (db == null) return const {};
    try {
      final rows = await db
          .customSelect(
            'SELECT model_id, AVG(elapsed_ms) AS avg_ms FROM route_events '
            'WHERE task = ? AND success = 1 AND elapsed_ms > 0 '
            'GROUP BY model_id ORDER BY id DESC LIMIT 20',
            variables: [Variable.withString(task.name)],
          )
          .get();
      return {
        for (final r in rows)
          if (r.data['model_id'] != null)
            r.data['model_id'] as String: (r.data['avg_ms'] as num).round(),
      };
    } catch (_) {
      return const {};
    }
  }

  /// 最近 [days] 天路由事件统计（建议面板用）。
  Future<List<RouteEventStat>> stats({int days = 30}) async {
    final db = await _db;
    if (db == null) return const [];
    try {
      final rows = await db
          .customSelect(
            'SELECT task, model_id, COUNT(*) AS n, AVG(elapsed_ms) AS avg_ms, '
            'SUM(cost) AS total_cost FROM route_events '
            'WHERE created_at >= ? AND success = 1 '
            'GROUP BY task, model_id ORDER BY task, n DESC',
            variables: [
              Variable.withInt(
                DateTime.now()
                        .subtract(Duration(days: days))
                        .millisecondsSinceEpoch,
              ),
            ],
          )
          .get();
      return [
        for (final r in rows)
          RouteEventStat(
            task: r.data['task'] as String,
            modelId: r.data['model_id'] as String? ?? '',
            calls: r.data['n'] as int? ?? 0,
            avgMs: r.data['avg_ms'] as num?,
            totalCost: r.data['total_cost'] as num? ?? 0,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// 路由事件统计。
class RouteEventStat {
  final String task;
  final String modelId;
  final int calls;
  final num? avgMs;
  final num totalCost;

  const RouteEventStat({
    required this.task,
    required this.modelId,
    required this.calls,
    this.avgMs,
    this.totalCost = 0,
  });
}

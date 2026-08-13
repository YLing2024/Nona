import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/services/model_router.dart';
import 'package:nona_chat/core/services/model_router_service.dart';
import 'package:nona_chat/core/services/provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  const router = ModelRouter();

  RouteCandidate c(
    String provider,
    String model, {
    double? price,
    int? latency,
    int? window,
    bool reasoning = false,
  }) => RouteCandidate(
    providerId: provider,
    modelId: model,
    pricePerM: price,
    avgLatencyMs: latency,
    contextWindow: window,
    reasoning: reasoning,
  );

  group('ModelRouter 决策（X-02）', () {
    test('成本优先选择最便宜模型', () {
      final ctx = ModelRouterContext(candidates: [
        c('p1', 'gpt-4o', price: 2.5, latency: 500),
        c('p1', 'gpt-4o-mini', price: 0.15, latency: 800),
        c('p2', 'haiku', price: 0.25, latency: 900),
      ]);
      final route = router.resolve(
        const RoutingRequest(task: RoutingTask.title, costWeight: 1.0),
        ctx,
      );
      expect(route.modelId, 'gpt-4o-mini');
      expect(route.reason, contains('成本'));
    });

    test('速度优先选择最快模型', () {
      final ctx = ModelRouterContext(candidates: [
        c('p1', 'fast', price: 5.0, latency: 100),
        c('p1', 'slow', price: 0.1, latency: 2000),
      ]);
      final route = router.resolve(
        const RoutingRequest(task: RoutingTask.title, costWeight: 0.0),
        ctx,
      );
      expect(route.modelId, 'fast');
    });

    test('上下文窗口过滤：输入超窗候选被排除', () {
      final ctx = ModelRouterContext(candidates: [
        c('p1', 'small', price: 0.1, latency: 100, window: 8000),
        c('p1', 'big', price: 1.0, latency: 300, window: 128000),
      ]);
      final route = router.resolve(
        const RoutingRequest(
          task: RoutingTask.summary,
          inputTokens: 30000,
          costWeight: 1.0,
        ),
        ctx,
      );
      expect(route.modelId, 'big', reason: 'small 窗口 8K < 30K 输入应被排除');
    });

    test('白名单过滤与推理要求', () {
      final ctx = ModelRouterContext(candidates: [
        c('p1', 'a', price: 0.1),
        c('p2', 'b', price: 0.2),
        c('p1', 'r1', price: 0.5, reasoning: true),
      ]);
      final whitelist = router.resolve(
        const RoutingRequest(
          task: RoutingTask.ocr,
          providerAllowlist: {'p1'},
          requireReasoning: true,
        ),
        ctx,
      );
      expect(whitelist.modelId, 'r1');
      final none = router.resolve(
        const RoutingRequest(
          task: RoutingTask.ocr,
          providerAllowlist: {'p9'},
        ),
        ctx,
      );
      expect(none.hasModel, isFalse);
    });

    test('无价格/延迟样本的候选按未知处理仍可选出', () {
      final ctx = ModelRouterContext(candidates: [
        c('p1', 'unknown-cost', latency: 200),
        c('p1', 'unknown-everything'),
      ]);
      final route = router.resolve(
        const RoutingRequest(task: RoutingTask.title, costWeight: 0.5),
        ctx,
      );
      expect(route.hasModel, isTrue);
    });
  });

  group('ModelRouterService 埋点与统计（X-02）', () {
    test('recordRouteEvent 可被 stats 读回', () async {
      final service = ModelRouterService(database: db);
      await service.recordRouteEvent(
        task: RoutingTask.title,
        providerId: 'p1',
        modelId: 'gpt-4o-mini',
        success: true,
        elapsedMs: 350,
        cost: 0.001,
      );
      await service.recordRouteEvent(
        task: RoutingTask.title,
        providerId: 'p1',
        modelId: 'gpt-4o-mini',
        success: true,
        elapsedMs: 450,
        cost: 0.002,
      );
      final stats = await service.stats();
      expect(stats, hasLength(1));
      expect(stats.first.modelId, 'gpt-4o-mini');
      expect(stats.first.calls, 2);
      expect(stats.first.avgMs, closeTo(400, 1));
      expect(stats.first.totalCost, closeTo(0.003, 1e-9));
    });

    test('失败事件不计入统计（仅成功样本）', () async {
      final service = ModelRouterService(database: db);
      await service.recordRouteEvent(
        task: RoutingTask.summary,
        modelId: 'm',
        success: true,
        elapsedMs: 100,
      );
      await service.recordRouteEvent(
        task: RoutingTask.summary,
        modelId: 'm',
        success: false,
        elapsedMs: 5000,
      );
      final stats = await service.stats();
      expect(stats.first.calls, 1, reason: '失败样本不计入统计');
      expect(stats.first.avgMs, closeTo(100, 1));
    });

    test('关闭路由时 route 返回 null（回退手动槽）', () async {
      final service = ModelRouterService(database: db);
      service.autoRoutingEnabled = false;
      final route = await service.route(RoutingTask.title);
      expect(route, isNull);
    });
  });

  test('ProviderService 组装候选（buildCandidates）', () async {
    await ProviderService().save([
      ChatProvider(
        id: 'p1',
        name: 'P1',
        baseUrl: 'https://example.com/v1',
        apiKey: 'k',
        modelIds: ['gpt-4o', 'gpt-4o-mini'],
      ),
    ]);
    final candidates = buildCandidates(await ProviderService().load());
    expect(candidates, hasLength(2));
    expect(candidates.first.modelId, 'gpt-4o');
  });
}

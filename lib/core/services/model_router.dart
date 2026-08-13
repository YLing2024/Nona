import '../models/chat_provider.dart';

/// 路由任务类型（X-02）。
enum RoutingTask { chat, summary, title, translate, ocr, embedding, imageGen }

/// 路由请求。
class RoutingRequest {
  final RoutingTask task;

  /// 输入 token 数（候选须满足 contextWindow ≥ inputTokens）。
  final int inputTokens;

  /// 0 = 纯成本优先；1 = 纯速度优先。
  final double costWeight;

  /// 服务商白名单（null = 全部）。
  final Set<String>? providerAllowlist;

  /// 模型白名单（null = 全部）。
  final Set<String>? modelAllowlist;

  /// 是否需要推理能力。
  final bool requireReasoning;

  const RoutingRequest({
    required this.task,
    this.inputTokens = 0,
    this.costWeight = 1.0,
    this.providerAllowlist,
    this.modelAllowlist,
    this.requireReasoning = false,
  });
}

/// 路由结果；providerId/modelId 全 null = 无可行模型。
class ModelRoute {
  final String? providerId;
  final String? modelId;
  final String reason;

  const ModelRoute({this.providerId, this.modelId, required this.reason});

  bool get hasModel => providerId != null && modelId != null;
}

/// 候选模型视图（由路由上下文提供）。
class RouteCandidate {
  final String providerId;
  final String modelId;

  /// 每百万 token 成本（美元；未知为 null）。
  final double? pricePerM;

  /// 平均延迟（毫秒；无样本为 null）。
  final int? avgLatencyMs;

  /// 上下文窗口（tokens；未知为 null）。
  final int? contextWindow;

  /// 是否多模态 / 推理。
  final bool multimodal;
  final bool reasoning;

  const RouteCandidate({
    required this.providerId,
    required this.modelId,
    this.pricePerM,
    this.avgLatencyMs,
    this.contextWindow,
    this.multimodal = false,
    this.reasoning = false,
  });
}

/// 路由上下文（能力表/价格表/延迟样本由调用方组装）。
class ModelRouterContext {
  final List<RouteCandidate> candidates;

  const ModelRouterContext({required this.candidates});
}

/// 智能模型路由核心（X-02，纯函数便于单测）。
///
/// 决策流程：候选 = 能力满足（contextWindow ≥ inputTokens、按需
/// multimodal/reasoning）+ 白名单过滤 → 按
/// `score = costWeight * normalizedCost + (1-costWeight) * normalizedLatency`
/// 取最小（未收录价格/延迟的候选按 1.0 处理）→ 输出 reason。
class ModelRouter {
  const ModelRouter();

  ModelRoute resolve(RoutingRequest request, ModelRouterContext ctx) {
    final eligible = ctx.candidates.where((c) {
      if (request.providerAllowlist != null &&
          !request.providerAllowlist!.contains(c.providerId)) {
        return false;
      }
      if (request.modelAllowlist != null &&
          !request.modelAllowlist!.contains(c.modelId)) {
        return false;
      }
      if (request.inputTokens > 0 &&
          c.contextWindow != null &&
          c.contextWindow! < request.inputTokens) {
        return false;
      }
      if (request.requireReasoning && !c.reasoning) return false;
      return true;
    }).toList();
    if (eligible.isEmpty) {
      return const ModelRoute(reason: '无满足条件的候选模型');
    }

    // 归一化：成本与延迟各自 min-max 到 0~1（未知按 1.0）
    final costs = [
      for (final c in eligible) c.pricePerM,
    ].whereType<double>().toList();
    final latencies = [
      for (final c in eligible) c.avgLatencyMs,
    ].whereType<int>().toList();
    final minCost = costs.isEmpty ? 0.0 : costs.reduce((a, b) => a < b ? a : b);
    final maxCost = costs.isEmpty ? 0.0 : costs.reduce((a, b) => a > b ? a : b);
    final minLat =
        latencies.isEmpty ? 0 : latencies.reduce((a, b) => a < b ? a : b);
    final maxLat =
        latencies.isEmpty ? 0 : latencies.reduce((a, b) => a > b ? a : b);

    double normCost(RouteCandidate c) {
      final p = c.pricePerM;
      if (p == null) return 1.0;
      if (maxCost == minCost) return 0.5;
      return (p - minCost) / (maxCost - minCost);
    }

    double normLatency(RouteCandidate c) {
      final l = c.avgLatencyMs;
      if (l == null) return 1.0;
      if (maxLat == minLat) return 0.5;
      return (l - minLat) / (maxLat - minLat);
    }

    final w = request.costWeight.clamp(0.0, 1.0);
    RouteCandidate? best;
    var bestScore = double.infinity;
    for (final c in eligible) {
      final score = w * normCost(c) + (1 - w) * normLatency(c);
      if (score < bestScore) {
        bestScore = score;
        best = c;
      }
    }
    if (best == null) return const ModelRoute(reason: '无可行模型');
    final reason = StringBuffer('${request.task.name} 路由');
    if (best.pricePerM != null) {
      reason.write('：成本 \$${(best.pricePerM! / 1000).toStringAsFixed(4)}/K');
    }
    if (best.avgLatencyMs != null) {
      reason.write(' · 延迟 ${best.avgLatencyMs}ms');
    }
    return ModelRoute(
      providerId: best.providerId,
      modelId: best.modelId,
      reason: reason.toString(),
    );
  }
}

/// 把服务商模型列表组装为路由候选。
List<RouteCandidate> buildCandidates(
  List<ChatProvider> providers, {
  Map<String, ModelConfig>? capabilities,
  Map<String, double>? pricePerMByModel,
  Map<String, int>? latencyByModel,
}) {
  final result = <RouteCandidate>[];
  for (final p in providers) {
    for (final model in p.modelIds) {
      final config = capabilities?[model] ?? capabilities?[model.split('/').last];
      result.add(
        RouteCandidate(
          providerId: p.id,
          modelId: model,
          pricePerM: pricePerMByModel?[model],
          avgLatencyMs: latencyByModel?[model],
          contextWindow: config?.contextWindow,
          multimodal: config?.multimodal ?? false,
          reasoning: config?.reasoning ?? false,
        ),
      );
    }
  }
  return result;
}

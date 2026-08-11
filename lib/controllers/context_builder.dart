import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/model_capability_service.dart';
import '../utils/token_counter.dart';

/// 摘要压缩计划（F3-1）：由 [ContextBuilder.buildPlan] 产出，
/// 调用方生成摘要后通过 [ContextBuilder.applyCompaction] 落地。
class CompactionPlan {
  /// 被压缩的原始消息（从最旧开始按轮次移除）。
  final List<ChatMessage> removedMessages;

  /// 压缩后保留的消息（首位保证为 user）。
  final List<ChatMessage> retainedMessages;

  /// 摘要允许占用的 token 预算（上下文上限 × summaryRatio）。
  final int summaryBudget;

  /// 压缩前消息在原数组中的起始下标。
  final int startIndex;

  const CompactionPlan({
    required this.removedMessages,
    required this.retainedMessages,
    required this.summaryBudget,
    required this.startIndex,
  });

  int get removedCount => removedMessages.length;
}

/// 上下文窗口管理器：token 估算 / 超限裁剪 / 摘要压缩 / 上下文上限推断。
///
/// 纯逻辑类（不依赖控制器状态），可脱离 Widget 与控制器独立单测；
/// 未来世界书 / 记忆注入等上下文组装逻辑也在此扩展。
class ContextBuilder {
  final ModelCapabilityService capabilityService;

  /// token 估算缓存（版本号变化时重算，避免流式高频重算）。
  int _cachedTokenVersion = -1;
  int _cachedTokens = 0;
  String? _cachedSessionId;

  ContextBuilder({ModelCapabilityService? capabilityService})
      : capabilityService = capabilityService ?? ModelCapabilityService();

  /// 会话上下文窗口上限：显式配置优先，否则按模型能力表/内置库推断。
  int? contextLimitFor(ChatSession session) {
    final explicit = session.options.maxContextTokens;
    if (explicit != null && explicit > 0) return explicit;
    return capabilityService.contextWindowFor(session.modelId ?? '');
  }

  /// 估算会话全部消息的 token 数（含系统提示词与摘要）。
  ///
  /// [tokenVersion] 为会话内容版本号：与上次调用相同时命中缓存，
  /// 用于流式输出期间避免每个 chunk 全量重算。
  int estimateTokens(ChatSession session, {required int tokenVersion}) {
    if (tokenVersion == _cachedTokenVersion && session.id == _cachedSessionId) {
      return _cachedTokens;
    }
    final modelId = session.modelId;
    var total = TokenCounter.estimate(
      session.options.systemPrompt,
      modelId: modelId,
    ) + 4;
    total += TokenCounter.estimate(session.summary, modelId: modelId);
    for (final m in session.messages) {
      total += TokenCounter.estimateMessage(m.role, m.content, m.images, modelId);
    }
    _cachedTokenVersion = tokenVersion;
    _cachedTokens = total;
    _cachedSessionId = session.id;
    return total;
  }

  /// 估算单条消息 token（供压缩计划/裁剪共用）。
  int estimateMessage(ChatMessage m, String? modelId) =>
      TokenCounter.estimateMessage(m.role, m.content, m.images, modelId);

  /// 会话累计上行/下行 token（由每条已完成的回复用量累加）。
  (int prompt, int completion) sessionUsage(ChatSession session) {
    var prompt = 0;
    var completion = 0;
    for (final m in session.messages) {
      prompt += m.promptTokens ?? 0;
      completion += m.completionTokens ?? 0;
    }
    return (prompt, completion);
  }

  /// 发送前自动裁剪：超出上下文上限时移除最早的消息。
  ///
  /// 上限取「显式配置」或「模型能力表/内置库推断的上下文窗口」。
  /// 返回移除的消息条数。
  int trimContext(ChatSession session) {
    final max = contextLimitFor(session);
    if (max == null || !session.options.autoTrim) return 0;
    final modelId = session.modelId;
    var total = TokenCounter.estimate(
      session.options.systemPrompt,
      modelId: modelId,
    ) + 4;
    for (final m in session.messages) {
      total += TokenCounter.estimateMessage(m.role, m.content, m.images, modelId);
    }
    var removed = 0;
    while (total > max && session.messages.length > 1) {
      final first = session.messages.removeAt(0);
      total -= TokenCounter.estimateMessage(
        first.role,
        first.content,
        first.images,
        modelId,
      );
      removed++;
    }
    // 首位不能是 assistant/tool 消息：Anthropic/Gemini 要求消息数组以
    // user 开头，否则直接 400（裁剪常从用户消息开始成对移除，
    // 剩在首位的可能是 assistant）。裁剪后若首位非 user 则一并移除。
    while (session.messages.isNotEmpty &&
        session.messages.first.role != 'user') {
      final first = session.messages.removeAt(0);
      total -= TokenCounter.estimateMessage(
        first.role,
        first.content,
        first.images,
        modelId,
      );
      removed++;
    }
    return removed;
  }

  /// 摘要压缩计划（F3-1）：超限时从最旧消息开始按「轮」（user + 其后
  /// assistant/tool）成对移除，保留最近 [ChatOptions.keepRecentMessages]
  /// 条全文，直到「保留消息 + 摘要预算 < 上下文上限」。
  ///
  /// 不超限 / 未开启自动裁剪 / 无可压缩消息时返回 null。
  /// 生成的计划不含摘要内容——调用方负责调用模型生成摘要
  /// （失败时回退 [trimContext]）。
  CompactionPlan? buildPlan(ChatSession session) {
    final max = contextLimitFor(session);
    if (max == null || !session.options.autoTrim) return null;
    final modelId = session.modelId;
    final summaryBudget = (max * session.options.summaryRatio.clamp(0.05, 0.5))
        .round();
    var total = TokenCounter.estimate(
      session.options.systemPrompt,
      modelId: modelId,
    ) + 4;
    final messages = session.messages;
    for (final m in messages) {
      total += estimateMessage(m, modelId);
    }
    if (total <= max) return null;
    if (messages.length <= 1) return null;

    final keepRecent = session.options.keepRecentMessages.clamp(2, 500);
    final removed = <ChatMessage>[];
    final retained = <ChatMessage>[...messages];
    var i = 0;
    while (retained.length > keepRecent && i < retained.length) {
      if (retained[i].role != 'user') {
        // 跳过游离的 assistant 尾（压缩后由首尾修正处理）
        i++;
        continue;
      }
      // 本轮的结束：下一个 user 或消息末尾
      var end = i + 1;
      while (end < retained.length && retained[end].role != 'user') {
        end++;
      }
      final turn = retained.sublist(i, end);
      var turnTokens = 0;
      for (final m in turn) {
        turnTokens += estimateMessage(m, modelId);
      }
      removed.addAll(turn);
      retained.removeRange(i, end);
      total -= turnTokens;
      if (total + summaryBudget <= max) break;
    }
    if (removed.isEmpty) return null;
    // 首位非 user 修正（Anthropic/Gemini 要求 user 开头）
    while (retained.isNotEmpty && retained.first.role != 'user') {
      removed.insert(0, retained.removeAt(0));
    }
    // 计算压缩起点：被移除消息在原始数组中的位置
    final removedIds = {for (final m in removed) identityHashCode(m)};
    final startIndex =
        messages.indexWhere((m) => removedIds.contains(identityHashCode(m)));
    return CompactionPlan(
      removedMessages: removed,
      retainedMessages: retained,
      summaryBudget: summaryBudget,
      startIndex: startIndex < 0 ? 0 : startIndex,
    );
  }

  /// 落地压缩计划：替换消息列表、写入会话摘要与压缩记录。
  void applyCompaction(
    ChatSession session,
    CompactionPlan plan, {
    required String summary,
  }) {
    final now = DateTime.now();
    session.messages
      ..clear()
      ..addAll(plan.retainedMessages);
    session.summary = summary.trim();
    session.summaryTokens = TokenCounter.estimate(
      session.summary,
      modelId: session.modelId,
    );
    session.compressedBlocks = [
      ...session.compressedBlocks,
      CompressedBlock(
        id: now.microsecondsSinceEpoch.toString(),
        startIndex: plan.startIndex,
        endIndex: plan.startIndex + plan.removedMessages.length - 1,
        summary: session.summary,
        messages: plan.removedMessages,
        createdAt: now,
      ),
    ];
    session.updatedAt = now;
  }

  /// 清空会话摘要与压缩记录（用户主动清除）。
  void clearCompaction(ChatSession session) {
    session.summary = '';
    session.summaryTokens = null;
    session.compressedBlocks = [];
  }
}

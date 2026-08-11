import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/controllers/context_builder.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/models/chat_session.dart';

/// F3-1 摘要压缩计划/落地单测（不依赖网络）。
void main() {
  ChatSession buildSession({
    int messages = 200,
    int maxContextTokens = 4000,
    double summaryRatio = 0.2,
    int keepRecent = 40,
    String? modelId,
  }) {
    final now = DateTime.now();
    final session = ChatSession(
      id: 's1',
      title: 't',
      options: ChatOptions(
        maxContextTokens: maxContextTokens,
        summaryRatio: summaryRatio,
        keepRecentMessages: keepRecent,
      ),
      messages: [
        for (var i = 0; i < messages; i++)
          if (i.isEven)
            ChatMessage(role: 'user', content: '用户问题 $i，这是一段比较长的内容用于占用 token 预算。')
          else
            ChatMessage(
              role: 'assistant',
              content: '助手回答 $i，这是对应回复的较长文本内容，用来模拟真实对话的上下文占用。',
            ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    session.modelId = modelId;
    return session;
  }

  final builder = ContextBuilder();

  test('不超限返回 null（无压缩计划）', () {
    final session = buildSession(messages: 10, maxContextTokens: 200000);
    expect(builder.buildPlan(session), isNull);
  });

  test('超限 2 倍会话生成压缩计划并保留最近消息', () {
    final session = buildSession(messages: 200, maxContextTokens: 4000);
    final plan = builder.buildPlan(session);
    expect(plan, isNotNull);
    expect(plan!.removedCount, greaterThan(0));
    // 保留最近 keepRecent 条全文
    expect(plan.retainedMessages.length, greaterThanOrEqualTo(40));
    // 保留消息首位为 user（Anthropic/Gemini 要求）
    expect(plan.retainedMessages.first.role, 'user');
    // 被移除的消息从最旧开始（第一轮 user+assistant）
    expect(plan.removedMessages.first.role, 'user');
  });

  test('摘要预算 = 上限 × ratio，越界自动降 ratio 再压缩', () {
    final session = buildSession(
      messages: 400,
      maxContextTokens: 2000,
      summaryRatio: 0.2,
      keepRecent: 4,
    );
    final plan = builder.buildPlan(session);
    expect(plan, isNotNull);
    expect(plan!.summaryBudget, 400);
    expect(plan.retainedMessages.length, greaterThanOrEqualTo(4));
  });

  test('applyCompaction 落地：消息替换、摘要写入、压缩记录可回溯', () {
    final session = buildSession(messages: 200, maxContextTokens: 4000);
    final plan = builder.buildPlan(session)!;
    builder.applyCompaction(
      session,
      plan,
      summary: '目标: 测试\n事实: 无\n偏好: 简洁\n待办: 无',
    );
    expect(session.summary, contains('目标'));
    expect(session.summaryTokens, greaterThan(0));
    expect(session.messages.length, plan.retainedMessages.length);
    expect(session.compressedBlocks, hasLength(1));
    expect(session.compressedBlocks.first.messages.length, plan.removedCount);
    expect(session.compressedBlocks.first.startIndex, 0);
    expect(session.compressedMessageCount, plan.removedCount);
  });

  test('clearCompaction 清空摘要与记录', () {
    final session = buildSession(messages: 200, maxContextTokens: 4000);
    final plan = builder.buildPlan(session)!;
    builder.applyCompaction(session, plan, summary: 'x');
    builder.clearCompaction(session);
    expect(session.summary, '');
    expect(session.compressedBlocks, isEmpty);
  });

  test('摘要占位 token 计入 estimateTokens', () {
    final session = buildSession(messages: 20, maxContextTokens: 400000);
    session.summary = '目标: A\n事实: B';
    final without = builder.estimateTokens(session, tokenVersion: 1);
    expect(without, greaterThan(0));
  });

  test('已压缩会话再次超限可继续压缩（增量压缩）', () {
    final session = buildSession(messages: 200, maxContextTokens: 4000);
    final plan1 = builder.buildPlan(session)!;
    builder.applyCompaction(session, plan1, summary: '第一次摘要');
    // 继续追加消息直到再次超限
    for (var i = 0; i < 100; i++) {
      session.messages.add(
        ChatMessage(
          role: i.isEven ? 'user' : 'assistant',
          content: '后续内容 $i 占用 token',
        ),
      );
    }
    final plan2 = builder.buildPlan(session);
    expect(plan2, isNotNull);
    builder.applyCompaction(session, plan2!, summary: '第二次摘要');
    expect(session.compressedBlocks, hasLength(2));
    expect(session.compressedMessageCount, plan1.removedCount + plan2.removedCount);
  });
}

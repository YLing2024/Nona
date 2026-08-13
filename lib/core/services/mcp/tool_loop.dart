import 'dart:convert';

import '../chat_service.dart';
import '../settings_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import 'approval_policy.dart';
import 'mcp_client.dart';

/// 工具调用循环：流式生成 → 模型请求工具 → 执行 → 结果回传 → 继续生成。
///
/// 循环上限 [maxRounds] 防止失控；每轮结果逐轮累积，
/// 最终返回汇总的 [ChatResult]（含全部轮次的内容与用量）。
class ToolLoopRunner {
  /// 执行一次完整的工具调用会话。
  ///
  /// [onToolCall]：执行工具并返回结果（由调用方接入 MCP/本地工具）。
  /// [onApprovalRequired]：每个工具执行前的审批钩子；返回拒绝时
  /// 跳过执行并以「denied by user」结果回传模型（模型可调整继续）。
  /// [onPartial]/[onReasoning]：仅首轮（模型直接回答）时回调流式增量。
  /// [isCancelled]：每轮开始前检查，取消则抛出 [ChatCancelledException]。
  /// [onNewHandle]：暴露当前轮句柄供取消传播。
  static Future<ChatResult> run({
    required AppSettings settings,
    required List<ChatMessage> messages,
    required ChatOptions options,
    List<Map<String, dynamic>>? tools,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? customBody,
    Future<McpToolResult> Function(ToolCallData call)? onToolCall,
    Future<ApprovalDecision> Function(ToolCallData call)? onApprovalRequired,
    void Function(String delta)? onPartial,
    void Function(String delta)? onReasoning,
    bool Function()? isCancelled,
    void Function(ChatRequestHandle handle)? onNewHandle,
    int maxRounds = 8,
  }) async {
    final current = List<ChatMessage>.from(messages);
    final fullContent = StringBuffer();
    ChatUsage? totalUsage;
    var totalElapsed = 0;
    List<ToolCallData>? lastToolCalls;

    for (var round = 0; round < maxRounds; round++) {
      if (isCancelled?.call() ?? false) {
        throw const ChatCancelledException();
      }
      final handle = ChatService().sendChat(
        settings: settings,
        messages: current,
        options: options,
        onPartial: round == 0 ? onPartial : null,
        onReasoning: round == 0 ? onReasoning : null,
        tools: tools,
        customHeaders: customHeaders,
        customBody: customBody,
      );
      onNewHandle?.call(handle);
      final result = await handle.result;
      totalElapsed += result.elapsedMs;
      totalUsage = _mergeUsage(totalUsage, result.usage);
      lastToolCalls = result.toolCalls;

      // 无工具调用：生成结束
      if (result.toolCalls == null || result.toolCalls!.isEmpty) {
        fullContent.write(result.content);
        return ChatResult(
          content: fullContent.toString(),
          usage: totalUsage,
          elapsedMs: totalElapsed,
          toolCalls: lastToolCalls,
        );
      }

      // 有工具调用：记录 assistant 消息并执行工具
      if (result.content.isNotEmpty) {
        fullContent.writeln(result.content);
      }
      current.add(
        ChatMessage(
          role: 'assistant',
          content: '',
          toolCallsJson: jsonEncode([
            for (final call in result.toolCalls!)
              {
                'id': call.id,
                'type': 'function',
                'function': {
                  'name': call.name,
                  'arguments': call.arguments,
                },
              },
          ]),
        ),
      );
      if (onToolCall == null) {
        // 无执行器：直接终止（避免死循环）
        return ChatResult(
          content: fullContent.toString(),
          usage: totalUsage,
          elapsedMs: totalElapsed,
          toolCalls: lastToolCalls,
        );
      }
      for (final call in result.toolCalls!) {
        McpToolResult toolResult;
        // 审批钩子：拒绝则跳过执行，把「denied」结果回传模型
        final decision = onApprovalRequired == null
            ? null
            : await onApprovalRequired(call);
        if (decision != null && !decision.allowed) {
          toolResult = const McpToolResult(
            content: 'tool execution denied by user',
            isError: true,
          );
          current.add(
            ChatMessage(
              role: 'tool',
              content: toolResult.content,
              toolCallId: call.id,
            ),
          );
          continue;
        }
        try {
          toolResult = await onToolCall(call);
        } catch (e) {
          toolResult = McpToolResult(
            content: 'tool execution failed: $e',
            isError: true,
          );
        }
        current.add(
          ChatMessage(
            role: 'tool',
            content: toolResult.content,
            toolCallId: call.id,
          ),
        );
      }
    }
    // 轮数耗尽：返回已累积内容
    return ChatResult(
      content: fullContent.toString(),
      usage: totalUsage,
      elapsedMs: totalElapsed,
      toolCalls: lastToolCalls,
    );
  }

  static ChatUsage? _mergeUsage(ChatUsage? a, ChatUsage? b) {
    if (b == null) return a;
    if (a == null) return b;
    return ChatUsage(
      promptTokens: a.promptTokens + b.promptTokens,
      completionTokens: a.completionTokens + b.completionTokens,
      totalTokens: (a.totalTokens ?? 0) + (b.totalTokens ?? 0),
    );
  }
}

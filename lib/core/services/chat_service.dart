import 'dart:async';

import '../models/chat_message.dart';
import '../models/chat_options.dart';
import 'chat/chat_exceptions.dart';
import 'chat/chat_request_handle.dart';
import 'chat/request_runner.dart';
import 'mcp/approval_policy.dart';
import 'mcp/mcp_client.dart';
import 'mcp/tool_loop.dart';
import 'settings_service.dart';

export 'chat/chat_exceptions.dart';
export 'chat/chat_request_handle.dart';

/// 一次回复的 token 用量。
class ChatUsage {
  final int promptTokens;
  final int completionTokens;
  final int? totalTokens;

  const ChatUsage({
    required this.promptTokens,
    required this.completionTokens,
    this.totalTokens,
  });

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt(),
    );
  }
}

/// 一次聊天请求的完整结果。
class ChatResult {
  final String content;
  final ChatUsage? usage;
  final int elapsedMs;

  /// 模型请求的工具调用（非空表示需要执行工具后继续生成）。
  final List<ToolCallData>? toolCalls;

  const ChatResult({
    required this.content,
    this.usage,
    required this.elapsedMs,
    this.toolCalls,
  });
}

/// 一次工具调用请求。
class ToolCallData {
  final String id;
  final String name;
  final String arguments;

  const ToolCallData({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// 调用 OpenAI 兼容 chat/completions 接口的服务门面。
///
/// 传输与解析细节委托 [RequestRunner] / [SseStreamParser] / 协议适配器。
class ChatService {
  /// 流式空闲超时（两次数据块之间无数据视为超时）。
  static const Duration kIdleTimeout = Duration(seconds: 120);

  /// 发送对话历史，返回助手的完整回复。
  ///
  /// [onPartial]：流式输出时逐块回调正文增量（非流式不回调）。
  /// [onReasoning]：流式输出时逐块回调思考内容增量。
  /// 返回句柄：[handle.result] 正常完成时携带完整回复与用量，
  /// 用户调用 [handle.cancel] 后以 [ChatCancelledException] 结束。
  ChatRequestHandle sendChat({
    required AppSettings settings,
    required List<ChatMessage> messages,
    ChatOptions options = const ChatOptions(),
    void Function(String delta)? onPartial,
    void Function(String delta)? onReasoning,
    List<Map<String, dynamic>>? tools,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? customBody,
  }) {
    return RequestRunner(
      settings: settings,
      messages: messages,
      options: options,
      onPartial: onPartial,
      onReasoning: onReasoning,
      tools: tools,
      customHeaders: customHeaders,
      customBody: customBody,
    ).start();
  }

  /// 带工具调用循环的发送：生成 → 模型请求工具 → 执行 → 回传 → 继续。
  ///
  /// [onToolCall] 执行工具并返回结果；取消会中止当前轮并结束。
  /// 返回的句柄与 [sendChat] 语义一致。
  ChatRequestHandle sendChatWithTools({
    required AppSettings settings,
    required List<ChatMessage> messages,
    ChatOptions options = const ChatOptions(),
    List<Map<String, dynamic>>? tools,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? customBody,
    Future<McpToolResult> Function(ToolCallData call)? onToolCall,
    Future<ApprovalDecision> Function(ToolCallData call)? onApprovalRequired,
    void Function(String delta)? onPartial,
    void Function(String delta)? onReasoning,
  }) {
    final completer = Completer<ChatResult>();
    ChatRequestHandle? currentHandle;
    var cancelled = false;

    Future<void> cancel() async {
      cancelled = true;
      await currentHandle?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const ChatCancelledException());
      }
    }

    final handle = ChatRequestHandle(
      result: completer.future,
      cancelFn: cancel,
    );
    unawaited(() async {
      try {
        final result = await ToolLoopRunner.run(
          settings: settings,
          messages: messages,
          options: options,
          tools: tools,
          customHeaders: customHeaders,
          customBody: customBody,
          onToolCall: onToolCall,
          onApprovalRequired: onApprovalRequired,
          onPartial: onPartial,
          onReasoning: onReasoning,
          isCancelled: () => cancelled,
          onNewHandle: (h) => currentHandle = h,
        );
        completer.complete(result);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    }());
    return handle;
  }

  /// 发送一次简短的非流式请求，返回助手正文。
  ///
  /// 用于自动生成标题等轻量场景：固定低 temperature、限制 maxTokens。
  /// 失败或返回空内容时抛出异常，由调用方决定降级策略。
  Future<String> sendSimple({
    required AppSettings settings,
    required String userMessage,
    String systemPrompt = '',
    int maxTokens = 30,
  }) async {
    final handle = sendChat(
      settings: settings,
      messages: [ChatMessage(role: 'user', content: userMessage)],
      options: ChatOptions(
        stream: false,
        maxTokens: maxTokens,
        temperature: 0.0,
        systemPrompt: systemPrompt,
      ),
    );
    final result = await handle.result;
    final content = result.content.trim();
    if (content.isEmpty) {
      throw const ChatException('', code: ChatException.emptyResponse);
    }
    return content;
  }
}

import 'dart:convert';

import '../chat_service.dart' show ChatUsage, ToolCallData;
import '../chat_protocol.dart' show ProtocolAdapter;
import '../protocol/protocol_adapter.dart' show DeltaStatus, ToolCallDelta;
import '../../utils/logger.dart';
import 'chat_exceptions.dart';

/// SSE `data:` 结束标记（OpenAI 流式）。
bool isSseDoneMarker(String data) => data == '[DONE]';

/// 流式 tool_calls 增量累积器（OpenAI delta 按 index 分片到达）。
class _ToolCallAccumulator {
  String id = '';
  String name = '';
  String arguments = '';
}

/// SSE 响应流逐行解析器（纯状态机，不持有网络/定时器）。
///
/// 职责：
/// - 行分类（`data:` 行 / 整包 JSON 行）与 JSON 解码
/// - 协议增量分发（[ProtocolAdapter.parseDelta]，三态契约见 [DeltaStatus]）
/// - 流式 tool_calls 分片按 index 合并（分片来自各适配器的 [ToolCallDelta]）
/// - 非流式 / 服务端忽略 stream 参数时的整包 JSON 兜底解析
///
/// 输出通过回调与公开状态暴露；结束分支（成功/错误码）由调用方
/// 检查 [error] 与 [hasOutput] 决定。
class SseStreamParser {
  final ProtocolAdapter protocol;

  /// 是否为流式请求（影响未知块 / 整包 JSON 的暂存分支）。
  final bool streaming;

  /// 每收到一行时回调（调用方用于日志捕获；需在解析前执行）。
  void Function(String line)? onRawLine;

  /// 取消检查；返回 true 时跳过本行解析。
  bool Function()? isCancelled;

  /// 正文增量（已累积进 [content]）。
  void Function(String delta)? onContent;

  /// 思考内容增量（已累积进 [reasoning]）。
  void Function(String delta)? onReasoning;

  SseStreamParser({
    required this.protocol,
    required this.streaming,
    this.onRawLine,
    this.isCancelled,
    this.onContent,
    this.onReasoning,
  });

  /// 累积正文。
  final StringBuffer content = StringBuffer();

  /// 累积思考内容。
  final StringBuffer reasoning = StringBuffer();

  /// 非 `data:` 行暂存（整包 JSON 可能分多行到达，供结束兜底合并解析）。
  final List<String> rawBuffer = [];

  /// 首个内容增量到达前收到的 `data:` 行（服务端忽略 stream 参数、
  /// 以单行 SSE 包装整包 JSON 时的兜底解析输入）。
  final List<String> pendingInitialData = [];

  /// 是否已暂存过「非本协议格式」的块（整包 JSON 兜底解析的触发条件）。
  bool _hasUnrecognized = false;

  /// 暂存字节数上限：防止恶意/畸形流内存无限增长。
  static const int _bufferCap = 512 * 1024;

  /// 已收到首个内容增量。
  bool gotDelta = false;

  /// 合并后的用量。
  ChatUsage? usage;

  /// 流式累积的工具调用（按 index 合并）。
  final Map<int, _ToolCallAccumulator> _toolCalls = {};

  /// 结束解析阶段设置的错误；null 表示可正常结束。
  ChatException? error;

  /// 是否已有输出（正文/思考/工具调用任一非空）。
  bool get hasOutput =>
      content.isNotEmpty || reasoning.isNotEmpty || _toolCalls.isNotEmpty;

  /// 是否累积到工具调用分片（含未完成分片）。
  bool get hasToolCalls => _toolCalls.isNotEmpty;

  /// 已累积的工具调用（仅 id/name 非空的）。
  List<ToolCallData> get collectedToolCalls => [
    for (final acc in _toolCalls.values)
      if (acc.id.isNotEmpty && acc.name.isNotEmpty)
        ToolCallData(id: acc.id, name: acc.name, arguments: acc.arguments),
  ];

  /// 追加一行到暂存缓冲；超限时清空并告警（防内存无限增长）。
  void _buffer(String line) {
    _bufferAll([line]);
  }

  void _bufferAll(List<String> lines) {
    rawBuffer.addAll(lines);
    var total = 0;
    for (final l in rawBuffer) {
      total += l.length;
    }
    if (total > _bufferCap) {
      Logger.warn('chat', 'SSE 暂存缓冲超过 512KB，丢弃（疑似畸形流）');
      rawBuffer.clear();
      _hasUnrecognized = false;
    }
  }
  /// 解析一行；返回后通过 [content]/[reasoning]/[usage]/[toolCalls] 读取状态。
  void handleLine(String line) {
    if (isCancelled?.call() ?? false) return;
    onRawLine?.call(line);
    if (!line.startsWith('data:')) {
      // 整包 JSON 可能分多行到达（非流式，或服务端忽略 stream 参数的兜底）：
      // 从首个 `{` 起暂存，待 handleDone 合并解析。
      // 流式 SSE 的空白行/注释行不会以 `{` 开头，不会被误收集。
      if (line.trimLeft().startsWith('{') || rawBuffer.isNotEmpty) {
        _hasUnrecognized = true;
        _buffer(line);
      }
      return;
    }
    final data = line.substring(5).trim();
    if (data.isEmpty || isSseDoneMarker(data)) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final parsed = protocol.parseDelta(json);
      switch (parsed.status) {
        case DeltaStatus.unrecognized:
          // 无法解析（如 Gemini 非流式包装的多行 JSON 首行，或流式模式下
          // 服务端忽略 stream 参数返回的单行整包 JSON）：暂存待 handleDone 兜底。
          _hasUnrecognized = true;
          if (!streaming) {
            _buffer(data);
          } else if (!gotDelta) {
            pendingInitialData.add(data);
          }
          return;
        case DeltaStatus.none:
          // 合法空块（role-only delta、空内容）：不缓存
          return;
        case DeltaStatus.delta:
          break;
      }
      final delta = parsed.delta!;
      // 工具调用分片合并（按 index；id 覆盖、name/arguments 拼接）
      final toolCalls = delta.toolCalls;
      if (toolCalls != null) {
        for (final tc in toolCalls) {
          _mergeToolCall(tc);
        }
      }
      if (delta.usage != null) {
        // 跨块合并用量：Anthropic 的 input_tokens 在 message_start，
        // output_tokens 在 message_delta，需合并而非覆盖
        final u = delta.usage!;
        usage = ChatUsage(
          promptTokens:
              u.promptTokens > 0 ? u.promptTokens : (usage?.promptTokens ?? 0),
          completionTokens: u.completionTokens > 0
              ? u.completionTokens
              : (usage?.completionTokens ?? 0),
          totalTokens: u.totalTokens ?? usage?.totalTokens,
        );
      }
      if (delta.done) return;
      if (delta.content != null && delta.content!.isNotEmpty) {
        content.write(delta.content);
        onContent?.call(delta.content!);
      }
      if (delta.reasoning != null && delta.reasoning!.isNotEmpty) {
        reasoning.write(delta.reasoning);
        onReasoning?.call(delta.reasoning!);
      }
      gotDelta = true;
    } catch (_) {
      // 非流式下 SSE 包装的多行 JSON：首行 `data: {` 无法单独解析，
      // 去掉前缀后暂存，等待 handleDone 与后续行合并解析。
      if (!streaming) {
        _hasUnrecognized = true;
        _buffer(data);
      }
    }
  }

  /// 合并一个工具调用分片到按 index 分组累积器。
  void _mergeToolCall(ToolCallDelta tc) {
    final acc = _toolCalls.putIfAbsent(tc.index, () => _ToolCallAccumulator());
    final id = tc.id;
    if (id != null && id.isNotEmpty) acc.id = id;
    final name = tc.name;
    if (name != null && name.isNotEmpty) acc.name += name;
    final arguments = tc.arguments;
    if (arguments != null && arguments.isNotEmpty) {
      acc.arguments += arguments;
    }
  }

  /// 流结束：若逐行解析未产出内容，尝试整包 JSON 兜底解析。
  ///
  /// 成功后内容写入 [content]；失败时设置 [error]（调用方据此结束请求）。
  void handleDone() {
    if (hasOutput) return;
    // 有工具调用或思考内容时即使正文为空也视为有效
    // （首轮 tool_calls / 只输出思考的回复不应报空）
    if (pendingInitialData.isNotEmpty && !gotDelta) {
      // 流式模式下服务端忽略 stream 参数、用单行 SSE 包装整包 JSON：
      // 首个增量前收到的 data 行已在 pendingInitialData 暂存
      final raw = pendingInitialData.join('\n').trim();
      if (raw.isNotEmpty) {
        _parseFullResponse(raw);
        return;
      }
    }
    if (rawBuffer.isNotEmpty && _hasUnrecognized) {
      // 逐行没解析到内容（非流式整包 JSON，或服务端忽略 stream
      // 参数返回整包 JSON）：把暂存的行合并后整体解析
      final raw = rawBuffer.join('\n').trim();
      if (raw.isNotEmpty) {
        _parseFullResponse(raw);
        return;
      }
    }
    // 服务端未返回任何内容（空响应），同样视为错误而非空结果
    error = const ChatException('', code: ChatException.emptyResponse);
  }

  /// 合并解析整包 JSON 并写入 [content]；失败设置 [error]。
  void _parseFullResponse(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = protocol.parseNonStream(data);
      if (parsed == null) {
        error = const ChatException('', code: ChatException.emptyResponse);
        return;
      }
      final (text, u) = parsed;
      if (u != null) usage = u;
      content.write(text);
    } catch (_) {
      error = const ChatException('', code: ChatException.invalidFormat);
    }
  }
}

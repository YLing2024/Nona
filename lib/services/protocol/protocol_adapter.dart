import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../chat_service.dart' show ChatUsage;
import 'protocol_factory.dart' show ProviderKind;

/// 一次 SSE 数据块解析结果。
class StreamDelta {
  final String? content;
  final String? reasoning;
  final ChatUsage? usage;

  /// 是否为结束标记（Anthropic message_stop / Gemini 空块等）。
  final bool done;

  /// 流式工具调用分片（按 index 累积；各适配器自行解析自家线格式）。
  final List<ToolCallDelta>? toolCalls;

  const StreamDelta({
    this.content,
    this.reasoning,
    this.usage,
    this.done = false,
    this.toolCalls,
  });
}

/// 工具调用增量分片（OpenAI 流式按 index 分片到达，需按 index 合并）。
class ToolCallDelta {
  /// 分片所属工具调用（同一工具的各分片 index 相同）。
  final int index;

  /// 首片携带完整 id（后续片为 null）。
  final String? id;

  /// 首片携带函数名（后续片为 null；个别实现按片拼接）。
  final String? name;

  /// 参数 JSON 增量片段（按到达顺序拼接）。
  final String? arguments;

  const ToolCallDelta({
    required this.index,
    this.id,
    this.name,
    this.arguments,
  });
}

/// [parseDelta] 三态契约，消除「null 同时表示合法空块与无法解析」的歧义。
enum DeltaStatus {
  /// 合法空块（role-only delta、空内容、结束标记等）——不缓存。
  none,

  /// 正常增量（内容/思考/用量/工具分片）。
  delta,

  /// 非本协议格式（无法解析）——缓存至 rawBuffer 供整包 JSON 兜底。
  unrecognized,
}

/// 协议增量解析结果。
class ParsedDelta {
  final DeltaStatus status;
  final StreamDelta? delta;

  const ParsedDelta.none()
      : status = DeltaStatus.none,
        delta = null;

  const ParsedDelta.delta(StreamDelta d)
      : status = DeltaStatus.delta,
        delta = d;

  const ParsedDelta.unrecognized()
      : status = DeltaStatus.unrecognized,
        delta = null;
}

/// 聊天协议适配器：URL / 请求头 / 请求体 / 响应解析按协议差异封装。
///
/// 新增协议时新建实现类（如 Responses、图像协议），不改动既有适配器。
abstract class ProtocolAdapter {
  ProviderKind get kind;

  /// 请求 URL。
  Uri uriFor(String baseUrl, String model);

  /// 请求头（apiKey 已校验非空）。
  Map<String, String> headersFor(String apiKey);

  /// 请求体（[apiMessages] 已含前置系统提示词）。
  ///
  /// [tools] 为 OpenAI function calling 格式的原始定义
  /// `{type: 'function', function: {name, description, parameters}}`；
  /// 各适配器自行转换为自家协议格式（OpenAI 原样、Anthropic
  /// `input_schema`、Gemini `functionDeclarations`），不支持时忽略。
  Map<String, dynamic> buildBody(
    String model,
    ChatOptions options,
    List<ChatMessage> apiMessages,
    List<Map<String, dynamic>>? tools,
  );

  /// 解析一条 SSE `data:` 负载；三态语义见 [DeltaStatus]。
  ParsedDelta parseDelta(Map<String, dynamic> json);

  /// 非流式响应整包 JSON 解析（部分服务端忽略 stream 参数时兜底）。
  /// 从整包 JSON 中提取最终文本与用量；无法解析返回 null。
  (String, ChatUsage?)? parseNonStream(Map<String, dynamic> json);
}

/// 单次会话的上下文参数（OpenAI Chat Completions 配置）。
class ChatOptions {
  /// 系统提示词。
  final String systemPrompt;

  /// 采样温度，0~2，越高越发散。
  final double temperature;

  /// 核采样，0~1。
  final double topP;

  /// 生成的最大 token 数，null 表示由服务端决定。
  final int? maxTokens;

  /// 话题新鲜度惩罚，-2~2。
  final double presencePenalty;

  /// 频率惩罚，-2~2。
  final double frequencyPenalty;

  /// 一次生成几条候选回复，null 表示服务端默认（1）。
  final int? n;

  /// 停止序列，命中即停止生成。
  final List<String> stop;

  /// 随机种子，相同种子与输入可复现相似输出。
  final int? seed;

  /// 响应格式：null / 'text' / 'json_object'。
  final String? responseFormat;

  /// 思考强度：null / 'min' / 'low' / 'medium' / 'high'，null 表示自动。
  final String? reasoningEffort;

  /// 是否流式输出。
  final bool stream;

  /// 上下文窗口上限（tokens）：发送前估算超出时自动裁剪早期消息。
  /// null 表示不限制。
  final int? maxContextTokens;

  /// 是否允许自动裁剪超限的早期消息。
  final bool autoTrim;

  const ChatOptions({
    this.systemPrompt = '',
    this.temperature = 1.0,
    this.topP = 1.0,
    this.maxTokens,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.n,
    this.stop = const [],
    this.seed,
    this.responseFormat,
    this.reasoningEffort,
    this.stream = true,
    this.maxContextTokens,
    this.autoTrim = true,
  });

  static const _unset = Object();

  ChatOptions copyWith({
    String? systemPrompt,
    double? temperature,
    double? topP,
    Object? maxTokens = _unset,
    double? presencePenalty,
    double? frequencyPenalty,
    Object? n = _unset,
    List<String>? stop,
    Object? seed = _unset,
    Object? responseFormat = _unset,
    Object? reasoningEffort = _unset,
    bool? stream,
    Object? maxContextTokens = _unset,
    bool? autoTrim,
  }) {
    return ChatOptions(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens == _unset ? this.maxTokens : maxTokens as int?,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      n: n == _unset ? this.n : n as int?,
      stop: stop ?? this.stop,
      seed: seed == _unset ? this.seed : seed as int?,
      responseFormat: responseFormat == _unset
          ? this.responseFormat
          : responseFormat as String?,
      reasoningEffort: reasoningEffort == _unset
          ? this.reasoningEffort
          : reasoningEffort as String?,
      stream: stream ?? this.stream,
      maxContextTokens: maxContextTokens == _unset
          ? this.maxContextTokens
          : maxContextTokens as int?,
      autoTrim: autoTrim ?? this.autoTrim,
    );
  }

  factory ChatOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChatOptions();
    return ChatOptions(
      systemPrompt: json['systemPrompt'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 1.0,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      maxTokens: json['maxTokens'] as int?,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      n: json['n'] as int?,
      stop: (json['stop'] as List<dynamic>? ?? []).cast<String>(),
      seed: json['seed'] as int?,
      responseFormat: json['responseFormat'] as String?,
      reasoningEffort: json['reasoningEffort'] as String?,
      stream: json['stream'] as bool? ?? true,
      maxContextTokens: json['maxContextTokens'] as int?,
      autoTrim: json['autoTrim'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'systemPrompt': systemPrompt,
    'temperature': temperature,
    'topP': topP,
    'maxTokens': maxTokens,
    'presencePenalty': presencePenalty,
    'frequencyPenalty': frequencyPenalty,
    'n': n,
    'stop': stop,
    'seed': seed,
    'responseFormat': responseFormat,
    'reasoningEffort': reasoningEffort,
    'stream': stream,
    'maxContextTokens': maxContextTokens,
    'autoTrim': autoTrim,
  };
}

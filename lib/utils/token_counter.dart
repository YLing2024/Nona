import '../models/chat_message.dart';
import 'token_estimator.dart';

/// token 估算工具。
///
/// 优先使用 tiktoken 精确编码（[TokenEstimator]，按模型自动选择词表）；
/// 词表未加载（启动早期或加载失败）时回退到启发式近似。
class TokenCounter {
  static final RegExp _cjk = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF\u3040-\u30FF\uAC00-\uD7AF\u3000-\u303F\uFF00-\uFFEF]',
  );

  /// 估算一段文本的 token 数。
  ///
  /// [modelId] 用于选择匹配的 tiktoken 词表（o200k/cl100k）；
  /// 省略时使用默认 cl100k。
  static int estimate(String text, {String? modelId}) {
    final kind = modelId == null
        ? TokenizerKind.cl100kBase
        : tokenizerKindForModel(modelId);
    final exact = TokenEstimator.instance.estimateCount(text, kind: kind);
    if (exact != null) return exact;
    return _heuristic(text);
  }

  /// 启发式近似（词表未就绪时的兜底）：
  /// 英文与数字约 4 字符/token，CJK 约 1.5 字符/token。
  static int _heuristic(String text) {
    if (text.isEmpty) return 0;
    var cjkChars = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_cjk.hasMatch(char)) cjkChars++;
    }
    final otherChars = text.length - cjkChars;
    return (cjkChars / 1.5).ceil() + (otherChars / 4).ceil();
  }

  /// 估算一条消息的 token 数（含角色标记开销与图片开销）。
  static int estimateMessage(
    String role,
    String content, [
    List<ChatImage> images = const [],
    String? modelId,
  ]) {
    var total = estimate(content, modelId: modelId) + 4; // role 与分隔符等开销
    for (final img in images) {
      total += img.estimatedTokens;
    }
    return total;
  }

  /// 人性化展示 token 数。
  static String format(int tokens) {
    if (tokens >= 10000) return '${(tokens / 1000).toStringAsFixed(1)}k';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(2)}k';
    return '$tokens';
  }
}

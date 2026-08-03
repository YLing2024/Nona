/// 启发式 token 估算工具。
///
/// 不依赖外部分词库，采用业界通用的近似规则：
/// - 英文与数字：约 4 个字符 ≈ 1 token
/// - 中文等 CJK：约 1.5 个字符 ≈ 1 token（取整）
/// 误差通常在 ±20% 以内，足够用于上下文窗口管理。
class TokenCounter {
  static final RegExp _cjk = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF\u3040-\u30FF\uAC00-\uD7AF\u3000-\u303F\uFF00-\uFFEF]',
  );

  /// 估算一段文本的 token 数。
  static int estimate(String text) {
    if (text.isEmpty) return 0;
    var cjkChars = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_cjk.hasMatch(char)) cjkChars++;
    }
    final otherChars = text.length - cjkChars;
    return (cjkChars / 1.5).ceil() + (otherChars / 4).ceil();
  }

  /// 估算一条消息的 token 数（含角色标记开销）。
  static int estimateMessage(String role, String content) {
    return estimate(content) + 4; // role 与分隔符等开销
  }

  /// 人性化展示 token 数。
  static String format(int tokens) {
    if (tokens >= 10000) return '${(tokens / 1000).toStringAsFixed(1)}k';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(2)}k';
    return '$tokens';
  }
}

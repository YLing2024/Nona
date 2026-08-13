/// E-02：TTS 文本分块器——句边界优先 + ASCII 空格补全 + 段落折叠。
class TextChunker {
  TextChunker._();

  /// 单块最大字符数。
  static const int defaultMaxChunkLength = 220;

  /// 中文/英文句边界字符。
  static const String _boundaries = '。！？；.!?;';

  /// 将文本切分为适合朗读的分块。
  ///
  /// 规则：
  /// - 优先在句边界（。！？；.!?;、换行）切分，块长 ≤ [maxChunkLength]；
  /// - 英文单词跨边界时回退到最近的 ASCII 空格（避免切断单词）；
  /// - 无法在边界内切分时硬切；
  /// - 块间（段落折叠）：连续空白折叠为单空格。
  static List<String> split(String text, {int maxChunkLength = defaultMaxChunkLength}) {
    if (text.isEmpty) return const [];
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const [];
    if (normalized.length <= maxChunkLength) return [normalized];

    final result = <String>[];
    var start = 0;
    while (start < normalized.length) {
      var end = start + maxChunkLength;
      if (end >= normalized.length) {
        result.add(normalized.substring(start));
        break;
      }
      // 在 [start, end] 内找最后一个句边界
      var cut = -1;
      for (var i = end - 1; i > start; i--) {
        if (_boundaries.contains(normalized[i])) {
          cut = i + 1;
          break;
        }
      }
      // 无句边界：回退找最后一个空格（防切词）
      if (cut < 0) {
        final space = normalized.lastIndexOf(' ', end - 1);
        if (space > start + 20) cut = space;
      }
      if (cut < 0) cut = end;
      result.add(normalized.substring(start, cut));
      start = cut;
    }
    return result;
  }
}

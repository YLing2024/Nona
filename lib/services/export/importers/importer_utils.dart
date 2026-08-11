import '../../../models/chat_message.dart';

/// 生成跨格式稳定的会话 id（导入后重复导入不产生重复会话）。
String stableSessionId(String prefix, String raw) {
  final key = raw.trim();
  if (key.isEmpty) return '${DateTime.now().microsecondsSinceEpoch}';
  var hash = 0;
  for (final rune in key.runes) {
    hash = (hash * 31 + rune) & 0x7FFFFFFF;
  }
  return '$prefix-$hash';
}

/// 解析导入时间戳（毫秒/秒自适应，或 ISO 字符串）。
DateTime? parseImportTime(Object? v) {
  if (v is int) {
    // 毫秒/秒时间戳自适应
    final ms = v > 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// 从 URL 构造图片附件（data URL 走 base64 解析，否则按远程 URL 保留）。
ChatImage imageFromUrl(String url) => url.startsWith('data:')
    ? ChatImage.fromDataUrl(url)
    : ChatImage(url: url, mimeType: 'image/*');

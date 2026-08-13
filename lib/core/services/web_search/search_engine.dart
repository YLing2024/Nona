/// 一条搜索结果。
class SearchResultItem {
  final String title;
  final String url;
  final String snippet;

  const SearchResultItem({
    required this.title,
    required this.url,
    required this.snippet,
  });

  /// 注入 prompt 的单条格式：[n] 标题 — URL\n摘要
  String toPromptLine(int index) => '[${index + 1}] $title — $url\n$snippet';
}

/// 搜索引擎抽象：不同引擎（免费 HTML 解析 / API）统一接口。
abstract class SearchEngine {
  String get name;

  /// 是否需要 API Key。
  bool get needsApiKey => false;

  /// 搜索并返回结果列表（按相关度排序）。
  Future<List<SearchResultItem>> search(String query, {int maxResults = 5});
}

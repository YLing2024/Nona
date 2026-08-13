import '../settings_service.dart';
import 'engines.dart';
import 'search_engine.dart';

/// 搜索执行结果：区分「成功但无结果」与「失败」，
/// UI 据此决定提示「无相关内容」还是引导配置引擎。
class SearchOutcome {
  final bool ok;
  final List<SearchResultItem> items;
  final String? error;

  const SearchOutcome._({
    required this.ok,
    this.items = const [],
    this.error,
  });

  const SearchOutcome.ok(List<SearchResultItem> items)
      : this._(ok: true, items: items);

  const SearchOutcome.fail(String error) : this._(ok: false, error: error);
}

/// 网络搜索门面：按设置选择引擎并注入上下文。
class WebSearchService {
  /// 支持的引擎列表。
  static const engineNames = ['bing', 'duckduckgo', 'tavily', 'bocha', 'searxng'];

  /// 按配置创建引擎；配置不完整（缺 API Key）返回 null。
  SearchEngine? engineFor(AppSettings settings) {
    switch (settings.webSearchEngine) {
      case 'bing':
        return BingSearchEngine();
      case 'duckduckgo':
        return DuckDuckGoSearchEngine();
      case 'tavily':
        if (settings.webSearchApiKey.trim().isEmpty) return null;
        return TavilySearchEngine(settings.webSearchApiKey.trim());
      case 'bocha':
        if (settings.webSearchApiKey.trim().isEmpty) return null;
        return BochaSearchEngine(settings.webSearchApiKey.trim());
      case 'searxng':
        if (settings.webSearchBaseUrl.trim().isEmpty) return null;
        return SearxngSearchEngine(settings.webSearchBaseUrl.trim());
      default:
        return BingSearchEngine();
    }
  }

  /// 引擎展示名（引擎名 + 是否需要 Key 提示）。
  static String engineLabel(String name) => switch (name) {
    'bing' => 'Bing (free)',
    'duckduckgo' => 'DuckDuckGo (free)',
    'tavily' => 'Tavily (API Key required)',
    'bocha' => 'Bocha (API Key required)',
    'searxng' => 'SearXNG (self-hosted)',
    _ => name,
  };

  /// 执行搜索；失败返回 [SearchOutcome.fail]（不阻断对话）。
  Future<SearchOutcome> search(
    AppSettings settings,
    String query, {
    int maxResults = 5,
  }) async {
    final engine = engineFor(settings);
    if (engine == null) {
      return SearchOutcome.fail('no engine configured');
    }
    try {
      final items = await engine.search(query, maxResults: maxResults);
      return SearchOutcome.ok(items);
    } catch (e) {
      return SearchOutcome.fail(e.toString());
    }
  }

  /// 将搜索结果格式化为注入系统提示词的文本（带引用编号）。
  static String resultsToPrompt(List<SearchResultItem> results) {
    if (results.isEmpty) return '';
    final sb = StringBuffer();
    sb.writeln('Here are real-time web search results. Base your answer on them '
        'and cite sources using [citation](number):');
    for (var i = 0; i < results.length; i++) {
      sb.writeln(results[i].toPromptLine(i));
    }
    return sb.toString();
  }
}

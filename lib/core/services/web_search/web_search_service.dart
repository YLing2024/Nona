import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../settings_service.dart';
import '../usage/usage_stats_service.dart';
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
///
/// D-01：16 引擎注册表；D-02：逐引擎 Key + 用量统计。
class WebSearchService {
  /// 支持的引擎列表（16 个）。
  static const engineNames = [
    'bing',
    'duckduckgo',
    'tavily',
    'bocha',
    'searxng',
    'brave',
    'exa',
    'grok',
    'jina',
    'linkup',
    'metaso',
    'ollama',
    'perplexity',
    'querit',
    'serper',
    'zhipu',
  ];

  /// 按配置创建引擎；配置不完整（缺 API Key）返回 null。
  SearchEngine? engineFor(AppSettings settings) {
    // D-01：webSearchApiKeys 为引擎 id → key 映射；旧单值键兼容
    String keyFor(String id) {
      final fromMap = settings.webSearchApiKeys[id];
      if (fromMap != null && fromMap.isNotEmpty) return fromMap;
      // 旧版单值（tavily/bocha 共用）
      return settings.webSearchApiKey.trim();
    }

    switch (settings.webSearchEngine) {
      case 'bing':
        return BingSearchEngine();
      case 'duckduckgo':
        return DuckDuckGoSearchEngine();
      case 'tavily':
        if (keyFor('tavily').isEmpty) return null;
        return TavilySearchEngine(keyFor('tavily'));
      case 'bocha':
        if (keyFor('bocha').isEmpty) return null;
        return BochaSearchEngine(keyFor('bocha'));
      case 'searxng':
        if (settings.webSearchBaseUrl.trim().isEmpty) return null;
        return SearxngSearchEngine(settings.webSearchBaseUrl.trim());
      case 'brave':
        if (keyFor('brave').isEmpty) return null;
        return BraveSearchEngine(keyFor('brave'));
      case 'exa':
        if (keyFor('exa').isEmpty) return null;
        return ExaSearchEngine(keyFor('exa'));
      case 'grok':
        if (keyFor('grok').isEmpty) return null;
        return GrokSearchEngine(keyFor('grok'));
      case 'jina':
        return JinaSearchEngine(keyFor('jina'));
      case 'linkup':
        if (keyFor('linkup').isEmpty) return null;
        return LinkUpSearchEngine(keyFor('linkup'));
      case 'metaso':
        if (keyFor('metaso').isEmpty) return null;
        return MetasoSearchEngine(keyFor('metaso'));
      case 'ollama':
        if (keyFor('ollama').isEmpty) return null;
        return OllamaSearchEngine(keyFor('ollama'));
      case 'perplexity':
        if (keyFor('perplexity').isEmpty) return null;
        return PerplexitySearchEngine(keyFor('perplexity'));
      case 'querit':
        if (keyFor('querit').isEmpty) return null;
        return QueritSearchEngine(keyFor('querit'));
      case 'serper':
        if (keyFor('serper').isEmpty) return null;
        return SerperSearchEngine(keyFor('serper'));
      case 'zhipu':
        if (keyFor('zhipu').isEmpty) return null;
        return ZhipuSearchEngine(keyFor('zhipu'));
      default:
        return BingSearchEngine();
    }
  }

  /// 引擎展示名（引擎名 + 是否需要 Key 提示）。
  static String engineLabel(String name) => switch (name) {
    'bing' => 'Bing (free)',
    'duckduckgo' => 'DuckDuckGo (free)',
    'tavily' => 'Tavily (API Key)',
    'bocha' => 'Bocha (API Key)',
    'searxng' => 'SearXNG (self-hosted)',
    'brave' => 'Brave (API Key)',
    'exa' => 'Exa (API Key)',
    'grok' => 'Grok (API Key)',
    'jina' => 'Jina (API Key)',
    'linkup' => 'LinkUp (API Key)',
    'metaso' => 'Metaso (API Key)',
    'ollama' => 'Ollama (API Key)',
    'perplexity' => 'Perplexity (API Key)',
    'querit' => 'Querit (API Key)',
    'serper' => 'Serper (API Key)',
    'zhipu' => 'Zhipu (API Key)',
    _ => name,
  };

  /// 引擎是否需要 Key。
  static bool needsKey(String name) => switch (name) {
    'bing' || 'duckduckgo' || 'searxng' || 'jina' => false,
    _ => true,
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
      // D-02：搜索用量统计（开关可控）
      if (settings.searchUsageEnabled) {
        unawaited(
          UsageStatsService().recordSearch(
            engine: settings.webSearchEngine,
            calls: 1,
          ),
        );
      }
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

/// D-02：搜索 Key 管理（引擎 → 多 Key 池，持久化 prefs）。
class SearchKeyStore {
  static const _kPrefsKey = 'search_engine_keys';

  /// 读取全部引擎的多 Key 池。
  static Future<Map<String, List<String>>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          e.key: (e.value as List<dynamic>? ?? []).cast<String>(),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, List<String>> pools) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(pools));
  }

  /// 取某引擎的当前生效 Key：多 Key 池非空时取第一个（轮换由
  /// KeyRoulette 承担），否则回退 settings 单值。
  static String effectiveKey(
    String engineId,
    Map<String, List<String>> pools,
    AppSettings settings,
  ) {
    final pool = pools[engineId];
    if (pool != null && pool.isNotEmpty) return pool.first;
    return settings.webSearchApiKey.trim();
  }
}

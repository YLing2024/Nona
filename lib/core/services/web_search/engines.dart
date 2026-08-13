import 'dart:convert';

import '../../network/app_http_client.dart';
import '../network_log_service.dart';
import 'search_engine.dart';

/// Bing 网页搜索：免费 HTML 解析（无需 API Key）。
class BingSearchEngine implements SearchEngine {
  final String _endpoint;

  BingSearchEngine({String endpoint = 'https://www.bing.com/search'})
    : _endpoint = endpoint;

  @override
  String get name => 'Bing';

  @override
  bool get needsApiKey => false;

  @override
  Future<List<SearchResultItem>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {'q': query, 'count': '$maxResults'},
    );
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/126.0 Safari/537.36',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      },
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode != 200) return const [];
    return BingSearchEngine.parseHtml(response.body, maxResults);
  }

  /// 解析 Bing 结果页：`li.b_algo` 内的 `h2 a`（标题/链接）与 `p`（摘要）。
  static List<SearchResultItem> parseHtml(String html, int maxResults) {
    final results = <SearchResultItem>[];
    // 提取 <li class="b_algo">...</li> 块（正则定位，避免完整 HTML 解析）
    final blockRe = RegExp(
      r'<li class="b_algo"[^>]*>(.*?)</li>',
      dotAll: true,
    );
    for (final block in blockRe.allMatches(html)) {
      if (results.length >= maxResults) break;
      final chunk = block.group(1)!;
      final titleMatch = RegExp(r'<h2[^>]*><a[^>]*href="([^"]+)"[^>]*>(.*?)</a>')
          .firstMatch(chunk);
      if (titleMatch == null) continue;
      final url = _resolveRealUrl(_unescape(titleMatch.group(1)!));
      final title = _stripTags(titleMatch.group(2)!);
      final snippetMatch = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
          .firstMatch(chunk);
      final snippet = snippetMatch == null
          ? ''
          : _stripTags(snippetMatch.group(1)!).trim();
      if (title.isEmpty) continue;
      results.add(
        SearchResultItem(title: title, url: url, snippet: snippet),
      );
    }
    return results;
  }

  /// Bing 结果链接是 `https://www.bing.com/ck/a?...&u=a1aHR0cHM6...` 的
  /// 重定向形式，真实 URL 是 base64url 编码在 `u` 参数里；
  /// 直接返回 ck/a 链接会让用户与 AI 引用错误的地址。
  static String _resolveRealUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == 'www.bing.com' &&
        (uri.path == '/ck/a' || uri.path.startsWith('/ck/?'))) {
      final u = uri.queryParameters['u'];
      if (u != null && u.isNotEmpty) {
        try {
          final decoded = utf8.decode(base64Url.decode(
            u.replaceAll('_', '/').replaceAll('-', '+'),
          ));
          if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
            return decoded;
          }
        } catch (_) {}
      }
    }
    return url;
  }

  static String _stripTags(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();

  static String _unescape(String s) => _stripTags(s);
}

/// DuckDuckGo Lite：免费 HTML 解析（无需 API Key）。
class DuckDuckGoSearchEngine implements SearchEngine {
  @override
  String get name => 'DuckDuckGo';

  @override
  bool get needsApiKey => false;

  @override
  Future<List<SearchResultItem>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final uri = Uri.parse('https://lite.duckduckgo.com/lite/').replace(
      queryParameters: {'q': query},
    );
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/126.0 Safari/537.36',
      },
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode != 200) return const [];
    return _parseHtml(response.body, maxResults);
  }

  /// DDG Lite 结果在表格行中：`<a rel="nofollow" href="URL">标题</a>` 后跟摘要。
  List<SearchResultItem> _parseHtml(String html, int maxResults) {
    final results = <SearchResultItem>[];
    final linkRe = RegExp(
      r'<a rel="nofollow" href="([^"]+)"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final snippetRe = RegExp(
      r'<td[^>]*result-snippet[^>]*>(.*?)</td>',
      dotAll: true,
    );
    final snippets = snippetRe.allMatches(html).map((m) => m.group(1)).toList();
    final matches = linkRe.allMatches(html).toList();
    var snippetIdx = 0;
    for (var i = 0; i < matches.length && results.length < maxResults; i++) {
      final url = _cleanUrl(matches[i].group(1)!);
      final title = _stripTags(matches[i].group(2)!).trim();
      if (title.isEmpty || url.isEmpty) continue;
      // 优先取独立摘要单元格，避免把分页/表格噪音混进摘要
      String snippet;
      if (snippetIdx < snippets.length) {
        snippet = _stripTags(snippets[snippetIdx++]!).trim();
      } else {
        final start = matches[i].end;
        final end = i + 1 < matches.length ? matches[i + 1].start : html.length;
        snippet = _stripTags(html.substring(start, end)).trim();
      }
      results.add(
        SearchResultItem(title: title, url: url, snippet: snippet),
      );
    }
    return results;
  }

  /// DDG 结果链接为 `//duckduckgo.com/l/?uddg=<urlencoded>` 重定向，
  /// 解码 uddg 参数得到真实地址。
  static String _cleanUrl(String url) {
    var clean = url.startsWith('//') ? 'https:$url' : url;
    clean = clean.replaceAll(RegExp(r'&amp;'), '&');
    final uri = Uri.tryParse(clean);
    if (uri != null &&
        uri.host.endsWith('duckduckgo.com') &&
        uri.path == '/l/') {
      final target = uri.queryParameters['uddg'];
      if (target != null && target.isNotEmpty) return target;
    }
    return clean;
  }

  static String _stripTags(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Tavily API：需 API Key。
class TavilySearchEngine implements SearchEngine {
  final String apiKey;
  final String _endpoint;

  TavilySearchEngine(this.apiKey, {String endpoint = 'https://api.tavily.com/search'})
      : _endpoint = endpoint;

  @override
  String get name => 'Tavily';

  @override
  bool get needsApiKey => true;

  @override
  Future<List<SearchResultItem>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: Uri.parse(_endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': apiKey,
        'query': query,
        'max_results': maxResults,
        'search_depth': 'basic',
      }),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 20),
    );
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    return [
      for (final r in results)
        if (r is Map<String, dynamic>)
          SearchResultItem(
            title: r['title'] as String? ?? '',
            url: r['url'] as String? ?? '',
            snippet: r['content'] as String? ?? '',
          ),
    ];
  }
}

/// 博查搜索（Bocha AI）：中文网络搜索 API，需 API Key。
///
/// 文档：https://open.bochaai.com/ （接口为 POST https://api.bochaai.com/v1/web-search，
/// 认证方式 Authorization: Bearer `key`，结果在 data.webPages.value）。
class BochaSearchEngine implements SearchEngine {
  final String apiKey;
  final String _endpoint;

  BochaSearchEngine(
    this.apiKey, {
    String endpoint = 'https://api.bochaai.com/v1/web-search',
  }) : _endpoint = endpoint;

  @override
  String get name => 'Bocha';

  @override
  bool get needsApiKey => true;

  @override
  Future<List<SearchResultItem>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'query': query,
        'count': maxResults.clamp(1, 50),
        'freshness': 'noLimit',
        'summary': true,
      }),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 20),
    );
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 200) return const [];
    final pages = (data['data'] as Map<String, dynamic>?)?['webPages']
        as Map<String, dynamic>?;
    final results = pages?['value'] as List<dynamic>? ?? const [];
    return [
      for (final r in results)
        if (r is Map<String, dynamic>)
          SearchResultItem(
            title: r['name'] as String? ?? '',
            url: r['url'] as String? ?? '',
            // summary 需请求时带 summary:true，缺省回退 snippet
            snippet: (r['summary'] as String? ?? r['snippet'] as String?) ?? '',
          ),
    ];
  }
}

/// SearXNG（自托管）：JSON API，需服务地址。
class SearxngSearchEngine implements SearchEngine {
  final String baseUrl;

  SearxngSearchEngine(this.baseUrl);

  @override
  String get name => 'SearXNG';

  @override
  bool get needsApiKey => false;

  @override
  Future<List<SearchResultItem>> search(
    String query, {
    int maxResults = 5,
  }) async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'safesearch': '0',
      },
    );
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    final list = [
      for (final r in results)
        if (r is Map<String, dynamic>)
          SearchResultItem(
            title: r['title'] as String? ?? '',
            url: r['url'] as String? ?? '',
            snippet: r['content'] as String? ?? '',
          ),
    ]..removeWhere((r) => r.title.isEmpty && r.snippet.isEmpty);
    // 注意：cascade 的 take() 结果会被丢弃，必须接收返回值
    return list.take(maxResults).toList();
  }
}

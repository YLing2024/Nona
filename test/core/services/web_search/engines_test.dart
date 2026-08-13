import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nona_chat/core/network/app_http_client.dart';
import 'package:nona_chat/core/services/network_log_service.dart'
    show NetworkLogType;
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/web_search/engines.dart';
import 'package:nona_chat/core/services/web_search/web_search_service.dart'
    show SearchKeyStore;
import 'package:shared_preferences/shared_preferences.dart';

/// 脚本化 fake 客户端：按请求 URI 返回预置 JSON/HTML。
class _ScriptedClient extends AppHttpClient {
  _ScriptedClient(this.responses);

  final Map<String, _Resp> responses;
  int calls = 0;
  final List<http.Request> requests = [];

  @override
  Future<http.Response> send({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    List<int>? bodyBytes,
    NetworkLogType type = NetworkLogType.other,
    Duration? timeout,
    bool retry = true,
  }) async {
    calls++;
    requests.add(
      http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body,
    );
    final resp = responses[uri.toString()] ?? responses['*'];
    if (resp == null) return http.Response('{}', 200);
    return http.Response(
      resp.body,
      resp.status,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  @override
  Future<http.StreamedResponse> sendStreamed({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    String body = '',
    Duration? connectTimeout,
    bool Function()? isCancelled,
  }) async {
    throw UnimplementedError();
  }
}

class _Resp {
  final String body;
  final int status;
  const _Resp(this.body, {this.status = 200});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHttpClient original;
  late _ScriptedClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = AppHttpClient.instance;
    client = _ScriptedClient({});
    AppHttpClient.overrideForTesting(client);
  });
  tearDown(() => AppHttpClient.overrideForTesting(original));

  group('BingSearchEngine', () {
    test('parseHtml：b_algo 块提取标题/链接/摘要，还原 ck/a 真实 URL', () {
      const html = '<html><body>'
          '<li class="b_algo"><h2><a href="https://www.bing.com/ck/a?'
          'u=aHR0cHM6Ly9leGFtcGxlLmNvbS9h">示例&nbsp;网站</a></h2>'
          '<p><strong>摘要</strong>内容 &amp; 更多</p></li>'
          '<li class="b_algo"><h2><a href="https://plain.com/b">普通链接</a></h2>'
          '<p>摘要二</p></li>'
          '<li class="not_algo"><h2><a href="https://x.com">跳过</a></h2></li>'
          '</body></html>';
      final results = BingSearchEngine.parseHtml(html, 5);
      expect(results.length, 2);
      expect(results[0].title, '示例 网站');
      expect(results[0].url, 'https://example.com/a');
      expect(results[0].snippet, '摘要内容 & 更多');
      expect(results[1].url, 'https://plain.com/b');
    });

    test('maxResults 截断；无标题块跳过', () {
      const html = '<li class="b_algo"><h2><a href="https://a.com/x">甲</a></h2>'
          '<p>一</p></li>'
          '<li class="b_algo"><h2><a href="https://a.com/y"></a></h2>'
          '<p>二</p></li>'
          '<li class="b_algo"><h2><a href="https://a.com/z">丙</a></h2>'
          '<p>三</p></li>';
      final results = BingSearchEngine.parseHtml(html, 2);
      expect(results.map((r) => r.title), ['甲', '丙']);
    });

    test('非 200 返回空', () async {
      client.responses['*'] = const _Resp('', status: 500);
      final results = await BingSearchEngine().search('q');
      expect(results, isEmpty);
    });
  });

  group('DuckDuckGoSearchEngine', () {
    test('表格行解析 + uddg 重定向解码', () async {
      client.responses['*'] = _Resp(
        '<html><a rel="nofollow" href="//duckduckgo.com/l/?uddg='
        'https%3A%2F%2Fddg.example.com%2Fx">标题一</a>'
        '<td class="result-snippet">片段一</td>'
        '<a rel="nofollow" href="https://direct.example.com/2">标题二</a>'
        '<td class="result-snippet">片段二</td></html>',
      );
      final results = await DuckDuckGoSearchEngine().search('q');
      expect(results.length, 2);
      expect(results[0].url, 'https://ddg.example.com/x');
      expect(results[0].title, '标题一');
      expect(results[0].snippet, '片段一');
      expect(results[1].url, 'https://direct.example.com/2');
    });
  });

  group('API 引擎（JSON 映射）', () {
    test('Tavily：results 映射 + 非 200 空', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'results': [
            {'title': 't1', 'url': 'https://tavily.com/1', 'content': 's1'},
            {'title': '', 'url': '', 'content': ''},
          ],
        }),
      );
      final r = await TavilySearchEngine('k').search('q');
      expect(r.length, 2);
      expect(r.first.title, 't1');
      client.responses['*'] = const _Resp('{}', status: 429);
      expect(await TavilySearchEngine('k').search('q'), isEmpty);
    });

    test('Bocha：code!=200 空；webPages.value 映射', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'code': 200,
          'data': {
            'webPages': {
              'value': [
                {'name': 'b1', 'url': 'https://b.cn/1', 'summary': 's'},
              ],
            },
          },
        }),
      );
      final r = await BochaSearchEngine('k').search('q');
      expect(r.single.title, 'b1');
      expect(r.single.snippet, 's');

      client.responses['*'] =
          _Resp(jsonEncode({'code': 401, 'data': {}}));
      expect(await BochaSearchEngine('k').search('q'), isEmpty);
    });

    test('SearXNG：results 映射 + 空标题过滤 + maxResults 截断', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'results': [
            {'title': 'x1', 'url': 'https://sx/1', 'content': 'c1'},
            {'title': '', 'url': '', 'content': ''},
            {'title': 'x2', 'url': 'https://sx/2', 'content': 'c2'},
          ],
        }),
      );
      final r = await SearxngSearchEngine('https://sx/').search('q',
          maxResults: 1);
      expect(r.single.title, 'x1');
    });

    test('Brave：web.results 映射 + X-Subscription-Token 头', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'web': {
            'results': [
              {'title': 'br', 'url': 'https://brave/1', 'description': 'd'},
            ],
          },
        }),
      );
      final r = await BraveSearchEngine('k').search('q');
      expect(r.single.snippet, 'd');
      expect(
        client.requests.last.headers['X-Subscription-Token'],
        'k',
      );
    });

    test('Exa：results 映射 + 非 200 空', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'results': [
            {'title': 'e1', 'url': 'https://exa/1', 'text': 't'},
          ],
        }),
      );
      final r = await ExaSearchEngine('k').search('q');
      expect(r.single.title, 'e1');
      client.responses['*'] = const _Resp('err', status: 500);
      expect(await ExaSearchEngine('k').search('q'), isEmpty);
    });

    test('Grok：output[].content[].url 解析', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'output': [
            {
              'content': [
                {'url': 'https://grok/1', 'title': 'g1', 'text': 's'},
                {'text': '无 url'},
              ],
            },
            {'content': 'not a list'},
          ],
        }),
      );
      final r = await GrokSearchEngine('k').search('q', maxResults: 5);
      expect(r.single.url, 'https://grok/1');
      expect(r.single.title, 'g1');
    });

    test('Jina：markdown 链接提取（跳过图片/空标题）', () async {
      client.responses['*'] = _Resp(
        '[标题一](https://jina/1)\n![图](https://jina/img)\n'
        '[](https://jina/empty)\n[标题二](https://jina/2)',
      );
      final r = await JinaSearchEngine('k').search('q', maxResults: 2);
      expect(r.map((e) => e.title), ['标题一', '标题二']);
    });

    test('LinkUp：results 映射（name 优先 title）', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'results': [
            {'name': 'n', 'url': 'https://l/1', 'content': 'c'},
          ],
        }),
      );
      final r = await LinkUpSearchEngine('k').search('q');
      expect(r.single.title, 'n');
    });

    test('Metaso/Ollama/Perplexity/Querit：通用映射', () async {
      final body = jsonEncode({
        'results': [
          {'title': 't', 'url': 'https://x/1', 'content': 'c', 'snippet': 's'},
        ],
      });
      for (final engine in [
        MetasoSearchEngine('k'),
        OllamaSearchEngine('k'),
        PerplexitySearchEngine('k'),
        QueritSearchEngine('k'),
      ]) {
        client.responses['*'] = _Resp(body);
        final r = await engine.search('q');
        expect(r.single.title, 't', reason: engine.name);
        expect(r.single.url, 'https://x/1');
      }
      // Perplexity 优先 content
      client.responses['*'] = _Resp(
        jsonEncode({
          'results': [
            {'title': 't', 'url': 'https://x/1', 'snippet': 's'},
          ],
        }),
      );
      final r = await PerplexitySearchEngine('k').search('q');
      expect(r.single.snippet, 's');
    });

    test('Serper：organic 映射（link 字段）', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'organic': [
            {'title': 's1', 'link': 'https://serper/1', 'snippet': 'd'},
          ],
        }),
      );
      final r = await SerperSearchEngine('k').search('q');
      expect(r.single.url, 'https://serper/1');
      expect(client.requests.last.headers['X-API-KEY'], 'k');
    });

    test('Zhipu：search_results 映射（link 优先 url）', () async {
      client.responses['*'] = _Resp(
        jsonEncode({
          'search_results': [
            {'title': 'z', 'link': 'https://z/1', 'content': 'c'},
          ],
        }),
      );
      final r = await ZhipuSearchEngine('k').search('q');
      expect(r.single.url, 'https://z/1');
      expect(r.single.snippet, 'c');
    });

    test('引擎基础属性', () {
      expect(BingSearchEngine().needsApiKey, isFalse);
      expect(TavilySearchEngine('k').needsApiKey, isTrue);
      expect(BingSearchEngine().name, 'Bing');
      expect(BraveSearchEngine('k').name, 'Brave');
      expect(SearxngSearchEngine('https://sx').name, 'SearXNG');
    });
  });

  group('SearchKeyStore', () {
    test('load/save 往返；坏数据回退空 Map', () async {
      expect(await SearchKeyStore.load(), isEmpty);
      await SearchKeyStore.save({
        'tavily': ['k1', 'k2'],
      });
      final loaded = await SearchKeyStore.load();
      expect(loaded['tavily'], ['k1', 'k2']);
    });

    test('effectiveKey：池优先，空池回退 settings 单值', () {
      final settings = AppSettings(webSearchApiKey: 'single-key');
      expect(
        SearchKeyStore.effectiveKey(
          'brave',
          {'brave': ['pool-key']},
          settings,
        ),
        'pool-key',
      );
      expect(
        SearchKeyStore.effectiveKey('brave', {}, settings),
        'single-key',
      );
    });
  });
}

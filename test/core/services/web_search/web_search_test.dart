import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/web_search/engines.dart';
import 'package:nona_chat/core/services/web_search/search_engine.dart';
import 'package:nona_chat/core/services/web_search/web_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_test 默认 mock 所有 HttpClient（返回 400）；
  // 恢复为真实网络，使本地 HttpServer 集成测试生效。
  setUp(() => HttpOverrides.global = null);

  group('Bing HTML 解析', () {
    final sampleHtml = '''
<html><body>
<ol id="b_results">
  <li class="b_algo">
    <h2><a href="https://example.com/flutter">Flutter 官方文档</a></h2>
    <div class="b_caption"><p>Flutter 是 Google 的开源 UI 工具包。</p></div>
  </li>
  <li class="b_algo">
    <h2><a href="https://example.com/dart">Dart 语言</a></h2>
    <div class="b_caption"><p>Dart 是面向客户端优化的编程语言。</p></div>
  </li>
</ol>
</body></html>
''';

    test('解析标题/链接/摘要', () {
      final results = BingSearchEngine.parseHtml(sampleHtml, 5);
      expect(results, hasLength(2));
      expect(results[0].title, 'Flutter 官方文档');
      expect(results[0].url, 'https://example.com/flutter');
      expect(results[0].snippet, contains('Flutter 是 Google'));
      expect(results[1].title, 'Dart 语言');
    });

    test('maxResults 截断', () {
      expect(BingSearchEngine.parseHtml(sampleHtml, 1), hasLength(1));
    });
  });

  group('WebSearchService 注入格式', () {
    test('resultsToPrompt 生成带编号的引用格式', () {
      final prompt = WebSearchService.resultsToPrompt([
        SearchResultItem(
          title: '标题A',
          url: 'https://a.com',
          snippet: '摘要A',
        ),
        SearchResultItem(
          title: '标题B',
          url: 'https://b.com',
          snippet: '摘要B',
        ),
      ]);
      expect(prompt, contains('[1] 标题A — https://a.com'));
      expect(prompt, contains('[citation](number)'));
      expect(prompt, contains('摘要A'));
      expect(prompt, contains('摘要B'));
    });

    test('空结果返回空字符串', () {
      expect(WebSearchService.resultsToPrompt(const []), '');
    });
  });

  group('引擎配置', () {
    final service = WebSearchService();

    test('bing 默认引擎无需 Key', () {
      final engine = service.engineFor(
        const AppSettings(webSearchEngine: 'bing'),
      );
      expect(engine, isA<BingSearchEngine>());
      expect(engine!.needsApiKey, isFalse);
    });

    test('tavily 缺 Key 返回 null', () {
      expect(
        service.engineFor(const AppSettings(webSearchEngine: 'tavily')),
        isNull,
      );
      final engine = service.engineFor(
        const AppSettings(webSearchEngine: 'tavily', webSearchApiKey: 'k'),
      );
      expect(engine, isA<TavilySearchEngine>());
    });

    test('bocha 缺 Key 返回 null', () {
      expect(
        service.engineFor(const AppSettings(webSearchEngine: 'bocha')),
        isNull,
      );
      final engine = service.engineFor(
        const AppSettings(webSearchEngine: 'bocha', webSearchApiKey: 'k'),
      );
      expect(engine, isA<BochaSearchEngine>());
      expect(engine!.needsApiKey, isTrue);
    });

    test('searxng 缺地址返回 null', () {
      expect(
        service.engineFor(const AppSettings(webSearchEngine: 'searxng')),
        isNull,
      );
      final engine = service.engineFor(
        const AppSettings(webSearchEngine: 'searxng', webSearchBaseUrl: 'x'),
      );
      expect(engine, isA<SearxngSearchEngine>());
    });
  });

  group('引擎联网请求（本地 HttpServer）', () {
    test('Tavily 引擎调用正确接口并解析结果', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final bodies = <String>[];
      server.listen((request) async {
        bodies.add(await utf8.decodeStream(request));
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"results":['
          '{"title":"结果一","url":"https://x.com/1","content":"内容一"},'
          '{"title":"结果二","url":"https://x.com/2","content":"内容二"}'
          ']}',
        );
        await request.response.close();
      });

      // 用子类覆盖 endpoint 指向本地服务器
      final engine = _LocalTavily(server.port);
      final results = await engine.search('测试');
      expect(results, hasLength(2));
      expect(results.first.title, '结果一');
      expect(results.first.url, 'https://x.com/1');
      expect(bodies.single, contains('"query":"测试"'));
      await server.close(force: true);
    });

    test('搜索失败返回空列表（不抛出）', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 500;
        await request.response.close();
      });
      final engine = _LocalTavily(server.port);
      expect(await engine.search('测试'), isEmpty);
      await server.close(force: true);
    });

    test('Bocha 引擎调用正确接口并解析 data.webPages.value', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestLog = <String, String?>{};
      server.listen((request) async {
        requestLog['authorization'] = request.headers.value('authorization');
        requestLog['body'] = await utf8.decodeStream(request);
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"code":200,"msg":"success","log_id":"t","data":{'
          '"queryContext":{"originalQuery":"测试"},'
          '"webPages":{"value":['
          '{"name":"结果一","url":"https://x.com/1","summary":"摘要一","snippet":"短一"},'
          '{"name":"结果二","url":"https://x.com/2","snippet":"短二"}'
          ']}}}',
        );
        await request.response.close();
      });

      final engine = _LocalBocha(server.port);
      final results = await engine.search('测试', maxResults: 5);
      expect(results, hasLength(2));
      expect(results.first.title, '结果一');
      expect(results.first.url, 'https://x.com/1');
      expect(results.first.snippet, '摘要一');
      // summary 缺省回退 snippet
      expect(results[1].snippet, '短二');
      expect(requestLog['authorization'], 'Bearer test-key');
      expect(requestLog['body'], contains('"query":"测试"'));
      expect(requestLog['body'], contains('"summary":true'));
      await server.close(force: true);
    });

    test('Bocha 业务错误码返回空列表', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"code":400,"msg":"invalid api key"}');
        await request.response.close();
      });
      final engine = _LocalBocha(server.port);
      expect(await engine.search('测试'), isEmpty);
      await server.close(force: true);
    });
  });
}

/// 指向本地测试服务器的 Tavily 实现。
class _LocalTavily extends TavilySearchEngine {
  _LocalTavily(int port)
    : super('test-key', endpoint: 'http://127.0.0.1:$port/search');
}

/// 指向本地测试服务器的 Bocha 实现。
class _LocalBocha extends BochaSearchEngine {
  _LocalBocha(int port)
    : super('test-key', endpoint: 'http://127.0.0.1:$port/web-search');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/mcp/mcp_client.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/web_search/engines.dart';
import 'package:nona_chat/core/services/web_search/search_engine.dart';
import 'package:nona_chat/core/services/web_search/web_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSearchService 静态工具（A-05 补测）', () {
    test('engineFor 按设置分发（含未知回退）', () {
      const base = AppSettings();
      final service = WebSearchService();
      expect(
        service.engineFor(base.copyWith(webSearchEngine: 'bing')),
        isA<BingSearchEngine>(),
      );
      expect(
        service.engineFor(
          base.copyWith(webSearchEngine: 'tavily', webSearchApiKey: 'k'),
        ),
        isA<TavilySearchEngine>(),
      );
      // 未知引擎回退 Bing，不崩
      expect(
        service.engineFor(base.copyWith(webSearchEngine: 'unknown')),
        isA<BingSearchEngine>(),
      );
    });

    test('resultsToPrompt 编号格式', () {
      final prompt = WebSearchService.resultsToPrompt([
        const SearchResultItem(
          title: '标题A',
          url: 'https://a.com',
          snippet: '摘要A',
        ),
        const SearchResultItem(
          title: '标题B',
          url: 'https://b.com',
          snippet: '摘要B',
        ),
      ]);
      expect(prompt, contains('[1] 标题A'));
      expect(prompt, contains('https://a.com'));
      expect(prompt, contains('[2] 标题B'));
      expect(WebSearchService.resultsToPrompt(const []), '');
    });

    test('engineLabel 兜底未知引擎名', () {
      expect(WebSearchService.engineLabel('bing'), isNotEmpty);
      expect(WebSearchService.engineLabel('不存在的引擎'), '不存在的引擎');
    });
  });

  group('SearchEngine 构造（A-05 补测）', () {
    test('Bing 引擎无需 key', () {
      final engine = BingSearchEngine();
      expect(engine.name, 'Bing');
      expect(engine.needsApiKey, isFalse);
    });

    test('Tavily 引擎需要 key', () {
      final engine = TavilySearchEngine('k');
      expect(engine.needsApiKey, isTrue);
    });
  });

  group('McpClient 模型（A-05 补测）', () {
    test('工具 schema 规范化：无 inputSchema 时为 null', () {
      final tool = McpToolDefinition.fromJson({
        'name': 'echo',
        'description': '回声',
      });
      expect(tool.name, 'echo');
      expect(tool.description, '回声');
      expect(tool.inputSchema, isNull);
    });

    test('带 inputSchema 的工具保留参数', () {
      final tool = McpToolDefinition.fromJson({
        'name': 'calc',
        'description': '计算',
        'inputSchema': {
          'type': 'object',
          'properties': {'a': {'type': 'number'}},
        },
      });
      expect(tool.inputSchema!['properties'], contains('a'));
    });

    test('McpToolResult.fromJson 提取文本/图片/结构化/错误', () {
      final text = McpToolResult.fromJson({
        'result': {
          'content': [
            {'type': 'text', 'text': '第一段'},
            {'type': 'text', 'text': '第二段'},
          ],
        },
      });
      expect(text.isError, isFalse);
      expect(text.content, contains('第一段'));
      expect(text.content, contains('第二段'));

      final image = McpToolResult.fromJson({
        'result': {
          'content': [
            {'type': 'image', 'mimeType': 'image/png', 'data': 'AAAA'},
          ],
        },
      });
      expect(image.isError, isFalse);
      expect(image.content, contains('image result'));

      final structured = McpToolResult.fromJson({
        'result': {'structuredContent': {'text': '类型化文本'}},
      });
      expect(structured.content, '类型化文本');

      final error = McpToolResult.fromJson({
        'error': '权限不足',
      });
      expect(error.isError, isTrue);
      expect(error.content, contains('权限不足'));
    });

    test('McpException 携带消息', () {
      const e = McpException('boom');
      expect(e.toString(), 'boom');
      expect(e.message, 'boom');
    });
  });
}

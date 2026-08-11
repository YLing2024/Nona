import 'dart:convert';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:html/parser.dart' show parseFragment;
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';

import '../app_http_client.dart';
import '../memory/memory_service.dart';
import '../network_log_service.dart';
import 'mcp_client.dart' show McpToolDefinition, McpToolResult;

/// 本地内置工具定义（schema 与执行器）。
class LocalTool {
  final McpToolDefinition definition;

  /// 执行工具；[arguments] 已解析为 Map。
  final Future<McpToolResult> Function(Map<String, dynamic> arguments) handler;

  const LocalTool({required this.definition, required this.handler});
}

/// 本地工具注册表：工具名 `builtin__{name}`，在编排器
/// [_resolveMcpTools] 中与 MCP 工具一并注入模型。
class LocalTools {
  /// 局域网/回环地址检测：默认拒绝访问（防 SSRF），并返回告警提示。
  static final RegExp _loopbackRe = RegExp(
    r'^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)',
  );
  static final RegExp _hostOnlyRe = RegExp(r'^(localhost|::1)$');

  /// fetch 响应体上限（1MB）。
  static const int _fetchMaxBytes = 1024 * 1024;

  /// fetch 请求超时。
  static const Duration _fetchTimeout = Duration(seconds: 15);

  static List<LocalTool> all() => [
    LocalTool(
      definition: const McpToolDefinition(
        name: 'builtin__fetch',
        description: 'Fetch the content of a URL and convert it to plain '
            'text. For scenarios that need to fetch and read web pages.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'url': {
              'type': 'string',
              'description': 'The http(s) URL of the web page to fetch',
            },
            'maxLength': {
              'type': 'integer',
              'description':
                  'Maximum characters to return (default 20000, max 100000)',
            },
          },
          'required': ['url'],
        },
      ),
      handler: _fetch,
    ),
    LocalTool(
      definition: const McpToolDefinition(
        name: 'builtin__time_info',
        description: 'Get the current date, time and timezone of the user\'s '
            'device. Useful when the user asks what time it is or for '
            'time-sensitive questions.',
        inputSchema: {'type': 'object', 'properties': {}},
      ),
      handler: _timeInfo,
    ),
    LocalTool(
      definition: const McpToolDefinition(
        name: 'builtin__calculator',
        description: 'Evaluate a math expression like "1 + 2 * 3", '
            '"sqrt(16)", "2^10". Returns the numeric result.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': 'The math expression to evaluate',
            },
          },
          'required': ['expression'],
        },
      ),
      handler: _calculator,
    ),
    LocalTool(
      definition: const McpToolDefinition(
        name: 'builtin__clipboard',
        description: 'Read or write the system clipboard. Writing requires '
            'user approval at runtime.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'action': {
              'type': 'string',
              'enum': ['read', 'write'],
              'description': 'read: return clipboard text; '
                  'write: replace clipboard content with [text]',
            },
            'text': {
              'type': 'string',
              'description': 'Text to write (required when action=write)',
            },
          },
          'required': ['action'],
        },
      ),
      handler: _clipboard,
    ),
    LocalTool(
      definition: const McpToolDefinition(
        name: 'builtin__memory_tool',
        description: 'Create, edit or delete a long-term memory about the '
            'user. Use this when the user states a lasting fact, preference '
            'or task that should be remembered across conversations.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'action': {
              'type': 'string',
              'enum': ['create', 'edit', 'delete'],
              'description': 'create: add a new memory; edit: update an '
                  'existing memory by id; delete: remove by id',
            },
            'id': {
              'type': 'string',
              'description': 'Memory id (required for edit/delete)',
            },
            'content': {
              'type': 'string',
              'description': 'The memory content (required for create/edit)',
            },
            'category': {
              'type': 'string',
              'enum': ['fact', 'preference', 'todo'],
              'description': 'Memory category (default fact)',
            },
          },
          'required': ['action'],
        },
      ),
      handler: _memoryTool,
    ),
  ];

  /// 按完整工具名（`builtin__name`）查找。
  static LocalTool? find(String fullName) {
    for (final t in all()) {
      if (t.definition.name == fullName) return t;
    }
    return null;
  }

  /// 全部工具的 schema（注入模型工具列表）。
  static List<Map<String, dynamic>> schemas() => [
    for (final t in all())
      {
        'type': 'function',
        'function': {
          'name': t.definition.name,
          'description': t.definition.description,
          if (t.definition.inputSchema != null)
            'parameters': t.definition.inputSchema,
        },
      },
  ];

  static Future<McpToolResult> _fetch(Map<String, dynamic> args) async {
    final rawUrl = (args['url'] as String? ?? '').trim();
    if (rawUrl.isEmpty) {
      return McpToolResult(
        content: 'fetch failed: url is required',
        isError: true,
      );
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return McpToolResult(
        content: 'fetch failed: only http(s) URLs are supported',
        isError: true,
      );
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        _hostOnlyRe.hasMatch(host) ||
        _loopbackRe.hasMatch(host)) {
      return McpToolResult(
        content: 'fetch failed: local network / loopback addresses are '
            'blocked for safety (got $host)',
        isError: true,
      );
    }
    final maxLength = (args['maxLength'] as num?)?.toInt() ?? 20000;
    final limit = maxLength.clamp(1, 100000);
    try {
      final response = await AppHttpClient.instance.send(
        method: 'GET',
        uri: uri,
        type: NetworkLogType.other,
        timeout: _fetchTimeout,
        retry: false,
      );
      if (response.statusCode != 200) {
        return McpToolResult(
          content: 'fetch failed: HTTP ${response.statusCode}',
          isError: true,
        );
      }
      final bytes = response.bodyBytes;
      if (bytes.length > _fetchMaxBytes) {
        return McpToolResult(
          content: 'fetch failed: response exceeds 1MB limit '
              '(${bytes.length} bytes)',
          isError: true,
        );
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      final plain = _htmlToText(text);
      if (plain.trim().isEmpty) {
        return McpToolResult(content: '(empty page)');
      }
      final truncated = plain.trim().length > limit
          ? '${plain.trim().substring(0, limit)}\n…(truncated)'
          : plain.trim();
      return McpToolResult(content: truncated);
    } on http.ClientException catch (e) {
      return McpToolResult(
        content: 'fetch failed: ${e.message}',
        isError: true,
      );
    } catch (e) {
      return McpToolResult(content: 'fetch failed: $e', isError: true);
    }
  }

  /// HTML → 纯文本（保留标题/列表结构，压缩空白）。
  static String _htmlToText(String html) {
    try {
      final doc = parseFragment(html);
      final text = doc.text ?? '';
      return text
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    } catch (_) {
      // 非 HTML 内容（纯文本/JSON）直接返回
      return html;
    }
  }

  static Future<McpToolResult> _timeInfo(Map<String, dynamic> args) async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final result = StringBuffer()
      ..writeln('date: ${now.year}-${two(now.month)}-${two(now.day)}')
      ..writeln('time: ${two(now.hour)}:${two(now.minute)}:${two(now.second)}')
      ..writeln('weekday: ${weekdays[now.weekday - 1]}')
      ..writeln('timezone: ${now.timeZoneName} (UTC offset '
          '${now.timeZoneOffset.inMinutes ~/ 60}h '
          '${(now.timeZoneOffset.inMinutes % 60).abs()}m)')
      ..writeln('unix_ts: ${now.millisecondsSinceEpoch ~/ 1000}');
    return McpToolResult(content: result.toString().trim());
  }

  static Future<McpToolResult> _calculator(Map<String, dynamic> args) async {
    final expression = (args['expression'] as String? ?? '').trim();
    if (expression.isEmpty) {
      return McpToolResult(
        content: 'calculator error: expression is required',
        isError: true,
      );
    }
    try {
      final parser = ShuntingYardParser();
      final exp = parser.parse(expression);
      final result = exp.evaluate(EvaluationType.REAL, ContextModel());
      return McpToolResult(content: '$expression = $result');
    } catch (e) {
      return McpToolResult(
        content: 'calculator error: cannot evaluate "$expression" ($e)',
        isError: true,
      );
    }
  }

  static Future<McpToolResult> _memoryTool(Map<String, dynamic> args) async {
    final action = args['action'] as String? ?? '';
    final service = MemoryService();
    switch (action) {
      case 'create':
        final content = args['content'] as String? ?? '';
        if (content.trim().isEmpty) {
          return const McpToolResult(
            content: 'memory error: content is required for create',
            isError: true,
          );
        }
        final m = await service.add(
          scope: MemoryScope.agent,
          content: content.trim(),
          category: args['category'] as String? ?? 'fact',
        );
        return m == null
            ? const McpToolResult(
                content: 'memory error: create failed',
                isError: true,
              )
            : McpToolResult(
                content: 'memory created: id=${m.id} content=${m.content}',
              );
      case 'edit':
        final id = args['id'] as String? ?? '';
        final content = args['content'] as String? ?? '';
        if (id.isEmpty || content.trim().isEmpty) {
          return const McpToolResult(
            content: 'memory error: id and content are required for edit',
            isError: true,
          );
        }
        await service.update(
          id,
          content.trim(),
          args['category'] as String? ?? 'fact',
        );
        return McpToolResult(content: 'memory updated: id=$id');
      case 'delete':
        final id = args['id'] as String? ?? '';
        if (id.isEmpty) {
          return const McpToolResult(
            content: 'memory error: id is required for delete',
            isError: true,
          );
        }
        await service.remove(id);
        return McpToolResult(content: 'memory deleted: id=$id');
      default:
        return McpToolResult(
          content: 'memory error: unknown action "$action"',
          isError: true,
        );
    }
  }

  static Future<McpToolResult> _clipboard(Map<String, dynamic> args) async {
    final action = args['action'] as String? ?? '';
    switch (action) {
      case 'read':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text ?? '';
        return McpToolResult(
          content: text.isEmpty
              ? '(clipboard is empty)'
              : 'clipboard content:\n$text',
        );
      case 'write':
        final text = args['text'] as String? ?? '';
        if (text.isEmpty) {
          return McpToolResult(
            content: 'clipboard error: text is required for write',
            isError: true,
          );
        }
        await Clipboard.setData(ClipboardData(text: text));
        return McpToolResult(content: 'clipboard updated (${text.length} chars)');
      default:
        return McpToolResult(
          content: 'clipboard error: unknown action "$action"',
          isError: true,
        );
    }
  }
}

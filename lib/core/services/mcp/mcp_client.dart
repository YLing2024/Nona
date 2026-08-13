import 'dart:async';
import 'dart:convert';

import '../../network/app_http_client.dart';
import '../network_log_service.dart';
import '../../../version.dart';

/// 一个 MCP 工具的 JSON Schema 参数定义。
class McpToolDefinition {  final String name;
  final String description;
  final Map<String, dynamic>? inputSchema;

  const McpToolDefinition({
    required this.name,
    required this.description,
    this.inputSchema,
  });

  factory McpToolDefinition.fromJson(Map<String, dynamic> json) =>
      McpToolDefinition(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        inputSchema: json['inputSchema'] as Map<String, dynamic>?,
      );
}

/// 工具调用结果。
class McpToolResult {
  final String content;
  final bool isError;

  const McpToolResult({required this.content, this.isError = false});

  /// 从 MCP call 响应中提取文本内容。
  factory McpToolResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    final content = result['content'] as List<dynamic>? ?? const [];
    final sb = StringBuffer();
    var isError = result['isError'] == true;
    for (final c in content) {
      if (c is! Map<String, dynamic>) continue;
      final type = c['type'];
      if (type == 'text') {
        sb.writeln(c['text'] ?? '');
      } else if (type == 'image') {
        // 图片结果是合法的 MCP 输出，不是错误
        final mime = c['mimeType'] as String? ?? 'image';
        final data = c['data'] as String? ?? '';
        sb.writeln('[image result: $mime, ${data.length} bytes base64]');
      }
    }
    if (sb.isEmpty) {
      // structuredContent：类型化替代字段，优先取 text 字段
      final structured = result['structuredContent'];
      if (structured is Map<String, dynamic>) {
        final text = structured['text'];
        if (text != null) sb.write(text.toString());
      }
    }
    if (sb.isEmpty) {
      final text = json['error'] as String?;
      if (text != null) {
        isError = true;
        sb.write(text);
      }
    }
    return McpToolResult(
      content: sb.toString().trim(),
      isError: isError,
    );
  }
}

/// 轻量 MCP 客户端：JSON-RPC 2.0 over Streamable HTTP / SSE。
///
/// 协议版本：2025-03-26。核心方法：initialize / tools/list / tools/call；
/// 响应以 `application/json` 返回（服务端如支持 SSE 通知流则忽略通知）。
class McpClient {
  final String baseUrl;
  final Map<String, String> headers;

  /// 会话标识（initialize 返回），供后续请求携带。
  String? _sessionId;
  int _requestId = 0;
  bool _initialized = false;

  McpClient({required this.baseUrl, this.headers = const {}});

  /// 服务器信息（initialize 结果）。
  Map<String, dynamic>? serverInfo;

  /// 发送请求。[notify] 为 true 时不携带 id（JSON-RPC 通知，部分严格
  /// 服务端会拒绝带 id 的通知请求）。
  Future<Map<String, dynamic>> _post(
    String method,
    Map<String, dynamic> params, {
    bool notify = false,
  }) async {
    final uri = Uri.parse(baseUrl);
    final id = ++_requestId;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      if (!notify) 'id': id,
      'method': method,
      'params': params,
    });
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      ...headers,
      if (_sessionId != null) 'Mcp-Session-Id': _sessionId!,
    };
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: uri,
      headers: mergedHeaders,
      body: body,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    final newSession = response.headers['mcp-session-id'];
    if (newSession != null) _sessionId = newSession;
    if (notify) return const {};

    final payload = _parseResponseBody(response.body, expectedId: id);
    if (payload is Map<String, dynamic> && payload['error'] != null) {
      final error = payload['error'] as Map<String, dynamic>;
      throw McpException(
        'MCP error (${error['code']}): ${error['message']}',
      );
    }
    if (payload is Map<String, dynamic> && payload['result'] != null) {
      return payload['result'] as Map<String, dynamic>;
    }
    throw McpException('MCP response format cannot be parsed');
  }

  /// 兼容 JSON 与 SSE 包装（`data: {...}`）。
  ///
  /// [expectedId]：期望的请求 id；响应的 id 不匹配时视为无效响应。
  /// SSE 流中优先取第一个「响应形状」（含 result/error 且 id 匹配）的块，
  /// 避免服务端在结果之后追加 keep-alive 通知导致解析失败。
  Object? _parseResponseBody(String body, {int? expectedId}) {
    bool idMatches(Map<String, dynamic> json) =>
        expectedId == null ||
        json['id'] == null ||
        json['id'].toString() == expectedId.toString();
    final trimmed = body.trim();
    if (trimmed.startsWith('{')) {
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (!idMatches(json)) return null;
        return json;
      } catch (_) {
        return null;
      }
    }
    if (trimmed.startsWith('data:')) {
      final lines = trimmed.split('\n');
      Object? fallback;
      for (final line in lines) {
        final l = line.trim();
        if (!l.startsWith('data:')) continue;
        final data = l.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (!idMatches(json)) continue;
          final isResponse =
              json.containsKey('result') || json.containsKey('error');
          if (isResponse) return json;
          if (fallback == null && json.containsKey('id')) fallback = json;
        } catch (_) {}
      }
      return fallback;
    }
    return null;
  }

  /// 握手初始化（幂等）。
  Future<void> initialize() async {
    if (_initialized) return;
    final result = await _post('initialize', {
      'protocolVersion': '2025-03-26',
      'capabilities': {},
      'clientInfo': {'name': 'nona', 'version': kAppVersion.split('+').first},
    });
    _initialized = true;
    serverInfo = result['serverInfo'] as Map<String, dynamic>?;
    // 通知服务端初始化完成（JSON-RPC 通知不带 id）
    try {
      await _post('notifications/initialized', const {}, notify: true);
    } catch (_) {
      // 部分服务端不接受已初始化通知，忽略
    }
  }

  /// 列出可用工具。
  Future<List<McpToolDefinition>> listTools() async {
    await initialize();
    final result = await _post('tools/list', const {});
    final tools = result['tools'] as List<dynamic>? ?? const [];
    return [
      for (final t in tools)
        if (t is Map<String, dynamic>)
          McpToolDefinition.fromJson(t),
    ];
  }

  /// 调用工具。
  Future<McpToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    await initialize();
    final result = await _post('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    return McpToolResult.fromJson(result);
  }
}

/// MCP 通信异常。
class McpException implements Exception {
  final String message;

  const McpException(this.message);

  @override
  String toString() => message;
}

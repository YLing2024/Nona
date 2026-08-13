import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../network/app_http_client.dart';
import '../network_log_service.dart';
import '../../../version.dart';

/// MCP 传输类型（F-01：stdio 本地进程）。
enum McpTransportKind { http, sse, stdio }

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

/// 轻量 MCP 客户端：JSON-RPC 2.0 over Streamable HTTP / SSE / STDIO。
///
/// 协议版本：2025-03-26。核心方法：initialize / tools/list / tools/call；
/// HTTP 响应以 `application/json` 返回（服务端如支持 SSE 通知流则忽略通知）。
class McpClient {
  final String baseUrl;
  final Map<String, String> headers;

  /// F-01：stdio 传输配置（非空时走本地进程）。
  final StdioConfig? stdio;

  /// 会话标识（initialize 返回），供后续请求携带。
  String? _sessionId;
  int _requestId = 0;
  bool _initialized = false;
  StdioMcpTransport? _stdioTransport;

  McpClient({
    required this.baseUrl,
    this.headers = const {},
    this.stdio,
  });

  /// 服务器信息（initialize 结果）。
  Map<String, dynamic>? serverInfo;

  /// F-01：传输进程是否存活。
  bool get isAlive => _stdioTransport?.isAlive ?? true;

  /// F-01：关闭传输（stdio 杀进程；退出前调用）。
  Future<void> close() async {
    await _stdioTransport?.close();
    _stdioTransport = null;
    _initialized = false;
  }

  /// 发送请求。[notify] 为 true 时不携带 id（JSON-RPC 通知，部分严格
  /// 服务端会拒绝带 id 的通知请求）。
  Future<Map<String, dynamic>> _post(
    String method,
    Map<String, dynamic> params, {
    bool notify = false,
  }) async {
    if (stdio != null) {
      final transport = _stdioTransport ??= StdioMcpTransport(stdio!);
      final id = ++_requestId;
      final body = {
        'jsonrpc': '2.0',
        if (!notify) 'id': id,
        'method': method,
        'params': params,
      };
      if (notify) {
        await transport.sendNotification(body);
        return const {};
      }
      final result = await transport.request(id, body);
      if (result['error'] != null) {
        final error = result['error'] as Map<String, dynamic>;
        throw McpException(
          'MCP error (${error['code']}): ${error['message']}',
        );
      }
      return result['result'] as Map<String, dynamic>? ?? const {};
    }
    return _postHttp(method, params, notify: notify);
  }

  Future<Map<String, dynamic>> _postHttp(
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

/// F-01：stdio 传输配置（命令 + 参数 + 环境 + 工作目录）。
class StdioConfig {
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final String? cwd;

  const StdioConfig({
    required this.command,
    this.args = const [],
    this.env = const {},
    this.cwd,
  });

  factory StdioConfig.fromJson(Map<String, dynamic> json) => StdioConfig(
        command: json['command'] as String? ?? '',
        args: (json['args'] as List<dynamic>? ?? []).cast<String>(),
        env: {
          for (final e in (json['env'] as Map<String, dynamic>? ?? {}).entries)
            e.key: e.value.toString(),
        },
        cwd: json['cwd'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'command': command,
        'args': args,
        'env': env,
        if (cwd != null) 'cwd': cwd,
      };
}


/// F-01：stdio 传输——json-rpc over stdin/stdout 行协议。
///
/// 生命周期：首次请求时启动进程；[close] 终止。stderr 转发日志。
class StdioMcpTransport {
  final StdioConfig config;
  Process? _process;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  late final Future<void> _ready;

  StdioMcpTransport(this.config) {
    _ready = _init();
  }

  Future<void> _init() async {
    final command = await resolveCommand(config.command);
    if (command == null) {
      throw McpException('command not found: ${config.command}');
    }
    final process = await Process.start(
      command,
      config.args,
      environment: config.env.isEmpty ? null : config.env,
      workingDirectory: config.cwd,
    );
    _process = process;
    // stdout 行监听：增量拼接后按行解析（json 单行响应）
    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    lines.listen(_onLine, onError: (_) {}, onDone: _onProcessExit);
    process.stderr.transform(utf8.decoder).listen((chunk) {
      _lastStderr.write(chunk);
    });
  }

  bool get isAlive => _process != null;

  void _onLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final id = decoded['id'];
    if (id == null) {
      // 服务端主动通知：忽略（上层用不到）
      return;
    }
    final completer = _pending.remove(int.tryParse(id.toString()) ?? -1);
    if (completer != null && !completer.isCompleted) {
      completer.complete(decoded);
    }
  }

  void _onProcessExit() {
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(const McpException('stdio process exited'));
      }
    }
    _pending.clear();
    _process = null;
  }

  /// 最近 stderr 内容（错误提示用）。
  static final StringBuffer _lastStderr = StringBuffer();

  static String get recentStderr => _lastStderr.toString();

  /// 解析命令路径：Windows 合并注册表 Machine/User PATH 与进程 PATH；
  /// 其余平台用 which。
  static Future<String?> resolveCommand(String command) async {
    if (command.contains('/') || command.contains(r'\')) {
      return File(command).existsSync() ? command : null;
    }
    if (Platform.isWindows) {
      final pathEnv = await _windowsPath();
      for (final dir in pathEnv.split(';')) {
        if (dir.trim().isEmpty) continue;
        final candidate = '$dir\\$command';
        for (final ext in _pathext()) {
          if (File('$candidate$ext').existsSync()) return '$candidate$ext';
        }
        if (File(candidate).existsSync()) return candidate;
      }
      return null;
    }
    final which = await Process.run('which', [command]);
    if (which.exitCode == 0 && (which.stdout as String).trim().isNotEmpty) {
      return (which.stdout as String).trim();
    }
    return null;
  }

  static Future<String> _windowsPath() async {
    final parts = <String>[
      if (Platform.environment['PATH'] != null) Platform.environment['PATH']!,
    ];
    try {
      for (final scope in ['HKEY_LOCAL_MACHINE', 'HKEY_CURRENT_USER']) {
        final result = await Process.run(
          'reg',
          ['query', '$scope\\Environment', '/v', 'Path'],
        );
        if (result.exitCode == 0) {
          final out = (result.stdout as String);
          final match = RegExp(
            r'Path\s+REG_(?:EXPAND_)?SZ\s+(.+)$',
            multiLine: true,
          ).firstMatch(out);
          if (match != null) parts.add(match.group(1)!.trim());
        }
      }
    } catch (_) {}
    final seen = <String>{};
    final merged = <String>[];
    for (final p in parts) {
      for (final dir in p.split(';')) {
        final normalized = dir.trim().toLowerCase();
        if (dir.trim().isEmpty || !seen.add(normalized)) continue;
        merged.add(dir.trim());
      }
    }
    return merged.join(';');
  }

  static List<String> _pathext() {
    final ext = Platform.environment['PATHEXT'] ?? '.EXE;.BAT;.CMD';
    return [
      for (final e in ext.split(';'))
        if (e.trim().isNotEmpty) e.trim().toLowerCase(),
    ];
  }

  Future<void> sendNotification(Map<String, dynamic> body) async {
    await _ready;
    _process?.stdin.writeln(jsonEncode(body));
  }

  Future<Map<String, dynamic>> request(
    int id,
    Map<String, dynamic> body,
  ) async {
    await _ready;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _process?.stdin.writeln(jsonEncode(body));
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        throw McpException('MCP stdio request timeout: ${body['method']}');
      },
    );
  }

  Future<void> close() async {
    final process = _process;
    _process = null;
    if (process == null) return;
    try {
      unawaited(process.stdin.close());
      await process.exitCode.timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      process.kill();
    } catch (_) {}
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(const McpException('stdio transport closed'));
      }
    }
    _pending.clear();
  }
}

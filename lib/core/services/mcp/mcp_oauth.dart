import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../network/app_http_client.dart';
import '../network_log_service.dart';

/// F-02：MCP OAuth 授权状态（持久化到 McpServerConfig.oauth）。
class McpOAuthState {
  final String? clientId;
  final String? clientSecret;
  final String? authorizationEndpoint;
  final String? tokenEndpoint;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? registrationSource; // preRegistered / cimd / dcr

  const McpOAuthState({
    this.clientId,
    this.clientSecret,
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.accessToken = '',
    this.refreshToken,
    this.expiresAt,
    this.registrationSource,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get hasToken => accessToken.isNotEmpty;

  factory McpOAuthState.fromJson(Map<String, dynamic> json) => McpOAuthState(
    clientId: json['clientId'] as String?,
    clientSecret: json['clientSecret'] as String?,
    authorizationEndpoint: json['authorizationEndpoint'] as String?,
    tokenEndpoint: json['tokenEndpoint'] as String?,
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String?,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.tryParse(json['expiresAt'] as String),
    registrationSource: json['registrationSource'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (clientId != null) 'clientId': clientId,
    if (clientSecret != null) 'clientSecret': clientSecret,
    if (authorizationEndpoint != null)
      'authorizationEndpoint': authorizationEndpoint,
    if (tokenEndpoint != null) 'tokenEndpoint': tokenEndpoint,
    'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (registrationSource != null) 'registrationSource': registrationSource,
  };

  McpOAuthState copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) => McpOAuthState(
    clientId: clientId,
    clientSecret: clientSecret,
    authorizationEndpoint: authorizationEndpoint,
    tokenEndpoint: tokenEndpoint,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    registrationSource: registrationSource,
  );
}

/// F-02：MCP OAuth 授权流——发现 → PKCE → 授权码 → token。
///
/// 回调：桌面用 loopback HttpServer 随机端口；移动端由宿主把
/// `nona-mcp://callback` deep-link 转发到 [completeAuthorization]。
class McpOAuthService {
  McpOAuthService._();

  static final McpOAuthService instance = McpOAuthService._();

  /// 单飞刷新：并发请求共享一次刷新。
  Future<McpOAuthState>? _refreshing;

  /// 发现授权服务器：`.well-known/oauth-protected-resource` +
  /// `oauth-authorization-server` + `openid-configuration`。
  static Future<Map<String, String>> discover(String baseUrl) async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final candidates = [
      '$base/.well-known/oauth-protected-resource',
      '$base/.well-known/oauth-authorization-server',
    ];
    for (final url in candidates) {
      try {
        final response = await AppHttpClient.instance.send(
          method: 'GET',
          uri: Uri.parse(url),
          headers: {'Accept': 'application/json'},
          type: NetworkLogType.other,
          timeout: const Duration(seconds: 10),
          retry: false,
        );
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authorizationServers =
            data['authorization_servers'] as List<dynamic>?;
        if (authorizationServers != null && authorizationServers.isNotEmpty) {
          return _discoverFromServer(authorizationServers.first.toString());
        }
        final endpoints = _extractEndpoints(data);
        if (endpoints.isNotEmpty) return endpoints;
      } catch (_) {}
    }
    throw const McpOAuthException('authorization server not discovered');
  }

  static Future<Map<String, String>> _discoverFromServer(String url) async {
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: Uri.parse(url),
      headers: {'Accept': 'application/json'},
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 10),
      retry: false,
    );
    if (response.statusCode != 200) throw const McpOAuthException('discovery failed');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final endpoints = _extractEndpoints(data);
    if (endpoints.isEmpty) throw const McpOAuthException('endpoints missing');
    return endpoints;
  }

  static Map<String, String> _extractEndpoints(Map<String, dynamic> data) {
    String? str(String? v) => (v == null || v.toString().isEmpty) ? null : v.toString();
    return {
      if (str(data['authorization_endpoint']) != null)
        'authorization_endpoint': str(data['authorization_endpoint'])!,
      if (str(data['token_endpoint']) != null)
        'token_endpoint': str(data['token_endpoint'])!,
      if (str(data['issuer']) != null) 'issuer': str(data['issuer'])!,
    };
  }

  /// 发起授权：返回 (授权 URL, PKCE verifier, 回调端口, 状态)。
  static Future<(
    Uri,
    String,
    HttpServer?,
    String,
  )> startAuthorization(
    String baseUrl, {
    required String clientId,
    String? redirectScheme,
  }) async {
    final endpoints = await discover(baseUrl);
    final authEndpoint = endpoints['authorization_endpoint'];
    if (authEndpoint == null) {
      throw const McpOAuthException('authorization endpoint missing');
    }
    final verifier = _pkceVerifier();
    final challenge = _pkceChallenge(verifier);
    final state = _randomState();
    final redirectUri = await _redirectUri(redirectScheme);
    final uri = Uri.parse(authEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'scope': 'mcp',
      },
    );
    return (uri, verifier, _server, state);
  }

  static HttpServer? _server;

  /// 回调服务器（桌面 loopback 随机端口）。
  static Future<String> _redirectUri(String? scheme) async {
    if (scheme != null && scheme.isNotEmpty) {
      return '$scheme://callback';
    }
    // 桌面：127.0.0.1 随机端口
    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen((request) {
        final code = request.uri.queryParameters['code'];
        if (code != null) {
          _callbackCompleters
              .where((c) => !c.isCompleted)
              .forEach((c) => c.complete(code));
        }
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><body><h3>授权完成，可关闭此窗口</h3></body></html>');
        request.response.close();
      });
    }
    return 'http://127.0.0.1:${_server!.port}/oauth/callback';
  }

  static final List<Completer<String>> _callbackCompleters = [];

  /// 完成授权码回调（桌面 loopback 自动；移动端由宿主传入 deep-link 的 code）。
  static Future<String> awaitAuthorizationCode({
    required String verifier,
    required String state,
    String? externalCode,
  }) async {
    if (externalCode != null && externalCode.isNotEmpty) {
      return externalCode;
    }
    final completer = Completer<String>();
    _callbackCompleters.add(completer);
    return completer.future.timeout(const Duration(minutes: 2));
  }

  /// 用授权码换 token（PKCE S256）。
  static Future<McpOAuthState> exchangeCode({
    required String tokenEndpoint,
    required String clientId,
    required String verifier,
    required String code,
    String? clientSecret,
    String? redirectUri,
  }) async {
    final params = {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'code_verifier': verifier,
      if (clientSecret != null && clientSecret.isNotEmpty)
        'client_secret': clientSecret,
      if (redirectUri != null && redirectUri.isNotEmpty)
        'redirect_uri': redirectUri,
    };
    return _requestToken(tokenEndpoint, params);
  }

  /// 刷新 token（单飞）。
  Future<McpOAuthState> refresh({
    required String tokenEndpoint,
    required String clientId,
    required String refreshToken,
    String? clientSecret,
  }) {
    return _refreshing ??= _refreshInner(
      tokenEndpoint: tokenEndpoint,
      clientId: clientId,
      refreshToken: refreshToken,
      clientSecret: clientSecret,
    ).whenComplete(() => _refreshing = null);
  }

  static Future<McpOAuthState> _refreshInner({
    required String tokenEndpoint,
    required String clientId,
    required String refreshToken,
    String? clientSecret,
  }) async {
    final params = {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
      if (clientSecret != null && clientSecret.isNotEmpty)
        'client_secret': clientSecret,
    };
    return _requestToken(tokenEndpoint, params);
  }

  static Future<McpOAuthState> _requestToken(
    String endpoint,
    Map<String, String> params,
  ) async {
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: Uri.parse(endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&'),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    if (response.statusCode != 200) {
      throw McpOAuthException(
        'token endpoint ${response.statusCode}: '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw const McpOAuthException('no access_token in response');
    }
    final expiresIn = data['expires_in'] as num?;
    return McpOAuthState(
      clientId: params['client_id'],
      clientSecret: params['client_secret'],
      tokenEndpoint: endpoint,
      accessToken: accessToken,
      refreshToken: data['refresh_token'] as String?,
      expiresAt: expiresIn == null
          ? null
          : DateTime.now().add(Duration(seconds: expiresIn.toInt())),
      registrationSource: 'oauth',
    );
  }

  static String _pkceVerifier() {
    final random = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url
        .encode(random)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String _pkceChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String _randomState() {
    final random = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(random).replaceAll('=', '');
  }

  static final _random = _SecureRandom();

  static void closeCallbackServer() {
    _server?.close(force: true);
    _server = null;
  }
}

/// 加密随机源。
class _SecureRandom {
  final _random = Random.secure();
  int nextInt(int max) => _random.nextInt(max);
}

/// OAuth 异常。
class McpOAuthException implements Exception {
  final String message;
  const McpOAuthException(this.message);

  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../network/app_http_client.dart';
import '../network_log_service.dart';
import 'sync_exception.dart';

/// 按 HTTP 状态码归类同步错误：401/403 认证失败，其余为存储层错误。
SyncException syncHttpError(String message, int statusCode, {Object? cause}) =>
    SyncException(
      message,
      kind: statusCode == 401 || statusCode == 403 ? 'auth' : 'storage',
      cause: cause,
    );

/// 远程备份文件条目。
class RemoteBackupFile {
  final String name;
  final int size;
  final DateTime? modified;

  const RemoteBackupFile({
    required this.name,
    required this.size,
    this.modified,
  });
}

/// WebDAV 客户端（Basic Auth + PUT/GET/DELETE/PROPFIND）。
class WebDavClient {
  final String baseUrl;
  final String username;
  final String password;

  WebDavClient({
    required this.baseUrl,
    this.username = '',
    this.password = '',
  });

  String get _authHeader {
    if (username.isEmpty) return '';
    return 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
  }

  Uri _uri(String path) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final clean = path.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$base/$clean');
  }

  Map<String, String> get _headers => {
    if (_authHeader.isNotEmpty) 'Authorization': _authHeader,
  };

  /// 上传文件（PUT）。
  Future<void> put(String path, Uint8List data) async {
    final response = await AppHttpClient.instance.send(
      method: 'PUT',
      uri: _uri(path),
      headers: _headers,
      bodyBytes: data,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 60),
      retry: false,
    );
    if (response.statusCode >= 400) {
      throw syncHttpError(
        'Upload failed (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
  }

  /// 下载文件（GET）。
  Future<Uint8List> get(String path) async {
    final streamed = await AppHttpClient.instance.sendStreamed(
      method: 'GET',
      uri: _uri(path),
      headers: _headers,
      connectTimeout: const Duration(seconds: 30),
    );
    if (streamed.statusCode >= 400) {
      throw syncHttpError(
        'Download failed (HTTP ${streamed.statusCode})',
        streamed.statusCode,
      );
    }
    final body = await streamed.stream.toBytes();
    return body;
  }

  /// 列出目录下的文件（PROPFIND Depth:1）。
  Future<List<RemoteBackupFile>> list(String path) async {
    final uri = _uri(path);
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll({
        ..._headers,
        'Depth': '1',
        'Content-Type': 'application/xml',
      })
      ..body =
          '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop>'
          '<d:displayname/><d:getcontentlength/><d:getlastmodified/>'
          '</d:prop></d:propfind>';
    final response = await AppHttpClient.instance.send(
      method: 'PROPFIND',
      uri: uri,
      headers: request.headers,
      body: request.body,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    if (response.statusCode >= 400) return const [];

    final basePath = uri.path;
    final files = <RemoteBackupFile>[];
    // 解析 <d:response> 块（容忍任意命名空间前缀：d:/D:/ns0:/无前缀）
    final responseRe = RegExp(
      r'<(?:[a-zA-Z][\w.-]*:)?response(?:\s[^>]*)?>(.*?)'
      r'</(?:[a-zA-Z][\w.-]*:)?response>',
      dotAll: true,
    );
    final hrefRe = RegExp(
      r'<(?:[a-zA-Z][\w.-]*:)?href(?:\s[^>]*)?>([^<]+)'
      r'</(?:[a-zA-Z][\w.-]*:)?href>',
    );
    final sizeRe = RegExp(
      r'<(?:[a-zA-Z][\w.-]*:)?getcontentlength(?:\s[^>]*)?>(\d+)'
      r'</(?:[a-zA-Z][\w.-]*:)?getcontentlength>',
    );
    final modifiedRe = RegExp(
      r'<(?:[a-zA-Z][\w.-]*:)?getlastmodified(?:\s[^>]*)?>([^<]+)'
      r'</(?:[a-zA-Z][\w.-]*:)?getlastmodified>',
    );
    for (final block in responseRe.allMatches(response.body)) {
      final chunk = block.group(1)!;
      final hrefMatch = hrefRe.firstMatch(chunk);
      if (hrefMatch == null) continue;
      final href = hrefMatch.group(1)!;
      // 仅取直接子文件（非目录本身）
      if (href == basePath || href.endsWith('/')) continue;
      // href 可能含 URL 编码（空格等），解码后取文件名
      final name = Uri.decodeComponent(href.split('/').last);
      if (name.isEmpty) continue;
      final sizeMatch = sizeRe.firstMatch(chunk);
      final modifiedMatch = modifiedRe.firstMatch(chunk);
      DateTime? modified;
      try {
        if (modifiedMatch != null) {
          modified = DateTime.parse(modifiedMatch.group(1)!.replaceFirst(
            ' GMT',
            'Z',
          ));
        }
      } catch (_) {}
      files.add(
        RemoteBackupFile(
          name: name,
          size: int.tryParse(sizeMatch?.group(1) ?? '') ?? 0,
          modified: modified,
        ),
      );
    }
    files.sort((a, b) => (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)));
    return files;
  }

  /// 删除文件（DELETE）。
  Future<void> delete(String path) async {
    final response = await AppHttpClient.instance.send(
      method: 'DELETE',
      uri: _uri(path),
      headers: _headers,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    if (response.statusCode >= 400 && response.statusCode != 404) {
      throw syncHttpError(
        'Delete failed (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
  }
}

/// S3 客户端（SigV4 签名，path-style）。
class S3Client {
  final String endpoint;
  final String accessKey;
  final String secretKey;
  final String bucket;
  final String region;

  S3Client({
    required this.endpoint,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    this.region = 'us-east-1',
  });

  String _host() {
    final uri = Uri.parse(endpoint);
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// 将 key 编码为 path-style 路径段：保留 `/` 作为路径分隔符，
  /// 逐段 URI 编码。请求 URL 与 SigV4 canonical URI 必须逐字节一致，
  /// 否则 AWS 会返回 SignatureDoesNotMatch（不能整体 encodeComponent，
  /// 那会把 `/` 变成 `%2F` 造成两侧不一致）。
  static String _encodedKey(String key) =>
      key.split('/').map(Uri.encodeComponent).join('/');

  /// 发送请求用的 URI（与签名路径一致）。
  Uri _uri(String key) {
    final base = endpoint.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/$bucket/${_encodedKey(key)}');
  }

  /// 签名与请求共用的规范化路径。
  String _canonicalPath(String key) => '/$bucket/${_encodedKey(key)}';

  /// 上传文件（PUT）。
  Future<void> put(String key, Uint8List data) async {
    final payloadHash = sha256.convert(data).toString();
    final headers = signedHeaders('PUT', _canonicalPath(key), {}, payloadHash);
    final response = await AppHttpClient.instance.send(
      method: 'PUT',
      uri: _uri(key),
      headers: {
        ...headers,
        'Content-Type': 'application/zip',
      },
      bodyBytes: data,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 120),
      retry: false,
    );
    if (response.statusCode >= 400) {
      throw syncHttpError(
        'Upload failed (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
  }

  /// 下载文件（GET）。
  Future<Uint8List> get(String key) async {
    final headers = signedHeaders('GET', _canonicalPath(key), {}, _emptyHash);
    final streamed = await AppHttpClient.instance.sendStreamed(
      method: 'GET',
      uri: _uri(key),
      headers: headers,
      connectTimeout: const Duration(seconds: 30),
    );
    if (streamed.statusCode >= 400) {
      throw syncHttpError(
        'Download failed (HTTP ${streamed.statusCode})',
        streamed.statusCode,
      );
    }
    return streamed.stream.toBytes();
  }

  /// 列出对象（ListObjectsV2）。[prefix] 限制列出前缀（如 `backups/`），
  /// 避免全桶扫描。
  Future<List<RemoteBackupFile>> list({String prefix = ''}) async {
    final query = <String, String>{'list-type': '2', 'prefix': prefix};
    final headers =
        signedHeaders('GET', '/$bucket', {}, _emptyHash, query: query);
    final base = endpoint.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/$bucket').replace(queryParameters: query);
    final response = await AppHttpClient.instance.send(
      method: 'GET',
      uri: uri,
      headers: headers,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    if (response.statusCode >= 400) return const [];
    final files = <RemoteBackupFile>[];
    final itemRe = RegExp(r'<Contents>(.*?)</Contents>', dotAll: true);
    final keyRe = RegExp(r'<Key>([^<]+)</Key>', dotAll: true);
    final sizeRe = RegExp(r'<Size>(\d+)</Size>');
    for (final m in itemRe.allMatches(response.body)) {
      final item = m.group(1)!;
      final keyMatch = keyRe.firstMatch(item);
      if (keyMatch == null) continue;
      final key = keyMatch.group(1)!;
      if (key.endsWith('/')) continue;
      final sizeMatch = sizeRe.firstMatch(item);
      files.add(
        RemoteBackupFile(
          name: key.split('/').last,
          size: int.tryParse(sizeMatch?.group(1) ?? '') ?? 0,
        ),
      );
    }
    return files;
  }

  /// 删除对象（DELETE）。
  Future<void> delete(String key) async {
    final headers = signedHeaders('DELETE', _canonicalPath(key), {}, _emptyHash);
    final response = await AppHttpClient.instance.send(
      method: 'DELETE',
      uri: _uri(key),
      headers: headers,
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 30),
      retry: false,
    );
    if (response.statusCode >= 400 && response.statusCode != 404) {
      throw syncHttpError(
        'Delete failed (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
  }

  static const _emptyHash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  /// SigV4 签名头。
  ///
  /// [path] 为与请求 URL 逐字节一致的规范化路径（含逐段编码）；
  /// [query] 为查询参数，参与签名的 canonical query string
  /// （排序 + URI 编码），不会拼进 [path]。
  Map<String, String> signedHeaders(
    String method,
    String path,
    Map<String, String> headers,
    String payloadHash, {
    Map<String, String> query = const {},
  }) {
    final now = DateTime.now().toUtc();
    final amzDate =
        '${now.toIso8601String().replaceAll(RegExp(r'[:-]'), '').substring(0, 15)}Z';
    final dateStamp = now.toIso8601String().substring(0, 10).replaceAll('-', '');
    final host = _host();

    final sortedHeaders = <String, String>{
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      ...headers,
    };
    final canonicalHeaders = sortedHeaders.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}\n')
        .join();
    final signedHeaderNames = sortedHeaders.keys
        .map((k) => k.toLowerCase())
        .toList()
      ..sort();
    final queryKeys = query.keys.toList()..sort();
    final canonicalQuery = queryKeys
        .map(
          (k) =>
              '${Uri.encodeQueryComponent(k)}='
              '${Uri.encodeQueryComponent(query[k]!)}',
        )
        .join('&');
    final canonicalRequest = [
      method,
      path,
      canonicalQuery,
      canonicalHeaders,
      signedHeaderNames.join(';'),
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      _sha256Hex(canonicalRequest),
    ].join('\n');

    final signingKey = _hmac(
      _hmac(_hmac(_hmac(
        utf8.encode('AWS4$secretKey'),
        dateStamp,
      ), region), 's3'), 'aws4_request');
    final signature = _hmacHex(signingKey, stringToSign);

    return {
      ...sortedHeaders,
      'Authorization':
          'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
          'SignedHeaders=${signedHeaderNames.join(';')}, '
          'Signature=$signature',
    };
  }

  static String _sha256Hex(String data) =>
      sha256.convert(utf8.encode(data)).toString();

  static List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  static String _hmacHex(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).toString();
}

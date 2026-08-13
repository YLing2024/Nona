import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../network/app_http_client.dart';
import '../../utils/logger.dart';

/// C-02：Google Vertex Service Account 认证（RS256 JWT → OAuth token）。
///
/// 解析 SA JSON（client_email/private_key/token_uri/project_id），
/// 签 JWT（aud=oauth2.googleapis.com/token，1 小时有效），
/// POST token_uri 换 access token；缓存到过期前 5 分钟。
class VertexServiceAccountAuth {
  VertexServiceAccountAuth._();

  /// token 缓存：key = email|scopes|tokenUri。
  static final Map<String, _CachedToken> _cache = {};

  /// 解析 Service Account JSON 文件内容。
  ///
  /// 返回字段映射；缺失关键字段时抛 [FormatException]。
  static Map<String, String> parseServiceAccountJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not a JSON object');
      }
      final email = decoded['client_email'] as String?;
      final privateKey = decoded['private_key'] as String?;
      final projectId = decoded['project_id'] as String?;
      final tokenUri = decoded['token_uri'] as String?;
      if (email == null || email.isEmpty) {
        throw const FormatException('missing client_email');
      }
      if (privateKey == null || privateKey.isEmpty) {
        throw const FormatException('missing private_key');
      }
      return {
        'client_email': email,
        'private_key': privateKey,
        'project_id': projectId ?? '',
        'token_uri': tokenUri ?? 'https://oauth2.googleapis.com/token',
      };
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('invalid SA JSON: $e');
    }
  }

  /// 获取 access token（带缓存；[sa] 为已解析的字段映射）。
  static Future<String> accessToken(Map<String, String> sa) async {
    final email = sa['client_email']!;
    final cacheKey = '$email|$_scope|${sa['token_uri']}';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.expired) {
      return cached.token;
    }
    final token = await _fetchToken(sa);
    _cache[cacheKey] = _CachedToken(token);
    return token;
  }

  static const _scope = 'https://www.googleapis.com/auth/cloud-platform';

  /// 请求 OAuth token 端点（grant_type=jwt-bearer）。
  static Future<String> _fetchToken(Map<String, String> sa) async {
    final assertion = _buildJwt(sa);
    final body = 'grant_type='
        'urn:ietf:params:oauth:grant-type:jwt-bearer'
        '&assertion=$assertion';
    try {
      final response = await AppHttpClient.instance.send(
        method: 'POST',
        uri: Uri.parse(sa['token_uri']!),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      if (response.statusCode != 200) {
        throw StateError(
          'token endpoint ${response.statusCode}: ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final token = decoded['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('no access_token in response');
      }
      return token;
    } catch (e) {
      Logger.error('vertex_auth', '获取 access token 失败', e);
      rethrow;
    }
  }

  /// 构造并签名 JWT（RS256）。
  static String _buildJwt(Map<String, String> sa) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };
    final claims = {
      'iss': sa['client_email'],
      'scope': _scope,
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now,
      'exp': now + 3600,
    };
    final signingInput = '${_b64(header)}.${_b64(claims)}';
    final signature = _signRsaSha256(
      sa['private_key']!,
      utf8.encode(signingInput),
    );
    return '$signingInput.${_b64(signature)}';
  }

  static String _b64(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  /// PEM 私钥 → RS256 签名（pointycastle）。
  static Uint8List _signRsaSha256(String pem, List<int> data) {
    final key = _parsePkcs8(pem);
    final signer = RSASigner(
      Digest('SHA-256'),
      '0609608648016503040201',
    )..init(
        true,
        // pointycastle 4.x 泛型推断：必须显式指定 T=RSAPrivateKey，
        // 否则 T 退化为 PrivateKey，RSAEngine.init 的强转在运行时会失败。
        PrivateKeyParameter<RSAPrivateKey>(key),
      );
    final signature = signer.generateSignature(Uint8List.fromList(data));
    return signature.bytes;
  }

  /// 解析 PKCS#8 PEM（-----BEGIN PRIVATE KEY-----）或
  /// PKCS#1（-----BEGIN RSA PRIVATE KEY-----）。
  static RSAPrivateKey _parsePkcs8(String pem) {
    final base64 = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final der = base64Decode(base64);
    try {
      return _parsePkcs8Der(der);
    } catch (_) {
      return _parsePkcs1Der(der);
    }
  }

  static RSAPrivateKey _parsePkcs8Der(List<int> der) {
    // PKCS#8：SEQUENCE( version, AlgorithmIdentifier, OCTET STRING(PKCS#1) )
    final parser = _DerReader(der);
    final seq = parser.readSequence();
    seq.readInt(); // version
    final alg = seq.readSequence();
    alg.readOid();
    alg.readAny(); // parameters
    final octet = seq.readOctetString();
    return _parsePkcs1Der(octet);
  }

  static RSAPrivateKey _parsePkcs1Der(List<int> der) {
    final parser = _DerReader(der);
    final seq = parser.readSequence();
    seq.readInt(); // version
    final modulus = seq.readBigInt();
    seq.readBigInt(); // publicExponent
    final privateExponent = seq.readBigInt();
    final p = seq.readBigInt();
    final q = seq.readBigInt();
    seq.readBigInt(); // dP
    seq.readBigInt(); // dQ
    seq.readBigInt(); // qInv
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }
}

/// token 缓存项（提前 5 分钟过期）。
class _CachedToken {
  final String token;
  final DateTime expiresAt;

  _CachedToken(this.token) : expiresAt = DateTime.now().add(
        const Duration(minutes: 55),
      );

  bool get expired => DateTime.now().isAfter(expiresAt);
}

/// 极简 DER 读取器（PKCS#8 / PKCS#1 私钥解析）。
class _DerReader {
  final List<int> _bytes;
  int _pos = 0;

  _DerReader(this._bytes);

  int _readByte() => _bytes[_pos++];

  int _readLength() {
    final first = _readByte();
    if (first < 0x80) return first;
    final count = first & 0x7F;
    var length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | _readByte();
    }
    return length;
  }

  _DerReader readSequence() {
    final tag = _readByte();
    if (tag != 0x30) {
      throw StateError('expected SEQUENCE, got 0x${tag.toRadixString(16)}');
    }
    final length = _readLength();
    final end = _pos + length;
    final sub = _bytes.sublist(_pos, end);
    _pos = end;
    return _DerReader(sub);
  }

  int readInt() {
    final tag = _readByte();
    if (tag != 0x02) throw StateError('expected INTEGER');
    final length = _readLength();
    var value = 0;
    for (var i = 0; i < length; i++) {
      value = (value << 8) | _readByte();
    }
    return value;
  }

  BigInt readBigInt() {
    final tag = _readByte();
    if (tag != 0x02) throw StateError('expected INTEGER');
    final length = _readLength();
    final bytes = <int>[];
    for (var i = 0; i < length; i++) {
      bytes.add(_readByte());
    }
    // 去掉前导 0（符号位）
    while (bytes.length > 1 && bytes.first == 0) {
      bytes.removeAt(0);
    }
    return BigInt.parse(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }

  String readOid() {
    final tag = _readByte();
    if (tag != 0x06) throw StateError('expected OID');
    final length = _readLength();
    _pos += length;
    return '';
  }

  List<int> readOctetString() {
    final tag = _readByte();
    if (tag != 0x04) throw StateError('expected OCTET STRING');
    final length = _readLength();
    final result = _bytes.sublist(_pos, _pos + length);
    _pos += length;
    return result;
  }

  /// 读取任意剩余 TLV（用于跳过 parameters）。
  void readAny() {
    final tag = _readByte();
    if (tag == 0x05) {
      final length = _readLength();
      _pos += length;
      return;
    }
    if (tag == 0x00) return;
    final length = _readLength();
    _pos += length;
  }
}

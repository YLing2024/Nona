import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nona_chat/core/network/app_http_client.dart';
import 'package:nona_chat/core/services/network_log_service.dart'
    show NetworkLogType;
import 'package:nona_chat/core/services/protocol/vertex_auth.dart';
import 'package:pointycastle/export.dart';

/// 测试用 AppHttpClient：记录请求并返回预置响应。
class _FakeClient extends AppHttpClient {
  _FakeClient(this.statusCode, this.body, {this.onRequest});

  final int statusCode;
  final String body;
  final void Function(http.Request)? onRequest;
  int calls = 0;

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
    onRequest?.call(
      http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = bodyBytes == null ? body : utf8.decode(bodyBytes),
    );
    return http.Response(this.body, statusCode);
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

/// 用 pointycastle 生成 RSA 密钥并编码为 PKCS#8 PEM（供 JWT 签名路径测试）。
String generateRsaPkcs8Pem() {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 1024, 64),
      _FixedRandom(),
    ));
  final key = keyGen.generateKeyPair().privateKey;

  // PKCS#1：SEQUENCE{version, n, e, d, p, q, dp, dq, qinv}
  final e = BigInt.parse('65537');
  final dp = key.privateExponent! % (key.p! - BigInt.one);
  final dq = key.privateExponent! % (key.q! - BigInt.one);
  final qInv = key.q!.modInverse(key.p!);
  final pkcs1 = _Seq([
    _int(BigInt.zero),
    _int(key.n!),
    _int(e),
    _int(key.privateExponent!),
    _int(key.p!),
    _int(key.q!),
    _int(dp),
    _int(dq),
    _int(qInv),
  ]);

  // PKCS#8：SEQUENCE{version, AlgId{oid rsaEncryption, NULL}, OCTET STRING{pkcs1}}
  const rsaOid = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
  final algId = _Seq([
    _tlv(0x06, rsaOid),
    _tlv(0x05, const []),
  ]);
  final pkcs8 = _Seq([
    _int(BigInt.zero),
    algId.bytes,
    _tlv(0x04, pkcs1.bytes),
  ]);

  var pem = '-----BEGIN PRIVATE KEY-----\n';
  final encoded = base64.encode(pkcs8.bytes);
  for (var i = 0; i < encoded.length; i += 64) {
    pem += '${encoded.substring(i, (i + 64).clamp(0, encoded.length))}\n';
  }
  pem += '-----END PRIVATE KEY-----\n';
  return pem;
}

/// 固定种子随机源（RSA 生成需要确定性输入）。
class _FixedRandom implements SecureRandom {
  int _state = 0x12345678;

  @override
  String get algorithmName => 'fixed';

  @override
  void seed(CipherParameters params) {}

  @override
  Uint8List nextBytes(int count) {
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
      out[i] = _state >> 24;
    }
    return out;
  }

  @override
  int nextUint8() => nextBytes(1)[0];

  @override
  int nextUint16() => (nextBytes(2)[0] << 8) | nextBytes(2)[1];

  @override
  int nextUint32() {
    _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _state;
  }

  @override
  BigInt nextBigInteger(int bitLength) {
    final bytes = (bitLength + 7) ~/ 8;
    final buf = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
      buf[i] = _state >> 24;
    }
    buf[0] |= 0x80;
    return BigInt.parse(
      buf.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }
}

class _Seq {
  final List<List<int>> children;
  _Seq(this.children);

  List<int> get bytes {
    final body = <int>[];
    for (final c in children) {
      body.addAll(c);
    }
    return [0x30, ..._len(body.length), ...body];
  }
}

Uint8List _int(BigInt v) {
  var bytes = _toBytes(v);
  if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
    bytes = [0, ...bytes];
  }
  return _tlv(0x02, bytes);
}

Uint8List _tlv(int tag, List<int> body) =>
    Uint8List.fromList([tag, ..._len(body.length), ...body]);

List<int> _len(int length) {
  if (length < 0x80) return [length];
  final bytes = <int>[];
  var n = length;
  while (n > 0) {
    bytes.insert(0, n & 0xFF);
    n >>= 8;
  }
  return [0x80 | bytes.length, ...bytes];
}

List<int> _toBytes(BigInt v) {
  final hex = v.toRadixString(16);
  final padded = hex.length.isOdd ? '0$hex' : hex;
  return [
    for (var i = 0; i < padded.length; i += 2)
      int.parse(padded.substring(i, i + 2), radix: 16),
  ];
}

void main() {
  late AppHttpClient original;

  setUp(() => original = AppHttpClient.instance);
  tearDown(() => AppHttpClient.overrideForTesting(original));

  group('VertexServiceAccountAuth.parseServiceAccountJson', () {
    test('完整 SA JSON 解析', () {
      final sa = VertexServiceAccountAuth.parseServiceAccountJson(
        jsonEncode({
          'client_email': 'svc@proj.iam.gserviceaccount.com',
          'private_key': '-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n',
          'project_id': 'my-proj',
        }),
      );
      expect(sa['client_email'], 'svc@proj.iam.gserviceaccount.com');
      expect(sa['project_id'], 'my-proj');
      expect(sa['token_uri'], 'https://oauth2.googleapis.com/token');
    });

    test('缺失 client_email → FormatException', () {
      expect(
        () => VertexServiceAccountAuth.parseServiceAccountJson(
          jsonEncode({'private_key': 'x'}),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('缺失 private_key → FormatException', () {
      expect(
        () => VertexServiceAccountAuth.parseServiceAccountJson(
          jsonEncode({'client_email': 'a@b.c'}),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('非 JSON → FormatException', () {
      expect(
        () => VertexServiceAccountAuth.parseServiceAccountJson('not json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('VertexServiceAccountAuth.accessToken', () {
    Map<String, String> saFor(String email) => {
          'client_email': email,
          'private_key': generateRsaPkcs8Pem(),
          'project_id': 'my-proj',
          'token_uri': 'https://oauth2.googleapis.com/token',
        };

    final sa = saFor('svc@proj.iam.gserviceaccount.com');

    test('签发 JWT 并换取 token；缓存避免重复请求', () async {
      String? grantType;
      String? assertion;
      final fake = _FakeClient(
        200,
        jsonEncode({'access_token': 'ya29.token'}),
        onRequest: (req) {
          grantType = Uri.splitQueryString(req.body)['grant_type'];
          assertion = Uri.splitQueryString(req.body)['assertion'];
        },
      );
      AppHttpClient.overrideForTesting(fake);

      final token = await VertexServiceAccountAuth.accessToken(sa);
      expect(token, 'ya29.token');
      expect(grantType, 'urn:ietf:params:oauth:grant-type:jwt-bearer');
      // JWT 结构：header.claims.signature（RS256）
      final parts = assertion!.split('.');
      expect(parts.length, 3);
      final header = jsonDecode(
        utf8.decode(_b64url(parts[0])),
      ) as Map<String, dynamic>;
      expect(header['alg'], 'RS256');
      final claims = jsonDecode(
        utf8.decode(_b64url(parts[1])),
      ) as Map<String, dynamic>;
      expect(claims['iss'], sa['client_email']);
      expect(claims['aud'], 'https://oauth2.googleapis.com/token');
      expect(claims['exp'] - claims['iat'], 3600);

      // 缓存：第二次调用不再发请求
      final token2 = await VertexServiceAccountAuth.accessToken(sa);
      expect(token2, 'ya29.token');
      expect(fake.calls, 1);
    });

    test('token 端点非 200 → StateError', () async {
      AppHttpClient.overrideForTesting(_FakeClient(401, '{"error":"denied"}'));
      final other = saFor('other@proj.iam.gserviceaccount.com');
      expect(
        () => VertexServiceAccountAuth.accessToken(other),
        throwsA(isA<StateError>()),
      );
    });

    test('响应无 access_token → StateError', () async {
      AppHttpClient.overrideForTesting(_FakeClient(200, '{"ok":true}'));
      final other = saFor('another@proj.iam.gserviceaccount.com');
      expect(
        () => VertexServiceAccountAuth.accessToken(other),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// base64url 解码（补 padding）。
Uint8List _b64url(String s) {
  var padded = s;
  while (padded.length % 4 != 0) {
    padded += '=';
  }
  return base64Url.decode(padded);
}

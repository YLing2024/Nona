import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/services/network_log_service.dart';

import '../support/reset_globals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetGlobalState();
  });

  tearDown(() {
    NetworkLogService.instance
      ..setEnabled(false)
      ..setMaxLogs(0)
      ..clear();
  });

  group('NetworkLogService', () {
    test('truncate 长正文保留头部并注明原长度', () {
      final long = 'a' * 9000;
      final truncated = NetworkLogService.truncate(long, max: 100);
      expect(truncated.length, lessThan(200));
      expect(truncated, contains('original 9000 chars'));
      expect(NetworkLogService.truncate('short'), 'short');
    });

    test('begin 脱敏 Authorization / X-API-Key 请求头', () {
      NetworkLogService.instance.setEnabled(true);
      final builder = NetworkLogService.begin(
        method: 'POST',
        url: 'https://x/v1',
        requestHeaders: const {
          'Authorization': 'Bearer sk-secret',
          'X-API-Key': 'k-1',
          'Content-Type': 'application/json',
        },
      );
      expect(builder, isNotNull);
      expect(builder!.requestHeaders['Authorization'], '******');
      expect(builder.requestHeaders['X-API-Key'], '******');
      expect(builder.requestHeaders['Content-Type'], 'application/json');
      NetworkLogService.instance.setEnabled(false);
    });

    test('F7-4 请求体脱敏全场景', () {
      final cases = <String, String>{
        '{"api_key":"sk-abc"}': '{"api_key":"******"}',
        '{"APIKey":"abc"}': '{"APIKey":"******"}',
        '{"password":"hunter2"}': '{"password":"******"}',
        '{"secret":"s1"}': '{"secret":"******"}',
        '{"refresh_token":"rt1"}': '{"refresh_token":"******"}',
        '{"access_token":"at1"}': '{"access_token":"******"}',
        '{"client_secret":"cs1"}': '{"client_secret":"******"}',
        '{"private_key":"pk1"}': '{"private_key":"******"}',
        '{"authorization":"Bearer x"}': '{"authorization":"******"}',
        '{"cookie":"sid=1"}': '{"cookie":"******"}',
        '{"token":"t1"}': '{"token":"******"}',
      };
      cases.forEach((input, expected) {
        expect(NetworkLogService.sanitizeBody(input), expected,
            reason: '应脱敏: $input');
      });
      // 非密钥字段不受影响
      expect(
        NetworkLogService.sanitizeBody('{"model":"gpt-4o","messages":[]}'),
        '{"model":"gpt-4o","messages":[]}',
      );
    });

    test('未启用时 begin 返回 null，不记录日志', () {
      NetworkLogService.instance.setEnabled(false);
      expect(
        NetworkLogService.begin(method: 'GET', url: 'https://x'),
        isNull,
      );
      expect(NetworkLogService.instance.logs, isEmpty);
    });

    test('record 受 maxLogs 限制，最新在前', () {
      NetworkLogService.instance
        ..setEnabled(true)
        ..setMaxLogs(3);
      for (var i = 0; i < 5; i++) {
        NetworkLogService.instance.record(_log('l$i'));
      }
      final logs = NetworkLogService.instance.logs;
      expect(logs, hasLength(3));
      expect(logs.first.id, 'l4');
      expect(logs.last.id, 'l2');
      NetworkLogService.instance.setEnabled(false);
    });
  });
}

NetworkLog _log(String id) {
  return NetworkLog(
    id: id,
    time: DateTime(2024),
    method: 'GET',
    url: 'https://x',
    statusCode: 200,
    durationMs: 1,
    requestBytes: 0,
    responseBytes: 0,
    requestHeaders: const {},
    requestBody: '',
    responseHeaders: const {},
    responseBody: '',
    type: NetworkLogType.other,
  );
}

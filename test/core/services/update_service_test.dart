import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/update_service.dart';

void main() {
  group('UpdateService 版本比较（J-02）', () {
    test('isNewerVersion：主/次/补丁版本比较', () {
      expect(UpdateService.isNewerVersion('v1.4.0', '1.3.0'), isTrue);
      expect(UpdateService.isNewerVersion('v1.3.1', '1.3.0'), isTrue);
      expect(UpdateService.isNewerVersion('v2.0.0', '1.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('v1.2.0', '1.3.0'), isFalse);
      expect(UpdateService.isNewerVersion('v1.3.0', '1.3.0'), isFalse);
      expect(UpdateService.isNewerVersion('v1.3.0+1', '1.3.0'), isFalse);
    });

    test('无效版本返回 false', () {
      expect(UpdateService.isNewerVersion('latest', '1.3.0'), isFalse);
      expect(UpdateService.isNewerVersion('v1.4.0', 'not-a-version'), isFalse);
    });
  });
}

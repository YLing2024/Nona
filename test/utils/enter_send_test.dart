import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/utils/enter_send.dart';

void main() {
  group('EnterSendLogic.shouldSend', () {
    test('sendOnEnter 开启：裸回车发送', () {
      expect(
        EnterSendLogic.shouldSend(
          sendOnEnter: true,
          plainEnter: true,
          controlPressed: false,
        ),
        isTrue,
      );
    });

    test('sendOnEnter 开启：Shift+Enter 不发送（换行）', () {
      expect(
        EnterSendLogic.shouldSend(
          sendOnEnter: true,
          plainEnter: false,
          controlPressed: false,
        ),
        isFalse,
      );
    });

    test('sendOnEnter 关闭：Ctrl+Enter 发送', () {
      expect(
        EnterSendLogic.shouldSend(
          sendOnEnter: false,
          plainEnter: false,
          controlPressed: true,
        ),
        isTrue,
      );
    });

    test('sendOnEnter 关闭：裸回车不发送（换行）', () {
      expect(
        EnterSendLogic.shouldSend(
          sendOnEnter: false,
          plainEnter: true,
          controlPressed: false,
        ),
        isFalse,
      );
    });

    test('sendOnEnter 关闭：Shift+Enter 不发送', () {
      expect(
        EnterSendLogic.shouldSend(
          sendOnEnter: false,
          plainEnter: false,
          controlPressed: false,
        ),
        isFalse,
      );
    });
  });
}

/// 平台环境检测（io 版）。
library;

import 'dart:io';

/// 是否为 flutter test 环境（FakeAsync 平台通道悬挂，需走存根）。
bool get isFlutterTest {
  try {
    return Platform.environment['FLUTTER_TEST'] == 'true';
  } catch (_) {
    return false;
  }
}

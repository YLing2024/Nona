import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/utils/stream_flusher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('同帧连续 100 次 add 合并为一次 onFlush（内容完整）', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var count = 0;
    var total = '';
    final flusher = StreamFlusher(onFlush: (s) {
      count++;
      total += s;
    });
    for (var i = 0; i < 100; i++) {
      flusher.add('x');
    }
    expect(count, 0, reason: '帧回调执行前不得触发');
    await tester.pump();
    expect(count, 1, reason: '同帧增量合并为一次通知');
    expect(total, 'x' * 100);
  });

  testWidgets('跨帧增量按帧分批通知', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var count = 0;
    var total = '';
    final flusher = StreamFlusher(onFlush: (s) {
      count++;
      total += s;
    });
    flusher.add('a');
    await tester.pump();
    flusher.add('b');
    flusher.add('c');
    await tester.pump();
    expect(count, 2);
    expect(total, 'abc');
  });

  testWidgets('flushNow 立即冲刷剩余增量，不重复触发', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var count = 0;
    var total = '';
    final flusher = StreamFlusher(onFlush: (s) {
      count++;
      total += s;
    });
    flusher.add('a');
    flusher.flushNow();
    expect(count, 1);
    expect(total, 'a');
    // 已注册的帧回调随后执行：缓冲为空 → no-op
    await tester.pump();
    expect(count, 1);
    expect(total, 'a');
  });

  testWidgets('空增量不触发 onFlush', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var count = 0;
    final flusher = StreamFlusher(onFlush: (_) => count++);
    flusher.add('');
    await tester.pump();
    flusher.flushNow();
    expect(count, 0);
  });

  testWidgets('flushNow 后可继续接收增量', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var count = 0;
    var total = '';
    final flusher = StreamFlusher(onFlush: (s) {
      count++;
      total += s;
    });
    flusher.add('a');
    flusher.flushNow();
    flusher.add('b');
    await tester.pump();
    expect(count, 2);
    expect(total, 'ab');
  });
}

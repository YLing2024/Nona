import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/roulette/key_roulette.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F2-3 多 Key 轮换单测。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  test('3 key 轮换分布均匀且不重复', () async {
    final roulette = KeyRoulette('p1');
    await roulette.setKeys(['k1', 'k2', 'k3']);
    final picked = <String>[];
    for (var i = 0; i < 9; i++) {
      picked.add((await roulette.next())!);
    }
    // ignore: avoid_print
    print('SEQ: $picked');
    // LRU：前 3 次各用一次，第 4 次回到 k1
    expect(picked.sublist(0, 3).toSet(), {'k1', 'k2', 'k3'});
    expect(picked[3], 'k1');
    final counts = <String, int>{};
    for (final k in picked) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    expect(counts['k1'], 3);
    expect(counts['k2'], 3);
    expect(counts['k3'], 3);
  });

  test('失败标记冷却：失败 key 短期不被选中', () async {
    final roulette = KeyRoulette('p2');
    await roulette.setKeys(['good', 'bad']);
    await roulette.markFailed('bad');
    final picked = <String>[];
    for (var i = 0; i < 4; i++) {
      picked.add((await roulette.next())!);
    }
    expect(picked, everyElement('good'), reason: '冷却期内只应选 good');
    await roulette.markSuccess('bad');
    final after = await roulette.next();
    // 冷却解除后 bad 重新可被选中（LRU 下 bad 最久未用）
    expect(after, 'bad');
  });

  test('从未用过优先于最久未用', () async {
    final roulette = KeyRoulette('p3');
    await roulette.setKeys(['a', 'b']);
    expect(await roulette.next(), 'a');
    // a 已用过：下一轮选从未用过的 b
    expect(await roulette.next(), 'b');
    // 都用过后回到最久未用的 a
    expect(await roulette.next(), 'a');
  });

  test('24h 过期重置使用历史（持久化状态直接注入）', () async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().microsecondsSinceEpoch;
    await prefs.setString(
      'roulette_p4',
      jsonEncode({
        'keys': ['a', 'b'],
        'lastUsed': {'a': 1, 'b': 2},
        'lastUsedWall': {
          'a': now - 25 * 3600000000,
          'b': now - 25 * 3600000000 + 1000000,
        },
        'failedAt': <String, int>{},
      }),
    );
    final roulette = KeyRoulette('p4');
    // 全部 key 距上次使用超过 24h：TTL 重置 → 从未用过语义 → 顺序 a,b
    expect(await roulette.next(), 'a');
    expect(await roulette.next(), 'b');
  });

  test('解析多行/逗号分隔 key', () {
    expect(
      KeyRoulette.parseKeys('k1,k2\nk3;k4\r\nk5'),
      ['k1', 'k2', 'k3', 'k4', 'k5'],
    );
    expect(KeyRoulette.parseKeys('  k1  ,  '), ['k1']);
  });

  test('空 key 集合返回 null', () async {
    final roulette = KeyRoulette('empty');
    expect(await roulette.next(), isNull);
  });
}

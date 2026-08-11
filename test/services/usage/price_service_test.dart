import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/services/usage/price_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F3-2 价格服务单测（内置价格表 + 自定义覆盖 + 最长前缀匹配）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 价格表从 assets 加载（测试环境 bundle 可用）
  });

  test('内置价格表加载：gpt-4o 与 claude-3-7-sonnet', () async {
    final svc = PriceService.instance;
    await svc.load();
    final gpt4o = await svc.priceFor('gpt-4o');
    expect(gpt4o, isNotNull);
    expect(gpt4o!.promptPerM, 2.5);
    expect(gpt4o.completionPerM, 10);
    final claude = await svc.priceFor('claude-3-7-sonnet');
    expect(claude, isNotNull);
    expect(claude!.promptPerM, 3);
  });

  test('未知模型返回 null', () async {
    await PriceService.instance.load();
    expect(await PriceService.instance.priceFor('totally-unknown-model-xyz'), isNull);
  });

  test('自定义价格覆盖内置（大小写不敏感）', () async {
    final svc = PriceService.instance;
    await svc.setCustomPrice('GPT-4O', const ModelPrice(promptPerM: 1, completionPerM: 2));
    expect((await svc.priceFor('gpt-4o'))!.promptPerM, 1);
    await svc.setCustomPrice('gpt-4o', null);
    expect((await svc.priceFor('gpt-4o'))!.promptPerM, 2.5);
  });

  test('costFor 按 token 数计算', () async {
    await PriceService.instance.load();
    // gpt-4o: 1M in = $2.5, 1M out = $10
    final cost = await PriceService.instance.costFor('gpt-4o', 1000000, 500000);
    expect(cost, closeTo(2.5 + 5.0, 0.001));
  });

  test('零 token 返回 0', () async {
    await PriceService.instance.load();
    expect(await PriceService.instance.costFor('gpt-4o', 0, 0), 0);
  });

  test('deepseek-chat 价格存在', () async {
    await PriceService.instance.load();
    final p = await PriceService.instance.priceFor('deepseek-chat');
    expect(p, isNotNull);
    expect(p!.promptPerM, 0.27);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/main.dart';
import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/services/provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.clean();
    dotenv.testLoad(fileInput: 'NONA_DEBUG_API_KEY=sk-test\n');
  });

  tearDown(() {
    dotenv.clean();
  });

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();
  }

  Future<void> seedDebugProviderWithModels() async {
    final service = ProviderService();
    final providers = await service.load();
    final idx = providers.indexWhere(
      (p) => p.id == ProviderService.debugProviderId,
    );
    providers[idx] = ChatProvider(
      id: ProviderService.debugProviderId,
      name: 'Debug · opencode',
      baseUrl: 'https://x/v1',
      apiKey: 'sk-test',
      modelIds: const ['gpt-4o-mini', 'gpt-4o', 'deepseek-chat'],
    );
    await service.save(providers);
  }

  testWidgets('DIAG: dump overflow details at 320 width',
      (WidgetTester tester) async {
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = original);

    await seedDebugProviderWithModels();
    await pumpApp(tester, const Size(320, 640));
    // ignore: avoid_print
    debugDumpRenderTree();
    for (final e in errors) {
      // ignore: avoid_print
      print('===== OVERFLOW DIAG =====\n${e.exception}');
      // ignore: avoid_print
      print('CREATOR: ${e.context?.toString() ?? 'none'}');
    }
    FlutterError.onError = original;
  });

  testWidgets('Narrow phone 360x740: no overflow on home',
      (WidgetTester tester) async {
    await seedDebugProviderWithModels();
    await pumpApp(tester, const Size(360, 740));
    expect(tester.takeException(), isNull,
        reason: '360px 窄屏首页不应有渲染溢出');
  });

  testWidgets('Small window 320x640: no overflow on home',
      (WidgetTester tester) async {
    await seedDebugProviderWithModels();
    await pumpApp(tester, const Size(320, 640));
    expect(tester.takeException(), isNull,
        reason: '320px 窄屏首页不应有渲染溢出');
  });

  testWidgets('Home with long model names: no overflow',
      (WidgetTester tester) async {
    final service = ProviderService();
    final providers = await service.load();
    final idx = providers.indexWhere(
      (p) => p.id == ProviderService.debugProviderId,
    );
    providers[idx] = ChatProvider(
      id: ProviderService.debugProviderId,
      name: 'Debug · opencode',
      baseUrl: 'https://x/v1',
      apiKey: 'sk-test',
      modelIds: const [
        'deepseek-v3-0324-very-long-model-name-for-testing',
      ],
    );
    await service.save(providers);
    await pumpApp(tester, const Size(360, 740));
    expect(tester.takeException(), isNull,
        reason: '长模型名不应导致工具条溢出');
  });
}

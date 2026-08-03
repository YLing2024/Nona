import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/services/provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '''
NONA_DEBUG_API_KEY=sk-test-debug-key
NONA_DEBUG_BASE_URL=https://debug.example.com/v1
''');
  });

  tearDown(() {
    dotenv.clean();
  });

  group('ProviderService debug provider', () {
    test('非 release 且 .env 配置了密钥时注入调试服务商', () async {
      final service = ProviderService();
      final providers = await service.load();

      final debug = providers
          .where((p) => p.id == ProviderService.debugProviderId)
          .firstOrNull;
      expect(debug, isNotNull, reason: '调试服务商应被注入');
      expect(debug!.baseUrl, 'https://debug.example.com/v1');
      expect(debug.apiKey, 'sk-test-debug-key');
    });

    test('未配置密钥时（如 release 或 .env 为空）不注入调试服务商', () async {
      dotenv.clean();
      dotenv.testLoad(fileInput: 'NONA_DEBUG_API_KEY=');
      final service = ProviderService();
      final providers = await service.load();
      expect(
        providers.any((p) => p.id == ProviderService.debugProviderId),
        isFalse,
        reason: '无密钥时不应注入调试服务商',
      );
    });

    test('save() 不持久化调试服务商，但保留其勾选模型', () async {
      final service = ProviderService();

      await service.save([
        ChatProvider(
          id: 'provider-custom',
          name: 'Custom',
          baseUrl: 'https://example.com/v1',
          apiKey: 'sk-test',
          modelIds: const ['model-a'],
        ),
        ChatProvider(
          id: ProviderService.debugProviderId,
          name: 'Debug · opencode',
          baseUrl: 'https://debug.example.com/v1',
          apiKey: 'sk-test-debug-key',
          modelIds: const ['model-x', 'model-y'],
        ),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('providers');
      expect(raw, isNotNull);
      expect(raw!.contains('provider-debug'), isFalse,
          reason: '调试服务商不应写入正式配置');
      final list = jsonDecode(raw) as List<dynamic>;
      expect(list, hasLength(1));
      expect((list.first as Map<String, dynamic>)['id'], 'provider-custom');

      // 勾选的模型单独保存，load 时注入到调试服务商上
      final providers = await service.load();
      final debug = providers
          .where((p) => p.id == ProviderService.debugProviderId)
          .firstOrNull;
      expect(debug!.modelIds, containsAll(['model-x', 'model-y']));
    });
  });
}

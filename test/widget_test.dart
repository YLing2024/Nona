// Nona 基础 UI 测试。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/main.dart';
import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/services/provider_service.dart';

void main() {
  testWidgets('App renders chat screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // 窄屏（默认测试视口）下显示空状态首页与输入区。
    expect(find.text('你好，我是 Nona'), findsOneWidget);
    expect(find.text('新建会话'), findsOneWidget);
    expect(
      find.text('输入消息，Enter 换行，Ctrl+Enter 发送'),
      findsOneWidget,
    );
  });

  testWidgets('Wide layout shows sidebar without Material errors',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // 宽屏：侧边栏品牌、搜索、会话项与设置入口均可见。
    expect(find.text('AI 聊天助手'), findsOneWidget);
    expect(find.text('搜索会话与消息…'), findsOneWidget);
    expect(find.text('新对话'), findsWidgets);
    expect(find.text('设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Content avoids status bar and bottom insets (notch)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(
      top: 47,
      bottom: 24,
      left: 0,
      right: 0,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // 顶部：会话标题不得与状态栏（刘海）重叠。
    final titleTop = tester.getTopLeft(find.text('新对话')).dy;
    expect(titleTop, greaterThanOrEqualTo(47));

    // 底部：发送按钮不得被手势条遮挡。
    final sendBottom = tester
        .getBottomLeft(
          find.byWidgetPredicate(
            (w) =>
                w is Icon &&
                w.icon == Icons.arrow_upward_rounded &&
                w.size == 20,
          ),
        )
        .dy;
    expect(sendBottom, lessThanOrEqualTo(850 - 24 + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Real .env injects debug provider into UI',
      (WidgetTester tester) async {
    if (!File('.env').existsSync()) {
      markTestSkipped('项目根缺少 .env，跳过');
      return;
    }
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env', isOptional: true);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // 打开 设置 → 服务商，Debug 服务商应出现在列表中。
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务商'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Debug'), findsOneWidget);
    expect(
      find.textContaining(ProviderService.debugProviderId),
      findsNothing,
      reason: '调试服务商不应持久化',
    );
  });

  testWidgets('Chat uses first provider that has models, not empty first',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_model': 'gpt-debug-model',
    });
    dotenv.clean();
    dotenv.testLoad(fileInput: 'NONA_DEBUG_API_KEY=sk-test\n');

    // 首次 load：内置空的 OpenAI + 调试服务商；模拟用户给调试服务商勾选模型
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
      modelIds: const ['gpt-debug-model'],
    );
    await service.save(providers);

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();

    // 工具条应显示调试服务商的模型，而不是「未配置模型」
    expect(find.text('未配置模型'), findsNothing);
    expect(find.textContaining('gpt-debug-model'), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/features/search/screens/search_screen.dart';
import 'package:nona_chat/features/settings/screens/settings_screen.dart';
import 'package:nona_chat/features/settings/screens/theme_settings_screen.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/theme_controller.dart';
import 'package:nona_chat/features/chat/widgets/chat_composer.dart';
import 'package:nona_chat/shared/widgets/chat_options_form.dart';
import 'package:nona_chat/shared/widgets/markdown_view.dart';
import 'package:nona_chat/features/chat/widgets/message_bubble.dart';
import 'package:nona_chat/features/chat/widgets/message_list.dart';

import '../../../support/app_test_wrapper.dart';
import '../../../support/reset_globals.dart';

void main() {
  Widget wrap(Widget child) => wrapApp(
        Scaffold(body: SingleChildScrollView(child: child)),
      );

  /// 流式组件含重复动画，用固定 pump 而非 pumpAndSettle。
  Future<void> pumpFixed(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(wrap(child));
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('MessageBubble', () {
    testWidgets('用户消息：内容+头像靠右，无 Nona 头', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(message: ChatMessage(role: 'user', content: '你好世界')),
      );
      expect(find.text('你好世界'), findsOneWidget);
      expect(find.text('Nona'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });

    testWidgets('助手消息：Nona 头 + 服务商模型标注 + Markdown 渲染', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(
            role: 'assistant',
            content: '这是 **加粗** 文本',
            providerName: 'OpenAI',
            modelId: 'gpt-4o-mini',
          ),
        ),
      );
      expect(find.text('Nona'), findsOneWidget);
      expect(find.textContaining('OpenAI · gpt-4o-mini'), findsOneWidget);
      expect(find.textContaining('加粗', findRichText: true), findsOneWidget);
    });

    testWidgets('思考内容：默认收起，点击展开全文', (tester) async {
      final reasoning = List.generate(12, (i) => '思考行 $i').join('\n');
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(
            role: 'assistant',
            content: '回答',
            reasoningContent: reasoning,
          ),
        ),
      );
      expect(find.text('思考过程'), findsOneWidget);
      // 收起时只显示最后 5 行
      expect(find.textContaining('思考行 7'), findsOneWidget);
      expect(find.textContaining('思考行 0'), findsNothing);

      await tester.tap(find.text('思考过程'));
      await tester.pump();
      expect(find.textContaining('思考行 0'), findsOneWidget);
    });

    testWidgets('失败与中断状态提示', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'assistant', content: '部分内容', failed: true),
        ),
      );
      expect(find.text('生成失败'), findsOneWidget);
      expect(find.text('已停止生成'), findsNothing);

      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'assistant', content: '部分内容', interrupted: true),
        ),
      );
      expect(find.text('已停止生成'), findsOneWidget);
      expect(find.text('生成失败'), findsNothing);
    });

    testWidgets('流式未出内容时显示正在生成', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'assistant', content: ''),
          isStreaming: true,
        ),
      );
      expect(find.text('正在生成…'), findsOneWidget);
    });

    testWidgets('token 用量统计展示', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(
            role: 'assistant',
            content: 'x',
            promptTokens: 1234,
            completionTokens: 500,
            elapsedMs: 1500,
          ),
        ),
      );
      expect(find.textContaining('↑1.23k'), findsOneWidget);
      expect(find.textContaining('↓500'), findsOneWidget);
      expect(find.textContaining('1.5s'), findsOneWidget);
    });

    testWidgets('点击复制/删除触发回调', (tester) async {
      var copied = false;
      var deleted = false;
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'user', content: '内容'),
          onCopy: () => copied = true,
          onDelete: () => deleted = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.copy_rounded));
      expect(copied, isTrue);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);
    });

    testWidgets('重新生成仅出现在可重生成的助手消息', (tester) async {
      var regenerated = false;
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'assistant', content: 'x'),
          canRegenerate: true,
          onRegenerate: () => regenerated = true,
        ),
      );
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(regenerated, isTrue);

      // 用户消息不出现重新生成
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'user', content: 'x'),
          canRegenerate: true,
          onRegenerate: () => regenerated = true,
        ),
      );
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    });

    testWidgets('回滚仅出现在用户消息', (tester) async {
      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'user', content: 'x'),
          onRollback: () {},
        ),
      );
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);

      await pumpFixed(
        tester,
        MessageBubble(
          message: ChatMessage(role: 'assistant', content: 'x'),
          onRollback: () {},
        ),
      );
      expect(find.byIcon(Icons.undo_rounded), findsNothing);
    });
  });

  group('MarkdownView', () {
    testWidgets('渲染段落与粗体', (tester) async {
      await pumpFixed(tester, const MarkdownView(data: '你好 **世界**'));
      expect(find.textContaining('世界', findRichText: true), findsOneWidget);
    });

    testWidgets('渲染代码块：语言标签 + 复制按钮', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(data: '```dart\nvoid main() {}\n```'),
      );
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('复制'), findsOneWidget);
      expect(find.textContaining('void main()', findRichText: true), findsOneWidget);
    });

    testWidgets('渲染行内代码', (tester) async {
      await pumpFixed(tester, const MarkdownView(data: '执行 `flutter test`'));
      expect(find.text('flutter test'), findsOneWidget);
    });

    testWidgets('渲染 LaTeX 行内公式', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(data: r'公式 $E=mc^2$ 结束'),
      );
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('渲染 LaTeX 块级公式', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(data: r'$$\frac{a}{b}$$'),
      );
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('任务列表渲染复选框（勾选/未勾选）', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(data: '- [x] 已完成\n- [ ] 待办'),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('已完成', findRichText: true), findsOneWidget);
      expect(find.text('待办', findRichText: true), findsOneWidget);
    });

    testWidgets('宽表格启用横向滚动容器', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(
          data: '| A | B |\n|---|---|\n| 1 | 2 |',
        ),
      );
      // IntrinsicColumnWidth 下 flutter_markdown 用横向 SingleChildScrollView 包裹表格
      final scrolls = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where((s) => s.scrollDirection == Axis.horizontal)
          .toList();
      expect(scrolls, isNotEmpty);
      expect(find.text('A', findRichText: true), findsOneWidget);
    });

    testWidgets('Mermaid 流程图渲染', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(
          data: '```mermaid\ngraph TD\n  A[Start] --> B[End]\n```',
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // 图由 CustomPainter 绘制，节点文字非 Text widget；断言渲染器存在且无源码兜底
      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.textContaining('Mermaid 语法暂不支持'), findsNothing);
    });

    testWidgets('Mermaid 非法语法回退显示源码', (tester) async {
      await pumpFixed(
        tester,
        const MarkdownView(
          data: '```mermaid\nthis is not valid mermaid @@@\n```',
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Mermaid 语法暂不支持'), findsOneWidget);
      expect(find.textContaining('not valid mermaid'), findsOneWidget);
    });
  });

  group('ChatComposer', () {
    ChatComposer buildComposer({
      List<ChatProvider>? providers,
      String? providerId,
      String? modelId,
      ChatOptions options = const ChatOptions(),
      bool isLoading = false,
      int estimatedTokens = 0,
      bool sendOnEnter = false,
      TextEditingController? controller,
      VoidCallback? onSend,
      List<ChatImage> pendingImages = const [],
      void Function(ChatImage image)? onAddImageUrl,
      void Function(int index)? onRemoveImage,
    }) {
      return ChatComposer(
        controller: controller ?? TextEditingController(),
        providers: providers ??
            [
              ChatProvider(
                id: 'p1',
                name: 'OpenAI',
                modelIds: ['gpt-4o', 'o1'],
                modelConfigs: {
                  'gpt-4o': const ModelConfig(),
                  'o1': const ModelConfig(reasoning: true),
                },
              ),
            ],
        providerId: providerId ?? 'p1',
        modelId: modelId,
        options: options,
        isLoading: isLoading,
        estimatedTokens: estimatedTokens,
        usagePrompt: 100,
        usageCompletion: 200,
        onModelChanged: (providerId, modelId) {},
        onEffortChanged: (effort) {},
        onStreamChanged: (stream) {},
        onSend: onSend ?? () {},
        onStop: () {},
        sendOnEnter: sendOnEnter,
        autoSelectModel: true,
        pendingImages: pendingImages,
        onPickImages: () {},
        onAddImageUrl: onAddImageUrl ?? (_) {},
        onRemoveImage: onRemoveImage ?? (_) {},
      );
    }

    testWidgets('模型自动选中并展示，工具条正常渲染', (tester) async {
      await pumpFixed(tester, buildComposer());
      expect(find.text('gpt-4o'), findsOneWidget);
      expect(find.text('流式'), findsOneWidget);
    });

    testWidgets('无模型时显示未配置模型且发送按钮禁用', (tester) async {
      var sent = false;
      await pumpFixed(
        tester,
        buildComposer(
          providers: const [],
          onSend: () => sent = true,
        ),
      );
      expect(find.text('未配置模型'), findsOneWidget);
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.arrow_upward_rounded && w.size == 20,
      ));
      expect(sent, isFalse);
    });

    testWidgets('点击发送按钮触发 onSend', (tester) async {
      var sent = false;
      final controller = TextEditingController(text: '你好');
      await pumpFixed(
        tester,
        buildComposer(controller: controller, onSend: () => sent = true),
      );
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.arrow_upward_rounded && w.size == 20,
      ));
      expect(sent, isTrue);
    });

    testWidgets('加载中显示停止按钮并禁用输入', (tester) async {
      await pumpFixed(
        tester,
        buildComposer(isLoading: true),
      );
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_upward_rounded && w.size == 20,
        ),
        findsNothing,
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('推理模型显示思考强度，非推理模型隐藏', (tester) async {
      await pumpFixed(tester, buildComposer(modelId: 'o1'));
      expect(find.text('思考：自动'), findsOneWidget);

      await pumpFixed(tester, buildComposer(modelId: 'gpt-4o'));
      expect(find.textContaining('思考'), findsNothing);
    });

    testWidgets('流式开关点击回调', (tester) async {
      bool? streamValue;
      final composed = ChatComposer(
        controller: TextEditingController(),
        providers: [
          ChatProvider(id: 'p1', name: 'OpenAI', modelIds: ['gpt-4o']),
        ],
        providerId: 'p1',
        modelId: 'gpt-4o',
        options: const ChatOptions(stream: true),
        isLoading: false,
        estimatedTokens: 0,
        usagePrompt: 0,
        usageCompletion: 0,
        onModelChanged: (providerId, modelId) {},
        onEffortChanged: (effort) {},
        onStreamChanged: (v) => streamValue = v,
        onSend: () {},
        onStop: () {},
        sendOnEnter: false,
        pendingImages: const [],
        onPickImages: () {},
        onAddImageUrl: (_) {},
        onRemoveImage: (_) {},
      );
      await pumpFixed(tester, composed);
      await tester.tap(find.text('流式'));
      expect(streamValue, isFalse);
    });

    testWidgets('token 统计与超限提示', (tester) async {
      await pumpFixed(
        tester,
        buildComposer(
          estimatedTokens: 16000,
          options: const ChatOptions(maxContextTokens: 8000),
        ),
      );
      expect(find.textContaining('上下文 16.0k'), findsOneWidget);
      expect(find.text('超出上限，发送时将裁剪'), findsOneWidget);
    });

    testWidgets('Enter 行为提示文案随偏好变化', (tester) async {
      await pumpFixed(tester, buildComposer(sendOnEnter: false));
      expect(
        find.text('输入消息，Enter 换行，Ctrl+Enter 发送'),
        findsOneWidget,
      );

      await pumpFixed(tester, buildComposer(sendOnEnter: true));
      expect(
        find.text('输入消息，Enter 发送，Shift+Enter 换行'),
        findsOneWidget,
      );
    });

    testWidgets('待发送图片显示缩略图并可移除', (tester) async {
      final images = [
        ChatImage(url: 'data:image/png;base64,iVBORw0KGgo=', mimeType: 'image/png'),
        ChatImage(url: 'https://x/a.png', mimeType: 'image/png'),
      ];
      var removed = -1;
      await pumpFixed(
        tester,
        buildComposer(
          pendingImages: images,
          onRemoveImage: (i) => removed = i,
        ),
      );
      // 两张缩略图 + 移除按钮
      expect(find.byType(ClipRRect), findsNWidgets(2));
      expect(find.byIcon(Icons.close), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.close).first);
      expect(removed, 0);
    });

    testWidgets('粘贴图片 Data URL 触发 onAddImageUrl 并清除输入框', (tester) async {
      final controller = TextEditingController();
      final added = <ChatImage>[];
      await pumpFixed(
        tester,
        buildComposer(
          controller: controller,
          onAddImageUrl: added.add,
        ),
      );

      const dataUrl = 'data:image/png;base64,iVBORw0KGgo=';
      // 模拟剪贴板返回图片 Data URL
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': dataUrl};
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      // 聚焦输入框后模拟 Ctrl+V
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(added, hasLength(1));
      expect(added.single.url, dataUrl);
    });

    testWidgets('粘贴普通文本不触发 onAddImageUrl', (tester) async {
      final controller = TextEditingController();
      final added = <ChatImage>[];
      await pumpFixed(
        tester,
        buildComposer(
          controller: controller,
          onAddImageUrl: added.add,
        ),
      );

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': '普通文本内容'};
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      // 聚焦输入框后模拟 Ctrl+V
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(added, isEmpty);
    });
  });

  group('ChatOptionsForm', () {
    testWidgets('初始值回填表单', (tester) async {
      await pumpFixed(
        tester,
        ChatOptionsForm(
          initial: const ChatOptions(
            systemPrompt: '你是助手',
            temperature: 0.5,
            maxTokens: 2048,
            stop: ['a', 'b'],
            seed: 42,
            responseFormat: 'json_object',
            maxContextTokens: 32000,
          ),
        ),
      );
      expect(find.text('你是助手'), findsOneWidget);
      expect(find.text('0.50'), findsOneWidget);
      expect(find.text('2048'), findsOneWidget);
      expect(find.text('a,b'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('32000 tokens'), findsOneWidget);
    });

    testWidgets('编辑后 value 反映修改', (tester) async {
      final formKey = GlobalKey<ChatOptionsFormState>();
      await pumpFixed(
        tester,
        ChatOptionsForm(key: formKey, initial: const ChatOptions()),
      );
      final state = formKey.currentState!;

      await tester.enterText(find.widgetWithText(TextField, '留空由服务端决定'), '4096');
      await tester.enterText(find.widgetWithText(TextField, '多个用英文逗号分隔'), 'a, b');
      await tester.pump();

      expect(state.value.maxTokens, 4096);
      expect(state.value.stop, ['a', 'b']);
      expect(state.value.systemPrompt, '');
    });

    testWidgets('只读模式禁用编辑', (tester) async {
      final formKey = GlobalKey<ChatOptionsFormState>();
      await pumpFixed(
        tester,
        ChatOptionsForm(
          key: formKey,
          initial: const ChatOptions(systemPrompt: '固定'),
        ),
      );
      formKey.currentState!.setReadOnly(true);
      await tester.pump();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.every((f) => f.readOnly), isTrue);
    });
  });

  group('SettingsScreen 文案', () {
    testWidgets('分组与入口文案正确（含清理后的 subtitle）', (tester) async {
      SharedPreferences.setMockInitialValues({
        'send_on_enter': false,
      });
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrapApp(
        SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('服务与内容'), findsOneWidget);
      expect(find.text('模型配置'), findsOneWidget);
      expect(find.text('聊天默认模型 · 标题生成模型'), findsOneWidget);
      expect(find.text('偏好设置'), findsOneWidget);
      expect(find.text('Enter 换行，Ctrl+Enter 发送'), findsOneWidget);
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('数据'), findsOneWidget);
      expect(find.text('关于 Nona'), findsOneWidget);
    });

    testWidgets('Enter 发送偏好下偏好设置 subtitle 更新', (tester) async {
      SharedPreferences.setMockInitialValues({
        'send_on_enter': true,
      });
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrapApp(
        SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Enter 发送，Shift+Enter 换行'), findsOneWidget);
    });
  });

  group('ThemeSettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      resetGlobalState();
    });

    testWidgets('预设色板点击后更新 accentColorNotifier 并持久化', (tester) async {
      await tester.pumpWidget(wrapApp(
        ThemeSettingsScreen(initialThemeMode: 'system'),
      ));
      await tester.pumpAndSettle();

      // 点击「天蓝」预设
      await tester.tap(find.text('天蓝'));
      await tester.pumpAndSettle();

      expect(accentColorNotifier.value, const Color(0xFF0EA5E9));
      final settings = await SettingsService().load();
      expect(settings.accentColor, 0xFF0EA5E9);
    });

    testWidgets('OLED 开关更新 oledDarkNotifier 并持久化', (tester) async {
      await tester.pumpWidget(wrapApp(
        ThemeSettingsScreen(initialThemeMode: 'system'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OLED 纯黑背景'));
      await tester.pumpAndSettle();

      expect(oledDarkNotifier.value, isTrue);
      final settings = await SettingsService().load();
      expect(settings.oledDark, isTrue);
    });

    testWidgets('模式单选切换并持久化', (tester) async {
      await tester.pumpWidget(wrapApp(
        ThemeSettingsScreen(initialThemeMode: 'system'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();

      expect(themeModeNotifier.value, ThemeMode.dark);
      final settings = await SettingsService().load();
      expect(settings.themeMode, 'dark');
    });
  });

  group('SearchScreen', () {
    final sessions = [
      ChatSession(
        id: 's1',
        title: 'Flutter 开发',
        messages: [
          ChatMessage(role: 'user', content: '怎么配置服务商？'),
          ChatMessage(role: 'assistant', content: '在设置中添加即可'),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
      ChatSession(
        id: 's2',
        title: '闲聊',
        messages: [
          ChatMessage(role: 'user', content: '今天天气不错'),
        ],
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ];

    testWidgets('输入关键词出现结果并高亮命中段', (tester) async {
      await tester.pumpWidget(
        wrapApp(SearchScreen(sessions: sessions)),
      );
      await tester.pumpAndSettle();

      expect(find.text('输入关键词，搜索全部会话'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '服务商');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Flutter 开发'), findsOneWidget);
      expect(find.textContaining('服务商', findRichText: true), findsWidgets);
    });

    testWidgets('无结果时显示提示', (tester) async {
      await tester.pumpWidget(
        wrapApp(SearchScreen(sessions: sessions)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '不存在的关键词xyz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.textContaining('没有找到'), findsOneWidget);
    });

    testWidgets('点击结果返回 SearchTarget', (tester) async {
      SearchTarget? popped;
      await tester.pumpWidget(
        wrapApp(Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<SearchTarget>(
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(sessions: sessions),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '天气');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      await tester.tap(find.text('闲聊'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.sessionId, 's2');
      expect(popped!.messageIndex, 0);
    });
  });

  group('MessageList 搜索结果跳转', () {
    testWidgets('initialScrollIndex 触发定位并回调完成', (tester) async {
      final messages = List.generate(
        30,
        (i) => ChatMessage(role: i.isEven ? 'user' : 'assistant', content: '消息 $i'),
      );
      final controller = ScrollController();
      var handled = false;
      await tester.pumpWidget(
        wrapApp(
          Scaffold(
            body: MessageList(
              messages: messages,
              streamingIndex: null,
              controller: controller,
              canRegenerate: false,
              initialScrollIndex: 25,
              onScrollTargetHandled: () => handled = true,
              onCopy: (_) {},
              onEdit: (_) {},
              onRollback: (_) {},
              onRollbackVersion: (_) {},
              onRegenerate: (_) {},
              onDelete: (_) {},
              onSpeak: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(handled, isTrue);
      // 定位后滚动位置应远离底部（不是初始的 maxScrollExtent 位置）
      expect(controller.position.pixels,
          lessThan(controller.position.maxScrollExtent));
      // 目标消息已可见
      expect(find.text('消息 25'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/services/chat_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/features/automation/workflow.dart';
import 'package:nona_chat/features/automation/workflow_service.dart';
import 'package:nona_chat/shared/workflow_event_bus.dart' as wf_bus;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;
  late WorkflowService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
    service = WorkflowService(database: db);
    // 注入失败动作替身：避免真实网络调用
    service.chatServiceFactory = () => _FailingChatService();
  });

  tearDown(() async {
    service.dispose();
    await db.close();
    resetNonaDatabaseForTest();
  });

  Workflow makeWorkflow(
    String id,
    WorkflowTrigger trigger, {
    bool enabled = true,
  }) => Workflow(
    id: id,
    name: '工作流-$id',
    trigger: trigger,
    actions: const [
      WorkflowAction(type: 'send_message', text: '测试消息'),
    ],
    enabled: enabled,
  );

  group('触发器匹配（X-01）', () {
    test('ScheduleTrigger 分钟匹配', () {
      final every30 = ScheduleTrigger(cronMinute: '*/30');
      expect(every30.matches(0), isTrue);
      expect(every30.matches(30), isTrue);
      expect(every30.matches(15), isFalse);
      final specific = ScheduleTrigger(cronMinute: '5');
      expect(specific.matches(5), isTrue);
      expect(specific.matches(6), isFalse);
      final list = ScheduleTrigger(cronMinute: '0,15');
      expect(list.matches(15), isTrue);
      expect(list.matches(7), isFalse);
    });

    test('DailyTrigger 时间匹配（±1 分钟窗口）', () {
      final daily = DailyTrigger(time: '09:00');
      expect(daily.matches(DateTime(2026, 8, 13, 9, 0)), isTrue);
      expect(daily.matches(DateTime(2026, 8, 13, 9, 1)), isTrue);
      expect(daily.matches(DateTime(2026, 8, 13, 10, 0)), isFalse);
    });

    test('EventTrigger 事件与过滤', () {
      final trigger = EventTrigger(on: 'chat_completed', filter: 'session.title contains 日报');
      expect(
        trigger.matchesEvent('chat_completed', {'session.title': '日报总结'}),
        isTrue,
      );
      expect(
        trigger.matchesEvent('chat_completed', {'session.title': '闲聊'}),
        isFalse,
      );
      expect(trigger.matchesEvent('other_event', {'session.title': '日报'}), isFalse);
      final any = EventTrigger(on: 'chat_completed');
      expect(any.matchesEvent('chat_completed', {}), isTrue);
    });

    test('JSON 往返（trigger/actions 序列化）', () {
      final w = makeWorkflow(
        'w1',
        EventTrigger(on: 'chat_completed', filter: 'x contains y'),
      );
      final json = {
        'trigger': w.trigger.toJson(),
        'actions': w.actions.map((a) => a.toJson()).toList(),
      };
      final restored = WorkflowTrigger.fromJson(
        json['trigger'] as Map<String, dynamic>,
      );
      expect(restored, isA<EventTrigger>());
      expect((restored as EventTrigger).filter, 'x contains y');
    });
  });

  group('WorkflowService（X-01）', () {
    test('CRUD 往返', () async {
      await service.save(makeWorkflow('w1', const ScheduleTrigger()));
      final list = await service.list();
      expect(list, hasLength(1));
      expect(list.first.name, '工作流-w1');
      expect(list.first.trigger, isA<ScheduleTrigger>());
      await service.delete('w1');
      expect(await service.list(), isEmpty);
    });

    test('运行失败动作仍记录历史（send_message 无 Key）', () async {
      await service.save(makeWorkflow('w1', const ManualTrigger()));
      final result = await service.run((await service.list()).first);
      expect(result.status, 'failed', reason: '未配置 Key 时应失败而非崩溃');
      final history = await service.history();
      expect(history, isNotEmpty);
      expect(history.first.status, 'failed');
    });

    test('历史滚动清理（仅保留 200 条）', () async {
      await service.save(makeWorkflow('w1', const ManualTrigger()));
      final w = (await service.list()).first;
      for (var i = 0; i < 205; i++) {
        await service.run(w);
      }
      final history = await service.history(limit: 500);
      expect(history.length, lessThanOrEqualTo(WorkflowService.kMaxHistory));
    });

    test('事件总线触发 event 工作流', () async {
      service.start();
      await service.save(
        makeWorkflow(
          'evt',
          EventTrigger(on: 'chat_completed', filter: 'session.title contains 日报'),
        ),
      );
      service.chatServiceFactory = () => _FailingChatService();
      wf_bus.WorkflowEventBus.instance.emit(
        'chat_completed',
        context: {'session.title': '日报总结'},
      );
      // 事件为异步触发，等待微任务
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final history = await service.history();
      expect(history, isNotEmpty, reason: '匹配事件的工作流应被执行');
      service.dispose();
    });
  });
}

/// 失败替身：sendSimple 直接抛错（避免真实网络）。
class _FailingChatService extends ChatService {
  @override
  Future<String> sendSimple({
    required AppSettings settings,
    required String userMessage,
    String systemPrompt = '',
    int maxTokens = 100,
  }) async {
    throw StateError('未配置 Key');
  }
}

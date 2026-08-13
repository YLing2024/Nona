import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/core/database/dao/session_dao.dart';
import 'package:nona_chat/core/database/nona_app_database.dart';
import 'package:nona_chat/core/database/nona_db_factory.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/usage/usage_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NonaAppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetNonaDatabaseForTest();
    db = (await openNonaDatabase(forceMemory: true))!;
  });

  tearDown(() async {
    await db.close();
    resetNonaDatabaseForTest();
  });

  // 相对今天 -1 天（保证落在 daily 窗口与当月内）
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  String two(int n) => n.toString().padLeft(2, '0');
  final yesterdayDate =
      '${yesterday.year}-${two(yesterday.month)}-${two(yesterday.day)}';

  ChatSession makeSession(
    String id, {
    String title = '会话',
    String? modelId,
    String? providerId,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title,
      modelId: modelId,
      providerId: providerId,
      messages: messages ??
          [
            ChatMessage(
              role: 'assistant',
              content: '回复',
              promptTokens: 100,
              completionTokens: 50,
              sentAt: yesterday,
              modelId: modelId,
              providerName: providerId,
            ),
          ],
      createdAt: yesterday,
      updatedAt: yesterday,
    );
  }

  group('UsageStatsService 预聚合（usage_daily）', () {
    test('recordSessions 冗余更新可被 daily/topModels/totals 读回', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        makeSession('s1', modelId: 'gpt-4o', providerId: 'openai'),
        makeSession('s2', modelId: 'gpt-4o-mini', providerId: 'openai'),
      ]);
      final service = UsageStatsService(database: db);
      await service.recordSessions(await dao.readAll() ?? const []);

      final daily = await service.daily(days: 30);
      expect(daily, isNotEmpty);
      final day = daily.firstWhere((d) => d.date == yesterdayDate);
      expect(day.promptTokens, 200);
      expect(day.completionTokens, 100);
      expect(day.calls, 2);

      final top = await service.topModels(limit: 10);
      expect(top, hasLength(2));
      expect(top.first.modelId, 'gpt-4o');

      final totals = await service.totals();
      expect(totals.$1, 200);
      expect(totals.$2, 100);
    });

    test('recordSessions 重复写入按调用累加（调用方保证不重复）', () async {
      final dao = SessionDao(db);
      final session = makeSession('s1', modelId: 'm', providerId: 'p');
      await dao.writeAll([session]);
      final service = UsageStatsService(database: db);
      await service.recordSessions([session]);
      await service.recordSessions([session]);
      final daily = await service.daily(days: 30);
      final day = daily.firstWhere((d) => d.date == yesterdayDate);
      expect(day.calls, 2, reason: 'recordSessions 每次调用都 upsert 累加');
    });

    test('无用量消息不写入 usage_daily', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        makeSession('s1', messages: [
          ChatMessage(role: 'user', content: '无用量'),
        ]),
      ]);
      final service = UsageStatsService(database: db);
      await service.recordSessions(await dao.readAll() ?? const []);
      final daily = await service.daily(days: 30);
      expect(daily, isEmpty);
      final totals = await service.totals();
      expect(totals.$1, 0);
      expect(totals.$3, 0);
    });

    test('monthCost 统计当月成本（价格表缺失按 0）', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        makeSession('s1', modelId: 'm', providerId: 'p'),
      ]);
      final service = UsageStatsService(database: db);
      await service.recordSessions(await dao.readAll() ?? const []);
      final cost = await service.monthCost();
      expect(cost, greaterThanOrEqualTo(0));
      expect(cost, lessThanOrEqualTo(10));
    });

    test('exportRawJson 导出原始记录', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        makeSession('s1', modelId: 'm', providerId: 'p'),
      ]);
      final service = UsageStatsService(database: db);
      await service.recordSessions(await dao.readAll() ?? const []);
      final raw = await service.exportRawJson();
      expect(raw, contains(yesterdayDate));
      expect(raw, contains('"model_id":"m"'));
    });

    test('topSessions 按 token 总量排序', () async {
      final dao = SessionDao(db);
      await dao.writeAll([
        makeSession('small', modelId: 'm', providerId: 'p', messages: [
          ChatMessage(
            role: 'assistant',
            content: 'a',
            promptTokens: 10,
            completionTokens: 5,
            sentAt: yesterday,
          ),
        ]),
        makeSession('large', modelId: 'm', providerId: 'p', messages: [
          ChatMessage(
            role: 'assistant',
            content: 'b',
            promptTokens: 500,
            completionTokens: 300,
            sentAt: yesterday,
          ),
        ]),
      ]);
      final service = UsageStatsService(database: db);
      await service.recordSessions(await dao.readAll() ?? const []);
      final top = await service.topSessions(limit: 10);
      expect(top.first.sessionId, 'large');
      expect(top.first.promptTokens, 500);
    });
  });
}

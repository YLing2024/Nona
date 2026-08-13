import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/services/export/import_report.dart';
import 'package:nona_chat/core/services/export/import_service.dart';

/// 构造 Nona 格式导出 JSON（含 2 条会话，1 条带图片、1 条带工具消息）。
Map<String, dynamic> _nonaJson() => {
  'app': 'nona',
  'type': 'backup',
  'version': 1,
  'sessions': [
    {
      'id': 'imported-s1',
      'title': '导入会话一',
      'options': {},
      'createdAt': '2024-01-01T00:00:00.000',
      'updatedAt': '2024-01-02T00:00:00.000',
      'messages': [
        {
          'role': 'user',
          'content': '你好',
          'sentAt': '2024-01-01T00:00:00.000',
          'images': [
            {'url': 'data:image/png;base64,AAAA', 'mimeType': 'image/png'},
          ],
        },
        {
          'role': 'assistant',
          'content': '你好！',
          'sentAt': '2024-01-01T00:00:01.000',
        },
      ],
    },
    {
      'id': 'imported-s2',
      'title': '导入会话二',
      'options': {},
      'createdAt': '2024-01-01T00:00:00.000',
      'updatedAt': '2024-01-02T00:00:00.000',
      'messages': [
        {
          'role': 'user',
          'content': '调用工具',
        },
        {
          'role': 'assistant',
          'content': '',
          'toolCallsJson':
              '[{"id":"call_1","type":"function","function":{"name":"f","arguments":"{}"}}]',
        },
      ],
    },
  ],
};

/// 坏记录（缺 id，应计入失败）。
Map<String, dynamic> _nonaJsonWithBadRecord() {
  final data = _nonaJson();
  data['sessions'] = [
    ...(data['sessions'] as List),
    {'title': '坏记录'}, // 缺 id / createdAt
  ];
  return data;
}

/// 走真实用户路径：jsonEncode → utf8 字节 → 嗅探解码。
ImportReport? _analyze({
  Map<String, dynamic>? json,
  Set<String>? existingIds,
}) =>
    ImportService.analyze(
      utf8.encode(jsonEncode(json ?? _nonaJson())),
      fileName: 'backup.json',
      existingIds: existingIds,
    );

void main() {
  group('ImportService.analyze（X-03 报告）', () {
    test('正常文件产出完整报告（数量/质量指标）', () {
      final report = _analyze();
      expect(report, isNotNull);
      expect(report!.sourceFormat, isNotEmpty);
      expect(report.sessions, 2);
      expect(report.succeeded, 2);
      expect(report.messages, 4);
      expect(report.failures, isEmpty);
      // 4 条消息 2 条带时间戳
      expect(report.quality.timestampCompleteRate, closeTo(0.5, 1e-9));
      expect(report.quality.multimodalPreserved, isTrue);
      expect(report.quality.toolMessagesPreserved, isTrue);
    });

    test('重复检测：与现有 id 集合比对', () {
      final report = _analyze(existingIds: {'imported-s1'});
      expect(report!.duplicates, hasLength(1));
      expect(report.duplicates.first.hashSessionId, 'imported-s1');
      expect(report.duplicates.first.existingTitle, '导入会话一');
    });

    test('坏记录计入 failures', () {
      final report = _analyze(json: _nonaJsonWithBadRecord());
      expect(report, isNotNull);
      expect(report!.sessions, greaterThanOrEqualTo(2));
      expect(report.failures, isNotEmpty);
    });
  });

  group('ImportReport.selectSessions（去重三选一）', () {
    ImportReport makeReport() {
      final decoded =
          jsonDecode(utf8.decode(utf8.encode(jsonEncode(_nonaJson()))));
      return ImportService.buildReport(
        ImportService.importFromJsonData(decoded)!,
        sourceFormat: 'nona',
        existingIds: {'imported-s1'},
      );
    }

    test('skip：跳过重复', () {
      final selected = makeReport().selectSessions(DuplicateAction.skip);
      expect(selected.map((s) => s.id), ['imported-s2']);
    });

    test('overwrite：保留 id 覆盖', () {
      final selected = makeReport().selectSessions(DuplicateAction.overwrite);
      expect(selected.map((s) => s.id), ['imported-s1', 'imported-s2']);
    });

    test('copy：重复会话换新 id', () {
      final selected = makeReport().selectSessions(DuplicateAction.copy);
      expect(selected, hasLength(2));
      expect(selected.first.id, isNot('imported-s1'));
      expect(selected.first.title, '导入会话一');
    });

    test('selectedIds 勾选过滤', () {
      final selected = makeReport().selectSessions(
        DuplicateAction.overwrite,
        selectedIds: {'imported-s2'},
      );
      expect(selected.map((s) => s.id), ['imported-s2']);
    });
  });

  group('ImportService.mergeProviders（服务商合并）', () {
    ChatProvider p(String id, String base, List<String> models) => ChatProvider(
      id: id,
      name: id,
      baseUrl: base,
      apiKey: 'local-key',
      modelIds: models,
    );

    test('同名（baseUrl）合并模型，key 保留本地', () {
      final local = [p('a', 'https://api.example.com/v1', ['gpt-4o'])];
      final imported = [
        p('b', 'https://api.example.com/v1', ['gpt-4o-mini', 'gpt-4o']),
      ];
      final merged = ImportService.mergeProviders(local, imported);
      expect(merged, hasLength(1));
      expect(merged.first.id, 'a');
      expect(merged.first.apiKey, 'local-key');
      expect(merged.first.modelIds, containsAll(['gpt-4o', 'gpt-4o-mini']));
    });

    test('不同 baseUrl 追加为新服务商', () {
      final merged = ImportService.mergeProviders(
        [p('a', 'https://a.example.com/v1', ['m1'])],
        [p('b', 'https://b.example.com/v1', ['m2'])],
      );
      expect(merged, hasLength(2));
    });

    test('空导入不动本地', () {
      final local = [p('a', 'https://a.example.com/v1', ['m1'])];
      expect(ImportService.mergeProviders(local, []), same(local));
    });
  });
}

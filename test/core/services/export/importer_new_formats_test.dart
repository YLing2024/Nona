import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/services/export/importers/importer_factory.dart';
import 'package:nona_chat/core/services/export/importers/kelivo_importer.dart';
import 'package:nona_chat/core/services/export/importers/rikkahub_importer.dart';
import 'package:nona_chat/core/services/export/import_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// F6：NextChat / OpenAI / RikkaHub / Kelivo 导入器测试。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => HttpOverrides.global = null);

  group('NextChat 导入器', () {
    test('chatMap/messageMap 结构解析', () {
      final data = {
        'chatMap': {
          'c1': {
            'id': 'c1',
            'topic': '旅行计划',
            'time': 1700000000000,
            'messages': ['m1', 'm2'],
          },
        },
        'messageMap': {
          'm1': {
            'role': 'user',
            'content': '帮我规划东京旅行',
            'time': 1700000001000,
          },
          'm2': {
            'role': 'assistant',
            'content': '好的，第一天去浅草寺',
            'reasoning_content': '先考虑交通',
            'time': 1700000002000,
          },
        },
      };
      final result = ImporterFactory.importJson(data);
      expect(result.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, '旅行计划');
      expect(s.messages, hasLength(2));
      expect(s.messages.first.role, 'user');
      expect(s.messages.last.content, contains('浅草寺'));
      expect(s.messages.last.reasoningContent, '先考虑交通');
    });

    test('单条损坏不阻塞其余', () {
      final data = {
        'chatMap': {
          'c1': {'id': 'c1', 'messages': ['bad', 'm2']},
        },
        'messageMap': {
          'bad': 'not-a-map',
          'm2': {'role': 'user', 'content': 'ok'},
        },
      };
      final result = ImporterFactory.importJson(data);
      expect(result.sessions, hasLength(1));
      expect(result.sessions.first.messages, hasLength(1));
    });
  });

  group('OpenAI 官方导入器', () {
    test('mapping 嵌套结构展平为消息', () {
      final data = {
        'title': 'ChatGPT 会话',
        'create_time': 1700000000.5,
        'mapping': {
          'root': {'parent': null, 'children': ['a']},
          'a': {
            'parent': 'root',
            'children': ['b'],
            'message': {
              'author': {'role': 'user'},
              'content': {'content_type': 'text', 'parts': ['你好']},
              'create_time': 1700000001.5,
            },
          },
          'b': {
            'parent': 'a',
            'children': [],
            'message': {
              'author': {'role': 'assistant'},
              'content': {'content_type': 'text', 'parts': ['你好！有什么可以帮你？']},
              'create_time': 1700000002.5,
            },
          },
        },
      };
      final result = ImporterFactory.importJson(data);
      expect(result.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, 'ChatGPT 会话');
      expect(s.messages, hasLength(2));
      expect(s.messages.first.content, '你好');
      expect(s.messages.last.role, 'assistant');
    });

    test('嗅探识别 openai 格式', () {
      final data = {
        'title': 't',
        'mapping': {'root': {'parent': null, 'children': []}},
      };
      expect(ImporterFactory.sniffJson(data), 'openai');
    });
  });

  group('RikkaHub SQLite 导入器', () {
    test('conversation 表 nodes JSON 解析', () {
      final dir = Directory.systemTemp.createTempSync('rikka-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final dbPath = '${dir.path}/rikkahub.db';

      // 用 sqlite3 建 RikkaHub 形状的库
      final db = sqlite3.open(dbPath);
      db.execute(
        'CREATE TABLE conversation (id TEXT PRIMARY KEY, assistant_id TEXT, '
        'title TEXT, nodes TEXT, create_at INTEGER, update_at INTEGER, '
        'is_pinned INTEGER)',
      );
      db.execute(
        'INSERT INTO conversation VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'conv-1',
          'assistant-1',
          '设定讨论',
          jsonEncode([
            {
              'id': 'node-1',
              'messages': [
                {
                  'id': 'msg-1',
                  'role': 'USER',
                  'createdAt': '2026-01-01T10:00:00',
                  'parts': [
                    {'type': 'text', 'text': '你好，介绍下这个设定'},
                  ],
                },
                {
                  'id': 'msg-2',
                  'role': 'ASSISTANT',
                  'parts': [
                    {'type': 'text', 'text': '这是一个奇幻世界'},
                    {'type': 'reasoning', 'reasoning': '让我想想'},
                  ],
                },
              ],
            },
          ]),
          1700000000000,
          1700000001000,
          1,
        ],
      );
      db.dispose();

      expect(RikkaHubImporter.matchesFile(dbPath), isTrue,
          reason: 'matchesFile 应识别 RikkaHub 库');
      final result = ImporterFactory.importSqlite(dbPath, 'rikkahub');
      // ignore: avoid_print
      print('rikkahub sessions=${result.sessions.length} '
          'failures=${result.failedItems.length}');
      expect(result.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, '设定讨论');
      expect(s.pinned, isTrue);
      expect(s.messages, hasLength(2));
      expect(s.messages.last.content, contains('奇幻世界'));
      expect(s.messages.last.reasoningContent, '让我想想');
    });
  });

  group('Kelivo SQLite 导入器', () {
    test('message_rows 按顺序 + 版本分组', () {
      final dir = Directory.systemTemp.createTempSync('kelivo-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final dbPath = '${dir.path}/kelivo.db';

      final db = sqlite3.open(dbPath);
      db.execute(
        'CREATE TABLE conversation_rows (id TEXT PRIMARY KEY, title TEXT, '
        'created_at INTEGER, updated_at INTEGER, is_pinned INTEGER, '
        'summary TEXT)',
      );
      db.execute(
        'CREATE TABLE message_rows (id TEXT PRIMARY KEY, conversation_id TEXT, '
        'role TEXT, content TEXT, timestamp INTEGER, model_id TEXT, '
        'prompt_tokens INTEGER, completion_tokens INTEGER, duration_ms INTEGER, '
        'reasoning_text TEXT, group_id TEXT, version INTEGER, message_order INTEGER)',
      );
      db.execute(
        'INSERT INTO conversation_rows VALUES (?, ?, ?, ?, ?, ?)',
        ['kv-1', '深度讨论', 1700000000000000, 1700000002000000, 0, '摘要'],
      );
      db.execute(
        'INSERT INTO message_rows VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'm1', 'kv-1', 'user', '第一个问题', 1700000001000000, null,
          null, null, null, null, null, 0, 0,
        ],
      );
      // 同一 groupId 两个版本：version 大者为最新（主消息），旧版进 alternatives
      db.execute(
        'INSERT INTO message_rows VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'm2-v1', 'kv-1', 'assistant', '旧回答', 1700000002000000, 'gpt-4o',
          10, 5, 100, null, 'g1', 0, 1,
        ],
      );
      db.execute(
        'INSERT INTO message_rows VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'm2-v2', 'kv-1', 'assistant', '新回答', 1700000003000000, 'gpt-4o',
          12, 6, 120, null, 'g1', 1, 1,
        ],
      );
      db.dispose();

      expect(KelivoImporter.matchesFile(dbPath), isTrue);
      final result = ImporterFactory.importSqlite(dbPath, 'kelivo');
      // ignore: avoid_print
      print('kelivo sessions=${result.sessions.length} '
          'failures=${result.failedItems.length}');
      for (final f in result.failedItems) {
        // ignore: avoid_print
        print('kelivo failure: ${f.reason}');
      }
      expect(result.sessions, hasLength(1));
      final s = result.sessions.first;
      expect(s.title, '深度讨论');
      expect(s.summary, '摘要');
      expect(s.messages, hasLength(2));
      // 主消息是最新版本
      final assistant = s.messages.last;
      expect(assistant.content, '新回答');
      expect(assistant.alternatives, hasLength(1));
      expect(assistant.alternatives.first.content, '旧回答');
      expect(assistant.promptTokens, 12);
    });
  });

  group('ImportService 统一入口', () {
    test('NextChat JSON 字节经 importFromBytes 导入', () {
      final bytes = utf8.encode(jsonEncode({
        'chatMap': {
          'c1': {'id': 'c1', 'messages': ['m1']},
        },
        'messageMap': {
          'm1': {'role': 'user', 'content': '你好'},
        },
      }));
      final result = ImportService.importFromBytes(
        bytes,
        fileName: 'backup.json',
      );
      expect(result, isNotNull);
      expect(result!.sessions, hasLength(1));
    });

    test('无法识别返回 null', () {
      final bytes = utf8.encode(jsonEncode({'foo': 'bar'}));
      final result = ImportService.importFromBytes(
        bytes,
        fileName: 'x.json',
      );
      expect(result, isNull);
    });
  });
}

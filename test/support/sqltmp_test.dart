import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('sqlite3 只读打开临时文件', () {
    final dir = Directory.systemTemp.createTempSync('sqltest');
    addTearDown(() => dir.deleteSync(recursive: true));
    final dbPath = '${dir.path}/t.db';
    final db = sqlite3.open(dbPath);
    db.execute('CREATE TABLE conversation (id TEXT PRIMARY KEY, nodes TEXT)');
    db.execute("INSERT INTO conversation VALUES ('1', '[]')");
    db.dispose();
    // ignore: avoid_print
    print('file exists: ${File(dbPath).existsSync()}');
    try {
      final db2 = sqlite3.open(dbPath, mode: OpenMode.readOnly);
      final rows = db2.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='conversation'",
      );
      // ignore: avoid_print
      print('rows: ${rows.length}');
      final cols = db2
          .select('PRAGMA table_info(conversation)')
          .map((r) => r['name'])
          .toList();
      // ignore: avoid_print
      print('cols: $cols');
      db2.dispose();
    } catch (e) {
      // ignore: avoid_print
      print('ERR: $e');
    }
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/services/storage_io_io.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nona_storage_test');
  });

  tearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('writeTextToPath 写入并返回路径；null/空路径返回 null', () async {
    final path = '${dir.path}${Platform.pathSeparator}a.txt';
    expect(await writeTextToPath(path, '你好'), path);
    expect(await File(path).readAsString(), '你好');
    expect(await writeTextToPath(null, 'x'), isNull);
    expect(await writeTextToPath('', 'x'), isNull);
  });

  test('writeBytesToPath 字节往返', () async {
    final path = '${dir.path}${Platform.pathSeparator}a.bin';
    final bytes = Uint8List.fromList([1, 2, 3, 255]);
    expect(await writeBytesToPath(path, bytes), path);
    expect(await File(path).readAsBytes(), bytes);
    expect(await writeBytesToPath(null, bytes), isNull);
  });

  test('父目录缺失时抛出（不静默吞错）', () async {
    final path = '${dir.path}${Platform.pathSeparator}sub${Platform.pathSeparator}b.txt';
    await expectLater(writeTextToPath(path, 'x'), throwsA(isA<FileSystemException>()));
  });
}

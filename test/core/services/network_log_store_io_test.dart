import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:nona_chat/core/models/network_log.dart';
import 'package:nona_chat/core/services/network_log_store_io.dart' as store;

/// 测试用 path_provider 实现：返回临时目录。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory dir;

  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationSupportPath() async => dir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;

  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late PathProviderPlatform original;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nona_nlog_test');
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(dir);
  });

  tearDown(() async {
    PathProviderPlatform.instance = original;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  NetworkLog makeLog(String content, {NetworkLogType type = NetworkLogType.chat}) {
    return NetworkLog(
      id: content.hashCode.toString(),
      time: DateTime(2026, 8, 9, 10, 30),
      method: 'POST',
      url: 'https://x/$content',
      type: type,
      requestBody: content,
      requestBytes: content.length,
      responseBytes: 0,
      requestHeaders: const {},
      responseHeaders: const {},
      responseBody: '',
      statusCode: 200,
      durationMs: 5,
    );
  }

  test('空目录读取返回空列表', () async {
    expect(await store.readLogs(), isEmpty);
  });

  test('追加写入 → 读取完整读回', () async {
    final logs = [makeLog('a'), makeLog('b')];
    await store.writeLogs(logs);
    final loaded = await store.readLogs();
    expect(loaded, hasLength(2));
    expect(loaded.map((l) => l.requestBody), ['a', 'b']);
    expect(loaded.first.url, 'https://x/a');
    expect(loaded.first.type, NetworkLogType.chat);
    expect(loaded.first.time, DateTime(2026, 8, 9, 10, 30));
  });

  test('重复写入覆盖旧内容（最新列表为准）', () async {
    await store.writeLogs([makeLog('v1')]);
    await store.writeLogs([makeLog('v2'), makeLog('v3')]);
    final loaded = await store.readLogs();
    expect(loaded.map((l) => l.requestBody), ['v2', 'v3']);
  });

  test('损坏文件读取容错返回空列表', () async {
    final file = File('${dir.path}${Platform.pathSeparator}network_logs.json');
    await file.writeAsString('{not json');
    expect(await store.readLogs(), isEmpty);
  });

  test('空文件读取返回空列表', () async {
    final file = File('${dir.path}${Platform.pathSeparator}network_logs.json');
    await file.writeAsString('');
    expect(await store.readLogs(), isEmpty);
  });

  test('写失败不抛出（只记录日志）', () async {
    // 用只读目录制造写入失败
    final readonly = Directory('${dir.path}${Platform.pathSeparator}ro');
    await readonly.create();
    PathProviderPlatform.instance = _FakePathProvider(readonly);
    // 文件已存在且为只读 → writeAsString 失败被吞掉
    final file = File('${readonly.path}${Platform.pathSeparator}network_logs.json');
    await file.writeAsString('[]');
    await Process.run(
      Platform.isWindows ? 'attrib' : 'chmod',
      Platform.isWindows ? ['+R', file.path] : ['444', file.path],
    );
    await store.writeLogs([makeLog('x')]);
    expect(await file.readAsString(), '[]');
    if (Platform.isWindows) {
      await Process.run('attrib', ['-R', file.path]);
    }
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/services/tts_service.dart';

/// 假 TTS 引擎：记录调用，可手动触发完成回调。
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  int stopCount = 0;
  VoidCallback? _onCompletion;
  String? lastText;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    lastText = text;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  void setCompletionHandler(VoidCallback handler) {
    _onCompletion = handler;
  }

  @override
  Future<void> setConfig({
    required double speechRate,
    required String language,
  }) async {}

  @override
  void dispose() {}

  void complete() => _onCompletion?.call();
}

void main() {
  late FakeTtsEngine engine;
  late TtsController controller;

  setUp(() {
    engine = FakeTtsEngine();
    controller = TtsController(engine);
  });

  tearDown(() {
    controller.dispose();
  });

  test('toggle 开始朗读并记录消息 id', () async {
    await controller.toggle('m1', '你好');
    expect(controller.isSpeaking, isTrue);
    expect(controller.currentId, 'm1');
    expect(controller.isSpeakingFor('m1'), isTrue);
    expect(engine.spoken, ['你好']);
  });

  test('同一消息再次点击切换为停止', () async {
    await controller.toggle('m1', '你好');
    await controller.toggle('m1', '你好');
    expect(controller.isSpeaking, isFalse);
    expect(controller.currentId, isNull);
    // 每次 toggle 开始都会先 stop 一次（清空旧播放），共 2 次
    expect(engine.stopCount, 2);
  });

  test('点击另一条消息：先停旧再读新', () async {
    await controller.toggle('m1', '第一条');
    await controller.toggle('m2', '第二条');
    expect(engine.stopCount, 2);
    expect(engine.spoken, ['第一条', '第二条']);
    expect(controller.currentId, 'm2');
    expect(controller.isSpeakingFor('m1'), isFalse);
    expect(controller.isSpeakingFor('m2'), isTrue);
  });

  test('朗读完成回调后复位状态', () async {
    await controller.toggle('m1', '你好');
    engine.complete();
    expect(controller.isSpeaking, isFalse);
    expect(controller.currentId, isNull);
  });

  test('stop 主动停止并复位', () async {
    await controller.toggle('m1', '你好');
    await controller.stop();
    // toggle 开始 + 主动 stop 各一次
    expect(engine.stopCount, 2);
    expect(controller.isSpeaking, isFalse);
    expect(controller.currentId, isNull);
  });

  test('未朗读时 stop 无副作用', () async {
    await controller.stop();
    expect(engine.stopCount, 0);
  });

  test('speak 抛异常时复位状态', () async {
    final bad = _ThrowingTtsEngine();
    final c = TtsController(bad);
    await c.toggle('m1', 'x');
    expect(c.isSpeaking, isFalse);
    c.dispose();
  });

  test('dispose 后引擎完成回调不抛异常', () async {
    final engine = FakeTtsEngine();
    final c = TtsController(engine);
    await c.toggle('m1', '你好');
    c.dispose();
    // dispose 后引擎迟到的完成回调不应触发 notifyListeners 崩溃
    expect(() => engine.complete(), returnsNormally);
  });

  test('dispose 后 toggle 无副作用', () async {
    final engine = FakeTtsEngine();
    final c = TtsController(engine);
    c.dispose();
    await c.toggle('m1', '你好');
    expect(engine.spoken, isEmpty);
  });

  group('长文本分块朗读', () {
    test('短文本单块朗读', () async {
      await controller.toggle('m1', '短文本');
      expect(engine.spoken, ['短文本']);
    });

    test('超长文本按句边界切块并顺序朗读', () async {
      final long = List.filled(40, '这是一句用于测试分块的句子。').join();
      expect(long.length, greaterThan(TtsController.maxChunkChars));
      await controller.toggle('m1', long);
      // 假引擎需手动触发完成回调推进下一块
      var safety = 0;
      while (controller.isSpeaking && safety < 200) {
        engine.complete();
        safety++;
      }
      expect(controller.isSpeaking, isFalse);
      expect(engine.spoken.length, greaterThan(1));
      expect(engine.spoken.join(), long);
      for (final chunk in engine.spoken) {
        expect(chunk.length, lessThanOrEqualTo(TtsController.maxChunkChars));
      }
    });

    test('每块完成回调后朗读下一块，全部读完复位', () async {
      final long = List.filled(40, '这是一句用于测试分块的句子。').join();
      await controller.toggle('m1', long);
      expect(engine.spoken.length, 1); // 仅首块已朗读
      engine.complete();
      expect(engine.spoken.length, 2); // 完成回调推进到下一块
      expect(controller.isSpeaking, isTrue);
      var safety = 0;
      while (controller.isSpeaking && safety < 200) {
        engine.complete();
        safety++;
      }
      expect(controller.isSpeaking, isFalse);
      expect(controller.currentId, isNull);
    });

    test('朗读中 stop 不再继续下一块', () async {
      final long = List.filled(40, '这是一句用于测试分块的句子。').join();
      await controller.toggle('m1', long);
      engine.complete();
      final spokenCount = engine.spoken.length;
      expect(spokenCount, greaterThan(1));
      await controller.stop();
      engine.complete(); // 停止后的迟到回调不应推进
      expect(engine.spoken.length, spokenCount);
      expect(controller.isSpeaking, isFalse);
    });
  });

  group('chunkText', () {
    test('空文本与短文本', () {
      expect(chunkText(''), isEmpty);
      expect(chunkText('hi'), ['hi']);
    });

    test('句边界切分优先（长句）', () {
      final text = '${'第一句内容比较长用于触发切分。' * 3}'
          '${'第二句内容同样很长用于触发切分。' * 3}'
          '${'第三句内容也很长用于触发切分。' * 3}';
      final chunks = chunkText(text, maxChars: 120);
      expect(chunks.length, 3);
      expect(chunks.join(), text);
    });

    test('无边界时硬切', () {
      final text = 'a' * 500;
      final chunks = chunkText(text, maxChars: 120);
      expect(chunks.length, 5);
      expect(chunks.join(), text);
      expect(chunks.every((c) => c.length <= 120), isTrue);
    });
  });
}

class _ThrowingTtsEngine implements TtsEngine {
  @override
  Future<void> speak(String text) async {
    throw Exception('speak failed');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setConfig({
    required double speechRate,
    required String language,
  }) async {}

  @override
  void setCompletionHandler(VoidCallback handler) {}

  @override
  void dispose() {}
}

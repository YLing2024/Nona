import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 引擎抽象：便于在单元测试中替换为假实现，也作为网络 TTS 的扩展点。
abstract class TtsEngine {
  /// 朗读文本；播放结束 / 取消 / 出错时回调 [completionHandler]。
  Future<void> speak(String text);

  /// 停止朗读（会触发 completionHandler）。
  Future<void> stop();

  /// 注册播放结束回调（含取消与出错）。
  void setCompletionHandler(VoidCallback handler);

  /// 更新语音配置（语速与语言）；实现可忽略不支持的项。
  Future<void> setConfig({required double speechRate, required String language});

  void dispose();
}

/// 系统 TTS 引擎实现（flutter_tts，调用各平台系统语音合成）。
///
/// 部分 ROM（如 MIUI）会拦截第三方应用对「默认引擎」的解析与绑定，
/// 导致引擎始终无法就绪而静默无声。因此朗读前显式枚举并绑定引擎，
/// 等待引擎就绪，speak 失败时重建引擎重试（参考 Kelivo 同款方案）。
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _tts = FlutterTts();
  VoidCallback? _onCompletion;
  bool _configured = false;

  /// 当前语音配置（可经 [setConfig] 更新，下次朗读生效）。
  double _speechRate = 0.5;
  String _language = 'zh-CN';

  /// 已显式绑定的引擎 id（避免重复重建引擎连接）。
  String? _engineId;

  FlutterTtsEngine() {
    _tts.setCompletionHandler(_onTtsDone);
    _tts.setCancelHandler(_onTtsDone);
    _tts.setErrorHandler((_) => _onCompletion?.call());
  }

  void _onTtsDone() => _onCompletion?.call();

  @override
  Future<void> setConfig({
    required double speechRate,
    required String language,
  }) async {
    _speechRate = speechRate;
    _language = language;
    _configured = false; // 强制下次朗读时重新应用
  }

  @override
  void setCompletionHandler(VoidCallback handler) {
    _onCompletion = handler;
  }

  @override
  Future<void> speak(String text) async {
    await _ensureReady();
    await _ensureConfigured();
    if (await _trySpeak(text)) return;
    // 首轮失败：重建引擎连接后重试（MIUI 等 ROM 上引擎首次绑定可能失败）
    for (var attempt = 0; attempt < 3; attempt++) {
      await _selectEngine();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _ensureConfigured();
      if (await _trySpeak(text)) return;
    }
    throw Exception('TTS speak failed');
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  void dispose() {
    // 停止正在播放的音频：dispose 后声音不能继续响
    _onCompletion = null;
    try {
      _tts.stop();
    } catch (_) {
      // 平台通道不可用时忽略（如测试环境）
    }
  }

  /// 等待系统 TTS 引擎就绪（已绑定且可用）。
  ///
  /// 若默认引擎解析/绑定被 ROM 拦截，则显式枚举引擎并绑定后再等待。
  Future<void> _ensureReady() async {
    for (var i = 0; i < 20; i++) {
      if (await _engineAvailable()) return;
      await _selectEngine();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  /// 查询引擎是否已就绪：getLanguages 返回非空语言列表即为已绑定可用。
  Future<bool> _engineAvailable() async {
    try {
      final langs = await _tts.getLanguages;
      return langs is List && langs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 枚举系统 TTS 引擎并显式绑定（优先 Google 引擎，其次系统首个）。
  ///
  /// flutter_tts 的 setEngine 会重建 TextToSpeech 并直接绑定指定组件，
  /// 不依赖 ROM 的「默认引擎」解析，可绕过部分 ROM 对第三方应用的拦截。
  Future<void> _selectEngine() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is! List || engines.isEmpty) return;
      String? chosen;
      for (final e in engines) {
        final s = e.toString();
        if (s.toLowerCase().contains('google')) {
          chosen = s;
          break;
        }
      }
      chosen ??= engines.first.toString();
      if (chosen == _engineId) return;
      await _tts.setEngine(chosen);
      _engineId = chosen;
      _configured = false; // 新引擎实例需重新应用语言/语速
    } catch (_) {
      // 引擎枚举/绑定失败时忽略，继续使用默认引擎
    }
  }

  /// 朗读单个文本；返回是否成功入队播放。
  Future<bool> _trySpeak(String text) async {
    try {
      final res = await _tts.speak(text, focus: true);
      return res == 1 || res == true;
    } catch (_) {
      return false;
    }
  }

  /// 惰性初始化语言/语速等参数（仅在首次朗读时调用，且容忍失败，
  /// 避免构造阶段触发平台通道调用——如在单元测试环境中抛异常）。
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_speechRate);
    } catch (_) {
      // 某些平台/环境下 TTS 参数不可用，忽略并继续
    }
  }
}

/// TTS 播放控制器：管理「正在朗读哪条消息」与「点击切换播放/停止」。
///
/// 长文本按句分块顺序朗读（避免单次朗读过长内容导致平台 TTS 截断），
/// 用户可随时停止；停止后清空剩余分块并复位状态。
class TtsController extends ChangeNotifier {
  final TtsEngine _engine;

  /// 单块朗读的最大字符数（超长文本按句边界切分）。
  static const int maxChunkChars = 360;

  String? _currentId;
  bool _speaking = false;
  bool _disposed = false;

  /// 待朗读分块队列与当前进度。
  List<String> _chunks = const [];
  int _chunkIndex = 0;

  /// 会话令牌：停止/切换时递增，用于忽略过期回调。
  int _session = 0;

  /// 当前发声分块对应的会话令牌（完成回调时校验）。
  int? _pendingToken;

  TtsController(this._engine) {
    _engine.setCompletionHandler(_onChunkDone);
  }

  /// 当前正在朗读的消息 id；未在朗读时为 null。
  String? get currentId => _currentId;

  /// 是否正在朗读。
  bool get isSpeaking => _speaking;

  /// 指定消息是否正在被朗读。
  bool isSpeakingFor(String messageId) => _speaking && _currentId == messageId;

  /// 更新语音配置并透传给引擎。
  Future<void> updateConfig({
    required double speechRate,
    required String language,
  }) async {
    await _engine.setConfig(speechRate: speechRate, language: language);
  }

  /// 点击朗读按钮：同一消息正在朗读则停止，否则切换朗读该消息。
  Future<void> toggle(String messageId, String text) async {
    if (_disposed) return;
    if (_speaking && _currentId == messageId) {
      await stop();
      return;
    }
    try {
      await _engine.stop();
    } catch (_) {
      // stop 失败不阻断切换（某些平台无音频会话时报错）
    }
    _session++;
    _currentId = messageId;
    _speaking = true;
    _chunks = _chunkText(text);
    _chunkIndex = 0;
    notifyListeners();
    await _speakCurrent();
  }

  /// 停止朗读。
  Future<void> stop() async {
    if (!_speaking || _disposed) return;
    _session++;
    _chunks = const [];
    try {
      await _engine.stop();
    } catch (_) {
      // 忽略平台 stop 异常，保证状态复位
    }
    _finish();
  }

  /// 朗读当前分块；无更多分块时结束。
  Future<void> _speakCurrent() async {
    if (_disposed || !_speaking) return;
    if (_chunkIndex >= _chunks.length) {
      _finish();
      return;
    }
    final token = _session;
    final text = _chunks[_chunkIndex++];
    _pendingToken = token;
    try {
      await _engine.speak(text);
      // 若朗读中用户停止/切换，token 已变化，忽略后续流程
      if (token == _session) {
        // speak 正常返回（可能未走 completionHandler，如异步等待平台回调）。
        // 若平台回调未及时到达，这里不主动推进，等待 _onChunkDone。
      }
    } catch (_) {
      // speak 失败：停止朗读而不是跳到下一块疯狂重试
      if (token == _session) _finish();
    }
  }

  void _onChunkDone() {
    if (_disposed || !_speaking) return;
    // 过期回调（停止/切换前旧播放的完成回调）不推进新播放的分块，
    // 防止跳读；仅消费「当前发声分块」的完成回调。
    if (_pendingToken == null || _pendingToken != _session) return;
    _pendingToken = null;
    // 继续下一块，或全部读完结束
    if (_chunkIndex < _chunks.length) {
      unawaited(_speakCurrent());
    } else {
      _finish();
    }
  }

  void _finish() {
    if (_disposed) return;
    _currentId = null;
    _speaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _engine.dispose();
    super.dispose();
  }
}

/// 将长文本切分为适合朗读的分块。
///
/// 优先在句边界（中文句号/感叹/问号/分号、换行、英文句点/感叹/问号）切分，
/// 使每块不超过 [maxChars]；无法在句边界内切分时硬切。
List<String> chunkText(String text, {int maxChars = TtsController.maxChunkChars}) {
  if (text.isEmpty) return const [];
  if (text.length <= maxChars) return [text];

  final result = <String>[];
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    buffer.write(text[i]);
    final char = text[i];
    final isBoundary = '。！？；.!?;\n'.contains(char);
    if ((isBoundary && buffer.length >= 40) || buffer.length >= maxChars) {
      result.add(buffer.toString());
      buffer.clear();
    }
  }
  if (buffer.isNotEmpty) result.add(buffer.toString());
  return result;
}

/// 分块切分（供 TtsController 使用，独立成函数便于单元测试）。
List<String> _chunkText(String text) => chunkText(text);

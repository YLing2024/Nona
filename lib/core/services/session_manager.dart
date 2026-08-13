import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/agent.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import 'session_service.dart';
import 'settings_service.dart';
import '../utils/logger.dart';

/// 会话集合管理器：加载 / 新建 / 切换 / 删除 / 置顶 / 复制 / 匿名会话，
/// 以及悬空引用清理与默认模型填充。
///
/// 持有会话列表状态（[sessions] / [currentSessionId] / [isAnonymous] /
/// [anonymousSession]），通过注入的回调读取宿主状态与通知刷新。
class SessionManager {
  final SessionService sessionService;

  /// 会话列表。
  List<ChatSession> sessions = [];

  /// 当前会话 id。
  String? currentSessionId;

  /// 匿名会话（[isAnonymous] 为 true 时使用，不持久化）。
  ChatSession? anonymousSession;

  /// 是否处于匿名模式。
  bool isAnonymous = false;

  /// 本地化默认会话标题（宿主发送前刷新）。
  final String Function() defaultTitle;

  /// 全局设置（读取默认模型等）。
  final AppSettings Function() settings;

  /// 已加载的服务商列表（读取模型能力）。
  final List<ChatProvider> Function() providers;

  /// 发送是否进行中（加载态下禁止切换/新建）。
  final bool Function() isLoading;

  /// 通知宿主刷新界面。
  final VoidCallback? onStateChanged;

  /// 会话内容版本号变更钩子（token 估算缓存失效）。
  final VoidCallback bumpTokenVersion;

  /// 展示提示条。
  final void Function(String message)? onSnack;

  /// 防抖落盘窗口：窗口内的连续 [persist] 合并为一次批量增量写。
  static const Duration _persistDebounce = Duration(milliseconds: 500);

  Timer? _persistTimer;

  /// 是否有会话被标记为脏（未落盘的变更）。
  bool _dirtyAll = false;

  /// 等待落盘的已删除会话 id（增量写必须显式删除，否则会被重写复活）。
  final Set<String> _deleted = {};

  SessionManager({
    required this.sessionService,
    required this.defaultTitle,
    required this.settings,
    required this.providers,
    required this.isLoading,
    this.onStateChanged,
    required this.bumpTokenVersion,
    this.onSnack,
  });

  /// 当前会话（匿名优先）。
  ChatSession? get currentSession {
    if (isAnonymous) return anonymousSession;
    for (final s in sessions) {
      if (s.id == currentSessionId) return s;
    }
    return null;
  }

  /// 加载会话列表；为空时创建一个默认会话并持久化。
  Future<void> load({required String title}) async {
    var list = await sessionService.load();
    if (list.isEmpty) {
      final session = ChatSession.create(defaultTitle: title);
      list = [session];
      await sessionService.saveAll(list);
    }
    var cleaned = cleanupSessions(list, providers());
    if (settings().chatModel.isNotEmpty && list.isNotEmpty) {
      for (final s in list) {
        if (s.modelId == null) applyDefaultModel(s);
      }
    }
    if (cleaned) await sessionService.saveAll(list);
    sessions = list;
    currentSessionId = list.first.id;
  }

  /// 联动清理：服务商或模型被删除后，清除会话中指向它们的引用。
  ///
  /// 返回是否有会话被修改，便于调用方决定是否持久化。
  bool cleanupSessions(
    List<ChatSession> sessions,
    List<ChatProvider> providers,
  ) {
    var changed = false;
    for (final s in sessions) {
      final pid = s.providerId;
      final provider = providers.where((p) => p.id == pid).firstOrNull;
      if (pid != null && provider == null) {
        // 服务商已被删除
        s.providerId = null;
        s.modelId = null;
        changed = true;
        continue;
      }
      if (provider != null &&
          s.modelId != null &&
          !provider.modelIds.contains(s.modelId)) {
        // 模型已被删除
        s.modelId = null;
        changed = true;
      }
    }
    return changed;
  }

  /// 为会话填充全局默认模型（找到包含默认模型的第一个服务商）。
  void applyDefaultModel(
    ChatSession session, [
    AppSettings? settings,
    List<ChatProvider>? providers,
  ]) {
    final s = settings ?? this.settings();
    final ps = providers ?? this.providers();
    if (s.chatModel.isEmpty) return;
    for (final p in ps) {
      if (p.modelIds.contains(s.chatModel)) {
        session.providerId = p.id;
        session.modelId = s.chatModel;
        return;
      }
    }
  }

  /// 标记全部会话为脏并启动防抖落盘（匿名模式跳过）。
  ///
  /// 高频调用（发送前快照 / 流式结束 / 模型切换）合并为一次
  /// 批量增量写：500ms 窗口内连续触发只落一次盘。
  /// 需要立即落盘请调用 [flushNow]（切会话 / 应用挂起 / 退出前）。
  Future<void> persist() {
    if (isAnonymous) return Future.value();
    _dirtyAll = true;
    _scheduleFlush();
    return Future.value();
  }

  void _scheduleFlush() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () {
      _persistTimer = null;
      unawaited(_flush());
    });
  }

  /// 取消防抖并立即批量落盘（切会话 / 退出前 / 应用挂起时调用）。
  Future<void> flushNow() {
    _persistTimer?.cancel();
    _persistTimer = null;
    return _flush();
  }

  /// 批量增量落盘：已删除的会话显式删除，脏会话逐个增量写。
  Future<void> _flush() async {
    if (isAnonymous) {
      _dirtyAll = false;
      _deleted.clear();
      return;
    }
    final deleted = List.of(_deleted);
    _deleted.clear();
    final dirtyAll = _dirtyAll;
    _dirtyAll = false;
    for (final id in deleted) {
      await sessionService.deleteById(id);
    }
    if (!dirtyAll) return;
    for (final s in sessions) {
      await sessionService.saveSession(s);
    }
  }

  /// 释放防抖定时器（宿主 dispose 时调用）。
  void dispose() {
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  /// 新建会话（可携带 Agent 配置）并切换过去。
  Future<void> newSession({Agent? agent}) async {
    if (isLoading()) return;
    final session = ChatSession.create(defaultTitle: defaultTitle());
    applyDefaultModel(session);
    if (agent != null) {
      session.options = agent.options;
      session.agentId = agent.id;
    }
    sessions.insert(0, session);
    currentSessionId = session.id;
    isAnonymous = false;
    bumpTokenVersion();
    await persist();
    onStateChanged?.call();
  }

  /// 切换当前会话（切换前强制落盘当前会话变更）。
  void switchSession(String id) {
    if (id == currentSessionId) return;
    unawaited(flushNow());
    currentSessionId = id;
    bumpTokenVersion();
    onStateChanged?.call();
  }

  /// 删除会话；删除最后一个时自动创建新的空会话。
  Future<void> deleteSession(ChatSession session) async {
    _deleted.add(session.id);
    sessions.removeWhere((s) => s.id == session.id);
    if (currentSessionId == session.id) {
      currentSessionId = sessions.firstOrNull?.id;
    }
    if (sessions.isEmpty) {
      final s = ChatSession.create(defaultTitle: defaultTitle());
      applyDefaultModel(s);
      sessions.add(s);
      currentSessionId = s.id;
    }
    bumpTokenVersion();
    await persist();
    onStateChanged?.call();
  }

  /// 切换置顶状态。
  Future<void> pinSession(ChatSession session) {
    session.pinned = !session.pinned;
    onStateChanged?.call();
    try {
      return persist();
    } catch (e) {
      Logger.error('session', 'pin state save failed', e);
      onSnack?.call('Save failed, please retry');
      return Future.value();
    }
  }

  /// 复制会话（新 id，标题带副本后缀）。
  Future<void> duplicateSession(
    ChatSession session, {
    String? copySuffix,
    String? snackText,
  }) async {
    final copy = session.duplicate(copySuffix: copySuffix ?? ' (copy)');
    sessions.insert(0, copy);
    bumpTokenVersion();
    await persist();
    if (snackText != null) onSnack?.call(snackText);
    onStateChanged?.call();
  }

  /// 切换匿名模式；首次进入时创建匿名会话。
  void toggleAnonymous({String? anonymousTitle}) {
    if (isLoading()) return;
    isAnonymous = !isAnonymous;
    if (isAnonymous && anonymousSession == null) {
      anonymousSession = ChatSession.create()
        ..title = anonymousTitle ?? defaultTitle();
      applyDefaultModel(anonymousSession!);
    }
    bumpTokenVersion();
    onStateChanged?.call();
  }
}

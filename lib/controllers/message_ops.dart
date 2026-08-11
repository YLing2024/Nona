import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// 消息操作：编辑 / 回滚 / 重新生成 / 版本回退 / 删除。
///
/// 持有重新生成的旧回复（[regenerateOriginal]，流式完成后写入新消息的
/// 版本历史）；其余会话状态通过注入的回调读取宿主。
class MessageOps {
  /// 当前会话（匿名优先）。
  final ChatSession? Function() currentSession;

  /// 发送是否进行中。
  final bool Function() isLoading;

  /// 流式中的占位消息（删除进行中消息时需先停止）。
  final ChatMessage? Function() streamingMessage;

  /// 停止当前生成（删除进行中消息时调用）。
  final Future<void> Function() stop;

  /// 以空文本重新发送（重新生成场景复用发送管线）。
  final Future<void> Function(String text) sendText;

  /// 回填输入框（回滚/删除用户消息后）。
  final void Function(String text)? onRestoreInput;

  /// 持久化当前会话列表。
  final Future<void> Function() persist;

  /// 会话内容版本号变更钩子（token 估算缓存失效）。
  final VoidCallback bumpTokenVersion;

  /// 通知宿主刷新界面。
  final VoidCallback? onStateChanged;

  /// 重新生成时被截断的旧回复（生成完成后存入新消息的版本历史）。
  ChatMessage? regenerateOriginal;

  MessageOps({
    required this.currentSession,
    required this.isLoading,
    required this.streamingMessage,
    required this.stop,
    required this.sendText,
    this.onRestoreInput,
    required this.persist,
    required this.bumpTokenVersion,
    this.onStateChanged,
  });

  /// 就地修改消息内容（编辑页保存后调用）。
  void editMessage(
    ChatMessage message,
    ChatSession session, {
    required String content,
    String? reasoning,
  }) {
    message.content = content;
    if (message.role == 'assistant') {
      message.reasoningContent = reasoning ?? '';
      // 手动编辑后视为完整消息，清除中断/失败标记
      message.interrupted = false;
      message.failed = false;
    }
    session.updatedAt = DateTime.now();
    bumpTokenVersion();
    persist();
    onStateChanged?.call();
  }

  /// 回滚到用户消息：删除该条及其后所有消息，回填输入框。
  Future<void> rollbackToMessage(ChatMessage message) async {
    final session = currentSession();
    if (session == null || isLoading()) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    final text = message.content;
    session.messages.removeRange(idx, session.messages.length);
    session.updatedAt = DateTime.now();
    bumpTokenVersion();
    await persist();
    onRestoreInput?.call(text);
    onStateChanged?.call();
  }

  /// 重新生成：保存旧回复用于版本回退，截断后重新发送。
  void regenerateMessage(ChatMessage message) {
    final session = currentSession();
    if (session == null || isLoading()) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    // 保存旧回复用于版本回退
    regenerateOriginal = message;
    session.truncateMessagesFrom(idx);
    bumpTokenVersion();
    sendText('');
  }

  /// 回退到上一版回复：与最新历史版本交换内容。
  void rollbackVersion(ChatMessage message) {
    if (message.alternatives.isEmpty) return;
    final last = message.alternatives.removeLast();
    final current = ChatMessage(
      role: message.role,
      content: message.content,
      images: message.images,
      documents: message.documents,
      reasoningContent: message.reasoningContent,
      interrupted: message.interrupted,
      failed: message.failed,
      promptTokens: message.promptTokens,
      completionTokens: message.completionTokens,
      elapsedMs: message.elapsedMs,
      providerName: message.providerName,
      modelId: message.modelId,
      toolCallId: message.toolCallId,
      toolCallsJson: message.toolCallsJson,
    );
    message.alternatives.add(current);
    message.content = last.content;
    message.reasoningContent = last.reasoningContent;
    message.interrupted = last.interrupted;
    message.failed = last.failed;
    message.promptTokens = last.promptTokens;
    message.completionTokens = last.completionTokens;
    message.elapsedMs = last.elapsedMs;
    message.providerName = last.providerName;
    message.modelId = last.modelId;
    bumpTokenVersion();
    persist();
    onStateChanged?.call();
  }

  /// 删除消息（含其后所有）；进行中的流式消息先停止再删除。
  Future<void> deleteMessage(ChatMessage message) async {
    final session = currentSession();
    if (session == null) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    if (isLoading() && identical(message, streamingMessage())) {
      await stop();
    }
    session.truncateMessagesFrom(idx);
    bumpTokenVersion();
    await persist();
    onStateChanged?.call();
  }
}

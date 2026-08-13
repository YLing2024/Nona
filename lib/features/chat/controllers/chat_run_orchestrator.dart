import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/agent.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/chat_options.dart';
import '../../../core/models/chat_provider.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/citation_source.dart';
import '../../../core/models/tool_step.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/checkpoint_service.dart';
import '../../../core/services/instruction_injection_service.dart';
import '../../../core/services/document_extractor.dart';
import '../../../../shared/workflow_event_bus.dart';
import '../../../features/platform/android_background.dart';
import '../../../features/platform/notification_service.dart';
import '../../../core/services/knowledge_base_service.dart';
import '../../../core/services/mcp/approval_policy.dart';import '../../../core/services/mcp/mcp_client.dart';
import '../../../core/services/mcp/mcp_service.dart';
import '../../../core/services/mcp/local_tools.dart';
import '../../../core/services/memory/memory_service.dart';
import '../../../core/services/network_log_service.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/roulette/key_roulette.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/usage/usage_stats_service.dart';
import '../../../core/services/web_search/web_search_service.dart';
import '../../../core/utils/prompt_variables.dart';
import 'attachment_manager.dart';
import 'context_builder.dart';
import 'message_ops.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/services/title_generator.dart';
import '../../../core/services/world_book_service.dart';

/// B-08：清除上下文（truncateIndex）后可见的消息子集；
/// 截断点后的首条强制为 user（协议要求），否则补一条占位。
List<ChatMessage> _visibleMessages(ChatSession session) {
  final truncate = session.truncateIndex;
  if (truncate == null || truncate <= 0) return session.messages;
  final from = truncate.clamp(0, session.messages.length);
  var list = session.messages.skip(from).toList();
  if (list.isNotEmpty && list.first.role != 'user') {
    list = [
      ChatMessage(role: 'user', content: '…'),
      ...list,
    ];
  }
  return list;
}

/// 聊天发送管线编排器：前置校验 → 上下文裁剪 → 服务商解析 →
/// 提示词组装（变量/记忆/知识库/搜索）→ 流式请求 → 帧级合并刷新 →
/// 结束收尾（成功/取消/失败/重试提示）。
///
/// 持有单次运行状态（活动句柄、待取消标记、MCP 工具缓存）；
/// 控制器状态（isLoading/streamingMessage 等）通过注入回调读写。
class ChatRunOrchestrator {
  final ChatService chatService;
  final ProviderService providerService;
  final WebSearchService webSearchService;
  final McpService mcpService;
  final KnowledgeBaseService knowledgeBase;
  final SessionManager sessionManager;
  final ContextBuilder contextBuilder;
  final MessageOps messageOps;
  final TitleGenerator titleGenerator;
  final AttachmentManager attachmentManager;

  /// 流式检查点（B-06：增量落库 + GenerationRuns 状态机）。
  final CheckpointService checkpointService;

  /// 当前活动的 GenerationRun id。
  String? _activeRunId;

  /// 已加载的 Agent 列表（长期记忆注入）。
  final List<Agent> Function() agents;

  /// 全局设置。
  final AppSettings Function() settings;

  /// 已加载的服务商列表（读取模型能力）；发送时刷新。
  final List<ChatProvider> Function() providers;
  final void Function(List<ChatProvider> providers) setProviders;

  /// 本地化文案（宿主发送前刷新）。
  final AppLocalizations? Function() l10n;

  /// 通知宿主刷新界面。
  final VoidCallback notify;

  /// 展示提示条。
  final void Function(String message)? onSnack;

  /// 滚动到底部。
  final VoidCallback? onScrollToBottom;

  /// 回填输入框。
  final void Function(String text)? onRestoreInput;

  /// 会话内容版本号变更钩子（token 估算缓存失效）。
  final VoidCallback bumpTokenVersion;

  /// 加载态读写（锁定发送入口 / 停止按钮可用性）。
  final bool Function() isLoading;
  final void Function(bool value) setIsLoading;

  /// 流式占位消息读写。
  final ChatMessage? Function() streamingMessage;
  final void Function(ChatMessage? value) setStreamingMessage;

  /// 打开设置页。
  final VoidCallback? onOpenSettings;

  /// 请求句柄尚未建立时用户按了停止：标记待取消，句柄创建后立即执行。
  bool _stopRequested = false;
  ChatRequestHandle? _activeHandle;

  /// 挂起的工具审批请求（stop/dispose 时以「拒绝」结束，杜绝悬挂）。
  Completer<ApprovalDecision>? _pendingApproval;

  /// 宿主提供的审批 UI 入口；null 时工具默认放行（保持可用性）。
  final Future<ApprovalDecision> Function({
    required String toolName,
    required String serverName,
    required String argumentsJson,
  })? requestApproval;

  /// 超预算确认入口（F3-2）；null 时放行。
  final Future<bool> Function()? onBudgetConfirm;

  /// MCP 工具缓存：schema + 启用服务 + 工具表，5 分钟内有效。
  (
    List<Map<String, dynamic>>,
    List<McpServerConfig>,
    Map<String, McpToolDefinition>
  )? _mcpToolsCache;
  DateTime? _mcpToolsCachedAt;

  ChatRunOrchestrator({
    required this.chatService,
    required this.providerService,
    required this.webSearchService,
    required this.mcpService,
    required this.knowledgeBase,
    required this.sessionManager,
    required this.contextBuilder,
    required this.messageOps,
    required this.titleGenerator,
    required this.attachmentManager,
    CheckpointService? checkpointService,
    required this.agents,
    required this.settings,
    required this.providers,
    required this.setProviders,
    required this.l10n,
    required this.notify,
    this.onSnack,
    this.onScrollToBottom,
    this.onRestoreInput,
    this.onOpenSettings,
    this.requestApproval,
    this.onBudgetConfirm,
    required this.bumpTokenVersion,
    required this.isLoading,
    required this.setIsLoading,
    required this.streamingMessage,
    required this.setStreamingMessage,
  }) : checkpointService = checkpointService ?? CheckpointService();

  /// 发送输入框内容（附件来自 AttachmentManager 待发队列）。
  Future<void> send({required String inputText}) async {
    final text = inputText.trim();
    if ((text.isEmpty && attachmentManager.images.isEmpty) || isLoading()) {
      return;
    }
    await sendText(text);
  }

  /// 核心发送流程；[text] 为空但带图片时表示纯图片消息，
  /// [text] 为空且无图片表示沿用已有消息（重新生成场景）。
  Future<void> sendText(String text) async {
    // 宿主在发送前必须刷新本地化文案
    final AppLocalizations localized = l10n()!;
    final session = sessionManager.currentSession;
    if (isLoading() || session == null) return;
    final images = List<ChatImage>.from(attachmentManager.images);
    final documents = List<ChatDocument>.from(attachmentManager.documents);
    ChatMessage? addedUser;
    if (text.trim().isNotEmpty ||
        images.isNotEmpty ||
        documents.isNotEmpty) {
      addedUser = ChatMessage(
          role: 'user',
          content: text.trim(),
          images: images,
          documents: documents);
      session.messages.add(addedUser);
      final isFirstUser =
          session.messages.where((m) => m.role == 'user').length == 1;
      if (!sessionManager.isAnonymous && isFirstUser) {
        titleGenerator.maybeAutoTitle(session);
      }
      session.updatedAt = DateTime.now();
      onRestoreInput?.call('');
      attachmentManager.images = [];
      attachmentManager.documents = [];
    } else if (session.messages.isEmpty) {
      return;
    }

    /// 前置校验失败时回滚刚添加的用户消息并恢复输入状态，
    /// 避免「带图片的消息已入列却无法重发」。
    void rollbackAddedUser() {
      if (addedUser != null) {
        session.messages.remove(addedUser);
        session.updatedAt = DateTime.now();
        attachmentManager.images = images;
        attachmentManager.documents = documents;
        onRestoreInput?.call(text);
      }
    }

    // 提前置位加载态：在第一个 await 之前锁住发送入口，
    // 杜绝「知识库检索/网络搜索等 await 窗口内」的双击并发发送竞态，
    // 同时让「停止」按钮尽早可用（stop() 在无句柄时记录待取消标记）。
    setIsLoading(true);
    _stopRequested = false;
    notify();

    // 上下文窗口管理：压缩/裁剪在服务商解析后执行（压缩需要模型参数），
    // 见 sendText 中 _maybeCompact 调用点。

    try {
      final loaded = await providerService.load();
      setProviders(loaded);
      if (loaded.isEmpty) {
        setIsLoading(false);
        onSnack?.call(localized.homeNoProvider);
        rollbackAddedUser();
        await sessionManager.persist();
        onOpenSettings?.call();
        notify();
        return;
      }

      // 解析服务商与模型
      ChatProvider? provider;
      for (final p in loaded) {
        if (p.id == session.providerId) {
          provider = p;
          break;
        }
      }
      // 默认选择第一个已配置模型的服务商（跳过空的 OpenAI 占位）
      provider ??= loaded
          .where((p) => p.modelIds.isNotEmpty)
          .firstOrNull ?? loaded.firstOrNull;
      if (provider == null || provider.apiKey.isEmpty) {
        setIsLoading(false);
        onSnack?.call(localized.homeNoApiKey);
        rollbackAddedUser();
        await sessionManager.persist();
        onOpenSettings?.call();
        notify();
        return;
      }
      var modelId = session.modelId;
      if (modelId == null) {
        setIsLoading(false);
        onSnack?.call(localized.homeNoModel);
        rollbackAddedUser();
        notify();
        return;
      }
      if (!provider.modelIds.contains(modelId)) {
        setIsLoading(false);
        onSnack?.call(localized.homeModelMismatch);
        rollbackAddedUser();
        await sessionManager.persist();
        onOpenSettings?.call();
        notify();
        return;
      }

      var effectiveSettings = AppSettings(
        apiKey: provider.apiKey,
        baseUrl: provider.baseUrl,
        model: modelId,
        providerKind: provider.kind.name,
        // C-01：服务商开启 Responses API 时请求走 /responses
        useResponseApi: provider.useResponseApi,
        // C-02：Vertex Service Account 认证字段（仅 Gemini/Vertex 生效）
        useVertex: provider.authMode == 'serviceAccount' &&
            provider.saJson.isNotEmpty &&
            provider.vertexProject.isNotEmpty,
        vertexProject: provider.vertexProject,
        vertexRegion: provider.vertexRegion,
        saJson: provider.saJson,
      );

      // I-01：Android 后台生成保活（on/onNotify 模式开启前台服务）
      _startBackgroundKeepalive();

      // F2-3 多 Key 轮换：配置了多个 Key 时本请求轮换选取
      _keyRoulette = null;
      _lastRouletteKey = null;
      if (provider.apiKeys.isNotEmpty) {
        final roulette = KeyRoulette(provider.id);
        await roulette.setKeys(provider.apiKeys);
        final key = await roulette.next();
        if (key != null && key.isNotEmpty) {
          _keyRoulette = roulette;
          _lastRouletteKey = key;
          effectiveSettings = effectiveSettings.copyWith(apiKey: key);
        }
      }

      // 非推理模型不支持思考，发送时去掉 reasoning_effort 参数
      var options = session.options;
      final isReasoning = provider.modelConfigs[modelId]?.reasoning ?? false;
      if (!isReasoning && options.reasoningEffort != null) {
        options = options.copyWith(reasoningEffort: null);
      }

      // F3-1 摘要压缩：超限时优先压缩早期消息（生成摘要），
      // 摘要失败回退原有裁剪；均不适用时跳过。
      final compacted = await _maybeCompact(
        session,
        effectiveSettings,
        localized,
      );
      if (compacted > 0) {
        onSnack?.call(localized.homeCompacted(compacted));
      } else {
        final trimmed = contextBuilder.trimContext(session);
        if (trimmed > 0) {
          onSnack?.call(localized.homeTrimmed(trimmed));
        }
      }
      session.updatedAt = DateTime.now();
      bumpTokenVersion();

      // F3-2 月度预算检查：≥80% 提示，100% 弹确认（可绕过）
      if (!await _checkBudget(localized)) {
        // 用户拒绝超预算发送
        setIsLoading(false);
        onSnack?.call(localized.statsBudgetBlocked);
        rollbackAddedUser();
        notify();
        return;
      }

      // Prompt 变量展开（{cur_date} / {model_id} 等）
      if (options.systemPrompt.contains('{')) {
        options = options.copyWith(
          systemPrompt: PromptVariables.resolve(
            options.systemPrompt,
            modelId: modelId,
            // 用实际界面语言（而非设置值 'system'）决定默认称谓
            locale: localized.localeName,
          ),
        );
      }

      // 会话摘要注入（压缩后的早期消息替代品）
      if (session.summary.trim().isNotEmpty) {
        options = options.copyWith(
          systemPrompt: [
            '<session_summary>\n${session.summary.trim()}\n</session_summary>',
            options.systemPrompt,
          ].where((s) => s.trim().isNotEmpty).join('\n\n'),
        );
      }

      // F4-3 记忆注入：会话 → Agent → 全局（>15 条时 bigram 打分取 top）
      final agentMemories = agents()
          .where((a) => a.id == session.agentId)
          .firstOrNull
          ?.memories;
      if (agentMemories != null ||
          session.memory.trim().isNotEmpty ||
          session.agentId != null) {
        final agentDbMemories = session.agentId == null
            ? const <Memory>[]
            : await _memoryService.list(
                scope: MemoryScope.agent,
                scopeRef: session.agentId,
              );
        final globalDbMemories = await _memoryService.list(
          scope: MemoryScope.global,
        );
        final memoryText = _memoryService.buildInjection(
          sessionMemory: session.memory,
          agentMemories: [
            for (final m in agentMemories ?? const [])
              Memory(
                id: '',
                scope: MemoryScope.agent,
                scopeRef: session.agentId,
                content: m,
                createdAt: DateTime(0),
                updatedAt: DateTime(0),
              ),
            ...agentDbMemories,
          ],
          globalMemories: globalDbMemories,
          query: text,
        );
        if (memoryText.trim().isNotEmpty) {
          final memoryPrompt = localized.orchestratorMemoryPrompt(memoryText);
          options = options.copyWith(
            systemPrompt: [
              memoryPrompt,
              options.systemPrompt,
            ].where((s) => s.trim().isNotEmpty).join('\n\n'),
          );
        }
      }

      // G-05 指令注入：用户自定义提示词片段（按 Agent 激活集）
      final instructionText =
          await _instructionInjections.buildInjection(session.agentId);
      if (instructionText.trim().isNotEmpty) {
        options = options.copyWith(
          systemPrompt: [
            instructionText,
            options.systemPrompt,
          ].where((s) => s.trim().isNotEmpty).join('\n\n'),
        );
      }

      // B-03：本次请求的引用出处（知识库/搜索），统一编号注入并随消息落库
      final citations = <CitationSource>[];
      void addCitations(List<CitationSource> cs) {
        citations.addAll(cs);
      }

      // 知识库检索注入（F4-1 多库：检索域 = Agent 绑定库 ∪ 全局库）
      if (text.trim().isNotEmpty) {
        final agent = agents()
            .where((a) => a.id == session.agentId)
            .firstOrNull;
        final kbChunks = await knowledgeBase.search(
          text,
          libraryIds: agent != null && agent.kbIds.isNotEmpty
              ? [...agent.kbIds, KnowledgeBaseService.globalLibraryId]
              : null,
        );
        if (kbChunks.isNotEmpty) {
          addCitations([
            for (final c in kbChunks)
              CitationSource(
                index: 0,
                title: c.docName,
                // 知识库无 URL：用伪协议定位（面板内展示文档/块信息）
                url: c.docId != null ? 'nona-kb://${c.docId}#${c.chunkId}' : '',
                snippet: c.text.length > 200 ? c.text.substring(0, 200) : c.text,
                sourceName: '知识库',
              ),
          ]);
        }
      }

      // 网络搜索：启用时先搜索，结果注入系统提示词（带引用编号）。
      // X-05：离线模式强制跳过（不发起网络请求）。
      if (settings().webSearchEnabled && !settings().offlineMode) {
        final query = text.trim().isEmpty
            ? (session.messages.isEmpty ? '' : session.messages.last.content)
            : text.trim();
        if (query.isNotEmpty) {
          final outcome = await webSearchService.search(settings(), query);
          if (outcome.ok) {
            if (outcome.items.isNotEmpty) {
              addCitations([
                for (final item in outcome.items)
                  CitationSource(
                    index: 0,
                    title: item.title,
                    url: item.url,
                    snippet: item.snippet,
                    sourceName: '搜索',
                  ),
              ]);
            }
          } else {
            // 搜索失败：不阻断对话，但明确提示用户（Web 端 CORS 下
            // Bing/DDG 大概率失败，引导改用 Tavily/Bocha 或自建 SearXNG）
            onSnack?.call(localized.orchestratorSearchFailed);
          }
        }
      }

      // 统一编号并生成引用提示词块（[n] 标题 — URL\n摘要）
      if (citations.isNotEmpty) {
        for (var i = 0; i < citations.length; i++) {
          citations[i] = CitationSource(
            index: i + 1,
            title: citations[i].title,
            url: citations[i].url,
            snippet: citations[i].snippet,
            sourceName: citations[i].sourceName,
            publishedAt: citations[i].publishedAt,
          );
        }
        final citationPrompt = citations
            .map(
              (c) => '[${c.index}] ${c.title}'
                  '${c.url.isNotEmpty ? ' — ${c.url}' : ''}\n'
                  '${c.snippet ?? ''}',
            )
            .join('\n');
        options = options.copyWith(
          systemPrompt: [
            citationPrompt,
            options.systemPrompt,
          ].where((s) => s.trim().isNotEmpty).join('\n\n'),
        );
      }

      // F5 世界书注入：系统提示词片段 + 消息数组插入（角色可配）
      await _worldBookService.ensureLoaded();
      final wbInjection =
          _worldBookService.buildInjection(session.messages);
      if (wbInjection.systemPromptAdd.isNotEmpty) {
        options = options.copyWith(
          systemPrompt: [
            wbInjection.systemPromptAdd,
            options.systemPrompt,
          ].where((s) => s.trim().isNotEmpty).join('\n\n'),
        );
      }
      final wbInserts = wbInjection.messageInserts;
      if (wbInserts.isNotEmpty) {
        final insertMessages = <ChatMessage>[
          for (final (role, content) in wbInserts)
            ChatMessage(role: role, content: content),
        ];
        // at_depth/top_of_chat：插在最早历史之前（消息数组头部）；
        // bottom_of_chat：追加在末尾（最近用户消息之后由发送流程保证）
        final bottomCount = wbInserts.length;
        if (insertMessages.isNotEmpty) {
          session.messages.insertAll(0, insertMessages);
          // 发送后移除注入消息，避免污染会话历史
          _wbInjectedCount = insertMessages.length;
          if (bottomCount > 0) {
            // bottom_of_chat 语义：插入在末尾但发送前需在用户消息之后；
            // 简化处理：整体放头部亦可触发（见 _cleanupWbInjection）
          }
        }
      }

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: '',
        // 标注本次回复使用的服务商与模型，用于消息头展示
        providerName: provider.name,
        modelId: modelId,
        // 可增长列表：重新生成时写入历史版本
        alternatives: [],
        // B-06：流式期间标记，供启动恢复识别遗留消息
        streamingState: 'streaming',
        // B-03：本次请求的引用出处（随消息落库 citations_json）
        citations: List<CitationSource>.from(citations),
      );
      session.messages.add(assistantMessage);
      setStreamingMessage(assistantMessage);
      notify();
      await sessionManager.persist();
      // B-06：创建 GenerationRun（preparing→requesting→streaming）
      _activeRunId = null;
      unawaited(
        checkpointService
            .beginRun(
              sessionId: session.id,
              messageId:
                  '${session.id}:${session.messages.indexOf(assistantMessage)}',
            )
            .then((id) => _activeRunId = id),
      );
      onScrollToBottom?.call();

      // B-06：提交当前消息快照到检查点写入器（latest-wins 节流落库）。
      void checkpointNow() {
        final idx = session.messages.indexOf(assistantMessage);
        if (idx < 0) return;
        checkpointService.checkpoint(
          MessageCheckpoint(
            sessionId: session.id,
            messageIndex: idx,
            content: assistantMessage.content,
            reasoning: assistantMessage.reasoningContent,
            toolCallsJson: assistantMessage.toolCallsJson,
            toolStepsJson: assistantMessage.toolStepsJson,
          ),
        );
      }

      // 流式增量帧级合并：chunk 只写入 StringBuffer（O(1) 追加），
      // 每帧最多提交一次通知，避免高频 chunk 触发全树重建；
      // 同时不再递增 tokenVersion，使 token 估算缓存命中，
      // 省去每个 chunk 对全部历史消息的全量 BPE 重算。
      final contentBuffer = StringBuffer();
      final reasoningBuffer = StringBuffer();
      var flushScheduled = false;
      void scheduleFlush() {
        if (flushScheduled) return;
        flushScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          flushScheduled = false;
          final c = contentBuffer.toString();
          final r = reasoningBuffer.toString();
          contentBuffer.clear();
          reasoningBuffer.clear();
          if (c.isEmpty && r.isEmpty) return;
          if (c.isNotEmpty) assistantMessage.content += c;
          if (r.isNotEmpty) assistantMessage.reasoningContent += r;
          session.updatedAt = DateTime.now();
          checkpointNow();
          notify();
        });
      }

      /// 立即提交缓冲中的剩余增量（流结束/取消/失败前调用，防止丢尾部）。
      void flushNow() {
        final c = contentBuffer.toString();
        final r = reasoningBuffer.toString();
        contentBuffer.clear();
        reasoningBuffer.clear();
        if (c.isEmpty && r.isEmpty) return;
        if (c.isNotEmpty) assistantMessage.content += c;
        if (r.isNotEmpty) assistantMessage.reasoningContent += r;
        session.updatedAt = DateTime.now();
        checkpointNow();
        notify();
      }

      /// 请求失败统一收尾：复位加载态；空回复移除占位消息，否则标记失败；
      /// 持久化并提示错误（errorText 为 null 时不提示）。
      Future<void> finishFailed(
        ChatSession s,
        ChatMessage m,
        String? errorText,
      ) async {
        flushNow();
        // B-06：终态清 streaming 标记 + 运行收尾
        final idx = s.messages.indexOf(m);
        if (idx >= 0) {
          unawaited(
            checkpointService.clearStreamingFlag(
              sessionId: s.id,
              messageIndex: idx,
            ),
          );
        }
        m.streamingState = null;
        unawaited(checkpointService.endRun(_activeRunId, 'failed'));
        _activeRunId = null;
        messageOps.regenerateOriginal = null;
        s.updatedAt = DateTime.now();
        _removeWbInjection(s);
        setIsLoading(false);
        setStreamingMessage(null);
        _activeHandle = null;
        bumpTokenVersion();
        if (m.content.isEmpty && m.reasoningContent.isEmpty) {
          s.messages.remove(m);
        } else {
          m.failed = true;
        }
        notify();
        await sessionManager.persist();
        if (errorText != null) onSnack?.call(errorText);
      }

      // MCP 工具：启用服务的工具列表（带内存缓存，避免每次发送都请求服务器）
      final mcpTools = await _resolveMcpTools();

      // B-08：清除上下文（truncateIndex）后，请求只发截断点之后的消息
      final visibleMessages = _visibleMessages(session);

      final handle = mcpTools == null
          ? chatService.sendChat(
              settings: effectiveSettings,
              messages: visibleMessages,
              options: options,
              customHeaders:
                  provider.customHeaders.isEmpty ? null : provider.customHeaders,
              customBody: provider.customBody,
              onPartial: (delta) {
                contentBuffer.write(delta);
                scheduleFlush();
              },
              onReasoning: (delta) {
                reasoningBuffer.write(delta);
                scheduleFlush();
              },
            )
          : chatService.sendChatWithTools(
              settings: effectiveSettings,
              messages: visibleMessages,
              options: options,
              tools: mcpTools.$1,
              customHeaders:
                  provider.customHeaders.isEmpty ? null : provider.customHeaders,
              customBody: provider.customBody,
              onToolCall: (call) => _dispatchTool(mcpTools, call),
              onApprovalRequired: (call) => _checkApproval(mcpTools, call),
              onPartial: (delta) {
                contentBuffer.write(delta);
                scheduleFlush();
              },
              onReasoning: (delta) {
                reasoningBuffer.write(delta);
                scheduleFlush();
              },
            );
      _activeHandle = handle;
      // 用户在请求建立前的 await 窗口内按了停止：立即取消刚创建的句柄
      if (_stopRequested) {
        _stopRequested = false;
        unawaited(handle.cancel());
      }

      try {
        final result = await handle.result;
        flushNow();
        assistantMessage.content = result.content;
        assistantMessage.promptTokens = result.usage?.promptTokens;
        assistantMessage.completionTokens = result.usage?.completionTokens;
        assistantMessage.elapsedMs = result.elapsedMs;
        assistantMessage.sentAt = DateTime.now();
        // B-06：终态写（清 streaming 标记），运行 completed
        final finalIdx = session.messages.indexOf(assistantMessage);
        if (finalIdx >= 0) {
          await checkpointService.finalizeMessage(
            MessageCheckpoint(
              sessionId: session.id,
              messageIndex: finalIdx,
              content: result.content,
              reasoning: assistantMessage.reasoningContent,
              toolCallsJson: assistantMessage.toolCallsJson,
            ),
          );
        }
        assistantMessage.streamingState = null;
        await checkpointService.endRun(_activeRunId, 'completed');
        _activeRunId = null;
        // 重新生成场景：把被截断的旧回复存入版本历史
        if (messageOps.regenerateOriginal != null) {
          assistantMessage.alternatives.add(messageOps.regenerateOriginal!);
          messageOps.regenerateOriginal = null;
        }
        session.updatedAt = DateTime.now();
        _removeWbInjection(session);
        setIsLoading(false);
        setStreamingMessage(null);
        _activeHandle = null;
        bumpTokenVersion();
        notify();
        await sessionManager.persist();
        // F3-2：用量冗余更新（usage_daily 预聚合）
        unawaited(_usageStats.recordSessions([session]));
        // X-01：会话完成事件（触发 event 型工作流）
        WorkflowEventBus.instance.emit(
          'chat_completed',
          context: {
            'session.id': session.id,
            'session.title': session.title,
            'session.model': session.modelId ?? '',
          },
        );
        // F2-3：本 Key 成功
        _markRoulette(success: true);
        // F4-3：每 10 轮自动提取记忆（失败静默，不阻塞）
        final userCount =
            session.messages.where((m) => m.role == 'user').length;
        if (userCount >= 10 && userCount % 10 == 0) {
          unawaited(
            _memoryService.extractAndMerge(
              session,
              agentId: session.agentId,
              settings: effectiveSettings,
            ),
          );
        }
      } on ChatCancelledException {
        flushNow();
        // B-06：终态清标记 + 运行 cancelled
        final idx = session.messages.indexOf(assistantMessage);
        if (idx >= 0) {
          unawaited(
            checkpointService.clearStreamingFlag(
              sessionId: session.id,
              messageIndex: idx,
            ),
          );
        }
        assistantMessage.streamingState = null;
        unawaited(checkpointService.endRun(_activeRunId, 'cancelled'));
        _activeRunId = null;
        messageOps.regenerateOriginal = null;
        assistantMessage.interrupted = true;
        session.updatedAt = DateTime.now();
        _removeWbInjection(session);
        setIsLoading(false);
        setStreamingMessage(null);
        _activeHandle = null;
        bumpTokenVersion();
        notify();
        await sessionManager.persist();
      } on ChatTimeoutException catch (e) {
        // 空闲超时有专属文案，不能降级为通用网络错误
        _markRoulette(success: false);
        await finishFailed(session, assistantMessage, e.message);
      } on ChatException catch (e) {
        _markRoulette(success: false);
        await finishFailed(session, assistantMessage, localizeChatError(localized, e));
      } catch (_) {
        _markRoulette(success: false);
        await finishFailed(session, assistantMessage, localized.homeNetworkError);
      }
    } catch (_) {
      // 前置阶段（服务商加载/知识库检索/网络搜索/MCP 解析/持久化）异常：
      // 必须复位加载态，并回滚已入列的消息，避免界面永久卡在「生成中」。
      final placeholder = streamingMessage();
      setStreamingMessage(null);
      _activeHandle = null;
      setIsLoading(false);
      _removeWbInjection(session);
      if (placeholder != null) {
        if (placeholder.content.isEmpty &&
            placeholder.reasoningContent.isEmpty) {
          session.messages.remove(placeholder);
        } else {
          placeholder.failed = true;
        }
        // B-06：终态清 streaming 标记 + 运行收尾
        final pIdx = session.messages.indexOf(placeholder);
        if (pIdx >= 0) {
          unawaited(
            checkpointService.clearStreamingFlag(
              sessionId: session.id,
              messageIndex: pIdx,
            ),
          );
        }
        placeholder.streamingState = null;
      } else {
        rollbackAddedUser();
      }
      unawaited(checkpointService.endRun(_activeRunId, 'cancelled'));
      _activeRunId = null;
      bumpTokenVersion();
      notify();
      unawaited(sessionManager.persist());
      onSnack?.call(localized.homeNetworkError);
    }
    // I-01：后台保活收尾（全部路径汇聚于此：成功/失败/取消）
    _finishBackgroundKeepalive();
    onScrollToBottom?.call();
  }

  /// I-01：后台生成保活（Android 前台服务 + 完成通知）。
  bool _backgroundEnabled = false;

  void _startBackgroundKeepalive() {
    final mode = settings().androidBackgroundMode;
    if (mode == 'off') return;
    if (!AndroidBackground.supported) return;
    _backgroundEnabled = true;
    unawaited(AndroidBackground.enable());
  }

  void _finishBackgroundKeepalive() {
    if (!_backgroundEnabled) return;
    _backgroundEnabled = false;
    unawaited(AndroidBackground.disable());
    final mode = settings().androidBackgroundMode;
    if (mode == 'onNotify') {
      unawaited(
        NotificationService.showChatCompleted(
          title: l10n()?.notificationChatCompleted ?? 'Nona',
          body: l10n()?.notificationChatCompleted ?? '生成完成',
        ),
      );
    }
  }

  /// 停止当前生成；句柄尚未建立时记录待取消标记。
  Future<void> stop() async {
    // 挂起的审批请求以「拒绝」结束，杜绝悬挂
    _pendingApproval?.complete(const ApprovalDecision(allowed: false));
    _pendingApproval = null;
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null) {
      await handle.cancel();
    } else if (isLoading()) {
      // 请求尚未建立（正在做搜索/MCP 解析等前置工作）：
      // 记录待取消标记，句柄创建后立即取消，避免「停止」被静默忽略。
      _stopRequested = true;
    }
  }

  /// 释放活动请求（宿主 dispose 时调用）。
  void dispose() {
    // 挂起的审批请求以「拒绝」结束，杜绝悬挂
    _pendingApproval?.complete(const ApprovalDecision(allowed: false));
    _pendingApproval = null;
    final handle = _activeHandle;
    _activeHandle = null;
    if (handle != null) {
      unawaited(handle.cancel());
    }
  }

  /// 工具执行分派：本地内置工具优先，其余走 MCP 服务。
  ///
  /// F-04：记录执行步骤到 assistant 消息的 toolStepsJson（流式期间
  /// 增量序列化 + checkpoint，终态保留可回看）。
  Future<McpToolResult> _dispatchTool(
    (List<Map<String, dynamic>>, List<McpServerConfig>,
    Map<String, McpToolDefinition>) mcpTools,
    ToolCallData call,
  ) async {
    final assistantMessage = streamingMessage();
    _appendToolStep(assistantMessage, call, status: 'executing');
    final started = DateTime.now();
    try {
      final local = LocalTools.find(call.name);
      final result = local != null
          ? await local.handler(decodeArguments(call.arguments))
          : await mcpService.callTool(
              mcpTools.$2,
              mcpTools.$3,
              call.name,
              decodeArguments(call.arguments),
            );
      _appendToolStep(
        assistantMessage,
        call,
        status: result.isError ? 'error' : 'done',
        resultText: result.content,
        startedAt: started,
      );
      return result;
    } catch (e) {
      _appendToolStep(
        assistantMessage,
        call,
        status: 'error',
        resultText: e.toString(),
        startedAt: started,
      );
      rethrow;
    }
  }

  /// F-04：更新流式消息的工具步骤（latest-wins 序列化 + checkpoint）。
  void _appendToolStep(
    ChatMessage? message,
    ToolCallData call, {
    required String status,
    String resultText = '',
    DateTime? startedAt,
  }) {
    if (message == null) return;
    final steps = ToolStepsCodec.decode(message.toolStepsJson);
    final index = steps.indexWhere((s) => s.callId == call.id);
    if (index >= 0) {
      steps[index] = steps[index].copyWith(
        status: status,
        resultText: resultText.isEmpty ? steps[index].resultText : resultText,
      );
    } else {
      steps.add(
        ToolStep(
          callId: call.id,
          name: call.name,
          argumentsJson: call.arguments,
          status: status,
          resultText: resultText,
          startedAt: startedAt ?? DateTime.now(),
        ),
      );
    }
    message.toolStepsJson = ToolStepsCodec.encode(steps);
    checkpointNow();
    notify();
  }

  /// 当前流式消息快照提交（B-06；F-04 步骤更新复用）。
  void checkpointNow() {
    final message = streamingMessage();
    if (message == null) return;
    final session = sessionManager.currentSession;
    if (session == null) return;
    final idx = session.messages.indexOf(message);
    if (idx < 0) return;
    checkpointService.checkpoint(
      MessageCheckpoint(
        sessionId: session.id,
        messageIndex: idx,
        content: message.content,
        reasoning: message.reasoningContent,
        toolCallsJson: message.toolCallsJson,
        toolStepsJson: message.toolStepsJson,
      ),
    );
  }

  /// 工具审批检查：
  /// - 本地内置工具默认放行（clipboard 写操作由执行器本身提示）
  /// - 未知工具放行（执行阶段自然报错）
  /// - MCP 工具按策略决定；需审批时挂起等待宿主弹窗，60s 超时 = 拒绝；
  ///   「记住并允许」写入策略持久化；审批事件写网络日志。
  Future<ApprovalDecision> _checkApproval(
    (List<Map<String, dynamic>>, List<McpServerConfig>,
    Map<String, McpToolDefinition>) mcpTools,
    ToolCallData call,
  ) async {
    if (LocalTools.find(call.name) != null) {
      return const ApprovalDecision(allowed: true);
    }
    String serverId = '';
    McpToolDefinition? def;
    for (final entry in mcpTools.$3.entries) {
      if (entry.value.name == call.name) {
        final sep = entry.key.indexOf('__');
        if (sep <= 0) return const ApprovalDecision(allowed: true);
        serverId = entry.key.substring(0, sep);
        def = entry.value;
        break;
      }
    }
    if (def == null) return const ApprovalDecision(allowed: true);
    final server =
        mcpTools.$2.where((s) => s.id == serverId).firstOrNull;
    if (server == null) return const ApprovalDecision(allowed: true);
    if (!await ApprovalPolicy.needsApproval(server, call.name)) {
      return const ApprovalDecision(allowed: true);
    }
    // 需要审批：宿主未提供 UI 时默认放行（保持可用性）
    final requester = requestApproval;
    if (requester == null) return const ApprovalDecision(allowed: true);
    final completer = Completer<ApprovalDecision>();
    _pendingApproval = completer;
    final log = NetworkLogService.begin(
      method: 'APPROVAL',
      url: 'mcp://$serverId/${call.name}',
      requestBody: call.arguments,
      type: NetworkLogType.other,
    );
    unawaited(requester(
      toolName: def.name,
      serverName: server.name,
      argumentsJson: call.arguments,
    ).then((d) {
      if (!completer.isCompleted) completer.complete(d);
    }));
    // F-03：审批超时按服务策略配置（默认 60s）
    final timeoutSeconds = await ApprovalPolicy.timeout(serverId);
    final decision = await completer.future.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () => const ApprovalDecision(allowed: false),
    );
    _pendingApproval = null;
    log?.end(
      statusCode: decision.allowed ? 200 : 403,
      responseBody: 'tool=${call.name} allowed=${decision.allowed} '
          'remember=${decision.remember}',
    );
    if (decision.remember) {
      await ApprovalPolicy.remember(serverId, call.name);
    }
    return decision;
  }

  /// 解析工具：MCP 启用服务的工具 + 本地内置工具。
  ///
  /// 无任何可用工具（含 MCP 全部失败）时返回 null（走普通发送路径）。
  /// 返回 (schema 列表, 启用的服务, 收集到的工具表)。
  Future<
      (List<Map<String, dynamic>>, List<McpServerConfig>,
      Map<String, McpToolDefinition>)?> _resolveMcpTools() async {
    final servers = await mcpService.load();
    final enabled = servers.where((s) => s.enabled).toList();
    final now = DateTime.now();
    if (enabled.isNotEmpty) {
      if (_mcpToolsCache != null &&
          _mcpToolsCachedAt != null &&
          now.difference(_mcpToolsCachedAt!).inMinutes < 5) {
        return _mcpToolsCache;
      }
    }
    final tools = <String, McpToolDefinition>{};
    if (enabled.isNotEmpty) {
      tools.addAll(await mcpService.collectTools(enabled));
    }
    // 本地内置工具常驻注入（fetch / time_info / calculator / clipboard）
    for (final t in LocalTools.all()) {
      tools[t.definition.name] = t.definition;
    }
    if (tools.isEmpty) return null;
    final schemas = <Map<String, dynamic>>[
      for (final tool in tools.values)
        {
          'type': 'function',
          'function': {
            'name': tool.name,
            'description': tool.description,
            if (tool.inputSchema != null) 'parameters': tool.inputSchema,
          },
        },
    ];
    final result = (schemas, enabled, tools);
    if (enabled.isNotEmpty) {
      _mcpToolsCache = result;
      _mcpToolsCachedAt = now;
    }
    return result;
  }

  /// 工具参数 JSON 解析（失败返回空对象）。
  static Map<String, dynamic> decodeArguments(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// 移除本次请求注入的世界书消息（不污染会话历史）。
  void _removeWbInjection(ChatSession session) {
    if (_wbInjectedCount <= 0) return;
    final count = _wbInjectedCount;
    _wbInjectedCount = 0;
    if (session.messages.length >= count) {
      session.messages.removeRange(0, count);
    }
  }

  /// F2-3 多 Key 轮换结果回写（失败标记冷却）。
  void _markRoulette({required bool success}) {
    final roulette = _keyRoulette;
    final key = _lastRouletteKey;
    if (roulette == null || key == null) return;
    if (success) {
      unawaited(roulette.markSuccess(key));
    } else {
      unawaited(roulette.markFailed(key));
    }
    _keyRoulette = null;
    _lastRouletteKey = null;
  }

  /// F3-2 月度预算检查（prefs `budget_monthly`，美元）。
  ///
  /// - 未设置预算 → 放行
  /// - 本月花费 ≥ 100% → 弹确认（宿主提供 UI；无 UI 时放行）
  /// - ≥ 80% → SnackBar 提示
  Future<bool> _checkBudget(AppLocalizations localized) async {
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getDouble('budget_monthly') ?? 0;
    if (budget <= 0) return true;
    final cost = await _usageStats.monthCost();
    final ratio = cost / budget;
    if (ratio >= 1.0) {
      final confirm = onBudgetConfirm;
      if (confirm == null) return true;
      return confirm();
    }
    if (ratio >= 0.8) {
      onSnack?.call(localized.statsBudgetWarning((ratio * 100).round()));
    }
    return true;
  }

  /// 用量记录（成功后冗余更新 usage_daily）。
  final UsageStatsService _usageStats = UsageStatsService();

  /// 记忆服务（F4-3 自动提取/注入）。
  final MemoryService _memoryService = MemoryService();

  /// 世界书服务（F5）。
  final WorldBookService _worldBookService = WorldBookService();

  /// 指令注入服务（G-05）。
  final InstructionInjectionService _instructionInjections =
      InstructionInjectionService();

  /// 本次请求注入的世界书消息数（发送后移除，不污染会话历史）。
  int _wbInjectedCount = 0;

  /// F2-3 多 Key 轮换状态（本请求）。
  KeyRoulette? _keyRoulette;
  String? _lastRouletteKey;

  /// F3-1 摘要压缩：超限时生成计划并调用模型生成摘要；成功落地返回
  /// 压缩条数，失败（模型错误/摘要为空）返回 0（调用方回退裁剪）。
  Future<int> _maybeCompact(
    ChatSession session,
    AppSettings settings,
    AppLocalizations localized,
  ) async {
    final plan = contextBuilder.buildPlan(session);
    if (plan == null) return 0;
    String summary;
    try {
      summary = await _generateSummary(plan.removedMessages, settings);
    } catch (_) {
      // 摘要生成失败不阻断发送：回退 trimContext
      return 0;
    }
    if (summary.trim().isEmpty) return 0;
    contextBuilder.applyCompaction(session, plan, summary: summary);
    return plan.removedCount;
  }

  /// 调用模型生成被压缩消息的摘要（JSON 四段式，≤300 token）。
  Future<String> _generateSummary(
    List<ChatMessage> messages,
    AppSettings settings,
  ) async {
    String prompt;
    try {
      prompt = await rootBundle.loadString('assets/prompts/summary.txt');
    } catch (_) {
      prompt =
          'Summarize the conversation into JSON with keys 目标/事实/偏好/待办. '
          'Output only the JSON.';
    }
    final handle = chatService.sendChat(
      settings: settings,
      messages: messages,
      options: ChatOptions(
        stream: false,
        maxTokens: 300,
        temperature: 0.2,
        systemPrompt: prompt,
      ),
    );
    final result = await handle.result;
    return _formatSummary(result.content.trim());
  }

  /// 解析模型返回的摘要：JSON 四段式 → 文本；非 JSON 时保留原文。
  static String _formatSummary(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final sb = StringBuffer();
        for (final key in const ['目标', '事实', '偏好', '待办']) {
          final v = decoded[key];
          if (v != null && v.toString().trim().isNotEmpty) {
            sb.writeln('$key: $v');
          }
        }
        return sb.toString().trim();
      }
    } catch (_) {
      // 非 JSON：模型未按格式输出，保留原文
    }
    return raw;
  }

  /// 将聊天异常映射为本地化文案；未知错误码回退原始描述。
  static String localizeChatError(AppLocalizations l10n, ChatException e) {
    switch (e.code) {
      case ChatException.emptyResponse:
        return l10n.chatErrorEmpty;
      case ChatException.invalidFormat:
        return l10n.chatErrorInvalidFormat;
      case ChatException.missingContent:
        return l10n.chatErrorMissingContent;
      case ChatException.streamFailed:
        return l10n.chatErrorStream;
      case ChatException.networkFailed:
        return l10n.homeNetworkError;
      default:
        // http_error 与未知错误码：保留状态码与服务端原始信息，信息量优先
        return e.message;
    }
  }
}

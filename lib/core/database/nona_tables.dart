import 'package:drift/drift.dart';

/// 会话表（对应旧版手写 DDL 的 sessions，含 v2 摘要列 / v4 记忆列，
/// v6 新增 tags_json / truncate_index）。
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get optionsJson => text().named('options_json')();
  TextColumn get providerId => text().named('provider_id').nullable()();
  TextColumn get modelId => text().named('model_id').nullable()();
  TextColumn get agentId => text().named('agent_id').nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  TextColumn get summary => text().withDefault(const Constant(''))();
  IntColumn get summaryTokens => integer().named('summary_tokens').nullable()();
  TextColumn get memory => text().withDefault(const Constant(''))();

  /// v6：标签（JSON 数组字符串）；null 视为无标签。
  TextColumn get tagsJson => text().named('tags_json').nullable()();

  /// v6：上下文清除标记（截断到该消息索引；null = 未清除）。
  IntColumn get truncateIndex => integer().named('truncate_index').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 消息表（对应 messages；v6 新增 parts_json / citations_json /
/// tool_steps_json / streaming_state）。
@DataClassName('MessageRow')
@TableIndex(name: 'idx_messages_session', columns: {#sessionId, #messageIndex})
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()
      .named('session_id')
      .references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get messageIndex => integer().named('message_index')();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get reasoningContent =>
      text().named('reasoning_content').withDefault(const Constant(''))();
  TextColumn get imagesJson =>
      text().named('images_json').withDefault(const Constant('[]'))();
  TextColumn get documentsJson =>
      text().named('documents_json').withDefault(const Constant('[]'))();
  TextColumn get alternativesJson =>
      text().named('alternatives_json').withDefault(const Constant('[]'))();
  TextColumn get toolCallId => text().named('tool_call_id').nullable()();
  TextColumn get toolCallsJson => text().named('tool_calls_json').nullable()();
  BoolColumn get interrupted => boolean().withDefault(const Constant(false))();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();
  IntColumn get promptTokens => integer().named('prompt_tokens').nullable()();
  IntColumn get completionTokens =>
      integer().named('completion_tokens').nullable()();
  IntColumn get elapsedMs => integer().named('elapsed_ms').nullable()();
  TextColumn get providerName => text().named('provider_name').nullable()();
  TextColumn get modelId => text().named('model_id').nullable()();
  IntColumn get sentAt => integer().named('sent_at').nullable()();

  /// v6：消息分段权威数据（text/reasoning/tool_call/tool_result），
  /// null = 旧消息，读 content 兼容。
  TextColumn get partsJson => text().named('parts_json').nullable()();

  /// v6：引用出处（B-03，JSON 数组）。
  TextColumn get citationsJson => text().named('citations_json').nullable()();

  /// v6：工具执行步骤（F-04，JSON 数组）。
  TextColumn get toolStepsJson => text().named('tool_steps_json').nullable()();

  /// v6：流式生成状态（B-06：streaming / 终态置空）。
  TextColumn get streamingState => text().named('streaming_state').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 消息 bigram 倒排索引（全文搜索；对应 message_tokens）。
@DataClassName('MessageTokenRow')
class MessageTokens extends Table {
  TextColumn get token => text()();
  TextColumn get sessionId => text().named('session_id')();
  TextColumn get messageId => text().named('message_id')();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {token, messageId, position};
}

/// 摘要压缩记录（对应 compressed_blocks）。
@DataClassName('CompressedBlockRow')
class CompressedBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()
      .named('session_id')
      .references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get startIndex => integer().named('start_index')();
  IntColumn get endIndex => integer().named('end_index')();
  TextColumn get summary => text()();
  TextColumn get messagesJson =>
      text().named('messages_json').withDefault(const Constant('[]'))();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 每日用量预聚合（对应 usage_daily）。
@DataClassName('UsageDailyRow')
class UsageDaily extends Table {
  TextColumn get modelId => text().named('model_id')();
  TextColumn get providerName => text().named('provider_name')();
  TextColumn get date => text()();
  IntColumn get promptTokens =>
      integer().named('prompt_tokens').withDefault(const Constant(0))();
  IntColumn get completionTokens =>
      integer().named('completion_tokens').withDefault(const Constant(0))();
  IntColumn get calls => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {modelId, providerName, date};
}

/// 图片生成历史（对应 gen_media）。
@DataClassName('GenMediaRow')
class GenMedia extends Table {
  TextColumn get id => text()();
  TextColumn get prompt => text()();
  TextColumn get modelId => text().named('model_id')();
  TextColumn get path => text()();
  TextColumn get type => text().withDefault(const Constant('image'))();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识库（对应 kb_libraries）。
@DataClassName('KbLibraryRow')
class KbLibraries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识库文档（对应 kb_documents）。
@DataClassName('KbDocumentRow')
@TableIndex(name: 'idx_kb_docs_lib', columns: {#libraryId})
class KbDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get source => text().withDefault(const Constant('text'))();
  TextColumn get libraryId =>
      text().named('library_id').withDefault(const Constant('default'))();
  TextColumn get embeddingModel => text().named('embedding_model').nullable()();
  IntColumn get chunkCount =>
      integer().named('chunk_count').withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识库分块（对应 kb_chunks）。
@DataClassName('KbChunkRow')
@TableIndex(name: 'idx_kb_chunks_doc', columns: {#docId, #position})
class KbChunks extends Table {
  TextColumn get id => text()();
  TextColumn get docId => text()
      .named('doc_id')
      .references(KbDocuments, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get chunkText => text().named('text')();
  IntColumn get tokens => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识库 bigram 索引（对应 kb_bigrams）。
@DataClassName('KbBigramRow')
@TableIndex(name: 'idx_kb_bigrams_key', columns: {#bigram})
class KbBigrams extends Table {
  TextColumn get bigram => text()();
  TextColumn get chunkId => text()
      .named('chunk_id')
      .references(KbChunks, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {bigram, chunkId};
}

/// 知识库向量（对应 kb_vectors）。
@DataClassName('KbVectorRow')
class KbVectors extends Table {
  TextColumn get chunkId => text()
      .named('chunk_id')
      .references(KbChunks, #id, onDelete: KeyAction.cascade)();
  IntColumn get dim => integer()();
  BlobColumn get vec => blob()();

  @override
  Set<Column> get primaryKey => {chunkId};
}

/// 记忆（对应 memories；scope 枚举 global/agent/session）。
@DataClassName('MemoryRow')
@TableIndex(name: 'idx_memories_scope', columns: {#scope, #scopeRef})
class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text()();
  TextColumn get scopeRef => text().named('scope_ref').nullable()();
  TextColumn get content => text()();
  TextColumn get category => text().withDefault(const Constant('fact'))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  TextColumn get sourceMessageId => text().named('source_message_id').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  // ---- v8：记忆系统 v2 扩展 ----
  /// 标签列表（JSON 数组）。
  TextColumn get tagsJson => text().named('tags_json').withDefault(const Constant('[]'))();

  /// 优先级（auto/low/medium/high）。
  TextColumn get priority => text().withDefault(const Constant('auto'))();

  /// 被注入次数（打分权重之一）。
  IntColumn get useCount => integer().named('use_count').withDefault(const Constant(0))();

  /// 最近一次被注入时间（ms 时间戳）。
  IntColumn get lastUsedAt => integer().named('last_used_at').nullable()();

  /// 版本历史（JSON 数组，编辑留痕）。
  TextColumn get historyJson => text().named('history_json').withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// v8：记忆空间预算（scope+scopeRef 唯一）。
@DataClassName('MemorySpaceRow')
class MemorySpaces extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text()();
  TextColumn get scopeRef => text().named('scope_ref').withDefault(const Constant(''))();
  IntColumn get maxItems => integer().named('max_items').withDefault(const Constant(200))();
  IntColumn get maxInjectTokens =>
      integer().named('max_inject_tokens').withDefault(const Constant(800))();
  IntColumn get maxItemChars =>
      integer().named('max_item_chars').withDefault(const Constant(100))();
  IntColumn get extractionInterval =>
      integer().named('extraction_interval').withDefault(const Constant(10))();

  @override
  Set<Column> get primaryKey => {id};
}

/// v8：自动提取游标（session_id + last_index，防重复提取）。
@DataClassName('MemoryStateRow')
class MemoryState extends Table {
  TextColumn get sessionId => text().named('session_id')();
  IntColumn get lastIndex => integer().named('last_index').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

/// 世界书条目（对应 world_book_entries；v6 新增 use_regex / book_id）。
@DataClassName('WorldBookEntryRow')
class WorldBookEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get keywordsJson =>
      text().named('keywords_json').withDefault(const Constant('[]'))();
  TextColumn get content => text()();
  IntColumn get priority => integer().withDefault(const Constant(100))();
  IntColumn get scanDepth => integer().named('scan_depth').withDefault(const Constant(1))();
  BoolColumn get caseSensitive =>
      boolean().named('case_sensitive').withDefault(const Constant(false))();
  TextColumn get injectionPosition => text()
      .named('injection_position')
      .withDefault(const Constant('top_of_chat'))();
  TextColumn get role => text().withDefault(const Constant('user'))();
  BoolColumn get constantActive =>
      boolean().named('constant_active').withDefault(const Constant(false))();
  TextColumn get scope => text().withDefault(const Constant('global'))();
  TextColumn get scopeRef => text().named('scope_ref').nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// v6：正则匹配开关（D-06）。
  BoolColumn get useRegex =>
      boolean().named('use_regex').withDefault(const Constant(false))();

  /// v6：所属书 id（D-06；null = 默认书）。
  TextColumn get bookId => text().named('book_id').nullable()();

  /// D-06：深度注入——第 N 轮用户消息后才注入（at_depth 位置配合）。
  IntColumn get injectDepth => integer().named('inject_depth').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 世界书（v6 新增，D-06 多书管理）。
@DataClassName('WorldBookRow')
class WorldBooks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 服务商分组（v7 新增，C-03）。
@DataClassName('ProviderGroupRow')
class ProviderGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 搜索 Key 池（v7 新增，D-02 多 Key 轮换）。
@DataClassName('SearchKeyRow')
class SearchKeys extends Table {
  TextColumn get id => text()();
  TextColumn get engineId => text().named('engine_id')();
  TextColumn get key => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get failCount => integer().named('fail_count').withDefault(const Constant(0))();
  IntColumn get lastUsedAt => integer().named('last_used_at').nullable()();
  IntColumn get failedAt => integer().named('failed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 快捷短语（v7 新增，G-04）。
@DataClassName('QuickPhraseRow')
class QuickPhrases extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get isGlobal =>
      boolean().named('is_global').withDefault(const Constant(true))();
  TextColumn get agentId => text().named('agent_id').nullable()();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 指令注入（v7 新增，G-05）。
@DataClassName('InstructionInjectionRow')
class InstructionInjections extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get prompt => text()();
  TextColumn get groupName => text().named('group_name').nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签（v7 新增，G-06）。
@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 生成运行状态机（v7 新增，B-06）。
/// state: preparing/requesting/streaming/completed/failed/cancelled/interrupted
@DataClassName('GenerationRunRow')
class GenerationRuns extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id').nullable()();
  TextColumn get messageId => text().named('message_id').nullable()();
  TextColumn get state => text().withDefault(const Constant('preparing'))();
  IntColumn get stateRevision =>
      integer().named('state_revision').withDefault(const Constant(0))();
  IntColumn get checkpointSeq =>
      integer().named('checkpoint_seq').withDefault(const Constant(0))();
  TextColumn get errorCode => text().named('error_code').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 变更日志（v7 新增，X-04 多设备增量同步）。
@DataClassName('ChangeLogRow')
class ChangeLog extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get op => text()();
  IntColumn get tsMicros => integer().named('ts_micros')();
  TextColumn get payloadHash => text().named('payload_hash').nullable()();
}

/// 模型路由事件样本（v7 新增，X-02）。
@DataClassName('RouteEventRow')
class RouteEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get task => text()();
  TextColumn get providerId => text().named('provider_id').nullable()();
  TextColumn get modelId => text().named('model_id').nullable()();
  BoolColumn get success => boolean().withDefault(const Constant(true))();
  IntColumn get elapsedMs => integer().named('elapsed_ms').withDefault(const Constant(0))();
  RealColumn get cost => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 自动化工作流（v7 新增，X-01）。
@DataClassName('WorkflowRow')
class Workflows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get triggerJson => text().named('trigger_json')();
  TextColumn get actionsJson => text().named('actions_json')();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get agentId => text().named('agent_id').nullable()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// 工作流运行历史（v7 新增，X-01）。
@DataClassName('WorkflowRunRow')
class WorkflowRuns extends Table {
  TextColumn get id => text()();
  TextColumn get workflowId => text().named('workflow_id')();
  TextColumn get status => text()();
  IntColumn get startedAt => integer().named('started_at')();
  IntColumn get finishedAt => integer().named('finished_at').nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get resultJson => text().named('result_json').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

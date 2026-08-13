// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nona_app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _summaryTokensMeta = const VerificationMeta(
    'summaryTokens',
  );
  @override
  late final GeneratedColumn<int> summaryTokens = GeneratedColumn<int>(
    'summary_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoryMeta = const VerificationMeta('memory');
  @override
  late final GeneratedColumn<String> memory = GeneratedColumn<String>(
    'memory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _truncateIndexMeta = const VerificationMeta(
    'truncateIndex',
  );
  @override
  late final GeneratedColumn<int> truncateIndex = GeneratedColumn<int>(
    'truncate_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    optionsJson,
    providerId,
    modelId,
    agentId,
    pinned,
    sortOrder,
    createdAt,
    updatedAt,
    summary,
    summaryTokens,
    memory,
    tagsJson,
    truncateIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('summary_tokens')) {
      context.handle(
        _summaryTokensMeta,
        summaryTokens.isAcceptableOrUnknown(
          data['summary_tokens']!,
          _summaryTokensMeta,
        ),
      );
    }
    if (data.containsKey('memory')) {
      context.handle(
        _memoryMeta,
        memory.isAcceptableOrUnknown(data['memory']!, _memoryMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('truncate_index')) {
      context.handle(
        _truncateIndexMeta,
        truncateIndex.isAcceptableOrUnknown(
          data['truncate_index']!,
          _truncateIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      summaryTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}summary_tokens'],
      ),
      memory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
      truncateIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}truncate_index'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final String title;
  final String optionsJson;
  final String? providerId;
  final String? modelId;
  final String? agentId;
  final bool pinned;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final String summary;
  final int? summaryTokens;
  final String memory;

  /// v6：标签（JSON 数组字符串）；null 视为无标签。
  final String? tagsJson;

  /// v6：上下文清除标记（截断到该消息索引；null = 未清除）。
  final int? truncateIndex;
  const SessionRow({
    required this.id,
    required this.title,
    required this.optionsJson,
    this.providerId,
    this.modelId,
    this.agentId,
    required this.pinned,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.summary,
    this.summaryTokens,
    required this.memory,
    this.tagsJson,
    this.truncateIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['options_json'] = Variable<String>(optionsJson);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || summaryTokens != null) {
      map['summary_tokens'] = Variable<int>(summaryTokens);
    }
    map['memory'] = Variable<String>(memory);
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    if (!nullToAbsent || truncateIndex != null) {
      map['truncate_index'] = Variable<int>(truncateIndex);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      title: Value(title),
      optionsJson: Value(optionsJson),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      pinned: Value(pinned),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      summary: Value(summary),
      summaryTokens: summaryTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryTokens),
      memory: Value(memory),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
      truncateIndex: truncateIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(truncateIndex),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      summary: serializer.fromJson<String>(json['summary']),
      summaryTokens: serializer.fromJson<int?>(json['summaryTokens']),
      memory: serializer.fromJson<String>(json['memory']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
      truncateIndex: serializer.fromJson<int?>(json['truncateIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'providerId': serializer.toJson<String?>(providerId),
      'modelId': serializer.toJson<String?>(modelId),
      'agentId': serializer.toJson<String?>(agentId),
      'pinned': serializer.toJson<bool>(pinned),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'summary': serializer.toJson<String>(summary),
      'summaryTokens': serializer.toJson<int?>(summaryTokens),
      'memory': serializer.toJson<String>(memory),
      'tagsJson': serializer.toJson<String?>(tagsJson),
      'truncateIndex': serializer.toJson<int?>(truncateIndex),
    };
  }

  SessionRow copyWith({
    String? id,
    String? title,
    String? optionsJson,
    Value<String?> providerId = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    Value<String?> agentId = const Value.absent(),
    bool? pinned,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    String? summary,
    Value<int?> summaryTokens = const Value.absent(),
    String? memory,
    Value<String?> tagsJson = const Value.absent(),
    Value<int?> truncateIndex = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    title: title ?? this.title,
    optionsJson: optionsJson ?? this.optionsJson,
    providerId: providerId.present ? providerId.value : this.providerId,
    modelId: modelId.present ? modelId.value : this.modelId,
    agentId: agentId.present ? agentId.value : this.agentId,
    pinned: pinned ?? this.pinned,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    summary: summary ?? this.summary,
    summaryTokens: summaryTokens.present
        ? summaryTokens.value
        : this.summaryTokens,
    memory: memory ?? this.memory,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
    truncateIndex: truncateIndex.present
        ? truncateIndex.value
        : this.truncateIndex,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      summary: data.summary.present ? data.summary.value : this.summary,
      summaryTokens: data.summaryTokens.present
          ? data.summaryTokens.value
          : this.summaryTokens,
      memory: data.memory.present ? data.memory.value : this.memory,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      truncateIndex: data.truncateIndex.present
          ? data.truncateIndex.value
          : this.truncateIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('agentId: $agentId, ')
          ..write('pinned: $pinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('summary: $summary, ')
          ..write('summaryTokens: $summaryTokens, ')
          ..write('memory: $memory, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('truncateIndex: $truncateIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    optionsJson,
    providerId,
    modelId,
    agentId,
    pinned,
    sortOrder,
    createdAt,
    updatedAt,
    summary,
    summaryTokens,
    memory,
    tagsJson,
    truncateIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.optionsJson == this.optionsJson &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.agentId == this.agentId &&
          other.pinned == this.pinned &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.summary == this.summary &&
          other.summaryTokens == this.summaryTokens &&
          other.memory == this.memory &&
          other.tagsJson == this.tagsJson &&
          other.truncateIndex == this.truncateIndex);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> optionsJson;
  final Value<String?> providerId;
  final Value<String?> modelId;
  final Value<String?> agentId;
  final Value<bool> pinned;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> summary;
  final Value<int?> summaryTokens;
  final Value<String> memory;
  final Value<String?> tagsJson;
  final Value<int?> truncateIndex;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.pinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.summary = const Value.absent(),
    this.summaryTokens = const Value.absent(),
    this.memory = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.truncateIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String title,
    required String optionsJson,
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.agentId = const Value.absent(),
    this.pinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.summary = const Value.absent(),
    this.summaryTokens = const Value.absent(),
    this.memory = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.truncateIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       optionsJson = Value(optionsJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? optionsJson,
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<String>? agentId,
    Expression<bool>? pinned,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? summary,
    Expression<int>? summaryTokens,
    Expression<String>? memory,
    Expression<String>? tagsJson,
    Expression<int>? truncateIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (optionsJson != null) 'options_json': optionsJson,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (agentId != null) 'agent_id': agentId,
      if (pinned != null) 'pinned': pinned,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (summary != null) 'summary': summary,
      if (summaryTokens != null) 'summary_tokens': summaryTokens,
      if (memory != null) 'memory': memory,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (truncateIndex != null) 'truncate_index': truncateIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? optionsJson,
    Value<String?>? providerId,
    Value<String?>? modelId,
    Value<String?>? agentId,
    Value<bool>? pinned,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? summary,
    Value<int?>? summaryTokens,
    Value<String>? memory,
    Value<String?>? tagsJson,
    Value<int?>? truncateIndex,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      optionsJson: optionsJson ?? this.optionsJson,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      agentId: agentId ?? this.agentId,
      pinned: pinned ?? this.pinned,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary ?? this.summary,
      summaryTokens: summaryTokens ?? this.summaryTokens,
      memory: memory ?? this.memory,
      tagsJson: tagsJson ?? this.tagsJson,
      truncateIndex: truncateIndex ?? this.truncateIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (summaryTokens.present) {
      map['summary_tokens'] = Variable<int>(summaryTokens.value);
    }
    if (memory.present) {
      map['memory'] = Variable<String>(memory.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (truncateIndex.present) {
      map['truncate_index'] = Variable<int>(truncateIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('agentId: $agentId, ')
          ..write('pinned: $pinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('summary: $summary, ')
          ..write('summaryTokens: $summaryTokens, ')
          ..write('memory: $memory, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('truncateIndex: $truncateIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _messageIndexMeta = const VerificationMeta(
    'messageIndex',
  );
  @override
  late final GeneratedColumn<int> messageIndex = GeneratedColumn<int>(
    'message_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningContentMeta = const VerificationMeta(
    'reasoningContent',
  );
  @override
  late final GeneratedColumn<String> reasoningContent = GeneratedColumn<String>(
    'reasoning_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagesJsonMeta = const VerificationMeta(
    'imagesJson',
  );
  @override
  late final GeneratedColumn<String> imagesJson = GeneratedColumn<String>(
    'images_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _documentsJsonMeta = const VerificationMeta(
    'documentsJson',
  );
  @override
  late final GeneratedColumn<String> documentsJson = GeneratedColumn<String>(
    'documents_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _alternativesJsonMeta = const VerificationMeta(
    'alternativesJson',
  );
  @override
  late final GeneratedColumn<String> alternativesJson = GeneratedColumn<String>(
    'alternatives_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _toolCallIdMeta = const VerificationMeta(
    'toolCallId',
  );
  @override
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
    'tool_call_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolCallsJsonMeta = const VerificationMeta(
    'toolCallsJson',
  );
  @override
  late final GeneratedColumn<String> toolCallsJson = GeneratedColumn<String>(
    'tool_calls_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interruptedMeta = const VerificationMeta(
    'interrupted',
  );
  @override
  late final GeneratedColumn<bool> interrupted = GeneratedColumn<bool>(
    'interrupted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("interrupted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _failedMeta = const VerificationMeta('failed');
  @override
  late final GeneratedColumn<bool> failed = GeneratedColumn<bool>(
    'failed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("failed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _promptTokensMeta = const VerificationMeta(
    'promptTokens',
  );
  @override
  late final GeneratedColumn<int> promptTokens = GeneratedColumn<int>(
    'prompt_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionTokensMeta = const VerificationMeta(
    'completionTokens',
  );
  @override
  late final GeneratedColumn<int> completionTokens = GeneratedColumn<int>(
    'completion_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerNameMeta = const VerificationMeta(
    'providerName',
  );
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
    'provider_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partsJsonMeta = const VerificationMeta(
    'partsJson',
  );
  @override
  late final GeneratedColumn<String> partsJson = GeneratedColumn<String>(
    'parts_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _citationsJsonMeta = const VerificationMeta(
    'citationsJson',
  );
  @override
  late final GeneratedColumn<String> citationsJson = GeneratedColumn<String>(
    'citations_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolStepsJsonMeta = const VerificationMeta(
    'toolStepsJson',
  );
  @override
  late final GeneratedColumn<String> toolStepsJson = GeneratedColumn<String>(
    'tool_steps_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamingStateMeta = const VerificationMeta(
    'streamingState',
  );
  @override
  late final GeneratedColumn<String> streamingState = GeneratedColumn<String>(
    'streaming_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    messageIndex,
    role,
    content,
    reasoningContent,
    imagesJson,
    documentsJson,
    alternativesJson,
    toolCallId,
    toolCallsJson,
    interrupted,
    failed,
    promptTokens,
    completionTokens,
    elapsedMs,
    providerName,
    modelId,
    sentAt,
    partsJson,
    citationsJson,
    toolStepsJson,
    streamingState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('message_index')) {
      context.handle(
        _messageIndexMeta,
        messageIndex.isAcceptableOrUnknown(
          data['message_index']!,
          _messageIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIndexMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('reasoning_content')) {
      context.handle(
        _reasoningContentMeta,
        reasoningContent.isAcceptableOrUnknown(
          data['reasoning_content']!,
          _reasoningContentMeta,
        ),
      );
    }
    if (data.containsKey('images_json')) {
      context.handle(
        _imagesJsonMeta,
        imagesJson.isAcceptableOrUnknown(data['images_json']!, _imagesJsonMeta),
      );
    }
    if (data.containsKey('documents_json')) {
      context.handle(
        _documentsJsonMeta,
        documentsJson.isAcceptableOrUnknown(
          data['documents_json']!,
          _documentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('alternatives_json')) {
      context.handle(
        _alternativesJsonMeta,
        alternativesJson.isAcceptableOrUnknown(
          data['alternatives_json']!,
          _alternativesJsonMeta,
        ),
      );
    }
    if (data.containsKey('tool_call_id')) {
      context.handle(
        _toolCallIdMeta,
        toolCallId.isAcceptableOrUnknown(
          data['tool_call_id']!,
          _toolCallIdMeta,
        ),
      );
    }
    if (data.containsKey('tool_calls_json')) {
      context.handle(
        _toolCallsJsonMeta,
        toolCallsJson.isAcceptableOrUnknown(
          data['tool_calls_json']!,
          _toolCallsJsonMeta,
        ),
      );
    }
    if (data.containsKey('interrupted')) {
      context.handle(
        _interruptedMeta,
        interrupted.isAcceptableOrUnknown(
          data['interrupted']!,
          _interruptedMeta,
        ),
      );
    }
    if (data.containsKey('failed')) {
      context.handle(
        _failedMeta,
        failed.isAcceptableOrUnknown(data['failed']!, _failedMeta),
      );
    }
    if (data.containsKey('prompt_tokens')) {
      context.handle(
        _promptTokensMeta,
        promptTokens.isAcceptableOrUnknown(
          data['prompt_tokens']!,
          _promptTokensMeta,
        ),
      );
    }
    if (data.containsKey('completion_tokens')) {
      context.handle(
        _completionTokensMeta,
        completionTokens.isAcceptableOrUnknown(
          data['completion_tokens']!,
          _completionTokensMeta,
        ),
      );
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    }
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('parts_json')) {
      context.handle(
        _partsJsonMeta,
        partsJson.isAcceptableOrUnknown(data['parts_json']!, _partsJsonMeta),
      );
    }
    if (data.containsKey('citations_json')) {
      context.handle(
        _citationsJsonMeta,
        citationsJson.isAcceptableOrUnknown(
          data['citations_json']!,
          _citationsJsonMeta,
        ),
      );
    }
    if (data.containsKey('tool_steps_json')) {
      context.handle(
        _toolStepsJsonMeta,
        toolStepsJson.isAcceptableOrUnknown(
          data['tool_steps_json']!,
          _toolStepsJsonMeta,
        ),
      );
    }
    if (data.containsKey('streaming_state')) {
      context.handle(
        _streamingStateMeta,
        streamingState.isAcceptableOrUnknown(
          data['streaming_state']!,
          _streamingStateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      messageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_index'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      reasoningContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning_content'],
      )!,
      imagesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images_json'],
      )!,
      documentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documents_json'],
      )!,
      alternativesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternatives_json'],
      )!,
      toolCallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_call_id'],
      ),
      toolCallsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_calls_json'],
      ),
      interrupted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}interrupted'],
      )!,
      failed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}failed'],
      )!,
      promptTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_tokens'],
      ),
      completionTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_tokens'],
      ),
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      ),
      providerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      ),
      partsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parts_json'],
      ),
      citationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citations_json'],
      ),
      toolStepsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_steps_json'],
      ),
      streamingState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}streaming_state'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String id;
  final String sessionId;
  final int messageIndex;
  final String role;
  final String content;
  final String reasoningContent;
  final String imagesJson;
  final String documentsJson;
  final String alternativesJson;
  final String? toolCallId;
  final String? toolCallsJson;
  final bool interrupted;
  final bool failed;
  final int? promptTokens;
  final int? completionTokens;
  final int? elapsedMs;
  final String? providerName;
  final String? modelId;
  final int? sentAt;

  /// v6：消息分段权威数据（text/reasoning/tool_call/tool_result），
  /// null = 旧消息，读 content 兼容。
  final String? partsJson;

  /// v6：引用出处（B-03，JSON 数组）。
  final String? citationsJson;

  /// v6：工具执行步骤（F-04，JSON 数组）。
  final String? toolStepsJson;

  /// v6：流式生成状态（B-06：streaming / 终态置空）。
  final String? streamingState;
  const MessageRow({
    required this.id,
    required this.sessionId,
    required this.messageIndex,
    required this.role,
    required this.content,
    required this.reasoningContent,
    required this.imagesJson,
    required this.documentsJson,
    required this.alternativesJson,
    this.toolCallId,
    this.toolCallsJson,
    required this.interrupted,
    required this.failed,
    this.promptTokens,
    this.completionTokens,
    this.elapsedMs,
    this.providerName,
    this.modelId,
    this.sentAt,
    this.partsJson,
    this.citationsJson,
    this.toolStepsJson,
    this.streamingState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['message_index'] = Variable<int>(messageIndex);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['reasoning_content'] = Variable<String>(reasoningContent);
    map['images_json'] = Variable<String>(imagesJson);
    map['documents_json'] = Variable<String>(documentsJson);
    map['alternatives_json'] = Variable<String>(alternativesJson);
    if (!nullToAbsent || toolCallId != null) {
      map['tool_call_id'] = Variable<String>(toolCallId);
    }
    if (!nullToAbsent || toolCallsJson != null) {
      map['tool_calls_json'] = Variable<String>(toolCallsJson);
    }
    map['interrupted'] = Variable<bool>(interrupted);
    map['failed'] = Variable<bool>(failed);
    if (!nullToAbsent || promptTokens != null) {
      map['prompt_tokens'] = Variable<int>(promptTokens);
    }
    if (!nullToAbsent || completionTokens != null) {
      map['completion_tokens'] = Variable<int>(completionTokens);
    }
    if (!nullToAbsent || elapsedMs != null) {
      map['elapsed_ms'] = Variable<int>(elapsedMs);
    }
    if (!nullToAbsent || providerName != null) {
      map['provider_name'] = Variable<String>(providerName);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<int>(sentAt);
    }
    if (!nullToAbsent || partsJson != null) {
      map['parts_json'] = Variable<String>(partsJson);
    }
    if (!nullToAbsent || citationsJson != null) {
      map['citations_json'] = Variable<String>(citationsJson);
    }
    if (!nullToAbsent || toolStepsJson != null) {
      map['tool_steps_json'] = Variable<String>(toolStepsJson);
    }
    if (!nullToAbsent || streamingState != null) {
      map['streaming_state'] = Variable<String>(streamingState);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      messageIndex: Value(messageIndex),
      role: Value(role),
      content: Value(content),
      reasoningContent: Value(reasoningContent),
      imagesJson: Value(imagesJson),
      documentsJson: Value(documentsJson),
      alternativesJson: Value(alternativesJson),
      toolCallId: toolCallId == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallId),
      toolCallsJson: toolCallsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallsJson),
      interrupted: Value(interrupted),
      failed: Value(failed),
      promptTokens: promptTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(promptTokens),
      completionTokens: completionTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(completionTokens),
      elapsedMs: elapsedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(elapsedMs),
      providerName: providerName == null && nullToAbsent
          ? const Value.absent()
          : Value(providerName),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      partsJson: partsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(partsJson),
      citationsJson: citationsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(citationsJson),
      toolStepsJson: toolStepsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(toolStepsJson),
      streamingState: streamingState == null && nullToAbsent
          ? const Value.absent()
          : Value(streamingState),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      messageIndex: serializer.fromJson<int>(json['messageIndex']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      reasoningContent: serializer.fromJson<String>(json['reasoningContent']),
      imagesJson: serializer.fromJson<String>(json['imagesJson']),
      documentsJson: serializer.fromJson<String>(json['documentsJson']),
      alternativesJson: serializer.fromJson<String>(json['alternativesJson']),
      toolCallId: serializer.fromJson<String?>(json['toolCallId']),
      toolCallsJson: serializer.fromJson<String?>(json['toolCallsJson']),
      interrupted: serializer.fromJson<bool>(json['interrupted']),
      failed: serializer.fromJson<bool>(json['failed']),
      promptTokens: serializer.fromJson<int?>(json['promptTokens']),
      completionTokens: serializer.fromJson<int?>(json['completionTokens']),
      elapsedMs: serializer.fromJson<int?>(json['elapsedMs']),
      providerName: serializer.fromJson<String?>(json['providerName']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      sentAt: serializer.fromJson<int?>(json['sentAt']),
      partsJson: serializer.fromJson<String?>(json['partsJson']),
      citationsJson: serializer.fromJson<String?>(json['citationsJson']),
      toolStepsJson: serializer.fromJson<String?>(json['toolStepsJson']),
      streamingState: serializer.fromJson<String?>(json['streamingState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'messageIndex': serializer.toJson<int>(messageIndex),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'reasoningContent': serializer.toJson<String>(reasoningContent),
      'imagesJson': serializer.toJson<String>(imagesJson),
      'documentsJson': serializer.toJson<String>(documentsJson),
      'alternativesJson': serializer.toJson<String>(alternativesJson),
      'toolCallId': serializer.toJson<String?>(toolCallId),
      'toolCallsJson': serializer.toJson<String?>(toolCallsJson),
      'interrupted': serializer.toJson<bool>(interrupted),
      'failed': serializer.toJson<bool>(failed),
      'promptTokens': serializer.toJson<int?>(promptTokens),
      'completionTokens': serializer.toJson<int?>(completionTokens),
      'elapsedMs': serializer.toJson<int?>(elapsedMs),
      'providerName': serializer.toJson<String?>(providerName),
      'modelId': serializer.toJson<String?>(modelId),
      'sentAt': serializer.toJson<int?>(sentAt),
      'partsJson': serializer.toJson<String?>(partsJson),
      'citationsJson': serializer.toJson<String?>(citationsJson),
      'toolStepsJson': serializer.toJson<String?>(toolStepsJson),
      'streamingState': serializer.toJson<String?>(streamingState),
    };
  }

  MessageRow copyWith({
    String? id,
    String? sessionId,
    int? messageIndex,
    String? role,
    String? content,
    String? reasoningContent,
    String? imagesJson,
    String? documentsJson,
    String? alternativesJson,
    Value<String?> toolCallId = const Value.absent(),
    Value<String?> toolCallsJson = const Value.absent(),
    bool? interrupted,
    bool? failed,
    Value<int?> promptTokens = const Value.absent(),
    Value<int?> completionTokens = const Value.absent(),
    Value<int?> elapsedMs = const Value.absent(),
    Value<String?> providerName = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    Value<int?> sentAt = const Value.absent(),
    Value<String?> partsJson = const Value.absent(),
    Value<String?> citationsJson = const Value.absent(),
    Value<String?> toolStepsJson = const Value.absent(),
    Value<String?> streamingState = const Value.absent(),
  }) => MessageRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    messageIndex: messageIndex ?? this.messageIndex,
    role: role ?? this.role,
    content: content ?? this.content,
    reasoningContent: reasoningContent ?? this.reasoningContent,
    imagesJson: imagesJson ?? this.imagesJson,
    documentsJson: documentsJson ?? this.documentsJson,
    alternativesJson: alternativesJson ?? this.alternativesJson,
    toolCallId: toolCallId.present ? toolCallId.value : this.toolCallId,
    toolCallsJson: toolCallsJson.present
        ? toolCallsJson.value
        : this.toolCallsJson,
    interrupted: interrupted ?? this.interrupted,
    failed: failed ?? this.failed,
    promptTokens: promptTokens.present ? promptTokens.value : this.promptTokens,
    completionTokens: completionTokens.present
        ? completionTokens.value
        : this.completionTokens,
    elapsedMs: elapsedMs.present ? elapsedMs.value : this.elapsedMs,
    providerName: providerName.present ? providerName.value : this.providerName,
    modelId: modelId.present ? modelId.value : this.modelId,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    partsJson: partsJson.present ? partsJson.value : this.partsJson,
    citationsJson: citationsJson.present
        ? citationsJson.value
        : this.citationsJson,
    toolStepsJson: toolStepsJson.present
        ? toolStepsJson.value
        : this.toolStepsJson,
    streamingState: streamingState.present
        ? streamingState.value
        : this.streamingState,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageIndex: data.messageIndex.present
          ? data.messageIndex.value
          : this.messageIndex,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      reasoningContent: data.reasoningContent.present
          ? data.reasoningContent.value
          : this.reasoningContent,
      imagesJson: data.imagesJson.present
          ? data.imagesJson.value
          : this.imagesJson,
      documentsJson: data.documentsJson.present
          ? data.documentsJson.value
          : this.documentsJson,
      alternativesJson: data.alternativesJson.present
          ? data.alternativesJson.value
          : this.alternativesJson,
      toolCallId: data.toolCallId.present
          ? data.toolCallId.value
          : this.toolCallId,
      toolCallsJson: data.toolCallsJson.present
          ? data.toolCallsJson.value
          : this.toolCallsJson,
      interrupted: data.interrupted.present
          ? data.interrupted.value
          : this.interrupted,
      failed: data.failed.present ? data.failed.value : this.failed,
      promptTokens: data.promptTokens.present
          ? data.promptTokens.value
          : this.promptTokens,
      completionTokens: data.completionTokens.present
          ? data.completionTokens.value
          : this.completionTokens,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      partsJson: data.partsJson.present ? data.partsJson.value : this.partsJson,
      citationsJson: data.citationsJson.present
          ? data.citationsJson.value
          : this.citationsJson,
      toolStepsJson: data.toolStepsJson.present
          ? data.toolStepsJson.value
          : this.toolStepsJson,
      streamingState: data.streamingState.present
          ? data.streamingState.value
          : this.streamingState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageIndex: $messageIndex, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('imagesJson: $imagesJson, ')
          ..write('documentsJson: $documentsJson, ')
          ..write('alternativesJson: $alternativesJson, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolCallsJson: $toolCallsJson, ')
          ..write('interrupted: $interrupted, ')
          ..write('failed: $failed, ')
          ..write('promptTokens: $promptTokens, ')
          ..write('completionTokens: $completionTokens, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('providerName: $providerName, ')
          ..write('modelId: $modelId, ')
          ..write('sentAt: $sentAt, ')
          ..write('partsJson: $partsJson, ')
          ..write('citationsJson: $citationsJson, ')
          ..write('toolStepsJson: $toolStepsJson, ')
          ..write('streamingState: $streamingState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sessionId,
    messageIndex,
    role,
    content,
    reasoningContent,
    imagesJson,
    documentsJson,
    alternativesJson,
    toolCallId,
    toolCallsJson,
    interrupted,
    failed,
    promptTokens,
    completionTokens,
    elapsedMs,
    providerName,
    modelId,
    sentAt,
    partsJson,
    citationsJson,
    toolStepsJson,
    streamingState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.messageIndex == this.messageIndex &&
          other.role == this.role &&
          other.content == this.content &&
          other.reasoningContent == this.reasoningContent &&
          other.imagesJson == this.imagesJson &&
          other.documentsJson == this.documentsJson &&
          other.alternativesJson == this.alternativesJson &&
          other.toolCallId == this.toolCallId &&
          other.toolCallsJson == this.toolCallsJson &&
          other.interrupted == this.interrupted &&
          other.failed == this.failed &&
          other.promptTokens == this.promptTokens &&
          other.completionTokens == this.completionTokens &&
          other.elapsedMs == this.elapsedMs &&
          other.providerName == this.providerName &&
          other.modelId == this.modelId &&
          other.sentAt == this.sentAt &&
          other.partsJson == this.partsJson &&
          other.citationsJson == this.citationsJson &&
          other.toolStepsJson == this.toolStepsJson &&
          other.streamingState == this.streamingState);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> messageIndex;
  final Value<String> role;
  final Value<String> content;
  final Value<String> reasoningContent;
  final Value<String> imagesJson;
  final Value<String> documentsJson;
  final Value<String> alternativesJson;
  final Value<String?> toolCallId;
  final Value<String?> toolCallsJson;
  final Value<bool> interrupted;
  final Value<bool> failed;
  final Value<int?> promptTokens;
  final Value<int?> completionTokens;
  final Value<int?> elapsedMs;
  final Value<String?> providerName;
  final Value<String?> modelId;
  final Value<int?> sentAt;
  final Value<String?> partsJson;
  final Value<String?> citationsJson;
  final Value<String?> toolStepsJson;
  final Value<String?> streamingState;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageIndex = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.reasoningContent = const Value.absent(),
    this.imagesJson = const Value.absent(),
    this.documentsJson = const Value.absent(),
    this.alternativesJson = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolCallsJson = const Value.absent(),
    this.interrupted = const Value.absent(),
    this.failed = const Value.absent(),
    this.promptTokens = const Value.absent(),
    this.completionTokens = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.providerName = const Value.absent(),
    this.modelId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.partsJson = const Value.absent(),
    this.citationsJson = const Value.absent(),
    this.toolStepsJson = const Value.absent(),
    this.streamingState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String sessionId,
    required int messageIndex,
    required String role,
    required String content,
    this.reasoningContent = const Value.absent(),
    this.imagesJson = const Value.absent(),
    this.documentsJson = const Value.absent(),
    this.alternativesJson = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolCallsJson = const Value.absent(),
    this.interrupted = const Value.absent(),
    this.failed = const Value.absent(),
    this.promptTokens = const Value.absent(),
    this.completionTokens = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.providerName = const Value.absent(),
    this.modelId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.partsJson = const Value.absent(),
    this.citationsJson = const Value.absent(),
    this.toolStepsJson = const Value.absent(),
    this.streamingState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       messageIndex = Value(messageIndex),
       role = Value(role),
       content = Value(content);
  static Insertable<MessageRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? messageIndex,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? reasoningContent,
    Expression<String>? imagesJson,
    Expression<String>? documentsJson,
    Expression<String>? alternativesJson,
    Expression<String>? toolCallId,
    Expression<String>? toolCallsJson,
    Expression<bool>? interrupted,
    Expression<bool>? failed,
    Expression<int>? promptTokens,
    Expression<int>? completionTokens,
    Expression<int>? elapsedMs,
    Expression<String>? providerName,
    Expression<String>? modelId,
    Expression<int>? sentAt,
    Expression<String>? partsJson,
    Expression<String>? citationsJson,
    Expression<String>? toolStepsJson,
    Expression<String>? streamingState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (messageIndex != null) 'message_index': messageIndex,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (reasoningContent != null) 'reasoning_content': reasoningContent,
      if (imagesJson != null) 'images_json': imagesJson,
      if (documentsJson != null) 'documents_json': documentsJson,
      if (alternativesJson != null) 'alternatives_json': alternativesJson,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (toolCallsJson != null) 'tool_calls_json': toolCallsJson,
      if (interrupted != null) 'interrupted': interrupted,
      if (failed != null) 'failed': failed,
      if (promptTokens != null) 'prompt_tokens': promptTokens,
      if (completionTokens != null) 'completion_tokens': completionTokens,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (providerName != null) 'provider_name': providerName,
      if (modelId != null) 'model_id': modelId,
      if (sentAt != null) 'sent_at': sentAt,
      if (partsJson != null) 'parts_json': partsJson,
      if (citationsJson != null) 'citations_json': citationsJson,
      if (toolStepsJson != null) 'tool_steps_json': toolStepsJson,
      if (streamingState != null) 'streaming_state': streamingState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? messageIndex,
    Value<String>? role,
    Value<String>? content,
    Value<String>? reasoningContent,
    Value<String>? imagesJson,
    Value<String>? documentsJson,
    Value<String>? alternativesJson,
    Value<String?>? toolCallId,
    Value<String?>? toolCallsJson,
    Value<bool>? interrupted,
    Value<bool>? failed,
    Value<int?>? promptTokens,
    Value<int?>? completionTokens,
    Value<int?>? elapsedMs,
    Value<String?>? providerName,
    Value<String?>? modelId,
    Value<int?>? sentAt,
    Value<String?>? partsJson,
    Value<String?>? citationsJson,
    Value<String?>? toolStepsJson,
    Value<String?>? streamingState,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      messageIndex: messageIndex ?? this.messageIndex,
      role: role ?? this.role,
      content: content ?? this.content,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      imagesJson: imagesJson ?? this.imagesJson,
      documentsJson: documentsJson ?? this.documentsJson,
      alternativesJson: alternativesJson ?? this.alternativesJson,
      toolCallId: toolCallId ?? this.toolCallId,
      toolCallsJson: toolCallsJson ?? this.toolCallsJson,
      interrupted: interrupted ?? this.interrupted,
      failed: failed ?? this.failed,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      providerName: providerName ?? this.providerName,
      modelId: modelId ?? this.modelId,
      sentAt: sentAt ?? this.sentAt,
      partsJson: partsJson ?? this.partsJson,
      citationsJson: citationsJson ?? this.citationsJson,
      toolStepsJson: toolStepsJson ?? this.toolStepsJson,
      streamingState: streamingState ?? this.streamingState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageIndex.present) {
      map['message_index'] = Variable<int>(messageIndex.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (reasoningContent.present) {
      map['reasoning_content'] = Variable<String>(reasoningContent.value);
    }
    if (imagesJson.present) {
      map['images_json'] = Variable<String>(imagesJson.value);
    }
    if (documentsJson.present) {
      map['documents_json'] = Variable<String>(documentsJson.value);
    }
    if (alternativesJson.present) {
      map['alternatives_json'] = Variable<String>(alternativesJson.value);
    }
    if (toolCallId.present) {
      map['tool_call_id'] = Variable<String>(toolCallId.value);
    }
    if (toolCallsJson.present) {
      map['tool_calls_json'] = Variable<String>(toolCallsJson.value);
    }
    if (interrupted.present) {
      map['interrupted'] = Variable<bool>(interrupted.value);
    }
    if (failed.present) {
      map['failed'] = Variable<bool>(failed.value);
    }
    if (promptTokens.present) {
      map['prompt_tokens'] = Variable<int>(promptTokens.value);
    }
    if (completionTokens.present) {
      map['completion_tokens'] = Variable<int>(completionTokens.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (partsJson.present) {
      map['parts_json'] = Variable<String>(partsJson.value);
    }
    if (citationsJson.present) {
      map['citations_json'] = Variable<String>(citationsJson.value);
    }
    if (toolStepsJson.present) {
      map['tool_steps_json'] = Variable<String>(toolStepsJson.value);
    }
    if (streamingState.present) {
      map['streaming_state'] = Variable<String>(streamingState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageIndex: $messageIndex, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('reasoningContent: $reasoningContent, ')
          ..write('imagesJson: $imagesJson, ')
          ..write('documentsJson: $documentsJson, ')
          ..write('alternativesJson: $alternativesJson, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolCallsJson: $toolCallsJson, ')
          ..write('interrupted: $interrupted, ')
          ..write('failed: $failed, ')
          ..write('promptTokens: $promptTokens, ')
          ..write('completionTokens: $completionTokens, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('providerName: $providerName, ')
          ..write('modelId: $modelId, ')
          ..write('sentAt: $sentAt, ')
          ..write('partsJson: $partsJson, ')
          ..write('citationsJson: $citationsJson, ')
          ..write('toolStepsJson: $toolStepsJson, ')
          ..write('streamingState: $streamingState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageTokensTable extends MessageTokens
    with TableInfo<$MessageTokensTable, MessageTokenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [token, sessionId, messageId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageTokenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {token, messageId, position};
  @override
  MessageTokenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageTokenRow(
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $MessageTokensTable createAlias(String alias) {
    return $MessageTokensTable(attachedDatabase, alias);
  }
}

class MessageTokenRow extends DataClass implements Insertable<MessageTokenRow> {
  final String token;
  final String sessionId;
  final String messageId;
  final int position;
  const MessageTokenRow({
    required this.token,
    required this.sessionId,
    required this.messageId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['token'] = Variable<String>(token);
    map['session_id'] = Variable<String>(sessionId);
    map['message_id'] = Variable<String>(messageId);
    map['position'] = Variable<int>(position);
    return map;
  }

  MessageTokensCompanion toCompanion(bool nullToAbsent) {
    return MessageTokensCompanion(
      token: Value(token),
      sessionId: Value(sessionId),
      messageId: Value(messageId),
      position: Value(position),
    );
  }

  factory MessageTokenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageTokenRow(
      token: serializer.fromJson<String>(json['token']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'token': serializer.toJson<String>(token),
      'sessionId': serializer.toJson<String>(sessionId),
      'messageId': serializer.toJson<String>(messageId),
      'position': serializer.toJson<int>(position),
    };
  }

  MessageTokenRow copyWith({
    String? token,
    String? sessionId,
    String? messageId,
    int? position,
  }) => MessageTokenRow(
    token: token ?? this.token,
    sessionId: sessionId ?? this.sessionId,
    messageId: messageId ?? this.messageId,
    position: position ?? this.position,
  );
  MessageTokenRow copyWithCompanion(MessageTokensCompanion data) {
    return MessageTokenRow(
      token: data.token.present ? data.token.value : this.token,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageTokenRow(')
          ..write('token: $token, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(token, sessionId, messageId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageTokenRow &&
          other.token == this.token &&
          other.sessionId == this.sessionId &&
          other.messageId == this.messageId &&
          other.position == this.position);
}

class MessageTokensCompanion extends UpdateCompanion<MessageTokenRow> {
  final Value<String> token;
  final Value<String> sessionId;
  final Value<String> messageId;
  final Value<int> position;
  final Value<int> rowid;
  const MessageTokensCompanion({
    this.token = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageTokensCompanion.insert({
    required String token,
    required String sessionId,
    required String messageId,
    required int position,
    this.rowid = const Value.absent(),
  }) : token = Value(token),
       sessionId = Value(sessionId),
       messageId = Value(messageId),
       position = Value(position);
  static Insertable<MessageTokenRow> custom({
    Expression<String>? token,
    Expression<String>? sessionId,
    Expression<String>? messageId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (token != null) 'token': token,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageTokensCompanion copyWith({
    Value<String>? token,
    Value<String>? sessionId,
    Value<String>? messageId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return MessageTokensCompanion(
      token: token ?? this.token,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageTokensCompanion(')
          ..write('token: $token, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompressedBlocksTable extends CompressedBlocks
    with TableInfo<$CompressedBlocksTable, CompressedBlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompressedBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startIndexMeta = const VerificationMeta(
    'startIndex',
  );
  @override
  late final GeneratedColumn<int> startIndex = GeneratedColumn<int>(
    'start_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endIndexMeta = const VerificationMeta(
    'endIndex',
  );
  @override
  late final GeneratedColumn<int> endIndex = GeneratedColumn<int>(
    'end_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messagesJsonMeta = const VerificationMeta(
    'messagesJson',
  );
  @override
  late final GeneratedColumn<String> messagesJson = GeneratedColumn<String>(
    'messages_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    startIndex,
    endIndex,
    summary,
    messagesJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compressed_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompressedBlockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('start_index')) {
      context.handle(
        _startIndexMeta,
        startIndex.isAcceptableOrUnknown(data['start_index']!, _startIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_startIndexMeta);
    }
    if (data.containsKey('end_index')) {
      context.handle(
        _endIndexMeta,
        endIndex.isAcceptableOrUnknown(data['end_index']!, _endIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_endIndexMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('messages_json')) {
      context.handle(
        _messagesJsonMeta,
        messagesJson.isAcceptableOrUnknown(
          data['messages_json']!,
          _messagesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompressedBlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompressedBlockRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      startIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_index'],
      )!,
      endIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_index'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      messagesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}messages_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CompressedBlocksTable createAlias(String alias) {
    return $CompressedBlocksTable(attachedDatabase, alias);
  }
}

class CompressedBlockRow extends DataClass
    implements Insertable<CompressedBlockRow> {
  final String id;
  final String sessionId;
  final int startIndex;
  final int endIndex;
  final String summary;
  final String messagesJson;
  final int createdAt;
  const CompressedBlockRow({
    required this.id,
    required this.sessionId,
    required this.startIndex,
    required this.endIndex,
    required this.summary,
    required this.messagesJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['start_index'] = Variable<int>(startIndex);
    map['end_index'] = Variable<int>(endIndex);
    map['summary'] = Variable<String>(summary);
    map['messages_json'] = Variable<String>(messagesJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CompressedBlocksCompanion toCompanion(bool nullToAbsent) {
    return CompressedBlocksCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      startIndex: Value(startIndex),
      endIndex: Value(endIndex),
      summary: Value(summary),
      messagesJson: Value(messagesJson),
      createdAt: Value(createdAt),
    );
  }

  factory CompressedBlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompressedBlockRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      startIndex: serializer.fromJson<int>(json['startIndex']),
      endIndex: serializer.fromJson<int>(json['endIndex']),
      summary: serializer.fromJson<String>(json['summary']),
      messagesJson: serializer.fromJson<String>(json['messagesJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'startIndex': serializer.toJson<int>(startIndex),
      'endIndex': serializer.toJson<int>(endIndex),
      'summary': serializer.toJson<String>(summary),
      'messagesJson': serializer.toJson<String>(messagesJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CompressedBlockRow copyWith({
    String? id,
    String? sessionId,
    int? startIndex,
    int? endIndex,
    String? summary,
    String? messagesJson,
    int? createdAt,
  }) => CompressedBlockRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    startIndex: startIndex ?? this.startIndex,
    endIndex: endIndex ?? this.endIndex,
    summary: summary ?? this.summary,
    messagesJson: messagesJson ?? this.messagesJson,
    createdAt: createdAt ?? this.createdAt,
  );
  CompressedBlockRow copyWithCompanion(CompressedBlocksCompanion data) {
    return CompressedBlockRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      startIndex: data.startIndex.present
          ? data.startIndex.value
          : this.startIndex,
      endIndex: data.endIndex.present ? data.endIndex.value : this.endIndex,
      summary: data.summary.present ? data.summary.value : this.summary,
      messagesJson: data.messagesJson.present
          ? data.messagesJson.value
          : this.messagesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompressedBlockRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('startIndex: $startIndex, ')
          ..write('endIndex: $endIndex, ')
          ..write('summary: $summary, ')
          ..write('messagesJson: $messagesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    startIndex,
    endIndex,
    summary,
    messagesJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompressedBlockRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.startIndex == this.startIndex &&
          other.endIndex == this.endIndex &&
          other.summary == this.summary &&
          other.messagesJson == this.messagesJson &&
          other.createdAt == this.createdAt);
}

class CompressedBlocksCompanion extends UpdateCompanion<CompressedBlockRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> startIndex;
  final Value<int> endIndex;
  final Value<String> summary;
  final Value<String> messagesJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CompressedBlocksCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.startIndex = const Value.absent(),
    this.endIndex = const Value.absent(),
    this.summary = const Value.absent(),
    this.messagesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompressedBlocksCompanion.insert({
    required String id,
    required String sessionId,
    required int startIndex,
    required int endIndex,
    required String summary,
    this.messagesJson = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       startIndex = Value(startIndex),
       endIndex = Value(endIndex),
       summary = Value(summary),
       createdAt = Value(createdAt);
  static Insertable<CompressedBlockRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? startIndex,
    Expression<int>? endIndex,
    Expression<String>? summary,
    Expression<String>? messagesJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (startIndex != null) 'start_index': startIndex,
      if (endIndex != null) 'end_index': endIndex,
      if (summary != null) 'summary': summary,
      if (messagesJson != null) 'messages_json': messagesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompressedBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? startIndex,
    Value<int>? endIndex,
    Value<String>? summary,
    Value<String>? messagesJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CompressedBlocksCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      summary: summary ?? this.summary,
      messagesJson: messagesJson ?? this.messagesJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (startIndex.present) {
      map['start_index'] = Variable<int>(startIndex.value);
    }
    if (endIndex.present) {
      map['end_index'] = Variable<int>(endIndex.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (messagesJson.present) {
      map['messages_json'] = Variable<String>(messagesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompressedBlocksCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('startIndex: $startIndex, ')
          ..write('endIndex: $endIndex, ')
          ..write('summary: $summary, ')
          ..write('messagesJson: $messagesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageDailyTable extends UsageDaily
    with TableInfo<$UsageDailyTable, UsageDailyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageDailyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerNameMeta = const VerificationMeta(
    'providerName',
  );
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
    'provider_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptTokensMeta = const VerificationMeta(
    'promptTokens',
  );
  @override
  late final GeneratedColumn<int> promptTokens = GeneratedColumn<int>(
    'prompt_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionTokensMeta = const VerificationMeta(
    'completionTokens',
  );
  @override
  late final GeneratedColumn<int> completionTokens = GeneratedColumn<int>(
    'completion_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _callsMeta = const VerificationMeta('calls');
  @override
  late final GeneratedColumn<int> calls = GeneratedColumn<int>(
    'calls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    modelId,
    providerName,
    date,
    promptTokens,
    completionTokens,
    calls,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageDailyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerNameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('prompt_tokens')) {
      context.handle(
        _promptTokensMeta,
        promptTokens.isAcceptableOrUnknown(
          data['prompt_tokens']!,
          _promptTokensMeta,
        ),
      );
    }
    if (data.containsKey('completion_tokens')) {
      context.handle(
        _completionTokensMeta,
        completionTokens.isAcceptableOrUnknown(
          data['completion_tokens']!,
          _completionTokensMeta,
        ),
      );
    }
    if (data.containsKey('calls')) {
      context.handle(
        _callsMeta,
        calls.isAcceptableOrUnknown(data['calls']!, _callsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {modelId, providerName, date};
  @override
  UsageDailyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageDailyRow(
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      providerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      promptTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_tokens'],
      )!,
      completionTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_tokens'],
      )!,
      calls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calls'],
      )!,
    );
  }

  @override
  $UsageDailyTable createAlias(String alias) {
    return $UsageDailyTable(attachedDatabase, alias);
  }
}

class UsageDailyRow extends DataClass implements Insertable<UsageDailyRow> {
  final String modelId;
  final String providerName;
  final String date;
  final int promptTokens;
  final int completionTokens;
  final int calls;
  const UsageDailyRow({
    required this.modelId,
    required this.providerName,
    required this.date,
    required this.promptTokens,
    required this.completionTokens,
    required this.calls,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['model_id'] = Variable<String>(modelId);
    map['provider_name'] = Variable<String>(providerName);
    map['date'] = Variable<String>(date);
    map['prompt_tokens'] = Variable<int>(promptTokens);
    map['completion_tokens'] = Variable<int>(completionTokens);
    map['calls'] = Variable<int>(calls);
    return map;
  }

  UsageDailyCompanion toCompanion(bool nullToAbsent) {
    return UsageDailyCompanion(
      modelId: Value(modelId),
      providerName: Value(providerName),
      date: Value(date),
      promptTokens: Value(promptTokens),
      completionTokens: Value(completionTokens),
      calls: Value(calls),
    );
  }

  factory UsageDailyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageDailyRow(
      modelId: serializer.fromJson<String>(json['modelId']),
      providerName: serializer.fromJson<String>(json['providerName']),
      date: serializer.fromJson<String>(json['date']),
      promptTokens: serializer.fromJson<int>(json['promptTokens']),
      completionTokens: serializer.fromJson<int>(json['completionTokens']),
      calls: serializer.fromJson<int>(json['calls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modelId': serializer.toJson<String>(modelId),
      'providerName': serializer.toJson<String>(providerName),
      'date': serializer.toJson<String>(date),
      'promptTokens': serializer.toJson<int>(promptTokens),
      'completionTokens': serializer.toJson<int>(completionTokens),
      'calls': serializer.toJson<int>(calls),
    };
  }

  UsageDailyRow copyWith({
    String? modelId,
    String? providerName,
    String? date,
    int? promptTokens,
    int? completionTokens,
    int? calls,
  }) => UsageDailyRow(
    modelId: modelId ?? this.modelId,
    providerName: providerName ?? this.providerName,
    date: date ?? this.date,
    promptTokens: promptTokens ?? this.promptTokens,
    completionTokens: completionTokens ?? this.completionTokens,
    calls: calls ?? this.calls,
  );
  UsageDailyRow copyWithCompanion(UsageDailyCompanion data) {
    return UsageDailyRow(
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      date: data.date.present ? data.date.value : this.date,
      promptTokens: data.promptTokens.present
          ? data.promptTokens.value
          : this.promptTokens,
      completionTokens: data.completionTokens.present
          ? data.completionTokens.value
          : this.completionTokens,
      calls: data.calls.present ? data.calls.value : this.calls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageDailyRow(')
          ..write('modelId: $modelId, ')
          ..write('providerName: $providerName, ')
          ..write('date: $date, ')
          ..write('promptTokens: $promptTokens, ')
          ..write('completionTokens: $completionTokens, ')
          ..write('calls: $calls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modelId,
    providerName,
    date,
    promptTokens,
    completionTokens,
    calls,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageDailyRow &&
          other.modelId == this.modelId &&
          other.providerName == this.providerName &&
          other.date == this.date &&
          other.promptTokens == this.promptTokens &&
          other.completionTokens == this.completionTokens &&
          other.calls == this.calls);
}

class UsageDailyCompanion extends UpdateCompanion<UsageDailyRow> {
  final Value<String> modelId;
  final Value<String> providerName;
  final Value<String> date;
  final Value<int> promptTokens;
  final Value<int> completionTokens;
  final Value<int> calls;
  final Value<int> rowid;
  const UsageDailyCompanion({
    this.modelId = const Value.absent(),
    this.providerName = const Value.absent(),
    this.date = const Value.absent(),
    this.promptTokens = const Value.absent(),
    this.completionTokens = const Value.absent(),
    this.calls = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageDailyCompanion.insert({
    required String modelId,
    required String providerName,
    required String date,
    this.promptTokens = const Value.absent(),
    this.completionTokens = const Value.absent(),
    this.calls = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : modelId = Value(modelId),
       providerName = Value(providerName),
       date = Value(date);
  static Insertable<UsageDailyRow> custom({
    Expression<String>? modelId,
    Expression<String>? providerName,
    Expression<String>? date,
    Expression<int>? promptTokens,
    Expression<int>? completionTokens,
    Expression<int>? calls,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modelId != null) 'model_id': modelId,
      if (providerName != null) 'provider_name': providerName,
      if (date != null) 'date': date,
      if (promptTokens != null) 'prompt_tokens': promptTokens,
      if (completionTokens != null) 'completion_tokens': completionTokens,
      if (calls != null) 'calls': calls,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageDailyCompanion copyWith({
    Value<String>? modelId,
    Value<String>? providerName,
    Value<String>? date,
    Value<int>? promptTokens,
    Value<int>? completionTokens,
    Value<int>? calls,
    Value<int>? rowid,
  }) {
    return UsageDailyCompanion(
      modelId: modelId ?? this.modelId,
      providerName: providerName ?? this.providerName,
      date: date ?? this.date,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      calls: calls ?? this.calls,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (promptTokens.present) {
      map['prompt_tokens'] = Variable<int>(promptTokens.value);
    }
    if (completionTokens.present) {
      map['completion_tokens'] = Variable<int>(completionTokens.value);
    }
    if (calls.present) {
      map['calls'] = Variable<int>(calls.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageDailyCompanion(')
          ..write('modelId: $modelId, ')
          ..write('providerName: $providerName, ')
          ..write('date: $date, ')
          ..write('promptTokens: $promptTokens, ')
          ..write('completionTokens: $completionTokens, ')
          ..write('calls: $calls, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenMediaTable extends GenMedia
    with TableInfo<$GenMediaTable, GenMediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prompt,
    modelId,
    path,
    type,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gen_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<GenMediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GenMediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenMediaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GenMediaTable createAlias(String alias) {
    return $GenMediaTable(attachedDatabase, alias);
  }
}

class GenMediaRow extends DataClass implements Insertable<GenMediaRow> {
  final String id;
  final String prompt;
  final String modelId;
  final String path;
  final String type;
  final int createdAt;
  const GenMediaRow({
    required this.id,
    required this.prompt,
    required this.modelId,
    required this.path,
    required this.type,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['prompt'] = Variable<String>(prompt);
    map['model_id'] = Variable<String>(modelId);
    map['path'] = Variable<String>(path);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  GenMediaCompanion toCompanion(bool nullToAbsent) {
    return GenMediaCompanion(
      id: Value(id),
      prompt: Value(prompt),
      modelId: Value(modelId),
      path: Value(path),
      type: Value(type),
      createdAt: Value(createdAt),
    );
  }

  factory GenMediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenMediaRow(
      id: serializer.fromJson<String>(json['id']),
      prompt: serializer.fromJson<String>(json['prompt']),
      modelId: serializer.fromJson<String>(json['modelId']),
      path: serializer.fromJson<String>(json['path']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prompt': serializer.toJson<String>(prompt),
      'modelId': serializer.toJson<String>(modelId),
      'path': serializer.toJson<String>(path),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  GenMediaRow copyWith({
    String? id,
    String? prompt,
    String? modelId,
    String? path,
    String? type,
    int? createdAt,
  }) => GenMediaRow(
    id: id ?? this.id,
    prompt: prompt ?? this.prompt,
    modelId: modelId ?? this.modelId,
    path: path ?? this.path,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );
  GenMediaRow copyWithCompanion(GenMediaCompanion data) {
    return GenMediaRow(
      id: data.id.present ? data.id.value : this.id,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      path: data.path.present ? data.path.value : this.path,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenMediaRow(')
          ..write('id: $id, ')
          ..write('prompt: $prompt, ')
          ..write('modelId: $modelId, ')
          ..write('path: $path, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, prompt, modelId, path, type, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenMediaRow &&
          other.id == this.id &&
          other.prompt == this.prompt &&
          other.modelId == this.modelId &&
          other.path == this.path &&
          other.type == this.type &&
          other.createdAt == this.createdAt);
}

class GenMediaCompanion extends UpdateCompanion<GenMediaRow> {
  final Value<String> id;
  final Value<String> prompt;
  final Value<String> modelId;
  final Value<String> path;
  final Value<String> type;
  final Value<int> createdAt;
  final Value<int> rowid;
  const GenMediaCompanion({
    this.id = const Value.absent(),
    this.prompt = const Value.absent(),
    this.modelId = const Value.absent(),
    this.path = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenMediaCompanion.insert({
    required String id,
    required String prompt,
    required String modelId,
    required String path,
    this.type = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       prompt = Value(prompt),
       modelId = Value(modelId),
       path = Value(path),
       createdAt = Value(createdAt);
  static Insertable<GenMediaRow> custom({
    Expression<String>? id,
    Expression<String>? prompt,
    Expression<String>? modelId,
    Expression<String>? path,
    Expression<String>? type,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prompt != null) 'prompt': prompt,
      if (modelId != null) 'model_id': modelId,
      if (path != null) 'path': path,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenMediaCompanion copyWith({
    Value<String>? id,
    Value<String>? prompt,
    Value<String>? modelId,
    Value<String>? path,
    Value<String>? type,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return GenMediaCompanion(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      modelId: modelId ?? this.modelId,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenMediaCompanion(')
          ..write('id: $id, ')
          ..write('prompt: $prompt, ')
          ..write('modelId: $modelId, ')
          ..write('path: $path, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KbLibrariesTable extends KbLibraries
    with TableInfo<$KbLibrariesTable, KbLibraryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbLibrariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_libraries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbLibraryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbLibraryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbLibraryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $KbLibrariesTable createAlias(String alias) {
    return $KbLibrariesTable(attachedDatabase, alias);
  }
}

class KbLibraryRow extends DataClass implements Insertable<KbLibraryRow> {
  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;
  const KbLibraryRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  KbLibrariesCompanion toCompanion(bool nullToAbsent) {
    return KbLibrariesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KbLibraryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbLibraryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  KbLibraryRow copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? updatedAt,
  }) => KbLibraryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KbLibraryRow copyWithCompanion(KbLibrariesCompanion data) {
    return KbLibraryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbLibraryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbLibraryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KbLibrariesCompanion extends UpdateCompanion<KbLibraryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const KbLibrariesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KbLibrariesCompanion.insert({
    required String id,
    required String name,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<KbLibraryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KbLibrariesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return KbLibrariesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbLibrariesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KbDocumentsTable extends KbDocuments
    with TableInfo<$KbDocumentsTable, KbDocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _libraryIdMeta = const VerificationMeta(
    'libraryId',
  );
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
    'library_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _embeddingModelMeta = const VerificationMeta(
    'embeddingModel',
  );
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
    'embedding_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chunkCountMeta = const VerificationMeta(
    'chunkCount',
  );
  @override
  late final GeneratedColumn<int> chunkCount = GeneratedColumn<int>(
    'chunk_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    source,
    libraryId,
    embeddingModel,
    chunkCount,
    enabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbDocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('library_id')) {
      context.handle(
        _libraryIdMeta,
        libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta),
      );
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
        _embeddingModelMeta,
        embeddingModel.isAcceptableOrUnknown(
          data['embedding_model']!,
          _embeddingModelMeta,
        ),
      );
    }
    if (data.containsKey('chunk_count')) {
      context.handle(
        _chunkCountMeta,
        chunkCount.isAcceptableOrUnknown(data['chunk_count']!, _chunkCountMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbDocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbDocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      libraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_id'],
      )!,
      embeddingModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_model'],
      ),
      chunkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_count'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $KbDocumentsTable createAlias(String alias) {
    return $KbDocumentsTable(attachedDatabase, alias);
  }
}

class KbDocumentRow extends DataClass implements Insertable<KbDocumentRow> {
  final String id;
  final String name;
  final String source;
  final String libraryId;
  final String? embeddingModel;
  final int chunkCount;
  final bool enabled;
  final int createdAt;
  final int updatedAt;
  const KbDocumentRow({
    required this.id,
    required this.name,
    required this.source,
    required this.libraryId,
    this.embeddingModel,
    required this.chunkCount,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    map['library_id'] = Variable<String>(libraryId);
    if (!nullToAbsent || embeddingModel != null) {
      map['embedding_model'] = Variable<String>(embeddingModel);
    }
    map['chunk_count'] = Variable<int>(chunkCount);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  KbDocumentsCompanion toCompanion(bool nullToAbsent) {
    return KbDocumentsCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      libraryId: Value(libraryId),
      embeddingModel: embeddingModel == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingModel),
      chunkCount: Value(chunkCount),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KbDocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbDocumentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      libraryId: serializer.fromJson<String>(json['libraryId']),
      embeddingModel: serializer.fromJson<String?>(json['embeddingModel']),
      chunkCount: serializer.fromJson<int>(json['chunkCount']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'libraryId': serializer.toJson<String>(libraryId),
      'embeddingModel': serializer.toJson<String?>(embeddingModel),
      'chunkCount': serializer.toJson<int>(chunkCount),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  KbDocumentRow copyWith({
    String? id,
    String? name,
    String? source,
    String? libraryId,
    Value<String?> embeddingModel = const Value.absent(),
    int? chunkCount,
    bool? enabled,
    int? createdAt,
    int? updatedAt,
  }) => KbDocumentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    libraryId: libraryId ?? this.libraryId,
    embeddingModel: embeddingModel.present
        ? embeddingModel.value
        : this.embeddingModel,
    chunkCount: chunkCount ?? this.chunkCount,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KbDocumentRow copyWithCompanion(KbDocumentsCompanion data) {
    return KbDocumentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      chunkCount: data.chunkCount.present
          ? data.chunkCount.value
          : this.chunkCount,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbDocumentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('libraryId: $libraryId, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    source,
    libraryId,
    embeddingModel,
    chunkCount,
    enabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbDocumentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.libraryId == this.libraryId &&
          other.embeddingModel == this.embeddingModel &&
          other.chunkCount == this.chunkCount &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KbDocumentsCompanion extends UpdateCompanion<KbDocumentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> source;
  final Value<String> libraryId;
  final Value<String?> embeddingModel;
  final Value<int> chunkCount;
  final Value<bool> enabled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const KbDocumentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.chunkCount = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KbDocumentsCompanion.insert({
    required String id,
    required String name,
    this.source = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.chunkCount = const Value.absent(),
    this.enabled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<KbDocumentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<String>? libraryId,
    Expression<String>? embeddingModel,
    Expression<int>? chunkCount,
    Expression<bool>? enabled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (libraryId != null) 'library_id': libraryId,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (chunkCount != null) 'chunk_count': chunkCount,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KbDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? source,
    Value<String>? libraryId,
    Value<String?>? embeddingModel,
    Value<int>? chunkCount,
    Value<bool>? enabled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return KbDocumentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      libraryId: libraryId ?? this.libraryId,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      chunkCount: chunkCount ?? this.chunkCount,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (chunkCount.present) {
      map['chunk_count'] = Variable<int>(chunkCount.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('libraryId: $libraryId, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KbChunksTable extends KbChunks
    with TableInfo<$KbChunksTable, KbChunkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _chunkTextMeta = const VerificationMeta(
    'chunkText',
  );
  @override
  late final GeneratedColumn<String> chunkText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokensMeta = const VerificationMeta('tokens');
  @override
  late final GeneratedColumn<int> tokens = GeneratedColumn<int>(
    'tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    docId,
    position,
    chunkText,
    tokens,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbChunkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _chunkTextMeta,
        chunkText.isAcceptableOrUnknown(data['text']!, _chunkTextMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkTextMeta);
    }
    if (data.containsKey('tokens')) {
      context.handle(
        _tokensMeta,
        tokens.isAcceptableOrUnknown(data['tokens']!, _tokensMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KbChunkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbChunkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      chunkText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      tokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens'],
      )!,
    );
  }

  @override
  $KbChunksTable createAlias(String alias) {
    return $KbChunksTable(attachedDatabase, alias);
  }
}

class KbChunkRow extends DataClass implements Insertable<KbChunkRow> {
  final String id;
  final String docId;
  final int position;
  final String chunkText;
  final int tokens;
  const KbChunkRow({
    required this.id,
    required this.docId,
    required this.position,
    required this.chunkText,
    required this.tokens,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['doc_id'] = Variable<String>(docId);
    map['position'] = Variable<int>(position);
    map['text'] = Variable<String>(chunkText);
    map['tokens'] = Variable<int>(tokens);
    return map;
  }

  KbChunksCompanion toCompanion(bool nullToAbsent) {
    return KbChunksCompanion(
      id: Value(id),
      docId: Value(docId),
      position: Value(position),
      chunkText: Value(chunkText),
      tokens: Value(tokens),
    );
  }

  factory KbChunkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbChunkRow(
      id: serializer.fromJson<String>(json['id']),
      docId: serializer.fromJson<String>(json['docId']),
      position: serializer.fromJson<int>(json['position']),
      chunkText: serializer.fromJson<String>(json['chunkText']),
      tokens: serializer.fromJson<int>(json['tokens']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'docId': serializer.toJson<String>(docId),
      'position': serializer.toJson<int>(position),
      'chunkText': serializer.toJson<String>(chunkText),
      'tokens': serializer.toJson<int>(tokens),
    };
  }

  KbChunkRow copyWith({
    String? id,
    String? docId,
    int? position,
    String? chunkText,
    int? tokens,
  }) => KbChunkRow(
    id: id ?? this.id,
    docId: docId ?? this.docId,
    position: position ?? this.position,
    chunkText: chunkText ?? this.chunkText,
    tokens: tokens ?? this.tokens,
  );
  KbChunkRow copyWithCompanion(KbChunksCompanion data) {
    return KbChunkRow(
      id: data.id.present ? data.id.value : this.id,
      docId: data.docId.present ? data.docId.value : this.docId,
      position: data.position.present ? data.position.value : this.position,
      chunkText: data.chunkText.present ? data.chunkText.value : this.chunkText,
      tokens: data.tokens.present ? data.tokens.value : this.tokens,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbChunkRow(')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('position: $position, ')
          ..write('chunkText: $chunkText, ')
          ..write('tokens: $tokens')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, docId, position, chunkText, tokens);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbChunkRow &&
          other.id == this.id &&
          other.docId == this.docId &&
          other.position == this.position &&
          other.chunkText == this.chunkText &&
          other.tokens == this.tokens);
}

class KbChunksCompanion extends UpdateCompanion<KbChunkRow> {
  final Value<String> id;
  final Value<String> docId;
  final Value<int> position;
  final Value<String> chunkText;
  final Value<int> tokens;
  final Value<int> rowid;
  const KbChunksCompanion({
    this.id = const Value.absent(),
    this.docId = const Value.absent(),
    this.position = const Value.absent(),
    this.chunkText = const Value.absent(),
    this.tokens = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KbChunksCompanion.insert({
    required String id,
    required String docId,
    this.position = const Value.absent(),
    required String chunkText,
    this.tokens = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       docId = Value(docId),
       chunkText = Value(chunkText);
  static Insertable<KbChunkRow> custom({
    Expression<String>? id,
    Expression<String>? docId,
    Expression<int>? position,
    Expression<String>? chunkText,
    Expression<int>? tokens,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (docId != null) 'doc_id': docId,
      if (position != null) 'position': position,
      if (chunkText != null) 'text': chunkText,
      if (tokens != null) 'tokens': tokens,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KbChunksCompanion copyWith({
    Value<String>? id,
    Value<String>? docId,
    Value<int>? position,
    Value<String>? chunkText,
    Value<int>? tokens,
    Value<int>? rowid,
  }) {
    return KbChunksCompanion(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      position: position ?? this.position,
      chunkText: chunkText ?? this.chunkText,
      tokens: tokens ?? this.tokens,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (chunkText.present) {
      map['text'] = Variable<String>(chunkText.value);
    }
    if (tokens.present) {
      map['tokens'] = Variable<int>(tokens.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbChunksCompanion(')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('position: $position, ')
          ..write('chunkText: $chunkText, ')
          ..write('tokens: $tokens, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KbBigramsTable extends KbBigrams
    with TableInfo<$KbBigramsTable, KbBigramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbBigramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bigramMeta = const VerificationMeta('bigram');
  @override
  late final GeneratedColumn<String> bigram = GeneratedColumn<String>(
    'bigram',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIdMeta = const VerificationMeta(
    'chunkId',
  );
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
    'chunk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_chunks (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [bigram, chunkId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_bigrams';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbBigramRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bigram')) {
      context.handle(
        _bigramMeta,
        bigram.isAcceptableOrUnknown(data['bigram']!, _bigramMeta),
      );
    } else if (isInserting) {
      context.missing(_bigramMeta);
    }
    if (data.containsKey('chunk_id')) {
      context.handle(
        _chunkIdMeta,
        chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bigram, chunkId};
  @override
  KbBigramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbBigramRow(
      bigram: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bigram'],
      )!,
      chunkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_id'],
      )!,
    );
  }

  @override
  $KbBigramsTable createAlias(String alias) {
    return $KbBigramsTable(attachedDatabase, alias);
  }
}

class KbBigramRow extends DataClass implements Insertable<KbBigramRow> {
  final String bigram;
  final String chunkId;
  const KbBigramRow({required this.bigram, required this.chunkId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bigram'] = Variable<String>(bigram);
    map['chunk_id'] = Variable<String>(chunkId);
    return map;
  }

  KbBigramsCompanion toCompanion(bool nullToAbsent) {
    return KbBigramsCompanion(bigram: Value(bigram), chunkId: Value(chunkId));
  }

  factory KbBigramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbBigramRow(
      bigram: serializer.fromJson<String>(json['bigram']),
      chunkId: serializer.fromJson<String>(json['chunkId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bigram': serializer.toJson<String>(bigram),
      'chunkId': serializer.toJson<String>(chunkId),
    };
  }

  KbBigramRow copyWith({String? bigram, String? chunkId}) => KbBigramRow(
    bigram: bigram ?? this.bigram,
    chunkId: chunkId ?? this.chunkId,
  );
  KbBigramRow copyWithCompanion(KbBigramsCompanion data) {
    return KbBigramRow(
      bigram: data.bigram.present ? data.bigram.value : this.bigram,
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbBigramRow(')
          ..write('bigram: $bigram, ')
          ..write('chunkId: $chunkId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bigram, chunkId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbBigramRow &&
          other.bigram == this.bigram &&
          other.chunkId == this.chunkId);
}

class KbBigramsCompanion extends UpdateCompanion<KbBigramRow> {
  final Value<String> bigram;
  final Value<String> chunkId;
  final Value<int> rowid;
  const KbBigramsCompanion({
    this.bigram = const Value.absent(),
    this.chunkId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KbBigramsCompanion.insert({
    required String bigram,
    required String chunkId,
    this.rowid = const Value.absent(),
  }) : bigram = Value(bigram),
       chunkId = Value(chunkId);
  static Insertable<KbBigramRow> custom({
    Expression<String>? bigram,
    Expression<String>? chunkId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bigram != null) 'bigram': bigram,
      if (chunkId != null) 'chunk_id': chunkId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KbBigramsCompanion copyWith({
    Value<String>? bigram,
    Value<String>? chunkId,
    Value<int>? rowid,
  }) {
    return KbBigramsCompanion(
      bigram: bigram ?? this.bigram,
      chunkId: chunkId ?? this.chunkId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bigram.present) {
      map['bigram'] = Variable<String>(bigram.value);
    }
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbBigramsCompanion(')
          ..write('bigram: $bigram, ')
          ..write('chunkId: $chunkId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KbVectorsTable extends KbVectors
    with TableInfo<$KbVectorsTable, KbVectorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KbVectorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chunkIdMeta = const VerificationMeta(
    'chunkId',
  );
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
    'chunk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kb_chunks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dimMeta = const VerificationMeta('dim');
  @override
  late final GeneratedColumn<int> dim = GeneratedColumn<int>(
    'dim',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vecMeta = const VerificationMeta('vec');
  @override
  late final GeneratedColumn<Uint8List> vec = GeneratedColumn<Uint8List>(
    'vec',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [chunkId, dim, vec];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kb_vectors';
  @override
  VerificationContext validateIntegrity(
    Insertable<KbVectorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chunk_id')) {
      context.handle(
        _chunkIdMeta,
        chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIdMeta);
    }
    if (data.containsKey('dim')) {
      context.handle(
        _dimMeta,
        dim.isAcceptableOrUnknown(data['dim']!, _dimMeta),
      );
    } else if (isInserting) {
      context.missing(_dimMeta);
    }
    if (data.containsKey('vec')) {
      context.handle(
        _vecMeta,
        vec.isAcceptableOrUnknown(data['vec']!, _vecMeta),
      );
    } else if (isInserting) {
      context.missing(_vecMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chunkId};
  @override
  KbVectorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KbVectorRow(
      chunkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_id'],
      )!,
      dim: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim'],
      )!,
      vec: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vec'],
      )!,
    );
  }

  @override
  $KbVectorsTable createAlias(String alias) {
    return $KbVectorsTable(attachedDatabase, alias);
  }
}

class KbVectorRow extends DataClass implements Insertable<KbVectorRow> {
  final String chunkId;
  final int dim;
  final Uint8List vec;
  const KbVectorRow({
    required this.chunkId,
    required this.dim,
    required this.vec,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chunk_id'] = Variable<String>(chunkId);
    map['dim'] = Variable<int>(dim);
    map['vec'] = Variable<Uint8List>(vec);
    return map;
  }

  KbVectorsCompanion toCompanion(bool nullToAbsent) {
    return KbVectorsCompanion(
      chunkId: Value(chunkId),
      dim: Value(dim),
      vec: Value(vec),
    );
  }

  factory KbVectorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KbVectorRow(
      chunkId: serializer.fromJson<String>(json['chunkId']),
      dim: serializer.fromJson<int>(json['dim']),
      vec: serializer.fromJson<Uint8List>(json['vec']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chunkId': serializer.toJson<String>(chunkId),
      'dim': serializer.toJson<int>(dim),
      'vec': serializer.toJson<Uint8List>(vec),
    };
  }

  KbVectorRow copyWith({String? chunkId, int? dim, Uint8List? vec}) =>
      KbVectorRow(
        chunkId: chunkId ?? this.chunkId,
        dim: dim ?? this.dim,
        vec: vec ?? this.vec,
      );
  KbVectorRow copyWithCompanion(KbVectorsCompanion data) {
    return KbVectorRow(
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
      dim: data.dim.present ? data.dim.value : this.dim,
      vec: data.vec.present ? data.vec.value : this.vec,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KbVectorRow(')
          ..write('chunkId: $chunkId, ')
          ..write('dim: $dim, ')
          ..write('vec: $vec')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chunkId, dim, $driftBlobEquality.hash(vec));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KbVectorRow &&
          other.chunkId == this.chunkId &&
          other.dim == this.dim &&
          $driftBlobEquality.equals(other.vec, this.vec));
}

class KbVectorsCompanion extends UpdateCompanion<KbVectorRow> {
  final Value<String> chunkId;
  final Value<int> dim;
  final Value<Uint8List> vec;
  final Value<int> rowid;
  const KbVectorsCompanion({
    this.chunkId = const Value.absent(),
    this.dim = const Value.absent(),
    this.vec = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KbVectorsCompanion.insert({
    required String chunkId,
    required int dim,
    required Uint8List vec,
    this.rowid = const Value.absent(),
  }) : chunkId = Value(chunkId),
       dim = Value(dim),
       vec = Value(vec);
  static Insertable<KbVectorRow> custom({
    Expression<String>? chunkId,
    Expression<int>? dim,
    Expression<Uint8List>? vec,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chunkId != null) 'chunk_id': chunkId,
      if (dim != null) 'dim': dim,
      if (vec != null) 'vec': vec,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KbVectorsCompanion copyWith({
    Value<String>? chunkId,
    Value<int>? dim,
    Value<Uint8List>? vec,
    Value<int>? rowid,
  }) {
    return KbVectorsCompanion(
      chunkId: chunkId ?? this.chunkId,
      dim: dim ?? this.dim,
      vec: vec ?? this.vec,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (dim.present) {
      map['dim'] = Variable<int>(dim.value);
    }
    if (vec.present) {
      map['vec'] = Variable<Uint8List>(vec.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KbVectorsCompanion(')
          ..write('chunkId: $chunkId, ')
          ..write('dim: $dim, ')
          ..write('vec: $vec, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoriesTable extends Memories
    with TableInfo<$MemoriesTable, MemoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeRefMeta = const VerificationMeta(
    'scopeRef',
  );
  @override
  late final GeneratedColumn<String> scopeRef = GeneratedColumn<String>(
    'scope_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fact'),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMessageIdMeta = const VerificationMeta(
    'sourceMessageId',
  );
  @override
  late final GeneratedColumn<String> sourceMessageId = GeneratedColumn<String>(
    'source_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _historyJsonMeta = const VerificationMeta(
    'historyJson',
  );
  @override
  late final GeneratedColumn<String> historyJson = GeneratedColumn<String>(
    'history_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scope,
    scopeRef,
    content,
    category,
    pinned,
    sourceMessageId,
    createdAt,
    updatedAt,
    tagsJson,
    priority,
    useCount,
    lastUsedAt,
    historyJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('scope_ref')) {
      context.handle(
        _scopeRefMeta,
        scopeRef.isAcceptableOrUnknown(data['scope_ref']!, _scopeRefMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('source_message_id')) {
      context.handle(
        _sourceMessageIdMeta,
        sourceMessageId.isAcceptableOrUnknown(
          data['source_message_id']!,
          _sourceMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('history_json')) {
      context.handle(
        _historyJsonMeta,
        historyJson.isAcceptableOrUnknown(
          data['history_json']!,
          _historyJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_ref'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      sourceMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_message_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      ),
      historyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_json'],
      )!,
    );
  }

  @override
  $MemoriesTable createAlias(String alias) {
    return $MemoriesTable(attachedDatabase, alias);
  }
}

class MemoryRow extends DataClass implements Insertable<MemoryRow> {
  final String id;
  final String scope;
  final String? scopeRef;
  final String content;
  final String category;
  final bool pinned;
  final String? sourceMessageId;
  final int createdAt;
  final int updatedAt;

  /// 标签列表（JSON 数组）。
  final String tagsJson;

  /// 优先级（auto/low/medium/high）。
  final String priority;

  /// 被注入次数（打分权重之一）。
  final int useCount;

  /// 最近一次被注入时间（ms 时间戳）。
  final int? lastUsedAt;

  /// 版本历史（JSON 数组，编辑留痕）。
  final String historyJson;
  const MemoryRow({
    required this.id,
    required this.scope,
    this.scopeRef,
    required this.content,
    required this.category,
    required this.pinned,
    this.sourceMessageId,
    required this.createdAt,
    required this.updatedAt,
    required this.tagsJson,
    required this.priority,
    required this.useCount,
    this.lastUsedAt,
    required this.historyJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || scopeRef != null) {
      map['scope_ref'] = Variable<String>(scopeRef);
    }
    map['content'] = Variable<String>(content);
    map['category'] = Variable<String>(category);
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || sourceMessageId != null) {
      map['source_message_id'] = Variable<String>(sourceMessageId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['tags_json'] = Variable<String>(tagsJson);
    map['priority'] = Variable<String>(priority);
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<int>(lastUsedAt);
    }
    map['history_json'] = Variable<String>(historyJson);
    return map;
  }

  MemoriesCompanion toCompanion(bool nullToAbsent) {
    return MemoriesCompanion(
      id: Value(id),
      scope: Value(scope),
      scopeRef: scopeRef == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeRef),
      content: Value(content),
      category: Value(category),
      pinned: Value(pinned),
      sourceMessageId: sourceMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMessageId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tagsJson: Value(tagsJson),
      priority: Value(priority),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      historyJson: Value(historyJson),
    );
  }

  factory MemoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryRow(
      id: serializer.fromJson<String>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      scopeRef: serializer.fromJson<String?>(json['scopeRef']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String>(json['category']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      sourceMessageId: serializer.fromJson<String?>(json['sourceMessageId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      priority: serializer.fromJson<String>(json['priority']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<int?>(json['lastUsedAt']),
      historyJson: serializer.fromJson<String>(json['historyJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scope': serializer.toJson<String>(scope),
      'scopeRef': serializer.toJson<String?>(scopeRef),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String>(category),
      'pinned': serializer.toJson<bool>(pinned),
      'sourceMessageId': serializer.toJson<String?>(sourceMessageId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'priority': serializer.toJson<String>(priority),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<int?>(lastUsedAt),
      'historyJson': serializer.toJson<String>(historyJson),
    };
  }

  MemoryRow copyWith({
    String? id,
    String? scope,
    Value<String?> scopeRef = const Value.absent(),
    String? content,
    String? category,
    bool? pinned,
    Value<String?> sourceMessageId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? tagsJson,
    String? priority,
    int? useCount,
    Value<int?> lastUsedAt = const Value.absent(),
    String? historyJson,
  }) => MemoryRow(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    scopeRef: scopeRef.present ? scopeRef.value : this.scopeRef,
    content: content ?? this.content,
    category: category ?? this.category,
    pinned: pinned ?? this.pinned,
    sourceMessageId: sourceMessageId.present
        ? sourceMessageId.value
        : this.sourceMessageId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    tagsJson: tagsJson ?? this.tagsJson,
    priority: priority ?? this.priority,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    historyJson: historyJson ?? this.historyJson,
  );
  MemoryRow copyWithCompanion(MemoriesCompanion data) {
    return MemoryRow(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeRef: data.scopeRef.present ? data.scopeRef.value : this.scopeRef,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      sourceMessageId: data.sourceMessageId.present
          ? data.sourceMessageId.value
          : this.sourceMessageId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      priority: data.priority.present ? data.priority.value : this.priority,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      historyJson: data.historyJson.present
          ? data.historyJson.value
          : this.historyJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryRow(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('pinned: $pinned, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('priority: $priority, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('historyJson: $historyJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scope,
    scopeRef,
    content,
    category,
    pinned,
    sourceMessageId,
    createdAt,
    updatedAt,
    tagsJson,
    priority,
    useCount,
    lastUsedAt,
    historyJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryRow &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.scopeRef == this.scopeRef &&
          other.content == this.content &&
          other.category == this.category &&
          other.pinned == this.pinned &&
          other.sourceMessageId == this.sourceMessageId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tagsJson == this.tagsJson &&
          other.priority == this.priority &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.historyJson == this.historyJson);
}

class MemoriesCompanion extends UpdateCompanion<MemoryRow> {
  final Value<String> id;
  final Value<String> scope;
  final Value<String?> scopeRef;
  final Value<String> content;
  final Value<String> category;
  final Value<bool> pinned;
  final Value<String?> sourceMessageId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> tagsJson;
  final Value<String> priority;
  final Value<int> useCount;
  final Value<int?> lastUsedAt;
  final Value<String> historyJson;
  final Value<int> rowid;
  const MemoriesCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeRef = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.pinned = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.priority = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.historyJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoriesCompanion.insert({
    required String id,
    required String scope,
    this.scopeRef = const Value.absent(),
    required String content,
    this.category = const Value.absent(),
    this.pinned = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.tagsJson = const Value.absent(),
    this.priority = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.historyJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scope = Value(scope),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MemoryRow> custom({
    Expression<String>? id,
    Expression<String>? scope,
    Expression<String>? scopeRef,
    Expression<String>? content,
    Expression<String>? category,
    Expression<bool>? pinned,
    Expression<String>? sourceMessageId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? tagsJson,
    Expression<String>? priority,
    Expression<int>? useCount,
    Expression<int>? lastUsedAt,
    Expression<String>? historyJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (scopeRef != null) 'scope_ref': scopeRef,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (pinned != null) 'pinned': pinned,
      if (sourceMessageId != null) 'source_message_id': sourceMessageId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (priority != null) 'priority': priority,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (historyJson != null) 'history_json': historyJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? scope,
    Value<String?>? scopeRef,
    Value<String>? content,
    Value<String>? category,
    Value<bool>? pinned,
    Value<String?>? sourceMessageId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? tagsJson,
    Value<String>? priority,
    Value<int>? useCount,
    Value<int?>? lastUsedAt,
    Value<String>? historyJson,
    Value<int>? rowid,
  }) {
    return MemoriesCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      scopeRef: scopeRef ?? this.scopeRef,
      content: content ?? this.content,
      category: category ?? this.category,
      pinned: pinned ?? this.pinned,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tagsJson: tagsJson ?? this.tagsJson,
      priority: priority ?? this.priority,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      historyJson: historyJson ?? this.historyJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeRef.present) {
      map['scope_ref'] = Variable<String>(scopeRef.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (sourceMessageId.present) {
      map['source_message_id'] = Variable<String>(sourceMessageId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (historyJson.present) {
      map['history_json'] = Variable<String>(historyJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoriesCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('pinned: $pinned, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('priority: $priority, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('historyJson: $historyJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemorySpacesTable extends MemorySpaces
    with TableInfo<$MemorySpacesTable, MemorySpaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorySpacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeRefMeta = const VerificationMeta(
    'scopeRef',
  );
  @override
  late final GeneratedColumn<String> scopeRef = GeneratedColumn<String>(
    'scope_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _maxItemsMeta = const VerificationMeta(
    'maxItems',
  );
  @override
  late final GeneratedColumn<int> maxItems = GeneratedColumn<int>(
    'max_items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(200),
  );
  static const VerificationMeta _maxInjectTokensMeta = const VerificationMeta(
    'maxInjectTokens',
  );
  @override
  late final GeneratedColumn<int> maxInjectTokens = GeneratedColumn<int>(
    'max_inject_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(800),
  );
  static const VerificationMeta _maxItemCharsMeta = const VerificationMeta(
    'maxItemChars',
  );
  @override
  late final GeneratedColumn<int> maxItemChars = GeneratedColumn<int>(
    'max_item_chars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _extractionIntervalMeta =
      const VerificationMeta('extractionInterval');
  @override
  late final GeneratedColumn<int> extractionInterval = GeneratedColumn<int>(
    'extraction_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scope,
    scopeRef,
    maxItems,
    maxInjectTokens,
    maxItemChars,
    extractionInterval,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_spaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorySpaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('scope_ref')) {
      context.handle(
        _scopeRefMeta,
        scopeRef.isAcceptableOrUnknown(data['scope_ref']!, _scopeRefMeta),
      );
    }
    if (data.containsKey('max_items')) {
      context.handle(
        _maxItemsMeta,
        maxItems.isAcceptableOrUnknown(data['max_items']!, _maxItemsMeta),
      );
    }
    if (data.containsKey('max_inject_tokens')) {
      context.handle(
        _maxInjectTokensMeta,
        maxInjectTokens.isAcceptableOrUnknown(
          data['max_inject_tokens']!,
          _maxInjectTokensMeta,
        ),
      );
    }
    if (data.containsKey('max_item_chars')) {
      context.handle(
        _maxItemCharsMeta,
        maxItemChars.isAcceptableOrUnknown(
          data['max_item_chars']!,
          _maxItemCharsMeta,
        ),
      );
    }
    if (data.containsKey('extraction_interval')) {
      context.handle(
        _extractionIntervalMeta,
        extractionInterval.isAcceptableOrUnknown(
          data['extraction_interval']!,
          _extractionIntervalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorySpaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorySpaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_ref'],
      )!,
      maxItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_items'],
      )!,
      maxInjectTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_inject_tokens'],
      )!,
      maxItemChars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_item_chars'],
      )!,
      extractionInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extraction_interval'],
      )!,
    );
  }

  @override
  $MemorySpacesTable createAlias(String alias) {
    return $MemorySpacesTable(attachedDatabase, alias);
  }
}

class MemorySpaceRow extends DataClass implements Insertable<MemorySpaceRow> {
  final String id;
  final String scope;
  final String scopeRef;
  final int maxItems;
  final int maxInjectTokens;
  final int maxItemChars;
  final int extractionInterval;
  const MemorySpaceRow({
    required this.id,
    required this.scope,
    required this.scopeRef,
    required this.maxItems,
    required this.maxInjectTokens,
    required this.maxItemChars,
    required this.extractionInterval,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope'] = Variable<String>(scope);
    map['scope_ref'] = Variable<String>(scopeRef);
    map['max_items'] = Variable<int>(maxItems);
    map['max_inject_tokens'] = Variable<int>(maxInjectTokens);
    map['max_item_chars'] = Variable<int>(maxItemChars);
    map['extraction_interval'] = Variable<int>(extractionInterval);
    return map;
  }

  MemorySpacesCompanion toCompanion(bool nullToAbsent) {
    return MemorySpacesCompanion(
      id: Value(id),
      scope: Value(scope),
      scopeRef: Value(scopeRef),
      maxItems: Value(maxItems),
      maxInjectTokens: Value(maxInjectTokens),
      maxItemChars: Value(maxItemChars),
      extractionInterval: Value(extractionInterval),
    );
  }

  factory MemorySpaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorySpaceRow(
      id: serializer.fromJson<String>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      scopeRef: serializer.fromJson<String>(json['scopeRef']),
      maxItems: serializer.fromJson<int>(json['maxItems']),
      maxInjectTokens: serializer.fromJson<int>(json['maxInjectTokens']),
      maxItemChars: serializer.fromJson<int>(json['maxItemChars']),
      extractionInterval: serializer.fromJson<int>(json['extractionInterval']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scope': serializer.toJson<String>(scope),
      'scopeRef': serializer.toJson<String>(scopeRef),
      'maxItems': serializer.toJson<int>(maxItems),
      'maxInjectTokens': serializer.toJson<int>(maxInjectTokens),
      'maxItemChars': serializer.toJson<int>(maxItemChars),
      'extractionInterval': serializer.toJson<int>(extractionInterval),
    };
  }

  MemorySpaceRow copyWith({
    String? id,
    String? scope,
    String? scopeRef,
    int? maxItems,
    int? maxInjectTokens,
    int? maxItemChars,
    int? extractionInterval,
  }) => MemorySpaceRow(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    scopeRef: scopeRef ?? this.scopeRef,
    maxItems: maxItems ?? this.maxItems,
    maxInjectTokens: maxInjectTokens ?? this.maxInjectTokens,
    maxItemChars: maxItemChars ?? this.maxItemChars,
    extractionInterval: extractionInterval ?? this.extractionInterval,
  );
  MemorySpaceRow copyWithCompanion(MemorySpacesCompanion data) {
    return MemorySpaceRow(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeRef: data.scopeRef.present ? data.scopeRef.value : this.scopeRef,
      maxItems: data.maxItems.present ? data.maxItems.value : this.maxItems,
      maxInjectTokens: data.maxInjectTokens.present
          ? data.maxInjectTokens.value
          : this.maxInjectTokens,
      maxItemChars: data.maxItemChars.present
          ? data.maxItemChars.value
          : this.maxItemChars,
      extractionInterval: data.extractionInterval.present
          ? data.extractionInterval.value
          : this.extractionInterval,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorySpaceRow(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('maxItems: $maxItems, ')
          ..write('maxInjectTokens: $maxInjectTokens, ')
          ..write('maxItemChars: $maxItemChars, ')
          ..write('extractionInterval: $extractionInterval')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scope,
    scopeRef,
    maxItems,
    maxInjectTokens,
    maxItemChars,
    extractionInterval,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorySpaceRow &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.scopeRef == this.scopeRef &&
          other.maxItems == this.maxItems &&
          other.maxInjectTokens == this.maxInjectTokens &&
          other.maxItemChars == this.maxItemChars &&
          other.extractionInterval == this.extractionInterval);
}

class MemorySpacesCompanion extends UpdateCompanion<MemorySpaceRow> {
  final Value<String> id;
  final Value<String> scope;
  final Value<String> scopeRef;
  final Value<int> maxItems;
  final Value<int> maxInjectTokens;
  final Value<int> maxItemChars;
  final Value<int> extractionInterval;
  final Value<int> rowid;
  const MemorySpacesCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeRef = const Value.absent(),
    this.maxItems = const Value.absent(),
    this.maxInjectTokens = const Value.absent(),
    this.maxItemChars = const Value.absent(),
    this.extractionInterval = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemorySpacesCompanion.insert({
    required String id,
    required String scope,
    this.scopeRef = const Value.absent(),
    this.maxItems = const Value.absent(),
    this.maxInjectTokens = const Value.absent(),
    this.maxItemChars = const Value.absent(),
    this.extractionInterval = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scope = Value(scope);
  static Insertable<MemorySpaceRow> custom({
    Expression<String>? id,
    Expression<String>? scope,
    Expression<String>? scopeRef,
    Expression<int>? maxItems,
    Expression<int>? maxInjectTokens,
    Expression<int>? maxItemChars,
    Expression<int>? extractionInterval,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (scopeRef != null) 'scope_ref': scopeRef,
      if (maxItems != null) 'max_items': maxItems,
      if (maxInjectTokens != null) 'max_inject_tokens': maxInjectTokens,
      if (maxItemChars != null) 'max_item_chars': maxItemChars,
      if (extractionInterval != null) 'extraction_interval': extractionInterval,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemorySpacesCompanion copyWith({
    Value<String>? id,
    Value<String>? scope,
    Value<String>? scopeRef,
    Value<int>? maxItems,
    Value<int>? maxInjectTokens,
    Value<int>? maxItemChars,
    Value<int>? extractionInterval,
    Value<int>? rowid,
  }) {
    return MemorySpacesCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      scopeRef: scopeRef ?? this.scopeRef,
      maxItems: maxItems ?? this.maxItems,
      maxInjectTokens: maxInjectTokens ?? this.maxInjectTokens,
      maxItemChars: maxItemChars ?? this.maxItemChars,
      extractionInterval: extractionInterval ?? this.extractionInterval,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeRef.present) {
      map['scope_ref'] = Variable<String>(scopeRef.value);
    }
    if (maxItems.present) {
      map['max_items'] = Variable<int>(maxItems.value);
    }
    if (maxInjectTokens.present) {
      map['max_inject_tokens'] = Variable<int>(maxInjectTokens.value);
    }
    if (maxItemChars.present) {
      map['max_item_chars'] = Variable<int>(maxItemChars.value);
    }
    if (extractionInterval.present) {
      map['extraction_interval'] = Variable<int>(extractionInterval.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorySpacesCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('maxItems: $maxItems, ')
          ..write('maxInjectTokens: $maxInjectTokens, ')
          ..write('maxItemChars: $maxItemChars, ')
          ..write('extractionInterval: $extractionInterval, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryStateTable extends MemoryState
    with TableInfo<$MemoryStateTable, MemoryStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastIndexMeta = const VerificationMeta(
    'lastIndex',
  );
  @override
  late final GeneratedColumn<int> lastIndex = GeneratedColumn<int>(
    'last_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, lastIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('last_index')) {
      context.handle(
        _lastIndexMeta,
        lastIndex.isAcceptableOrUnknown(data['last_index']!, _lastIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  MemoryStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryStateRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      lastIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_index'],
      )!,
    );
  }

  @override
  $MemoryStateTable createAlias(String alias) {
    return $MemoryStateTable(attachedDatabase, alias);
  }
}

class MemoryStateRow extends DataClass implements Insertable<MemoryStateRow> {
  final String sessionId;
  final int lastIndex;
  const MemoryStateRow({required this.sessionId, required this.lastIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['last_index'] = Variable<int>(lastIndex);
    return map;
  }

  MemoryStateCompanion toCompanion(bool nullToAbsent) {
    return MemoryStateCompanion(
      sessionId: Value(sessionId),
      lastIndex: Value(lastIndex),
    );
  }

  factory MemoryStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryStateRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      lastIndex: serializer.fromJson<int>(json['lastIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'lastIndex': serializer.toJson<int>(lastIndex),
    };
  }

  MemoryStateRow copyWith({String? sessionId, int? lastIndex}) =>
      MemoryStateRow(
        sessionId: sessionId ?? this.sessionId,
        lastIndex: lastIndex ?? this.lastIndex,
      );
  MemoryStateRow copyWithCompanion(MemoryStateCompanion data) {
    return MemoryStateRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lastIndex: data.lastIndex.present ? data.lastIndex.value : this.lastIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryStateRow(')
          ..write('sessionId: $sessionId, ')
          ..write('lastIndex: $lastIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, lastIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryStateRow &&
          other.sessionId == this.sessionId &&
          other.lastIndex == this.lastIndex);
}

class MemoryStateCompanion extends UpdateCompanion<MemoryStateRow> {
  final Value<String> sessionId;
  final Value<int> lastIndex;
  final Value<int> rowid;
  const MemoryStateCompanion({
    this.sessionId = const Value.absent(),
    this.lastIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryStateCompanion.insert({
    required String sessionId,
    this.lastIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<MemoryStateRow> custom({
    Expression<String>? sessionId,
    Expression<int>? lastIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (lastIndex != null) 'last_index': lastIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryStateCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? lastIndex,
    Value<int>? rowid,
  }) {
    return MemoryStateCompanion(
      sessionId: sessionId ?? this.sessionId,
      lastIndex: lastIndex ?? this.lastIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (lastIndex.present) {
      map['last_index'] = Variable<int>(lastIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryStateCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('lastIndex: $lastIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorldBookEntriesTable extends WorldBookEntries
    with TableInfo<$WorldBookEntriesTable, WorldBookEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldBookEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordsJsonMeta = const VerificationMeta(
    'keywordsJson',
  );
  @override
  late final GeneratedColumn<String> keywordsJson = GeneratedColumn<String>(
    'keywords_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _scanDepthMeta = const VerificationMeta(
    'scanDepth',
  );
  @override
  late final GeneratedColumn<int> scanDepth = GeneratedColumn<int>(
    'scan_depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _caseSensitiveMeta = const VerificationMeta(
    'caseSensitive',
  );
  @override
  late final GeneratedColumn<bool> caseSensitive = GeneratedColumn<bool>(
    'case_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("case_sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _injectionPositionMeta = const VerificationMeta(
    'injectionPosition',
  );
  @override
  late final GeneratedColumn<String> injectionPosition =
      GeneratedColumn<String>(
        'injection_position',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('top_of_chat'),
      );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _constantActiveMeta = const VerificationMeta(
    'constantActive',
  );
  @override
  late final GeneratedColumn<bool> constantActive = GeneratedColumn<bool>(
    'constant_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("constant_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('global'),
  );
  static const VerificationMeta _scopeRefMeta = const VerificationMeta(
    'scopeRef',
  );
  @override
  late final GeneratedColumn<String> scopeRef = GeneratedColumn<String>(
    'scope_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _useRegexMeta = const VerificationMeta(
    'useRegex',
  );
  @override
  late final GeneratedColumn<bool> useRegex = GeneratedColumn<bool>(
    'use_regex',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_regex" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _injectDepthMeta = const VerificationMeta(
    'injectDepth',
  );
  @override
  late final GeneratedColumn<int> injectDepth = GeneratedColumn<int>(
    'inject_depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    keywordsJson,
    content,
    priority,
    scanDepth,
    caseSensitive,
    injectionPosition,
    role,
    constantActive,
    scope,
    scopeRef,
    enabled,
    useRegex,
    bookId,
    injectDepth,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'world_book_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorldBookEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('keywords_json')) {
      context.handle(
        _keywordsJsonMeta,
        keywordsJson.isAcceptableOrUnknown(
          data['keywords_json']!,
          _keywordsJsonMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('scan_depth')) {
      context.handle(
        _scanDepthMeta,
        scanDepth.isAcceptableOrUnknown(data['scan_depth']!, _scanDepthMeta),
      );
    }
    if (data.containsKey('case_sensitive')) {
      context.handle(
        _caseSensitiveMeta,
        caseSensitive.isAcceptableOrUnknown(
          data['case_sensitive']!,
          _caseSensitiveMeta,
        ),
      );
    }
    if (data.containsKey('injection_position')) {
      context.handle(
        _injectionPositionMeta,
        injectionPosition.isAcceptableOrUnknown(
          data['injection_position']!,
          _injectionPositionMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('constant_active')) {
      context.handle(
        _constantActiveMeta,
        constantActive.isAcceptableOrUnknown(
          data['constant_active']!,
          _constantActiveMeta,
        ),
      );
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    }
    if (data.containsKey('scope_ref')) {
      context.handle(
        _scopeRefMeta,
        scopeRef.isAcceptableOrUnknown(data['scope_ref']!, _scopeRefMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('use_regex')) {
      context.handle(
        _useRegexMeta,
        useRegex.isAcceptableOrUnknown(data['use_regex']!, _useRegexMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('inject_depth')) {
      context.handle(
        _injectDepthMeta,
        injectDepth.isAcceptableOrUnknown(
          data['inject_depth']!,
          _injectDepthMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorldBookEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorldBookEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      keywordsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords_json'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      scanDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_depth'],
      )!,
      caseSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}case_sensitive'],
      )!,
      injectionPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}injection_position'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      constantActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}constant_active'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_ref'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      useRegex: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_regex'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      ),
      injectDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inject_depth'],
      )!,
    );
  }

  @override
  $WorldBookEntriesTable createAlias(String alias) {
    return $WorldBookEntriesTable(attachedDatabase, alias);
  }
}

class WorldBookEntryRow extends DataClass
    implements Insertable<WorldBookEntryRow> {
  final String id;
  final String title;
  final String keywordsJson;
  final String content;
  final int priority;
  final int scanDepth;
  final bool caseSensitive;
  final String injectionPosition;
  final String role;
  final bool constantActive;
  final String scope;
  final String? scopeRef;
  final bool enabled;

  /// v6：正则匹配开关（D-06）。
  final bool useRegex;

  /// v6：所属书 id（D-06；null = 默认书）。
  final String? bookId;

  /// D-06：深度注入——第 N 轮用户消息后才注入（at_depth 位置配合）。
  final int injectDepth;
  const WorldBookEntryRow({
    required this.id,
    required this.title,
    required this.keywordsJson,
    required this.content,
    required this.priority,
    required this.scanDepth,
    required this.caseSensitive,
    required this.injectionPosition,
    required this.role,
    required this.constantActive,
    required this.scope,
    this.scopeRef,
    required this.enabled,
    required this.useRegex,
    this.bookId,
    required this.injectDepth,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['keywords_json'] = Variable<String>(keywordsJson);
    map['content'] = Variable<String>(content);
    map['priority'] = Variable<int>(priority);
    map['scan_depth'] = Variable<int>(scanDepth);
    map['case_sensitive'] = Variable<bool>(caseSensitive);
    map['injection_position'] = Variable<String>(injectionPosition);
    map['role'] = Variable<String>(role);
    map['constant_active'] = Variable<bool>(constantActive);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || scopeRef != null) {
      map['scope_ref'] = Variable<String>(scopeRef);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['use_regex'] = Variable<bool>(useRegex);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    map['inject_depth'] = Variable<int>(injectDepth);
    return map;
  }

  WorldBookEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorldBookEntriesCompanion(
      id: Value(id),
      title: Value(title),
      keywordsJson: Value(keywordsJson),
      content: Value(content),
      priority: Value(priority),
      scanDepth: Value(scanDepth),
      caseSensitive: Value(caseSensitive),
      injectionPosition: Value(injectionPosition),
      role: Value(role),
      constantActive: Value(constantActive),
      scope: Value(scope),
      scopeRef: scopeRef == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeRef),
      enabled: Value(enabled),
      useRegex: Value(useRegex),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      injectDepth: Value(injectDepth),
    );
  }

  factory WorldBookEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorldBookEntryRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      keywordsJson: serializer.fromJson<String>(json['keywordsJson']),
      content: serializer.fromJson<String>(json['content']),
      priority: serializer.fromJson<int>(json['priority']),
      scanDepth: serializer.fromJson<int>(json['scanDepth']),
      caseSensitive: serializer.fromJson<bool>(json['caseSensitive']),
      injectionPosition: serializer.fromJson<String>(json['injectionPosition']),
      role: serializer.fromJson<String>(json['role']),
      constantActive: serializer.fromJson<bool>(json['constantActive']),
      scope: serializer.fromJson<String>(json['scope']),
      scopeRef: serializer.fromJson<String?>(json['scopeRef']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      useRegex: serializer.fromJson<bool>(json['useRegex']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      injectDepth: serializer.fromJson<int>(json['injectDepth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'keywordsJson': serializer.toJson<String>(keywordsJson),
      'content': serializer.toJson<String>(content),
      'priority': serializer.toJson<int>(priority),
      'scanDepth': serializer.toJson<int>(scanDepth),
      'caseSensitive': serializer.toJson<bool>(caseSensitive),
      'injectionPosition': serializer.toJson<String>(injectionPosition),
      'role': serializer.toJson<String>(role),
      'constantActive': serializer.toJson<bool>(constantActive),
      'scope': serializer.toJson<String>(scope),
      'scopeRef': serializer.toJson<String?>(scopeRef),
      'enabled': serializer.toJson<bool>(enabled),
      'useRegex': serializer.toJson<bool>(useRegex),
      'bookId': serializer.toJson<String?>(bookId),
      'injectDepth': serializer.toJson<int>(injectDepth),
    };
  }

  WorldBookEntryRow copyWith({
    String? id,
    String? title,
    String? keywordsJson,
    String? content,
    int? priority,
    int? scanDepth,
    bool? caseSensitive,
    String? injectionPosition,
    String? role,
    bool? constantActive,
    String? scope,
    Value<String?> scopeRef = const Value.absent(),
    bool? enabled,
    bool? useRegex,
    Value<String?> bookId = const Value.absent(),
    int? injectDepth,
  }) => WorldBookEntryRow(
    id: id ?? this.id,
    title: title ?? this.title,
    keywordsJson: keywordsJson ?? this.keywordsJson,
    content: content ?? this.content,
    priority: priority ?? this.priority,
    scanDepth: scanDepth ?? this.scanDepth,
    caseSensitive: caseSensitive ?? this.caseSensitive,
    injectionPosition: injectionPosition ?? this.injectionPosition,
    role: role ?? this.role,
    constantActive: constantActive ?? this.constantActive,
    scope: scope ?? this.scope,
    scopeRef: scopeRef.present ? scopeRef.value : this.scopeRef,
    enabled: enabled ?? this.enabled,
    useRegex: useRegex ?? this.useRegex,
    bookId: bookId.present ? bookId.value : this.bookId,
    injectDepth: injectDepth ?? this.injectDepth,
  );
  WorldBookEntryRow copyWithCompanion(WorldBookEntriesCompanion data) {
    return WorldBookEntryRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      keywordsJson: data.keywordsJson.present
          ? data.keywordsJson.value
          : this.keywordsJson,
      content: data.content.present ? data.content.value : this.content,
      priority: data.priority.present ? data.priority.value : this.priority,
      scanDepth: data.scanDepth.present ? data.scanDepth.value : this.scanDepth,
      caseSensitive: data.caseSensitive.present
          ? data.caseSensitive.value
          : this.caseSensitive,
      injectionPosition: data.injectionPosition.present
          ? data.injectionPosition.value
          : this.injectionPosition,
      role: data.role.present ? data.role.value : this.role,
      constantActive: data.constantActive.present
          ? data.constantActive.value
          : this.constantActive,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeRef: data.scopeRef.present ? data.scopeRef.value : this.scopeRef,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      useRegex: data.useRegex.present ? data.useRegex.value : this.useRegex,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      injectDepth: data.injectDepth.present
          ? data.injectDepth.value
          : this.injectDepth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorldBookEntryRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('keywordsJson: $keywordsJson, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('scanDepth: $scanDepth, ')
          ..write('caseSensitive: $caseSensitive, ')
          ..write('injectionPosition: $injectionPosition, ')
          ..write('role: $role, ')
          ..write('constantActive: $constantActive, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('enabled: $enabled, ')
          ..write('useRegex: $useRegex, ')
          ..write('bookId: $bookId, ')
          ..write('injectDepth: $injectDepth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    keywordsJson,
    content,
    priority,
    scanDepth,
    caseSensitive,
    injectionPosition,
    role,
    constantActive,
    scope,
    scopeRef,
    enabled,
    useRegex,
    bookId,
    injectDepth,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorldBookEntryRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.keywordsJson == this.keywordsJson &&
          other.content == this.content &&
          other.priority == this.priority &&
          other.scanDepth == this.scanDepth &&
          other.caseSensitive == this.caseSensitive &&
          other.injectionPosition == this.injectionPosition &&
          other.role == this.role &&
          other.constantActive == this.constantActive &&
          other.scope == this.scope &&
          other.scopeRef == this.scopeRef &&
          other.enabled == this.enabled &&
          other.useRegex == this.useRegex &&
          other.bookId == this.bookId &&
          other.injectDepth == this.injectDepth);
}

class WorldBookEntriesCompanion extends UpdateCompanion<WorldBookEntryRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> keywordsJson;
  final Value<String> content;
  final Value<int> priority;
  final Value<int> scanDepth;
  final Value<bool> caseSensitive;
  final Value<String> injectionPosition;
  final Value<String> role;
  final Value<bool> constantActive;
  final Value<String> scope;
  final Value<String?> scopeRef;
  final Value<bool> enabled;
  final Value<bool> useRegex;
  final Value<String?> bookId;
  final Value<int> injectDepth;
  final Value<int> rowid;
  const WorldBookEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.keywordsJson = const Value.absent(),
    this.content = const Value.absent(),
    this.priority = const Value.absent(),
    this.scanDepth = const Value.absent(),
    this.caseSensitive = const Value.absent(),
    this.injectionPosition = const Value.absent(),
    this.role = const Value.absent(),
    this.constantActive = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeRef = const Value.absent(),
    this.enabled = const Value.absent(),
    this.useRegex = const Value.absent(),
    this.bookId = const Value.absent(),
    this.injectDepth = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldBookEntriesCompanion.insert({
    required String id,
    required String title,
    this.keywordsJson = const Value.absent(),
    required String content,
    this.priority = const Value.absent(),
    this.scanDepth = const Value.absent(),
    this.caseSensitive = const Value.absent(),
    this.injectionPosition = const Value.absent(),
    this.role = const Value.absent(),
    this.constantActive = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeRef = const Value.absent(),
    this.enabled = const Value.absent(),
    this.useRegex = const Value.absent(),
    this.bookId = const Value.absent(),
    this.injectDepth = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content);
  static Insertable<WorldBookEntryRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? keywordsJson,
    Expression<String>? content,
    Expression<int>? priority,
    Expression<int>? scanDepth,
    Expression<bool>? caseSensitive,
    Expression<String>? injectionPosition,
    Expression<String>? role,
    Expression<bool>? constantActive,
    Expression<String>? scope,
    Expression<String>? scopeRef,
    Expression<bool>? enabled,
    Expression<bool>? useRegex,
    Expression<String>? bookId,
    Expression<int>? injectDepth,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (keywordsJson != null) 'keywords_json': keywordsJson,
      if (content != null) 'content': content,
      if (priority != null) 'priority': priority,
      if (scanDepth != null) 'scan_depth': scanDepth,
      if (caseSensitive != null) 'case_sensitive': caseSensitive,
      if (injectionPosition != null) 'injection_position': injectionPosition,
      if (role != null) 'role': role,
      if (constantActive != null) 'constant_active': constantActive,
      if (scope != null) 'scope': scope,
      if (scopeRef != null) 'scope_ref': scopeRef,
      if (enabled != null) 'enabled': enabled,
      if (useRegex != null) 'use_regex': useRegex,
      if (bookId != null) 'book_id': bookId,
      if (injectDepth != null) 'inject_depth': injectDepth,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldBookEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? keywordsJson,
    Value<String>? content,
    Value<int>? priority,
    Value<int>? scanDepth,
    Value<bool>? caseSensitive,
    Value<String>? injectionPosition,
    Value<String>? role,
    Value<bool>? constantActive,
    Value<String>? scope,
    Value<String?>? scopeRef,
    Value<bool>? enabled,
    Value<bool>? useRegex,
    Value<String?>? bookId,
    Value<int>? injectDepth,
    Value<int>? rowid,
  }) {
    return WorldBookEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      keywordsJson: keywordsJson ?? this.keywordsJson,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      scanDepth: scanDepth ?? this.scanDepth,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      injectionPosition: injectionPosition ?? this.injectionPosition,
      role: role ?? this.role,
      constantActive: constantActive ?? this.constantActive,
      scope: scope ?? this.scope,
      scopeRef: scopeRef ?? this.scopeRef,
      enabled: enabled ?? this.enabled,
      useRegex: useRegex ?? this.useRegex,
      bookId: bookId ?? this.bookId,
      injectDepth: injectDepth ?? this.injectDepth,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (keywordsJson.present) {
      map['keywords_json'] = Variable<String>(keywordsJson.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (scanDepth.present) {
      map['scan_depth'] = Variable<int>(scanDepth.value);
    }
    if (caseSensitive.present) {
      map['case_sensitive'] = Variable<bool>(caseSensitive.value);
    }
    if (injectionPosition.present) {
      map['injection_position'] = Variable<String>(injectionPosition.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (constantActive.present) {
      map['constant_active'] = Variable<bool>(constantActive.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeRef.present) {
      map['scope_ref'] = Variable<String>(scopeRef.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (useRegex.present) {
      map['use_regex'] = Variable<bool>(useRegex.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (injectDepth.present) {
      map['inject_depth'] = Variable<int>(injectDepth.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldBookEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('keywordsJson: $keywordsJson, ')
          ..write('content: $content, ')
          ..write('priority: $priority, ')
          ..write('scanDepth: $scanDepth, ')
          ..write('caseSensitive: $caseSensitive, ')
          ..write('injectionPosition: $injectionPosition, ')
          ..write('role: $role, ')
          ..write('constantActive: $constantActive, ')
          ..write('scope: $scope, ')
          ..write('scopeRef: $scopeRef, ')
          ..write('enabled: $enabled, ')
          ..write('useRegex: $useRegex, ')
          ..write('bookId: $bookId, ')
          ..write('injectDepth: $injectDepth, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorldBooksTable extends WorldBooks
    with TableInfo<$WorldBooksTable, WorldBookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    enabled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'world_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorldBookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorldBookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorldBookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WorldBooksTable createAlias(String alias) {
    return $WorldBooksTable(attachedDatabase, alias);
  }
}

class WorldBookRow extends DataClass implements Insertable<WorldBookRow> {
  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final int sortOrder;
  const WorldBookRow({
    required this.id,
    required this.name,
    this.description,
    required this.enabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WorldBooksCompanion toCompanion(bool nullToAbsent) {
    return WorldBooksCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      enabled: Value(enabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory WorldBookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorldBookRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'enabled': serializer.toJson<bool>(enabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WorldBookRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? enabled,
    int? sortOrder,
  }) => WorldBookRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WorldBookRow copyWithCompanion(WorldBooksCompanion data) {
    return WorldBookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorldBookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, enabled, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorldBookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.enabled == this.enabled &&
          other.sortOrder == this.sortOrder);
}

class WorldBooksCompanion extends UpdateCompanion<WorldBookRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> enabled;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WorldBooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldBooksCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorldBookRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? enabled,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (enabled != null) 'enabled': enabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldBooksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? enabled,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WorldBooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldBooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderGroupsTable extends ProviderGroups
    with TableInfo<$ProviderGroupsTable, ProviderGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $ProviderGroupsTable createAlias(String alias) {
    return $ProviderGroupsTable(attachedDatabase, alias);
  }
}

class ProviderGroupRow extends DataClass
    implements Insertable<ProviderGroupRow> {
  final String id;
  final String name;
  final int sortOrder;
  final String? color;
  const ProviderGroupRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.color,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  ProviderGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProviderGroupsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory ProviderGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'color': serializer.toJson<String?>(color),
    };
  }

  ProviderGroupRow copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Value<String?> color = const Value.absent(),
  }) => ProviderGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    color: color.present ? color.value : this.color,
  );
  ProviderGroupRow copyWithCompanion(ProviderGroupsCompanion data) {
    return ProviderGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.color == this.color);
}

class ProviderGroupsCompanion extends UpdateCompanion<ProviderGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String?> color;
  final Value<int> rowid;
  const ProviderGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderGroupsCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ProviderGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String?>? color,
    Value<int>? rowid,
  }) {
    return ProviderGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchKeysTable extends SearchKeys
    with TableInfo<$SearchKeysTable, SearchKeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineIdMeta = const VerificationMeta(
    'engineId',
  );
  @override
  late final GeneratedColumn<String> engineId = GeneratedColumn<String>(
    'engine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _failCountMeta = const VerificationMeta(
    'failCount',
  );
  @override
  late final GeneratedColumn<int> failCount = GeneratedColumn<int>(
    'fail_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failedAtMeta = const VerificationMeta(
    'failedAt',
  );
  @override
  late final GeneratedColumn<int> failedAt = GeneratedColumn<int>(
    'failed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    engineId,
    key,
    enabled,
    failCount,
    lastUsedAt,
    failedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchKeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('engine_id')) {
      context.handle(
        _engineIdMeta,
        engineId.isAcceptableOrUnknown(data['engine_id']!, _engineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_engineIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('fail_count')) {
      context.handle(
        _failCountMeta,
        failCount.isAcceptableOrUnknown(data['fail_count']!, _failCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('failed_at')) {
      context.handle(
        _failedAtMeta,
        failedAt.isAcceptableOrUnknown(data['failed_at']!, _failedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchKeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchKeyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      engineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      failCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fail_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      ),
      failedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_at'],
      ),
    );
  }

  @override
  $SearchKeysTable createAlias(String alias) {
    return $SearchKeysTable(attachedDatabase, alias);
  }
}

class SearchKeyRow extends DataClass implements Insertable<SearchKeyRow> {
  final String id;
  final String engineId;
  final String key;
  final bool enabled;
  final int failCount;
  final int? lastUsedAt;
  final int? failedAt;
  const SearchKeyRow({
    required this.id,
    required this.engineId,
    required this.key,
    required this.enabled,
    required this.failCount,
    this.lastUsedAt,
    this.failedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['engine_id'] = Variable<String>(engineId);
    map['key'] = Variable<String>(key);
    map['enabled'] = Variable<bool>(enabled);
    map['fail_count'] = Variable<int>(failCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<int>(lastUsedAt);
    }
    if (!nullToAbsent || failedAt != null) {
      map['failed_at'] = Variable<int>(failedAt);
    }
    return map;
  }

  SearchKeysCompanion toCompanion(bool nullToAbsent) {
    return SearchKeysCompanion(
      id: Value(id),
      engineId: Value(engineId),
      key: Value(key),
      enabled: Value(enabled),
      failCount: Value(failCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      failedAt: failedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(failedAt),
    );
  }

  factory SearchKeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchKeyRow(
      id: serializer.fromJson<String>(json['id']),
      engineId: serializer.fromJson<String>(json['engineId']),
      key: serializer.fromJson<String>(json['key']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      failCount: serializer.fromJson<int>(json['failCount']),
      lastUsedAt: serializer.fromJson<int?>(json['lastUsedAt']),
      failedAt: serializer.fromJson<int?>(json['failedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'engineId': serializer.toJson<String>(engineId),
      'key': serializer.toJson<String>(key),
      'enabled': serializer.toJson<bool>(enabled),
      'failCount': serializer.toJson<int>(failCount),
      'lastUsedAt': serializer.toJson<int?>(lastUsedAt),
      'failedAt': serializer.toJson<int?>(failedAt),
    };
  }

  SearchKeyRow copyWith({
    String? id,
    String? engineId,
    String? key,
    bool? enabled,
    int? failCount,
    Value<int?> lastUsedAt = const Value.absent(),
    Value<int?> failedAt = const Value.absent(),
  }) => SearchKeyRow(
    id: id ?? this.id,
    engineId: engineId ?? this.engineId,
    key: key ?? this.key,
    enabled: enabled ?? this.enabled,
    failCount: failCount ?? this.failCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    failedAt: failedAt.present ? failedAt.value : this.failedAt,
  );
  SearchKeyRow copyWithCompanion(SearchKeysCompanion data) {
    return SearchKeyRow(
      id: data.id.present ? data.id.value : this.id,
      engineId: data.engineId.present ? data.engineId.value : this.engineId,
      key: data.key.present ? data.key.value : this.key,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      failCount: data.failCount.present ? data.failCount.value : this.failCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      failedAt: data.failedAt.present ? data.failedAt.value : this.failedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeyRow(')
          ..write('id: $id, ')
          ..write('engineId: $engineId, ')
          ..write('key: $key, ')
          ..write('enabled: $enabled, ')
          ..write('failCount: $failCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('failedAt: $failedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, engineId, key, enabled, failCount, lastUsedAt, failedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchKeyRow &&
          other.id == this.id &&
          other.engineId == this.engineId &&
          other.key == this.key &&
          other.enabled == this.enabled &&
          other.failCount == this.failCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.failedAt == this.failedAt);
}

class SearchKeysCompanion extends UpdateCompanion<SearchKeyRow> {
  final Value<String> id;
  final Value<String> engineId;
  final Value<String> key;
  final Value<bool> enabled;
  final Value<int> failCount;
  final Value<int?> lastUsedAt;
  final Value<int?> failedAt;
  final Value<int> rowid;
  const SearchKeysCompanion({
    this.id = const Value.absent(),
    this.engineId = const Value.absent(),
    this.key = const Value.absent(),
    this.enabled = const Value.absent(),
    this.failCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.failedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchKeysCompanion.insert({
    required String id,
    required String engineId,
    required String key,
    this.enabled = const Value.absent(),
    this.failCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.failedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       engineId = Value(engineId),
       key = Value(key);
  static Insertable<SearchKeyRow> custom({
    Expression<String>? id,
    Expression<String>? engineId,
    Expression<String>? key,
    Expression<bool>? enabled,
    Expression<int>? failCount,
    Expression<int>? lastUsedAt,
    Expression<int>? failedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (engineId != null) 'engine_id': engineId,
      if (key != null) 'key': key,
      if (enabled != null) 'enabled': enabled,
      if (failCount != null) 'fail_count': failCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (failedAt != null) 'failed_at': failedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchKeysCompanion copyWith({
    Value<String>? id,
    Value<String>? engineId,
    Value<String>? key,
    Value<bool>? enabled,
    Value<int>? failCount,
    Value<int?>? lastUsedAt,
    Value<int?>? failedAt,
    Value<int>? rowid,
  }) {
    return SearchKeysCompanion(
      id: id ?? this.id,
      engineId: engineId ?? this.engineId,
      key: key ?? this.key,
      enabled: enabled ?? this.enabled,
      failCount: failCount ?? this.failCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      failedAt: failedAt ?? this.failedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (engineId.present) {
      map['engine_id'] = Variable<String>(engineId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (failCount.present) {
      map['fail_count'] = Variable<int>(failCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (failedAt.present) {
      map['failed_at'] = Variable<int>(failedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeysCompanion(')
          ..write('id: $id, ')
          ..write('engineId: $engineId, ')
          ..write('key: $key, ')
          ..write('enabled: $enabled, ')
          ..write('failCount: $failCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('failedAt: $failedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickPhrasesTable extends QuickPhrases
    with TableInfo<$QuickPhrasesTable, QuickPhraseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickPhrasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isGlobalMeta = const VerificationMeta(
    'isGlobal',
  );
  @override
  late final GeneratedColumn<bool> isGlobal = GeneratedColumn<bool>(
    'is_global',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_global" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    isGlobal,
    agentId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_phrases';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickPhraseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_global')) {
      context.handle(
        _isGlobalMeta,
        isGlobal.isAcceptableOrUnknown(data['is_global']!, _isGlobalMeta),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickPhraseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickPhraseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isGlobal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_global'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QuickPhrasesTable createAlias(String alias) {
    return $QuickPhrasesTable(attachedDatabase, alias);
  }
}

class QuickPhraseRow extends DataClass implements Insertable<QuickPhraseRow> {
  final String id;
  final String title;
  final String content;
  final bool isGlobal;
  final String? agentId;
  final int sortOrder;
  const QuickPhraseRow({
    required this.id,
    required this.title,
    required this.content,
    required this.isGlobal,
    this.agentId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['is_global'] = Variable<bool>(isGlobal);
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuickPhrasesCompanion toCompanion(bool nullToAbsent) {
    return QuickPhrasesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      isGlobal: Value(isGlobal),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      sortOrder: Value(sortOrder),
    );
  }

  factory QuickPhraseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickPhraseRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      isGlobal: serializer.fromJson<bool>(json['isGlobal']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'isGlobal': serializer.toJson<bool>(isGlobal),
      'agentId': serializer.toJson<String?>(agentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  QuickPhraseRow copyWith({
    String? id,
    String? title,
    String? content,
    bool? isGlobal,
    Value<String?> agentId = const Value.absent(),
    int? sortOrder,
  }) => QuickPhraseRow(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    isGlobal: isGlobal ?? this.isGlobal,
    agentId: agentId.present ? agentId.value : this.agentId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  QuickPhraseRow copyWithCompanion(QuickPhrasesCompanion data) {
    return QuickPhraseRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      isGlobal: data.isGlobal.present ? data.isGlobal.value : this.isGlobal,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickPhraseRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isGlobal: $isGlobal, ')
          ..write('agentId: $agentId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, isGlobal, agentId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickPhraseRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.isGlobal == this.isGlobal &&
          other.agentId == this.agentId &&
          other.sortOrder == this.sortOrder);
}

class QuickPhrasesCompanion extends UpdateCompanion<QuickPhraseRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<bool> isGlobal;
  final Value<String?> agentId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuickPhrasesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.isGlobal = const Value.absent(),
    this.agentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickPhrasesCompanion.insert({
    required String id,
    required String title,
    required String content,
    this.isGlobal = const Value.absent(),
    this.agentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content);
  static Insertable<QuickPhraseRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? isGlobal,
    Expression<String>? agentId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isGlobal != null) 'is_global': isGlobal,
      if (agentId != null) 'agent_id': agentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickPhrasesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<bool>? isGlobal,
    Value<String?>? agentId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QuickPhrasesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isGlobal: isGlobal ?? this.isGlobal,
      agentId: agentId ?? this.agentId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isGlobal.present) {
      map['is_global'] = Variable<bool>(isGlobal.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickPhrasesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isGlobal: $isGlobal, ')
          ..write('agentId: $agentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstructionInjectionsTable extends InstructionInjections
    with TableInfo<$InstructionInjectionsTable, InstructionInjectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstructionInjectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, prompt, groupName, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruction_injections';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstructionInjectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstructionInjectionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstructionInjectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $InstructionInjectionsTable createAlias(String alias) {
    return $InstructionInjectionsTable(attachedDatabase, alias);
  }
}

class InstructionInjectionRow extends DataClass
    implements Insertable<InstructionInjectionRow> {
  final String id;
  final String title;
  final String prompt;
  final String? groupName;
  final bool enabled;
  const InstructionInjectionRow({
    required this.id,
    required this.title,
    required this.prompt,
    this.groupName,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['prompt'] = Variable<String>(prompt);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  InstructionInjectionsCompanion toCompanion(bool nullToAbsent) {
    return InstructionInjectionsCompanion(
      id: Value(id),
      title: Value(title),
      prompt: Value(prompt),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      enabled: Value(enabled),
    );
  }

  factory InstructionInjectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstructionInjectionRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      prompt: serializer.fromJson<String>(json['prompt']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'prompt': serializer.toJson<String>(prompt),
      'groupName': serializer.toJson<String?>(groupName),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  InstructionInjectionRow copyWith({
    String? id,
    String? title,
    String? prompt,
    Value<String?> groupName = const Value.absent(),
    bool? enabled,
  }) => InstructionInjectionRow(
    id: id ?? this.id,
    title: title ?? this.title,
    prompt: prompt ?? this.prompt,
    groupName: groupName.present ? groupName.value : this.groupName,
    enabled: enabled ?? this.enabled,
  );
  InstructionInjectionRow copyWithCompanion(
    InstructionInjectionsCompanion data,
  ) {
    return InstructionInjectionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstructionInjectionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('prompt: $prompt, ')
          ..write('groupName: $groupName, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, prompt, groupName, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstructionInjectionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.prompt == this.prompt &&
          other.groupName == this.groupName &&
          other.enabled == this.enabled);
}

class InstructionInjectionsCompanion
    extends UpdateCompanion<InstructionInjectionRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> prompt;
  final Value<String?> groupName;
  final Value<bool> enabled;
  final Value<int> rowid;
  const InstructionInjectionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.prompt = const Value.absent(),
    this.groupName = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstructionInjectionsCompanion.insert({
    required String id,
    required String title,
    required String prompt,
    this.groupName = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       prompt = Value(prompt);
  static Insertable<InstructionInjectionRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? prompt,
    Expression<String>? groupName,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (prompt != null) 'prompt': prompt,
      if (groupName != null) 'group_name': groupName,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstructionInjectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? prompt,
    Value<String?>? groupName,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return InstructionInjectionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      groupName: groupName ?? this.groupName,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstructionInjectionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('prompt: $prompt, ')
          ..write('groupName: $groupName, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  final String? color;
  const TagRow({required this.id, required this.name, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
    };
  }

  TagRow copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
  }) => TagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
  );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenerationRunsTable extends GenerationRuns
    with TableInfo<$GenerationRunsTable, GenerationRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenerationRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('preparing'),
  );
  static const VerificationMeta _stateRevisionMeta = const VerificationMeta(
    'stateRevision',
  );
  @override
  late final GeneratedColumn<int> stateRevision = GeneratedColumn<int>(
    'state_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checkpointSeqMeta = const VerificationMeta(
    'checkpointSeq',
  );
  @override
  late final GeneratedColumn<int> checkpointSeq = GeneratedColumn<int>(
    'checkpoint_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    messageId,
    state,
    stateRevision,
    checkpointSeq,
    errorCode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generation_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<GenerationRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('state_revision')) {
      context.handle(
        _stateRevisionMeta,
        stateRevision.isAcceptableOrUnknown(
          data['state_revision']!,
          _stateRevisionMeta,
        ),
      );
    }
    if (data.containsKey('checkpoint_seq')) {
      context.handle(
        _checkpointSeqMeta,
        checkpointSeq.isAcceptableOrUnknown(
          data['checkpoint_seq']!,
          _checkpointSeqMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GenerationRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenerationRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      stateRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_revision'],
      )!,
      checkpointSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}checkpoint_seq'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GenerationRunsTable createAlias(String alias) {
    return $GenerationRunsTable(attachedDatabase, alias);
  }
}

class GenerationRunRow extends DataClass
    implements Insertable<GenerationRunRow> {
  final String id;
  final String? sessionId;
  final String? messageId;
  final String state;
  final int stateRevision;
  final int checkpointSeq;
  final String? errorCode;
  final int createdAt;
  final int updatedAt;
  const GenerationRunRow({
    required this.id,
    this.sessionId,
    this.messageId,
    required this.state,
    required this.stateRevision,
    required this.checkpointSeq,
    this.errorCode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['state'] = Variable<String>(state);
    map['state_revision'] = Variable<int>(stateRevision);
    map['checkpoint_seq'] = Variable<int>(checkpointSeq);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  GenerationRunsCompanion toCompanion(bool nullToAbsent) {
    return GenerationRunsCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      state: Value(state),
      stateRevision: Value(stateRevision),
      checkpointSeq: Value(checkpointSeq),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GenerationRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenerationRunRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      state: serializer.fromJson<String>(json['state']),
      stateRevision: serializer.fromJson<int>(json['stateRevision']),
      checkpointSeq: serializer.fromJson<int>(json['checkpointSeq']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String?>(sessionId),
      'messageId': serializer.toJson<String?>(messageId),
      'state': serializer.toJson<String>(state),
      'stateRevision': serializer.toJson<int>(stateRevision),
      'checkpointSeq': serializer.toJson<int>(checkpointSeq),
      'errorCode': serializer.toJson<String?>(errorCode),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  GenerationRunRow copyWith({
    String? id,
    Value<String?> sessionId = const Value.absent(),
    Value<String?> messageId = const Value.absent(),
    String? state,
    int? stateRevision,
    int? checkpointSeq,
    Value<String?> errorCode = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => GenerationRunRow(
    id: id ?? this.id,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    messageId: messageId.present ? messageId.value : this.messageId,
    state: state ?? this.state,
    stateRevision: stateRevision ?? this.stateRevision,
    checkpointSeq: checkpointSeq ?? this.checkpointSeq,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GenerationRunRow copyWithCompanion(GenerationRunsCompanion data) {
    return GenerationRunRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      state: data.state.present ? data.state.value : this.state,
      stateRevision: data.stateRevision.present
          ? data.stateRevision.value
          : this.stateRevision,
      checkpointSeq: data.checkpointSeq.present
          ? data.checkpointSeq.value
          : this.checkpointSeq,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenerationRunRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('state: $state, ')
          ..write('stateRevision: $stateRevision, ')
          ..write('checkpointSeq: $checkpointSeq, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    messageId,
    state,
    stateRevision,
    checkpointSeq,
    errorCode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenerationRunRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.messageId == this.messageId &&
          other.state == this.state &&
          other.stateRevision == this.stateRevision &&
          other.checkpointSeq == this.checkpointSeq &&
          other.errorCode == this.errorCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GenerationRunsCompanion extends UpdateCompanion<GenerationRunRow> {
  final Value<String> id;
  final Value<String?> sessionId;
  final Value<String?> messageId;
  final Value<String> state;
  final Value<int> stateRevision;
  final Value<int> checkpointSeq;
  final Value<String?> errorCode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const GenerationRunsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.state = const Value.absent(),
    this.stateRevision = const Value.absent(),
    this.checkpointSeq = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenerationRunsCompanion.insert({
    required String id,
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.state = const Value.absent(),
    this.stateRevision = const Value.absent(),
    this.checkpointSeq = const Value.absent(),
    this.errorCode = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GenerationRunRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? messageId,
    Expression<String>? state,
    Expression<int>? stateRevision,
    Expression<int>? checkpointSeq,
    Expression<String>? errorCode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
      if (state != null) 'state': state,
      if (stateRevision != null) 'state_revision': stateRevision,
      if (checkpointSeq != null) 'checkpoint_seq': checkpointSeq,
      if (errorCode != null) 'error_code': errorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenerationRunsCompanion copyWith({
    Value<String>? id,
    Value<String?>? sessionId,
    Value<String?>? messageId,
    Value<String>? state,
    Value<int>? stateRevision,
    Value<int>? checkpointSeq,
    Value<String?>? errorCode,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return GenerationRunsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      state: state ?? this.state,
      stateRevision: stateRevision ?? this.stateRevision,
      checkpointSeq: checkpointSeq ?? this.checkpointSeq,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (stateRevision.present) {
      map['state_revision'] = Variable<int>(stateRevision.value);
    }
    if (checkpointSeq.present) {
      map['checkpoint_seq'] = Variable<int>(checkpointSeq.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenerationRunsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('state: $state, ')
          ..write('stateRevision: $stateRevision, ')
          ..write('checkpointSeq: $checkpointSeq, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeLogTable extends ChangeLog
    with TableInfo<$ChangeLogTable, ChangeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMicrosMeta = const VerificationMeta(
    'tsMicros',
  );
  @override
  late final GeneratedColumn<int> tsMicros = GeneratedColumn<int>(
    'ts_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    entityType,
    entityId,
    op,
    tsMicros,
    payloadHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('ts_micros')) {
      context.handle(
        _tsMicrosMeta,
        tsMicros.isAcceptableOrUnknown(data['ts_micros']!, _tsMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_tsMicrosMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  ChangeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      tsMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts_micros'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      ),
    );
  }

  @override
  $ChangeLogTable createAlias(String alias) {
    return $ChangeLogTable(attachedDatabase, alias);
  }
}

class ChangeLogRow extends DataClass implements Insertable<ChangeLogRow> {
  final int seq;
  final String entityType;
  final String entityId;
  final String op;
  final int tsMicros;
  final String? payloadHash;
  const ChangeLogRow({
    required this.seq,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.tsMicros,
    this.payloadHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['ts_micros'] = Variable<int>(tsMicros);
    if (!nullToAbsent || payloadHash != null) {
      map['payload_hash'] = Variable<String>(payloadHash);
    }
    return map;
  }

  ChangeLogCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogCompanion(
      seq: Value(seq),
      entityType: Value(entityType),
      entityId: Value(entityId),
      op: Value(op),
      tsMicros: Value(tsMicros),
      payloadHash: payloadHash == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadHash),
    );
  }

  factory ChangeLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogRow(
      seq: serializer.fromJson<int>(json['seq']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      tsMicros: serializer.fromJson<int>(json['tsMicros']),
      payloadHash: serializer.fromJson<String?>(json['payloadHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'tsMicros': serializer.toJson<int>(tsMicros),
      'payloadHash': serializer.toJson<String?>(payloadHash),
    };
  }

  ChangeLogRow copyWith({
    int? seq,
    String? entityType,
    String? entityId,
    String? op,
    int? tsMicros,
    Value<String?> payloadHash = const Value.absent(),
  }) => ChangeLogRow(
    seq: seq ?? this.seq,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    tsMicros: tsMicros ?? this.tsMicros,
    payloadHash: payloadHash.present ? payloadHash.value : this.payloadHash,
  );
  ChangeLogRow copyWithCompanion(ChangeLogCompanion data) {
    return ChangeLogRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      tsMicros: data.tsMicros.present ? data.tsMicros.value : this.tsMicros,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogRow(')
          ..write('seq: $seq, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('tsMicros: $tsMicros, ')
          ..write('payloadHash: $payloadHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, entityType, entityId, op, tsMicros, payloadHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogRow &&
          other.seq == this.seq &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.tsMicros == this.tsMicros &&
          other.payloadHash == this.payloadHash);
}

class ChangeLogCompanion extends UpdateCompanion<ChangeLogRow> {
  final Value<int> seq;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> op;
  final Value<int> tsMicros;
  final Value<String?> payloadHash;
  const ChangeLogCompanion({
    this.seq = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.tsMicros = const Value.absent(),
    this.payloadHash = const Value.absent(),
  });
  ChangeLogCompanion.insert({
    this.seq = const Value.absent(),
    required String entityType,
    required String entityId,
    required String op,
    required int tsMicros,
    this.payloadHash = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       op = Value(op),
       tsMicros = Value(tsMicros);
  static Insertable<ChangeLogRow> custom({
    Expression<int>? seq,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<int>? tsMicros,
    Expression<String>? payloadHash,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (tsMicros != null) 'ts_micros': tsMicros,
      if (payloadHash != null) 'payload_hash': payloadHash,
    });
  }

  ChangeLogCompanion copyWith({
    Value<int>? seq,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? op,
    Value<int>? tsMicros,
    Value<String?>? payloadHash,
  }) {
    return ChangeLogCompanion(
      seq: seq ?? this.seq,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      tsMicros: tsMicros ?? this.tsMicros,
      payloadHash: payloadHash ?? this.payloadHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (tsMicros.present) {
      map['ts_micros'] = Variable<int>(tsMicros.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogCompanion(')
          ..write('seq: $seq, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('tsMicros: $tsMicros, ')
          ..write('payloadHash: $payloadHash')
          ..write(')'))
        .toString();
  }
}

class $RouteEventsTable extends RouteEvents
    with TableInfo<$RouteEventsTable, RouteEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskMeta = const VerificationMeta('task');
  @override
  late final GeneratedColumn<String> task = GeneratedColumn<String>(
    'task',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
    'success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("success" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    task,
    providerId,
    modelId,
    success,
    elapsedMs,
    cost,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task')) {
      context.handle(
        _taskMeta,
        task.isAcceptableOrUnknown(data['task']!, _taskMeta),
      );
    } else if (isInserting) {
      context.missing(_taskMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RouteEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      task: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}success'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RouteEventsTable createAlias(String alias) {
    return $RouteEventsTable(attachedDatabase, alias);
  }
}

class RouteEventRow extends DataClass implements Insertable<RouteEventRow> {
  final int id;
  final String task;
  final String? providerId;
  final String? modelId;
  final bool success;
  final int elapsedMs;
  final double cost;
  final int createdAt;
  const RouteEventRow({
    required this.id,
    required this.task,
    this.providerId,
    this.modelId,
    required this.success,
    required this.elapsedMs,
    required this.cost,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task'] = Variable<String>(task);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    map['success'] = Variable<bool>(success);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['cost'] = Variable<double>(cost);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RouteEventsCompanion toCompanion(bool nullToAbsent) {
    return RouteEventsCompanion(
      id: Value(id),
      task: Value(task),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      success: Value(success),
      elapsedMs: Value(elapsedMs),
      cost: Value(cost),
      createdAt: Value(createdAt),
    );
  }

  factory RouteEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteEventRow(
      id: serializer.fromJson<int>(json['id']),
      task: serializer.fromJson<String>(json['task']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      success: serializer.fromJson<bool>(json['success']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      cost: serializer.fromJson<double>(json['cost']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'task': serializer.toJson<String>(task),
      'providerId': serializer.toJson<String?>(providerId),
      'modelId': serializer.toJson<String?>(modelId),
      'success': serializer.toJson<bool>(success),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'cost': serializer.toJson<double>(cost),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RouteEventRow copyWith({
    int? id,
    String? task,
    Value<String?> providerId = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    bool? success,
    int? elapsedMs,
    double? cost,
    int? createdAt,
  }) => RouteEventRow(
    id: id ?? this.id,
    task: task ?? this.task,
    providerId: providerId.present ? providerId.value : this.providerId,
    modelId: modelId.present ? modelId.value : this.modelId,
    success: success ?? this.success,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    cost: cost ?? this.cost,
    createdAt: createdAt ?? this.createdAt,
  );
  RouteEventRow copyWithCompanion(RouteEventsCompanion data) {
    return RouteEventRow(
      id: data.id.present ? data.id.value : this.id,
      task: data.task.present ? data.task.value : this.task,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      success: data.success.present ? data.success.value : this.success,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      cost: data.cost.present ? data.cost.value : this.cost,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteEventRow(')
          ..write('id: $id, ')
          ..write('task: $task, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('success: $success, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('cost: $cost, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    task,
    providerId,
    modelId,
    success,
    elapsedMs,
    cost,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteEventRow &&
          other.id == this.id &&
          other.task == this.task &&
          other.providerId == this.providerId &&
          other.modelId == this.modelId &&
          other.success == this.success &&
          other.elapsedMs == this.elapsedMs &&
          other.cost == this.cost &&
          other.createdAt == this.createdAt);
}

class RouteEventsCompanion extends UpdateCompanion<RouteEventRow> {
  final Value<int> id;
  final Value<String> task;
  final Value<String?> providerId;
  final Value<String?> modelId;
  final Value<bool> success;
  final Value<int> elapsedMs;
  final Value<double> cost;
  final Value<int> createdAt;
  const RouteEventsCompanion({
    this.id = const Value.absent(),
    this.task = const Value.absent(),
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.success = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.cost = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RouteEventsCompanion.insert({
    this.id = const Value.absent(),
    required String task,
    this.providerId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.success = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.cost = const Value.absent(),
    required int createdAt,
  }) : task = Value(task),
       createdAt = Value(createdAt);
  static Insertable<RouteEventRow> custom({
    Expression<int>? id,
    Expression<String>? task,
    Expression<String>? providerId,
    Expression<String>? modelId,
    Expression<bool>? success,
    Expression<int>? elapsedMs,
    Expression<double>? cost,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (task != null) 'task': task,
      if (providerId != null) 'provider_id': providerId,
      if (modelId != null) 'model_id': modelId,
      if (success != null) 'success': success,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (cost != null) 'cost': cost,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RouteEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? task,
    Value<String?>? providerId,
    Value<String?>? modelId,
    Value<bool>? success,
    Value<int>? elapsedMs,
    Value<double>? cost,
    Value<int>? createdAt,
  }) {
    return RouteEventsCompanion(
      id: id ?? this.id,
      task: task ?? this.task,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      success: success ?? this.success,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (task.present) {
      map['task'] = Variable<String>(task.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteEventsCompanion(')
          ..write('id: $id, ')
          ..write('task: $task, ')
          ..write('providerId: $providerId, ')
          ..write('modelId: $modelId, ')
          ..write('success: $success, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('cost: $cost, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkflowsTable extends Workflows
    with TableInfo<$WorkflowsTable, WorkflowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerJsonMeta = const VerificationMeta(
    'triggerJson',
  );
  @override
  late final GeneratedColumn<String> triggerJson = GeneratedColumn<String>(
    'trigger_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionsJsonMeta = const VerificationMeta(
    'actionsJson',
  );
  @override
  late final GeneratedColumn<String> actionsJson = GeneratedColumn<String>(
    'actions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    triggerJson,
    actionsJson,
    enabled,
    agentId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkflowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('trigger_json')) {
      context.handle(
        _triggerJsonMeta,
        triggerJson.isAcceptableOrUnknown(
          data['trigger_json']!,
          _triggerJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerJsonMeta);
    }
    if (data.containsKey('actions_json')) {
      context.handle(
        _actionsJsonMeta,
        actionsJson.isAcceptableOrUnknown(
          data['actions_json']!,
          _actionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actionsJsonMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkflowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      triggerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_json'],
      )!,
      actionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actions_json'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorkflowsTable createAlias(String alias) {
    return $WorkflowsTable(attachedDatabase, alias);
  }
}

class WorkflowRow extends DataClass implements Insertable<WorkflowRow> {
  final String id;
  final String name;
  final String triggerJson;
  final String actionsJson;
  final bool enabled;
  final String? agentId;
  final int updatedAt;
  const WorkflowRow({
    required this.id,
    required this.name,
    required this.triggerJson,
    required this.actionsJson,
    required this.enabled,
    this.agentId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['trigger_json'] = Variable<String>(triggerJson);
    map['actions_json'] = Variable<String>(actionsJson);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WorkflowsCompanion toCompanion(bool nullToAbsent) {
    return WorkflowsCompanion(
      id: Value(id),
      name: Value(name),
      triggerJson: Value(triggerJson),
      actionsJson: Value(actionsJson),
      enabled: Value(enabled),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkflowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      triggerJson: serializer.fromJson<String>(json['triggerJson']),
      actionsJson: serializer.fromJson<String>(json['actionsJson']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'triggerJson': serializer.toJson<String>(triggerJson),
      'actionsJson': serializer.toJson<String>(actionsJson),
      'enabled': serializer.toJson<bool>(enabled),
      'agentId': serializer.toJson<String?>(agentId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WorkflowRow copyWith({
    String? id,
    String? name,
    String? triggerJson,
    String? actionsJson,
    bool? enabled,
    Value<String?> agentId = const Value.absent(),
    int? updatedAt,
  }) => WorkflowRow(
    id: id ?? this.id,
    name: name ?? this.name,
    triggerJson: triggerJson ?? this.triggerJson,
    actionsJson: actionsJson ?? this.actionsJson,
    enabled: enabled ?? this.enabled,
    agentId: agentId.present ? agentId.value : this.agentId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkflowRow copyWithCompanion(WorkflowsCompanion data) {
    return WorkflowRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      triggerJson: data.triggerJson.present
          ? data.triggerJson.value
          : this.triggerJson,
      actionsJson: data.actionsJson.present
          ? data.actionsJson.value
          : this.actionsJson,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('triggerJson: $triggerJson, ')
          ..write('actionsJson: $actionsJson, ')
          ..write('enabled: $enabled, ')
          ..write('agentId: $agentId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    triggerJson,
    actionsJson,
    enabled,
    agentId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.triggerJson == this.triggerJson &&
          other.actionsJson == this.actionsJson &&
          other.enabled == this.enabled &&
          other.agentId == this.agentId &&
          other.updatedAt == this.updatedAt);
}

class WorkflowsCompanion extends UpdateCompanion<WorkflowRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> triggerJson;
  final Value<String> actionsJson;
  final Value<bool> enabled;
  final Value<String?> agentId;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WorkflowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.triggerJson = const Value.absent(),
    this.actionsJson = const Value.absent(),
    this.enabled = const Value.absent(),
    this.agentId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowsCompanion.insert({
    required String id,
    required String name,
    required String triggerJson,
    required String actionsJson,
    this.enabled = const Value.absent(),
    this.agentId = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       triggerJson = Value(triggerJson),
       actionsJson = Value(actionsJson),
       updatedAt = Value(updatedAt);
  static Insertable<WorkflowRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? triggerJson,
    Expression<String>? actionsJson,
    Expression<bool>? enabled,
    Expression<String>? agentId,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (triggerJson != null) 'trigger_json': triggerJson,
      if (actionsJson != null) 'actions_json': actionsJson,
      if (enabled != null) 'enabled': enabled,
      if (agentId != null) 'agent_id': agentId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? triggerJson,
    Value<String>? actionsJson,
    Value<bool>? enabled,
    Value<String?>? agentId,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkflowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerJson: triggerJson ?? this.triggerJson,
      actionsJson: actionsJson ?? this.actionsJson,
      enabled: enabled ?? this.enabled,
      agentId: agentId ?? this.agentId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (triggerJson.present) {
      map['trigger_json'] = Variable<String>(triggerJson.value);
    }
    if (actionsJson.present) {
      map['actions_json'] = Variable<String>(actionsJson.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('triggerJson: $triggerJson, ')
          ..write('actionsJson: $actionsJson, ')
          ..write('enabled: $enabled, ')
          ..write('agentId: $agentId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkflowRunsTable extends WorkflowRuns
    with TableInfo<$WorkflowRunsTable, WorkflowRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkflowRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workflowIdMeta = const VerificationMeta(
    'workflowId',
  );
  @override
  late final GeneratedColumn<String> workflowId = GeneratedColumn<String>(
    'workflow_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workflowId,
    status,
    startedAt,
    finishedAt,
    error,
    resultJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workflow_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkflowRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workflow_id')) {
      context.handle(
        _workflowIdMeta,
        workflowId.isAcceptableOrUnknown(data['workflow_id']!, _workflowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workflowIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkflowRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkflowRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workflowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
    );
  }

  @override
  $WorkflowRunsTable createAlias(String alias) {
    return $WorkflowRunsTable(attachedDatabase, alias);
  }
}

class WorkflowRunRow extends DataClass implements Insertable<WorkflowRunRow> {
  final String id;
  final String workflowId;
  final String status;
  final int startedAt;
  final int? finishedAt;
  final String? error;
  final String? resultJson;
  const WorkflowRunRow({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.error,
    this.resultJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workflow_id'] = Variable<String>(workflowId);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    return map;
  }

  WorkflowRunsCompanion toCompanion(bool nullToAbsent) {
    return WorkflowRunsCompanion(
      id: Value(id),
      workflowId: Value(workflowId),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
    );
  }

  factory WorkflowRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkflowRunRow(
      id: serializer.fromJson<String>(json['id']),
      workflowId: serializer.fromJson<String>(json['workflowId']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      error: serializer.fromJson<String?>(json['error']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workflowId': serializer.toJson<String>(workflowId),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'error': serializer.toJson<String?>(error),
      'resultJson': serializer.toJson<String?>(resultJson),
    };
  }

  WorkflowRunRow copyWith({
    String? id,
    String? workflowId,
    String? status,
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> resultJson = const Value.absent(),
  }) => WorkflowRunRow(
    id: id ?? this.id,
    workflowId: workflowId ?? this.workflowId,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    error: error.present ? error.value : this.error,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
  );
  WorkflowRunRow copyWithCompanion(WorkflowRunsCompanion data) {
    return WorkflowRunRow(
      id: data.id.present ? data.id.value : this.id,
      workflowId: data.workflowId.present
          ? data.workflowId.value
          : this.workflowId,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      error: data.error.present ? data.error.value : this.error,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowRunRow(')
          ..write('id: $id, ')
          ..write('workflowId: $workflowId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('error: $error, ')
          ..write('resultJson: $resultJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workflowId,
    status,
    startedAt,
    finishedAt,
    error,
    resultJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkflowRunRow &&
          other.id == this.id &&
          other.workflowId == this.workflowId &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.error == this.error &&
          other.resultJson == this.resultJson);
}

class WorkflowRunsCompanion extends UpdateCompanion<WorkflowRunRow> {
  final Value<String> id;
  final Value<String> workflowId;
  final Value<String> status;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<String?> error;
  final Value<String?> resultJson;
  final Value<int> rowid;
  const WorkflowRunsCompanion({
    this.id = const Value.absent(),
    this.workflowId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.error = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkflowRunsCompanion.insert({
    required String id,
    required String workflowId,
    required String status,
    required int startedAt,
    this.finishedAt = const Value.absent(),
    this.error = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workflowId = Value(workflowId),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<WorkflowRunRow> custom({
    Expression<String>? id,
    Expression<String>? workflowId,
    Expression<String>? status,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<String>? error,
    Expression<String>? resultJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workflowId != null) 'workflow_id': workflowId,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (error != null) 'error': error,
      if (resultJson != null) 'result_json': resultJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkflowRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? workflowId,
    Value<String>? status,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<String?>? error,
    Value<String?>? resultJson,
    Value<int>? rowid,
  }) {
    return WorkflowRunsCompanion(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      error: error ?? this.error,
      resultJson: resultJson ?? this.resultJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workflowId.present) {
      map['workflow_id'] = Variable<String>(workflowId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkflowRunsCompanion(')
          ..write('id: $id, ')
          ..write('workflowId: $workflowId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('error: $error, ')
          ..write('resultJson: $resultJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NonaAppDatabase extends GeneratedDatabase {
  _$NonaAppDatabase(QueryExecutor e) : super(e);
  $NonaAppDatabaseManager get managers => $NonaAppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageTokensTable messageTokens = $MessageTokensTable(this);
  late final $CompressedBlocksTable compressedBlocks = $CompressedBlocksTable(
    this,
  );
  late final $UsageDailyTable usageDaily = $UsageDailyTable(this);
  late final $GenMediaTable genMedia = $GenMediaTable(this);
  late final $KbLibrariesTable kbLibraries = $KbLibrariesTable(this);
  late final $KbDocumentsTable kbDocuments = $KbDocumentsTable(this);
  late final $KbChunksTable kbChunks = $KbChunksTable(this);
  late final $KbBigramsTable kbBigrams = $KbBigramsTable(this);
  late final $KbVectorsTable kbVectors = $KbVectorsTable(this);
  late final $MemoriesTable memories = $MemoriesTable(this);
  late final $MemorySpacesTable memorySpaces = $MemorySpacesTable(this);
  late final $MemoryStateTable memoryState = $MemoryStateTable(this);
  late final $WorldBookEntriesTable worldBookEntries = $WorldBookEntriesTable(
    this,
  );
  late final $WorldBooksTable worldBooks = $WorldBooksTable(this);
  late final $ProviderGroupsTable providerGroups = $ProviderGroupsTable(this);
  late final $SearchKeysTable searchKeys = $SearchKeysTable(this);
  late final $QuickPhrasesTable quickPhrases = $QuickPhrasesTable(this);
  late final $InstructionInjectionsTable instructionInjections =
      $InstructionInjectionsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $GenerationRunsTable generationRuns = $GenerationRunsTable(this);
  late final $ChangeLogTable changeLog = $ChangeLogTable(this);
  late final $RouteEventsTable routeEvents = $RouteEventsTable(this);
  late final $WorkflowsTable workflows = $WorkflowsTable(this);
  late final $WorkflowRunsTable workflowRuns = $WorkflowRunsTable(this);
  late final Index idxMessagesSession = Index(
    'idx_messages_session',
    'CREATE INDEX idx_messages_session ON messages (session_id, message_index)',
  );
  late final Index idxKbDocsLib = Index(
    'idx_kb_docs_lib',
    'CREATE INDEX idx_kb_docs_lib ON kb_documents (library_id)',
  );
  late final Index idxKbChunksDoc = Index(
    'idx_kb_chunks_doc',
    'CREATE INDEX idx_kb_chunks_doc ON kb_chunks (doc_id, position)',
  );
  late final Index idxKbBigramsKey = Index(
    'idx_kb_bigrams_key',
    'CREATE INDEX idx_kb_bigrams_key ON kb_bigrams (bigram)',
  );
  late final Index idxMemoriesScope = Index(
    'idx_memories_scope',
    'CREATE INDEX idx_memories_scope ON memories (scope, scope_ref)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    messages,
    messageTokens,
    compressedBlocks,
    usageDaily,
    genMedia,
    kbLibraries,
    kbDocuments,
    kbChunks,
    kbBigrams,
    kbVectors,
    memories,
    memorySpaces,
    memoryState,
    worldBookEntries,
    worldBooks,
    providerGroups,
    searchKeys,
    quickPhrases,
    instructionInjections,
    tags,
    generationRuns,
    changeLog,
    routeEvents,
    workflows,
    workflowRuns,
    idxMessagesSession,
    idxKbDocsLib,
    idxKbChunksDoc,
    idxKbBigramsKey,
    idxMemoriesScope,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('compressed_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'kb_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('kb_chunks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'kb_chunks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('kb_bigrams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'kb_chunks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('kb_vectors', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String title,
      required String optionsJson,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<String?> agentId,
      Value<bool> pinned,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<String> summary,
      Value<int?> summaryTokens,
      Value<String> memory,
      Value<String?> tagsJson,
      Value<int?> truncateIndex,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> optionsJson,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<String?> agentId,
      Value<bool> pinned,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> summary,
      Value<int?> summaryTokens,
      Value<String> memory,
      Value<String?> tagsJson,
      Value<int?> truncateIndex,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$NonaAppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<MessageRow>>
  _messagesRefsTable(_$NonaAppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.messages.sessionId),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompressedBlocksTable, List<CompressedBlockRow>>
  _compressedBlocksRefsTable(_$NonaAppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.compressedBlocks,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.compressedBlocks.sessionId,
        ),
      );

  $$CompressedBlocksTableProcessedTableManager get compressedBlocksRefs {
    final manager = $$CompressedBlocksTableTableManager(
      $_db,
      $_db.compressedBlocks,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _compressedBlocksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get summaryTokens => $composableBuilder(
    column: $table.summaryTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memory => $composableBuilder(
    column: $table.memory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get truncateIndex => $composableBuilder(
    column: $table.truncateIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> compressedBlocksRefs(
    Expression<bool> Function($$CompressedBlocksTableFilterComposer f) f,
  ) {
    final $$CompressedBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compressedBlocks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompressedBlocksTableFilterComposer(
            $db: $db,
            $table: $db.compressedBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get summaryTokens => $composableBuilder(
    column: $table.summaryTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memory => $composableBuilder(
    column: $table.memory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get truncateIndex => $composableBuilder(
    column: $table.truncateIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get summaryTokens => $composableBuilder(
    column: $table.summaryTokens,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memory =>
      $composableBuilder(column: $table.memory, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<int> get truncateIndex => $composableBuilder(
    column: $table.truncateIndex,
    builder: (column) => column,
  );

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> compressedBlocksRefs<T extends Object>(
    Expression<T> Function($$CompressedBlocksTableAnnotationComposer a) f,
  ) {
    final $$CompressedBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compressedBlocks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompressedBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.compressedBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool messagesRefs, bool compressedBlocksRefs})
        > {
  $$SessionsTableTableManager(_$NonaAppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int?> summaryTokens = const Value.absent(),
                Value<String> memory = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<int?> truncateIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                title: title,
                optionsJson: optionsJson,
                providerId: providerId,
                modelId: modelId,
                agentId: agentId,
                pinned: pinned,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                summary: summary,
                summaryTokens: summaryTokens,
                memory: memory,
                tagsJson: tagsJson,
                truncateIndex: truncateIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String optionsJson,
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> summary = const Value.absent(),
                Value<int?> summaryTokens = const Value.absent(),
                Value<String> memory = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<int?> truncateIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                title: title,
                optionsJson: optionsJson,
                providerId: providerId,
                modelId: modelId,
                agentId: agentId,
                pinned: pinned,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                summary: summary,
                summaryTokens: summaryTokens,
                memory: memory,
                tagsJson: tagsJson,
                truncateIndex: truncateIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({messagesRefs = false, compressedBlocksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messagesRefs) db.messages,
                    if (compressedBlocksRefs) db.compressedBlocks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          MessageRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (compressedBlocksRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          CompressedBlockRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._compressedBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).compressedBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool messagesRefs, bool compressedBlocksRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String sessionId,
      required int messageIndex,
      required String role,
      required String content,
      Value<String> reasoningContent,
      Value<String> imagesJson,
      Value<String> documentsJson,
      Value<String> alternativesJson,
      Value<String?> toolCallId,
      Value<String?> toolCallsJson,
      Value<bool> interrupted,
      Value<bool> failed,
      Value<int?> promptTokens,
      Value<int?> completionTokens,
      Value<int?> elapsedMs,
      Value<String?> providerName,
      Value<String?> modelId,
      Value<int?> sentAt,
      Value<String?> partsJson,
      Value<String?> citationsJson,
      Value<String?> toolStepsJson,
      Value<String?> streamingState,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> messageIndex,
      Value<String> role,
      Value<String> content,
      Value<String> reasoningContent,
      Value<String> imagesJson,
      Value<String> documentsJson,
      Value<String> alternativesJson,
      Value<String?> toolCallId,
      Value<String?> toolCallsJson,
      Value<bool> interrupted,
      Value<bool> failed,
      Value<int?> promptTokens,
      Value<int?> completionTokens,
      Value<int?> elapsedMs,
      Value<String?> providerName,
      Value<String?> modelId,
      Value<int?> sentAt,
      Value<String?> partsJson,
      Value<String?> citationsJson,
      Value<String?> toolStepsJson,
      Value<String?> streamingState,
      Value<int> rowid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$NonaAppDatabase, $MessagesTable, MessageRow> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$NonaAppDatabase db) => db.sessions
      .createAlias($_aliasNameGenerator(db.messages.sessionId, db.sessions.id));

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageIndex => $composableBuilder(
    column: $table.messageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagesJson => $composableBuilder(
    column: $table.imagesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentsJson => $composableBuilder(
    column: $table.documentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get interrupted => $composableBuilder(
    column: $table.interrupted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolStepsJson => $composableBuilder(
    column: $table.toolStepsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamingState => $composableBuilder(
    column: $table.streamingState,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageIndex => $composableBuilder(
    column: $table.messageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagesJson => $composableBuilder(
    column: $table.imagesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentsJson => $composableBuilder(
    column: $table.documentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get interrupted => $composableBuilder(
    column: $table.interrupted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolStepsJson => $composableBuilder(
    column: $table.toolStepsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamingState => $composableBuilder(
    column: $table.streamingState,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get messageIndex => $composableBuilder(
    column: $table.messageIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get reasoningContent => $composableBuilder(
    column: $table.reasoningContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagesJson => $composableBuilder(
    column: $table.imagesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentsJson => $composableBuilder(
    column: $table.documentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get interrupted => $composableBuilder(
    column: $table.interrupted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get failed =>
      $composableBuilder(column: $table.failed, builder: (column) => column);

  GeneratedColumn<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get partsJson =>
      $composableBuilder(column: $table.partsJson, builder: (column) => column);

  GeneratedColumn<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolStepsJson => $composableBuilder(
    column: $table.toolStepsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamingState => $composableBuilder(
    column: $table.streamingState,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (MessageRow, $$MessagesTableReferences),
          MessageRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MessagesTableTableManager(_$NonaAppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> messageIndex = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> reasoningContent = const Value.absent(),
                Value<String> imagesJson = const Value.absent(),
                Value<String> documentsJson = const Value.absent(),
                Value<String> alternativesJson = const Value.absent(),
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> toolCallsJson = const Value.absent(),
                Value<bool> interrupted = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<int?> promptTokens = const Value.absent(),
                Value<int?> completionTokens = const Value.absent(),
                Value<int?> elapsedMs = const Value.absent(),
                Value<String?> providerName = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int?> sentAt = const Value.absent(),
                Value<String?> partsJson = const Value.absent(),
                Value<String?> citationsJson = const Value.absent(),
                Value<String?> toolStepsJson = const Value.absent(),
                Value<String?> streamingState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                sessionId: sessionId,
                messageIndex: messageIndex,
                role: role,
                content: content,
                reasoningContent: reasoningContent,
                imagesJson: imagesJson,
                documentsJson: documentsJson,
                alternativesJson: alternativesJson,
                toolCallId: toolCallId,
                toolCallsJson: toolCallsJson,
                interrupted: interrupted,
                failed: failed,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                elapsedMs: elapsedMs,
                providerName: providerName,
                modelId: modelId,
                sentAt: sentAt,
                partsJson: partsJson,
                citationsJson: citationsJson,
                toolStepsJson: toolStepsJson,
                streamingState: streamingState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int messageIndex,
                required String role,
                required String content,
                Value<String> reasoningContent = const Value.absent(),
                Value<String> imagesJson = const Value.absent(),
                Value<String> documentsJson = const Value.absent(),
                Value<String> alternativesJson = const Value.absent(),
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> toolCallsJson = const Value.absent(),
                Value<bool> interrupted = const Value.absent(),
                Value<bool> failed = const Value.absent(),
                Value<int?> promptTokens = const Value.absent(),
                Value<int?> completionTokens = const Value.absent(),
                Value<int?> elapsedMs = const Value.absent(),
                Value<String?> providerName = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int?> sentAt = const Value.absent(),
                Value<String?> partsJson = const Value.absent(),
                Value<String?> citationsJson = const Value.absent(),
                Value<String?> toolStepsJson = const Value.absent(),
                Value<String?> streamingState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                messageIndex: messageIndex,
                role: role,
                content: content,
                reasoningContent: reasoningContent,
                imagesJson: imagesJson,
                documentsJson: documentsJson,
                alternativesJson: alternativesJson,
                toolCallId: toolCallId,
                toolCallsJson: toolCallsJson,
                interrupted: interrupted,
                failed: failed,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                elapsedMs: elapsedMs,
                providerName: providerName,
                modelId: modelId,
                sentAt: sentAt,
                partsJson: partsJson,
                citationsJson: citationsJson,
                toolStepsJson: toolStepsJson,
                streamingState: streamingState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$MessagesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, $$MessagesTableReferences),
      MessageRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$MessageTokensTableCreateCompanionBuilder =
    MessageTokensCompanion Function({
      required String token,
      required String sessionId,
      required String messageId,
      required int position,
      Value<int> rowid,
    });
typedef $$MessageTokensTableUpdateCompanionBuilder =
    MessageTokensCompanion Function({
      Value<String> token,
      Value<String> sessionId,
      Value<String> messageId,
      Value<int> position,
      Value<int> rowid,
    });

class $$MessageTokensTableFilterComposer
    extends Composer<_$NonaAppDatabase, $MessageTokensTable> {
  $$MessageTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageTokensTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $MessageTokensTable> {
  $$MessageTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageTokensTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $MessageTokensTable> {
  $$MessageTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$MessageTokensTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $MessageTokensTable,
          MessageTokenRow,
          $$MessageTokensTableFilterComposer,
          $$MessageTokensTableOrderingComposer,
          $$MessageTokensTableAnnotationComposer,
          $$MessageTokensTableCreateCompanionBuilder,
          $$MessageTokensTableUpdateCompanionBuilder,
          (
            MessageTokenRow,
            BaseReferences<
              _$NonaAppDatabase,
              $MessageTokensTable,
              MessageTokenRow
            >,
          ),
          MessageTokenRow,
          PrefetchHooks Function()
        > {
  $$MessageTokensTableTableManager(
    _$NonaAppDatabase db,
    $MessageTokensTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageTokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageTokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> token = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageTokensCompanion(
                token: token,
                sessionId: sessionId,
                messageId: messageId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String token,
                required String sessionId,
                required String messageId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => MessageTokensCompanion.insert(
                token: token,
                sessionId: sessionId,
                messageId: messageId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageTokensTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $MessageTokensTable,
      MessageTokenRow,
      $$MessageTokensTableFilterComposer,
      $$MessageTokensTableOrderingComposer,
      $$MessageTokensTableAnnotationComposer,
      $$MessageTokensTableCreateCompanionBuilder,
      $$MessageTokensTableUpdateCompanionBuilder,
      (
        MessageTokenRow,
        BaseReferences<_$NonaAppDatabase, $MessageTokensTable, MessageTokenRow>,
      ),
      MessageTokenRow,
      PrefetchHooks Function()
    >;
typedef $$CompressedBlocksTableCreateCompanionBuilder =
    CompressedBlocksCompanion Function({
      required String id,
      required String sessionId,
      required int startIndex,
      required int endIndex,
      required String summary,
      Value<String> messagesJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CompressedBlocksTableUpdateCompanionBuilder =
    CompressedBlocksCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> startIndex,
      Value<int> endIndex,
      Value<String> summary,
      Value<String> messagesJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$CompressedBlocksTableReferences
    extends
        BaseReferences<
          _$NonaAppDatabase,
          $CompressedBlocksTable,
          CompressedBlockRow
        > {
  $$CompressedBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$NonaAppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.compressedBlocks.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompressedBlocksTableFilterComposer
    extends Composer<_$NonaAppDatabase, $CompressedBlocksTable> {
  $$CompressedBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startIndex => $composableBuilder(
    column: $table.startIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endIndex => $composableBuilder(
    column: $table.endIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messagesJson => $composableBuilder(
    column: $table.messagesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompressedBlocksTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $CompressedBlocksTable> {
  $$CompressedBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startIndex => $composableBuilder(
    column: $table.startIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endIndex => $composableBuilder(
    column: $table.endIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messagesJson => $composableBuilder(
    column: $table.messagesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompressedBlocksTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $CompressedBlocksTable> {
  $$CompressedBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startIndex => $composableBuilder(
    column: $table.startIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endIndex =>
      $composableBuilder(column: $table.endIndex, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get messagesJson => $composableBuilder(
    column: $table.messagesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompressedBlocksTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $CompressedBlocksTable,
          CompressedBlockRow,
          $$CompressedBlocksTableFilterComposer,
          $$CompressedBlocksTableOrderingComposer,
          $$CompressedBlocksTableAnnotationComposer,
          $$CompressedBlocksTableCreateCompanionBuilder,
          $$CompressedBlocksTableUpdateCompanionBuilder,
          (CompressedBlockRow, $$CompressedBlocksTableReferences),
          CompressedBlockRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$CompressedBlocksTableTableManager(
    _$NonaAppDatabase db,
    $CompressedBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompressedBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompressedBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompressedBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> startIndex = const Value.absent(),
                Value<int> endIndex = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> messagesJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompressedBlocksCompanion(
                id: id,
                sessionId: sessionId,
                startIndex: startIndex,
                endIndex: endIndex,
                summary: summary,
                messagesJson: messagesJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int startIndex,
                required int endIndex,
                required String summary,
                Value<String> messagesJson = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CompressedBlocksCompanion.insert(
                id: id,
                sessionId: sessionId,
                startIndex: startIndex,
                endIndex: endIndex,
                summary: summary,
                messagesJson: messagesJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompressedBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$CompressedBlocksTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$CompressedBlocksTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CompressedBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $CompressedBlocksTable,
      CompressedBlockRow,
      $$CompressedBlocksTableFilterComposer,
      $$CompressedBlocksTableOrderingComposer,
      $$CompressedBlocksTableAnnotationComposer,
      $$CompressedBlocksTableCreateCompanionBuilder,
      $$CompressedBlocksTableUpdateCompanionBuilder,
      (CompressedBlockRow, $$CompressedBlocksTableReferences),
      CompressedBlockRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$UsageDailyTableCreateCompanionBuilder =
    UsageDailyCompanion Function({
      required String modelId,
      required String providerName,
      required String date,
      Value<int> promptTokens,
      Value<int> completionTokens,
      Value<int> calls,
      Value<int> rowid,
    });
typedef $$UsageDailyTableUpdateCompanionBuilder =
    UsageDailyCompanion Function({
      Value<String> modelId,
      Value<String> providerName,
      Value<String> date,
      Value<int> promptTokens,
      Value<int> completionTokens,
      Value<int> calls,
      Value<int> rowid,
    });

class $$UsageDailyTableFilterComposer
    extends Composer<_$NonaAppDatabase, $UsageDailyTable> {
  $$UsageDailyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calls => $composableBuilder(
    column: $table.calls,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsageDailyTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $UsageDailyTable> {
  $$UsageDailyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calls => $composableBuilder(
    column: $table.calls,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsageDailyTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $UsageDailyTable> {
  $$UsageDailyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get promptTokens => $composableBuilder(
    column: $table.promptTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionTokens => $composableBuilder(
    column: $table.completionTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calls =>
      $composableBuilder(column: $table.calls, builder: (column) => column);
}

class $$UsageDailyTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $UsageDailyTable,
          UsageDailyRow,
          $$UsageDailyTableFilterComposer,
          $$UsageDailyTableOrderingComposer,
          $$UsageDailyTableAnnotationComposer,
          $$UsageDailyTableCreateCompanionBuilder,
          $$UsageDailyTableUpdateCompanionBuilder,
          (
            UsageDailyRow,
            BaseReferences<_$NonaAppDatabase, $UsageDailyTable, UsageDailyRow>,
          ),
          UsageDailyRow,
          PrefetchHooks Function()
        > {
  $$UsageDailyTableTableManager(_$NonaAppDatabase db, $UsageDailyTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageDailyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> modelId = const Value.absent(),
                Value<String> providerName = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> promptTokens = const Value.absent(),
                Value<int> completionTokens = const Value.absent(),
                Value<int> calls = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageDailyCompanion(
                modelId: modelId,
                providerName: providerName,
                date: date,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                calls: calls,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modelId,
                required String providerName,
                required String date,
                Value<int> promptTokens = const Value.absent(),
                Value<int> completionTokens = const Value.absent(),
                Value<int> calls = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsageDailyCompanion.insert(
                modelId: modelId,
                providerName: providerName,
                date: date,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                calls: calls,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsageDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $UsageDailyTable,
      UsageDailyRow,
      $$UsageDailyTableFilterComposer,
      $$UsageDailyTableOrderingComposer,
      $$UsageDailyTableAnnotationComposer,
      $$UsageDailyTableCreateCompanionBuilder,
      $$UsageDailyTableUpdateCompanionBuilder,
      (
        UsageDailyRow,
        BaseReferences<_$NonaAppDatabase, $UsageDailyTable, UsageDailyRow>,
      ),
      UsageDailyRow,
      PrefetchHooks Function()
    >;
typedef $$GenMediaTableCreateCompanionBuilder =
    GenMediaCompanion Function({
      required String id,
      required String prompt,
      required String modelId,
      required String path,
      Value<String> type,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$GenMediaTableUpdateCompanionBuilder =
    GenMediaCompanion Function({
      Value<String> id,
      Value<String> prompt,
      Value<String> modelId,
      Value<String> path,
      Value<String> type,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$GenMediaTableFilterComposer
    extends Composer<_$NonaAppDatabase, $GenMediaTable> {
  $$GenMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GenMediaTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $GenMediaTable> {
  $$GenMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GenMediaTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $GenMediaTable> {
  $$GenMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GenMediaTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $GenMediaTable,
          GenMediaRow,
          $$GenMediaTableFilterComposer,
          $$GenMediaTableOrderingComposer,
          $$GenMediaTableAnnotationComposer,
          $$GenMediaTableCreateCompanionBuilder,
          $$GenMediaTableUpdateCompanionBuilder,
          (
            GenMediaRow,
            BaseReferences<_$NonaAppDatabase, $GenMediaTable, GenMediaRow>,
          ),
          GenMediaRow,
          PrefetchHooks Function()
        > {
  $$GenMediaTableTableManager(_$NonaAppDatabase db, $GenMediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenMediaCompanion(
                id: id,
                prompt: prompt,
                modelId: modelId,
                path: path,
                type: type,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String prompt,
                required String modelId,
                required String path,
                Value<String> type = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GenMediaCompanion.insert(
                id: id,
                prompt: prompt,
                modelId: modelId,
                path: path,
                type: type,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GenMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $GenMediaTable,
      GenMediaRow,
      $$GenMediaTableFilterComposer,
      $$GenMediaTableOrderingComposer,
      $$GenMediaTableAnnotationComposer,
      $$GenMediaTableCreateCompanionBuilder,
      $$GenMediaTableUpdateCompanionBuilder,
      (
        GenMediaRow,
        BaseReferences<_$NonaAppDatabase, $GenMediaTable, GenMediaRow>,
      ),
      GenMediaRow,
      PrefetchHooks Function()
    >;
typedef $$KbLibrariesTableCreateCompanionBuilder =
    KbLibrariesCompanion Function({
      required String id,
      required String name,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$KbLibrariesTableUpdateCompanionBuilder =
    KbLibrariesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$KbLibrariesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $KbLibrariesTable> {
  $$KbLibrariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KbLibrariesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $KbLibrariesTable> {
  $$KbLibrariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KbLibrariesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $KbLibrariesTable> {
  $$KbLibrariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KbLibrariesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $KbLibrariesTable,
          KbLibraryRow,
          $$KbLibrariesTableFilterComposer,
          $$KbLibrariesTableOrderingComposer,
          $$KbLibrariesTableAnnotationComposer,
          $$KbLibrariesTableCreateCompanionBuilder,
          $$KbLibrariesTableUpdateCompanionBuilder,
          (
            KbLibraryRow,
            BaseReferences<_$NonaAppDatabase, $KbLibrariesTable, KbLibraryRow>,
          ),
          KbLibraryRow,
          PrefetchHooks Function()
        > {
  $$KbLibrariesTableTableManager(_$NonaAppDatabase db, $KbLibrariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbLibrariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbLibrariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbLibrariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbLibrariesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => KbLibrariesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KbLibrariesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $KbLibrariesTable,
      KbLibraryRow,
      $$KbLibrariesTableFilterComposer,
      $$KbLibrariesTableOrderingComposer,
      $$KbLibrariesTableAnnotationComposer,
      $$KbLibrariesTableCreateCompanionBuilder,
      $$KbLibrariesTableUpdateCompanionBuilder,
      (
        KbLibraryRow,
        BaseReferences<_$NonaAppDatabase, $KbLibrariesTable, KbLibraryRow>,
      ),
      KbLibraryRow,
      PrefetchHooks Function()
    >;
typedef $$KbDocumentsTableCreateCompanionBuilder =
    KbDocumentsCompanion Function({
      required String id,
      required String name,
      Value<String> source,
      Value<String> libraryId,
      Value<String?> embeddingModel,
      Value<int> chunkCount,
      Value<bool> enabled,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$KbDocumentsTableUpdateCompanionBuilder =
    KbDocumentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> source,
      Value<String> libraryId,
      Value<String?> embeddingModel,
      Value<int> chunkCount,
      Value<bool> enabled,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$KbDocumentsTableReferences
    extends
        BaseReferences<_$NonaAppDatabase, $KbDocumentsTable, KbDocumentRow> {
  $$KbDocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$KbChunksTable, List<KbChunkRow>>
  _kbChunksRefsTable(_$NonaAppDatabase db) => MultiTypedResultKey.fromTable(
    db.kbChunks,
    aliasName: $_aliasNameGenerator(db.kbDocuments.id, db.kbChunks.docId),
  );

  $$KbChunksTableProcessedTableManager get kbChunksRefs {
    final manager = $$KbChunksTableTableManager(
      $_db,
      $_db.kbChunks,
    ).filter((f) => f.docId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_kbChunksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KbDocumentsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $KbDocumentsTable> {
  $$KbDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> kbChunksRefs(
    Expression<bool> Function($$KbChunksTableFilterComposer f) f,
  ) {
    final $$KbChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.docId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableFilterComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbDocumentsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $KbDocumentsTable> {
  $$KbDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KbDocumentsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $KbDocumentsTable> {
  $$KbDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> kbChunksRefs<T extends Object>(
    Expression<T> Function($$KbChunksTableAnnotationComposer a) f,
  ) {
    final $$KbChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.docId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbDocumentsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $KbDocumentsTable,
          KbDocumentRow,
          $$KbDocumentsTableFilterComposer,
          $$KbDocumentsTableOrderingComposer,
          $$KbDocumentsTableAnnotationComposer,
          $$KbDocumentsTableCreateCompanionBuilder,
          $$KbDocumentsTableUpdateCompanionBuilder,
          (KbDocumentRow, $$KbDocumentsTableReferences),
          KbDocumentRow,
          PrefetchHooks Function({bool kbChunksRefs})
        > {
  $$KbDocumentsTableTableManager(_$NonaAppDatabase db, $KbDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> libraryId = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int> chunkCount = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbDocumentsCompanion(
                id: id,
                name: name,
                source: source,
                libraryId: libraryId,
                embeddingModel: embeddingModel,
                chunkCount: chunkCount,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> source = const Value.absent(),
                Value<String> libraryId = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int> chunkCount = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => KbDocumentsCompanion.insert(
                id: id,
                name: name,
                source: source,
                libraryId: libraryId,
                embeddingModel: embeddingModel,
                chunkCount: chunkCount,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KbDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({kbChunksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (kbChunksRefs) db.kbChunks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (kbChunksRefs)
                    await $_getPrefetchedData<
                      KbDocumentRow,
                      $KbDocumentsTable,
                      KbChunkRow
                    >(
                      currentTable: table,
                      referencedTable: $$KbDocumentsTableReferences
                          ._kbChunksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KbDocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).kbChunksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.docId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KbDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $KbDocumentsTable,
      KbDocumentRow,
      $$KbDocumentsTableFilterComposer,
      $$KbDocumentsTableOrderingComposer,
      $$KbDocumentsTableAnnotationComposer,
      $$KbDocumentsTableCreateCompanionBuilder,
      $$KbDocumentsTableUpdateCompanionBuilder,
      (KbDocumentRow, $$KbDocumentsTableReferences),
      KbDocumentRow,
      PrefetchHooks Function({bool kbChunksRefs})
    >;
typedef $$KbChunksTableCreateCompanionBuilder =
    KbChunksCompanion Function({
      required String id,
      required String docId,
      Value<int> position,
      required String chunkText,
      Value<int> tokens,
      Value<int> rowid,
    });
typedef $$KbChunksTableUpdateCompanionBuilder =
    KbChunksCompanion Function({
      Value<String> id,
      Value<String> docId,
      Value<int> position,
      Value<String> chunkText,
      Value<int> tokens,
      Value<int> rowid,
    });

final class $$KbChunksTableReferences
    extends BaseReferences<_$NonaAppDatabase, $KbChunksTable, KbChunkRow> {
  $$KbChunksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbDocumentsTable _docIdTable(_$NonaAppDatabase db) => db.kbDocuments
      .createAlias($_aliasNameGenerator(db.kbChunks.docId, db.kbDocuments.id));

  $$KbDocumentsTableProcessedTableManager get docId {
    final $_column = $_itemColumn<String>('doc_id')!;

    final manager = $$KbDocumentsTableTableManager(
      $_db,
      $_db.kbDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_docIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$KbBigramsTable, List<KbBigramRow>>
  _kbBigramsRefsTable(_$NonaAppDatabase db) => MultiTypedResultKey.fromTable(
    db.kbBigrams,
    aliasName: $_aliasNameGenerator(db.kbChunks.id, db.kbBigrams.chunkId),
  );

  $$KbBigramsTableProcessedTableManager get kbBigramsRefs {
    final manager = $$KbBigramsTableTableManager(
      $_db,
      $_db.kbBigrams,
    ).filter((f) => f.chunkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_kbBigramsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KbVectorsTable, List<KbVectorRow>>
  _kbVectorsRefsTable(_$NonaAppDatabase db) => MultiTypedResultKey.fromTable(
    db.kbVectors,
    aliasName: $_aliasNameGenerator(db.kbChunks.id, db.kbVectors.chunkId),
  );

  $$KbVectorsTableProcessedTableManager get kbVectorsRefs {
    final manager = $$KbVectorsTableTableManager(
      $_db,
      $_db.kbVectors,
    ).filter((f) => f.chunkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_kbVectorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KbChunksTableFilterComposer
    extends Composer<_$NonaAppDatabase, $KbChunksTable> {
  $$KbChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chunkText => $composableBuilder(
    column: $table.chunkText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokens => $composableBuilder(
    column: $table.tokens,
    builder: (column) => ColumnFilters(column),
  );

  $$KbDocumentsTableFilterComposer get docId {
    final $$KbDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.kbDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.kbDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> kbBigramsRefs(
    Expression<bool> Function($$KbBigramsTableFilterComposer f) f,
  ) {
    final $$KbBigramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbBigrams,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbBigramsTableFilterComposer(
            $db: $db,
            $table: $db.kbBigrams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> kbVectorsRefs(
    Expression<bool> Function($$KbVectorsTableFilterComposer f) f,
  ) {
    final $$KbVectorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbVectors,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbVectorsTableFilterComposer(
            $db: $db,
            $table: $db.kbVectors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbChunksTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $KbChunksTable> {
  $$KbChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chunkText => $composableBuilder(
    column: $table.chunkText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokens => $composableBuilder(
    column: $table.tokens,
    builder: (column) => ColumnOrderings(column),
  );

  $$KbDocumentsTableOrderingComposer get docId {
    final $$KbDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.kbDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.kbDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbChunksTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $KbChunksTable> {
  $$KbChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get chunkText =>
      $composableBuilder(column: $table.chunkText, builder: (column) => column);

  GeneratedColumn<int> get tokens =>
      $composableBuilder(column: $table.tokens, builder: (column) => column);

  $$KbDocumentsTableAnnotationComposer get docId {
    final $$KbDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.kbDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.kbDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> kbBigramsRefs<T extends Object>(
    Expression<T> Function($$KbBigramsTableAnnotationComposer a) f,
  ) {
    final $$KbBigramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbBigrams,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbBigramsTableAnnotationComposer(
            $db: $db,
            $table: $db.kbBigrams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> kbVectorsRefs<T extends Object>(
    Expression<T> Function($$KbVectorsTableAnnotationComposer a) f,
  ) {
    final $$KbVectorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kbVectors,
      getReferencedColumn: (t) => t.chunkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbVectorsTableAnnotationComposer(
            $db: $db,
            $table: $db.kbVectors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KbChunksTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $KbChunksTable,
          KbChunkRow,
          $$KbChunksTableFilterComposer,
          $$KbChunksTableOrderingComposer,
          $$KbChunksTableAnnotationComposer,
          $$KbChunksTableCreateCompanionBuilder,
          $$KbChunksTableUpdateCompanionBuilder,
          (KbChunkRow, $$KbChunksTableReferences),
          KbChunkRow,
          PrefetchHooks Function({
            bool docId,
            bool kbBigramsRefs,
            bool kbVectorsRefs,
          })
        > {
  $$KbChunksTableTableManager(_$NonaAppDatabase db, $KbChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> chunkText = const Value.absent(),
                Value<int> tokens = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbChunksCompanion(
                id: id,
                docId: docId,
                position: position,
                chunkText: chunkText,
                tokens: tokens,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String docId,
                Value<int> position = const Value.absent(),
                required String chunkText,
                Value<int> tokens = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbChunksCompanion.insert(
                id: id,
                docId: docId,
                position: position,
                chunkText: chunkText,
                tokens: tokens,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KbChunksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({docId = false, kbBigramsRefs = false, kbVectorsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (kbBigramsRefs) db.kbBigrams,
                    if (kbVectorsRefs) db.kbVectors,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (docId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.docId,
                                    referencedTable: $$KbChunksTableReferences
                                        ._docIdTable(db),
                                    referencedColumn: $$KbChunksTableReferences
                                        ._docIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (kbBigramsRefs)
                        await $_getPrefetchedData<
                          KbChunkRow,
                          $KbChunksTable,
                          KbBigramRow
                        >(
                          currentTable: table,
                          referencedTable: $$KbChunksTableReferences
                              ._kbBigramsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KbChunksTableReferences(
                                db,
                                table,
                                p0,
                              ).kbBigramsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chunkId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (kbVectorsRefs)
                        await $_getPrefetchedData<
                          KbChunkRow,
                          $KbChunksTable,
                          KbVectorRow
                        >(
                          currentTable: table,
                          referencedTable: $$KbChunksTableReferences
                              ._kbVectorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KbChunksTableReferences(
                                db,
                                table,
                                p0,
                              ).kbVectorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chunkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$KbChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $KbChunksTable,
      KbChunkRow,
      $$KbChunksTableFilterComposer,
      $$KbChunksTableOrderingComposer,
      $$KbChunksTableAnnotationComposer,
      $$KbChunksTableCreateCompanionBuilder,
      $$KbChunksTableUpdateCompanionBuilder,
      (KbChunkRow, $$KbChunksTableReferences),
      KbChunkRow,
      PrefetchHooks Function({
        bool docId,
        bool kbBigramsRefs,
        bool kbVectorsRefs,
      })
    >;
typedef $$KbBigramsTableCreateCompanionBuilder =
    KbBigramsCompanion Function({
      required String bigram,
      required String chunkId,
      Value<int> rowid,
    });
typedef $$KbBigramsTableUpdateCompanionBuilder =
    KbBigramsCompanion Function({
      Value<String> bigram,
      Value<String> chunkId,
      Value<int> rowid,
    });

final class $$KbBigramsTableReferences
    extends BaseReferences<_$NonaAppDatabase, $KbBigramsTable, KbBigramRow> {
  $$KbBigramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbChunksTable _chunkIdTable(_$NonaAppDatabase db) => db.kbChunks
      .createAlias($_aliasNameGenerator(db.kbBigrams.chunkId, db.kbChunks.id));

  $$KbChunksTableProcessedTableManager get chunkId {
    final $_column = $_itemColumn<String>('chunk_id')!;

    final manager = $$KbChunksTableTableManager(
      $_db,
      $_db.kbChunks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chunkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KbBigramsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $KbBigramsTable> {
  $$KbBigramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bigram => $composableBuilder(
    column: $table.bigram,
    builder: (column) => ColumnFilters(column),
  );

  $$KbChunksTableFilterComposer get chunkId {
    final $$KbChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableFilterComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbBigramsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $KbBigramsTable> {
  $$KbBigramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bigram => $composableBuilder(
    column: $table.bigram,
    builder: (column) => ColumnOrderings(column),
  );

  $$KbChunksTableOrderingComposer get chunkId {
    final $$KbChunksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableOrderingComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbBigramsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $KbBigramsTable> {
  $$KbBigramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bigram =>
      $composableBuilder(column: $table.bigram, builder: (column) => column);

  $$KbChunksTableAnnotationComposer get chunkId {
    final $$KbChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbBigramsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $KbBigramsTable,
          KbBigramRow,
          $$KbBigramsTableFilterComposer,
          $$KbBigramsTableOrderingComposer,
          $$KbBigramsTableAnnotationComposer,
          $$KbBigramsTableCreateCompanionBuilder,
          $$KbBigramsTableUpdateCompanionBuilder,
          (KbBigramRow, $$KbBigramsTableReferences),
          KbBigramRow,
          PrefetchHooks Function({bool chunkId})
        > {
  $$KbBigramsTableTableManager(_$NonaAppDatabase db, $KbBigramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbBigramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbBigramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbBigramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bigram = const Value.absent(),
                Value<String> chunkId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbBigramsCompanion(
                bigram: bigram,
                chunkId: chunkId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bigram,
                required String chunkId,
                Value<int> rowid = const Value.absent(),
              }) => KbBigramsCompanion.insert(
                bigram: bigram,
                chunkId: chunkId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KbBigramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chunkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chunkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chunkId,
                                referencedTable: $$KbBigramsTableReferences
                                    ._chunkIdTable(db),
                                referencedColumn: $$KbBigramsTableReferences
                                    ._chunkIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$KbBigramsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $KbBigramsTable,
      KbBigramRow,
      $$KbBigramsTableFilterComposer,
      $$KbBigramsTableOrderingComposer,
      $$KbBigramsTableAnnotationComposer,
      $$KbBigramsTableCreateCompanionBuilder,
      $$KbBigramsTableUpdateCompanionBuilder,
      (KbBigramRow, $$KbBigramsTableReferences),
      KbBigramRow,
      PrefetchHooks Function({bool chunkId})
    >;
typedef $$KbVectorsTableCreateCompanionBuilder =
    KbVectorsCompanion Function({
      required String chunkId,
      required int dim,
      required Uint8List vec,
      Value<int> rowid,
    });
typedef $$KbVectorsTableUpdateCompanionBuilder =
    KbVectorsCompanion Function({
      Value<String> chunkId,
      Value<int> dim,
      Value<Uint8List> vec,
      Value<int> rowid,
    });

final class $$KbVectorsTableReferences
    extends BaseReferences<_$NonaAppDatabase, $KbVectorsTable, KbVectorRow> {
  $$KbVectorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KbChunksTable _chunkIdTable(_$NonaAppDatabase db) => db.kbChunks
      .createAlias($_aliasNameGenerator(db.kbVectors.chunkId, db.kbChunks.id));

  $$KbChunksTableProcessedTableManager get chunkId {
    final $_column = $_itemColumn<String>('chunk_id')!;

    final manager = $$KbChunksTableTableManager(
      $_db,
      $_db.kbChunks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chunkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KbVectorsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $KbVectorsTable> {
  $$KbVectorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get vec => $composableBuilder(
    column: $table.vec,
    builder: (column) => ColumnFilters(column),
  );

  $$KbChunksTableFilterComposer get chunkId {
    final $$KbChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableFilterComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbVectorsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $KbVectorsTable> {
  $$KbVectorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dim => $composableBuilder(
    column: $table.dim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get vec => $composableBuilder(
    column: $table.vec,
    builder: (column) => ColumnOrderings(column),
  );

  $$KbChunksTableOrderingComposer get chunkId {
    final $$KbChunksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableOrderingComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbVectorsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $KbVectorsTable> {
  $$KbVectorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dim =>
      $composableBuilder(column: $table.dim, builder: (column) => column);

  GeneratedColumn<Uint8List> get vec =>
      $composableBuilder(column: $table.vec, builder: (column) => column);

  $$KbChunksTableAnnotationComposer get chunkId {
    final $$KbChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chunkId,
      referencedTable: $db.kbChunks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KbChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.kbChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KbVectorsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $KbVectorsTable,
          KbVectorRow,
          $$KbVectorsTableFilterComposer,
          $$KbVectorsTableOrderingComposer,
          $$KbVectorsTableAnnotationComposer,
          $$KbVectorsTableCreateCompanionBuilder,
          $$KbVectorsTableUpdateCompanionBuilder,
          (KbVectorRow, $$KbVectorsTableReferences),
          KbVectorRow,
          PrefetchHooks Function({bool chunkId})
        > {
  $$KbVectorsTableTableManager(_$NonaAppDatabase db, $KbVectorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KbVectorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KbVectorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KbVectorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chunkId = const Value.absent(),
                Value<int> dim = const Value.absent(),
                Value<Uint8List> vec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KbVectorsCompanion(
                chunkId: chunkId,
                dim: dim,
                vec: vec,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chunkId,
                required int dim,
                required Uint8List vec,
                Value<int> rowid = const Value.absent(),
              }) => KbVectorsCompanion.insert(
                chunkId: chunkId,
                dim: dim,
                vec: vec,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KbVectorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chunkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chunkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chunkId,
                                referencedTable: $$KbVectorsTableReferences
                                    ._chunkIdTable(db),
                                referencedColumn: $$KbVectorsTableReferences
                                    ._chunkIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$KbVectorsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $KbVectorsTable,
      KbVectorRow,
      $$KbVectorsTableFilterComposer,
      $$KbVectorsTableOrderingComposer,
      $$KbVectorsTableAnnotationComposer,
      $$KbVectorsTableCreateCompanionBuilder,
      $$KbVectorsTableUpdateCompanionBuilder,
      (KbVectorRow, $$KbVectorsTableReferences),
      KbVectorRow,
      PrefetchHooks Function({bool chunkId})
    >;
typedef $$MemoriesTableCreateCompanionBuilder =
    MemoriesCompanion Function({
      required String id,
      required String scope,
      Value<String?> scopeRef,
      required String content,
      Value<String> category,
      Value<bool> pinned,
      Value<String?> sourceMessageId,
      required int createdAt,
      required int updatedAt,
      Value<String> tagsJson,
      Value<String> priority,
      Value<int> useCount,
      Value<int?> lastUsedAt,
      Value<String> historyJson,
      Value<int> rowid,
    });
typedef $$MemoriesTableUpdateCompanionBuilder =
    MemoriesCompanion Function({
      Value<String> id,
      Value<String> scope,
      Value<String?> scopeRef,
      Value<String> content,
      Value<String> category,
      Value<bool> pinned,
      Value<String?> sourceMessageId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> tagsJson,
      Value<String> priority,
      Value<int> useCount,
      Value<int?> lastUsedAt,
      Value<String> historyJson,
      Value<int> rowid,
    });

class $$MemoriesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $MemoriesTable> {
  $$MemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoriesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $MemoriesTable> {
  $$MemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoriesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $MemoriesTable> {
  $$MemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeRef =>
      $composableBuilder(column: $table.scopeRef, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => column,
  );
}

class $$MemoriesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $MemoriesTable,
          MemoryRow,
          $$MemoriesTableFilterComposer,
          $$MemoriesTableOrderingComposer,
          $$MemoriesTableAnnotationComposer,
          $$MemoriesTableCreateCompanionBuilder,
          $$MemoriesTableUpdateCompanionBuilder,
          (
            MemoryRow,
            BaseReferences<_$NonaAppDatabase, $MemoriesTable, MemoryRow>,
          ),
          MemoryRow,
          PrefetchHooks Function()
        > {
  $$MemoriesTableTableManager(_$NonaAppDatabase db, $MemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> scopeRef = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<String?> sourceMessageId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<String> historyJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion(
                id: id,
                scope: scope,
                scopeRef: scopeRef,
                content: content,
                category: category,
                pinned: pinned,
                sourceMessageId: sourceMessageId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tagsJson: tagsJson,
                priority: priority,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                historyJson: historyJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scope,
                Value<String?> scopeRef = const Value.absent(),
                required String content,
                Value<String> category = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<String?> sourceMessageId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> tagsJson = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<String> historyJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion.insert(
                id: id,
                scope: scope,
                scopeRef: scopeRef,
                content: content,
                category: category,
                pinned: pinned,
                sourceMessageId: sourceMessageId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tagsJson: tagsJson,
                priority: priority,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                historyJson: historyJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $MemoriesTable,
      MemoryRow,
      $$MemoriesTableFilterComposer,
      $$MemoriesTableOrderingComposer,
      $$MemoriesTableAnnotationComposer,
      $$MemoriesTableCreateCompanionBuilder,
      $$MemoriesTableUpdateCompanionBuilder,
      (MemoryRow, BaseReferences<_$NonaAppDatabase, $MemoriesTable, MemoryRow>),
      MemoryRow,
      PrefetchHooks Function()
    >;
typedef $$MemorySpacesTableCreateCompanionBuilder =
    MemorySpacesCompanion Function({
      required String id,
      required String scope,
      Value<String> scopeRef,
      Value<int> maxItems,
      Value<int> maxInjectTokens,
      Value<int> maxItemChars,
      Value<int> extractionInterval,
      Value<int> rowid,
    });
typedef $$MemorySpacesTableUpdateCompanionBuilder =
    MemorySpacesCompanion Function({
      Value<String> id,
      Value<String> scope,
      Value<String> scopeRef,
      Value<int> maxItems,
      Value<int> maxInjectTokens,
      Value<int> maxItemChars,
      Value<int> extractionInterval,
      Value<int> rowid,
    });

class $$MemorySpacesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $MemorySpacesTable> {
  $$MemorySpacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxItems => $composableBuilder(
    column: $table.maxItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxInjectTokens => $composableBuilder(
    column: $table.maxInjectTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxItemChars => $composableBuilder(
    column: $table.maxItemChars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extractionInterval => $composableBuilder(
    column: $table.extractionInterval,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemorySpacesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $MemorySpacesTable> {
  $$MemorySpacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxItems => $composableBuilder(
    column: $table.maxItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxInjectTokens => $composableBuilder(
    column: $table.maxInjectTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxItemChars => $composableBuilder(
    column: $table.maxItemChars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extractionInterval => $composableBuilder(
    column: $table.extractionInterval,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemorySpacesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $MemorySpacesTable> {
  $$MemorySpacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeRef =>
      $composableBuilder(column: $table.scopeRef, builder: (column) => column);

  GeneratedColumn<int> get maxItems =>
      $composableBuilder(column: $table.maxItems, builder: (column) => column);

  GeneratedColumn<int> get maxInjectTokens => $composableBuilder(
    column: $table.maxInjectTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxItemChars => $composableBuilder(
    column: $table.maxItemChars,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extractionInterval => $composableBuilder(
    column: $table.extractionInterval,
    builder: (column) => column,
  );
}

class $$MemorySpacesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $MemorySpacesTable,
          MemorySpaceRow,
          $$MemorySpacesTableFilterComposer,
          $$MemorySpacesTableOrderingComposer,
          $$MemorySpacesTableAnnotationComposer,
          $$MemorySpacesTableCreateCompanionBuilder,
          $$MemorySpacesTableUpdateCompanionBuilder,
          (
            MemorySpaceRow,
            BaseReferences<
              _$NonaAppDatabase,
              $MemorySpacesTable,
              MemorySpaceRow
            >,
          ),
          MemorySpaceRow,
          PrefetchHooks Function()
        > {
  $$MemorySpacesTableTableManager(
    _$NonaAppDatabase db,
    $MemorySpacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorySpacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorySpacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemorySpacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> scopeRef = const Value.absent(),
                Value<int> maxItems = const Value.absent(),
                Value<int> maxInjectTokens = const Value.absent(),
                Value<int> maxItemChars = const Value.absent(),
                Value<int> extractionInterval = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorySpacesCompanion(
                id: id,
                scope: scope,
                scopeRef: scopeRef,
                maxItems: maxItems,
                maxInjectTokens: maxInjectTokens,
                maxItemChars: maxItemChars,
                extractionInterval: extractionInterval,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scope,
                Value<String> scopeRef = const Value.absent(),
                Value<int> maxItems = const Value.absent(),
                Value<int> maxInjectTokens = const Value.absent(),
                Value<int> maxItemChars = const Value.absent(),
                Value<int> extractionInterval = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorySpacesCompanion.insert(
                id: id,
                scope: scope,
                scopeRef: scopeRef,
                maxItems: maxItems,
                maxInjectTokens: maxInjectTokens,
                maxItemChars: maxItemChars,
                extractionInterval: extractionInterval,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemorySpacesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $MemorySpacesTable,
      MemorySpaceRow,
      $$MemorySpacesTableFilterComposer,
      $$MemorySpacesTableOrderingComposer,
      $$MemorySpacesTableAnnotationComposer,
      $$MemorySpacesTableCreateCompanionBuilder,
      $$MemorySpacesTableUpdateCompanionBuilder,
      (
        MemorySpaceRow,
        BaseReferences<_$NonaAppDatabase, $MemorySpacesTable, MemorySpaceRow>,
      ),
      MemorySpaceRow,
      PrefetchHooks Function()
    >;
typedef $$MemoryStateTableCreateCompanionBuilder =
    MemoryStateCompanion Function({
      required String sessionId,
      Value<int> lastIndex,
      Value<int> rowid,
    });
typedef $$MemoryStateTableUpdateCompanionBuilder =
    MemoryStateCompanion Function({
      Value<String> sessionId,
      Value<int> lastIndex,
      Value<int> rowid,
    });

class $$MemoryStateTableFilterComposer
    extends Composer<_$NonaAppDatabase, $MemoryStateTable> {
  $$MemoryStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastIndex => $composableBuilder(
    column: $table.lastIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryStateTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $MemoryStateTable> {
  $$MemoryStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastIndex => $composableBuilder(
    column: $table.lastIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryStateTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $MemoryStateTable> {
  $$MemoryStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get lastIndex =>
      $composableBuilder(column: $table.lastIndex, builder: (column) => column);
}

class $$MemoryStateTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $MemoryStateTable,
          MemoryStateRow,
          $$MemoryStateTableFilterComposer,
          $$MemoryStateTableOrderingComposer,
          $$MemoryStateTableAnnotationComposer,
          $$MemoryStateTableCreateCompanionBuilder,
          $$MemoryStateTableUpdateCompanionBuilder,
          (
            MemoryStateRow,
            BaseReferences<
              _$NonaAppDatabase,
              $MemoryStateTable,
              MemoryStateRow
            >,
          ),
          MemoryStateRow,
          PrefetchHooks Function()
        > {
  $$MemoryStateTableTableManager(_$NonaAppDatabase db, $MemoryStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> lastIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryStateCompanion(
                sessionId: sessionId,
                lastIndex: lastIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<int> lastIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryStateCompanion.insert(
                sessionId: sessionId,
                lastIndex: lastIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryStateTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $MemoryStateTable,
      MemoryStateRow,
      $$MemoryStateTableFilterComposer,
      $$MemoryStateTableOrderingComposer,
      $$MemoryStateTableAnnotationComposer,
      $$MemoryStateTableCreateCompanionBuilder,
      $$MemoryStateTableUpdateCompanionBuilder,
      (
        MemoryStateRow,
        BaseReferences<_$NonaAppDatabase, $MemoryStateTable, MemoryStateRow>,
      ),
      MemoryStateRow,
      PrefetchHooks Function()
    >;
typedef $$WorldBookEntriesTableCreateCompanionBuilder =
    WorldBookEntriesCompanion Function({
      required String id,
      required String title,
      Value<String> keywordsJson,
      required String content,
      Value<int> priority,
      Value<int> scanDepth,
      Value<bool> caseSensitive,
      Value<String> injectionPosition,
      Value<String> role,
      Value<bool> constantActive,
      Value<String> scope,
      Value<String?> scopeRef,
      Value<bool> enabled,
      Value<bool> useRegex,
      Value<String?> bookId,
      Value<int> injectDepth,
      Value<int> rowid,
    });
typedef $$WorldBookEntriesTableUpdateCompanionBuilder =
    WorldBookEntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> keywordsJson,
      Value<String> content,
      Value<int> priority,
      Value<int> scanDepth,
      Value<bool> caseSensitive,
      Value<String> injectionPosition,
      Value<String> role,
      Value<bool> constantActive,
      Value<String> scope,
      Value<String?> scopeRef,
      Value<bool> enabled,
      Value<bool> useRegex,
      Value<String?> bookId,
      Value<int> injectDepth,
      Value<int> rowid,
    });

class $$WorldBookEntriesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $WorldBookEntriesTable> {
  $$WorldBookEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywordsJson => $composableBuilder(
    column: $table.keywordsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanDepth => $composableBuilder(
    column: $table.scanDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get caseSensitive => $composableBuilder(
    column: $table.caseSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get injectionPosition => $composableBuilder(
    column: $table.injectionPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get constantActive => $composableBuilder(
    column: $table.constantActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useRegex => $composableBuilder(
    column: $table.useRegex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get injectDepth => $composableBuilder(
    column: $table.injectDepth,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorldBookEntriesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $WorldBookEntriesTable> {
  $$WorldBookEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywordsJson => $composableBuilder(
    column: $table.keywordsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanDepth => $composableBuilder(
    column: $table.scanDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get caseSensitive => $composableBuilder(
    column: $table.caseSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get injectionPosition => $composableBuilder(
    column: $table.injectionPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get constantActive => $composableBuilder(
    column: $table.constantActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeRef => $composableBuilder(
    column: $table.scopeRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useRegex => $composableBuilder(
    column: $table.useRegex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get injectDepth => $composableBuilder(
    column: $table.injectDepth,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorldBookEntriesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $WorldBookEntriesTable> {
  $$WorldBookEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get keywordsJson => $composableBuilder(
    column: $table.keywordsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get scanDepth =>
      $composableBuilder(column: $table.scanDepth, builder: (column) => column);

  GeneratedColumn<bool> get caseSensitive => $composableBuilder(
    column: $table.caseSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get injectionPosition => $composableBuilder(
    column: $table.injectionPosition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get constantActive => $composableBuilder(
    column: $table.constantActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeRef =>
      $composableBuilder(column: $table.scopeRef, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get useRegex =>
      $composableBuilder(column: $table.useRegex, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get injectDepth => $composableBuilder(
    column: $table.injectDepth,
    builder: (column) => column,
  );
}

class $$WorldBookEntriesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $WorldBookEntriesTable,
          WorldBookEntryRow,
          $$WorldBookEntriesTableFilterComposer,
          $$WorldBookEntriesTableOrderingComposer,
          $$WorldBookEntriesTableAnnotationComposer,
          $$WorldBookEntriesTableCreateCompanionBuilder,
          $$WorldBookEntriesTableUpdateCompanionBuilder,
          (
            WorldBookEntryRow,
            BaseReferences<
              _$NonaAppDatabase,
              $WorldBookEntriesTable,
              WorldBookEntryRow
            >,
          ),
          WorldBookEntryRow,
          PrefetchHooks Function()
        > {
  $$WorldBookEntriesTableTableManager(
    _$NonaAppDatabase db,
    $WorldBookEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldBookEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldBookEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldBookEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> keywordsJson = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> scanDepth = const Value.absent(),
                Value<bool> caseSensitive = const Value.absent(),
                Value<String> injectionPosition = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> constantActive = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> scopeRef = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> useRegex = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<int> injectDepth = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldBookEntriesCompanion(
                id: id,
                title: title,
                keywordsJson: keywordsJson,
                content: content,
                priority: priority,
                scanDepth: scanDepth,
                caseSensitive: caseSensitive,
                injectionPosition: injectionPosition,
                role: role,
                constantActive: constantActive,
                scope: scope,
                scopeRef: scopeRef,
                enabled: enabled,
                useRegex: useRegex,
                bookId: bookId,
                injectDepth: injectDepth,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> keywordsJson = const Value.absent(),
                required String content,
                Value<int> priority = const Value.absent(),
                Value<int> scanDepth = const Value.absent(),
                Value<bool> caseSensitive = const Value.absent(),
                Value<String> injectionPosition = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> constantActive = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> scopeRef = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> useRegex = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<int> injectDepth = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldBookEntriesCompanion.insert(
                id: id,
                title: title,
                keywordsJson: keywordsJson,
                content: content,
                priority: priority,
                scanDepth: scanDepth,
                caseSensitive: caseSensitive,
                injectionPosition: injectionPosition,
                role: role,
                constantActive: constantActive,
                scope: scope,
                scopeRef: scopeRef,
                enabled: enabled,
                useRegex: useRegex,
                bookId: bookId,
                injectDepth: injectDepth,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorldBookEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $WorldBookEntriesTable,
      WorldBookEntryRow,
      $$WorldBookEntriesTableFilterComposer,
      $$WorldBookEntriesTableOrderingComposer,
      $$WorldBookEntriesTableAnnotationComposer,
      $$WorldBookEntriesTableCreateCompanionBuilder,
      $$WorldBookEntriesTableUpdateCompanionBuilder,
      (
        WorldBookEntryRow,
        BaseReferences<
          _$NonaAppDatabase,
          $WorldBookEntriesTable,
          WorldBookEntryRow
        >,
      ),
      WorldBookEntryRow,
      PrefetchHooks Function()
    >;
typedef $$WorldBooksTableCreateCompanionBuilder =
    WorldBooksCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<bool> enabled,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WorldBooksTableUpdateCompanionBuilder =
    WorldBooksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> enabled,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WorldBooksTableFilterComposer
    extends Composer<_$NonaAppDatabase, $WorldBooksTable> {
  $$WorldBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorldBooksTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $WorldBooksTable> {
  $$WorldBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorldBooksTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $WorldBooksTable> {
  $$WorldBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WorldBooksTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $WorldBooksTable,
          WorldBookRow,
          $$WorldBooksTableFilterComposer,
          $$WorldBooksTableOrderingComposer,
          $$WorldBooksTableAnnotationComposer,
          $$WorldBooksTableCreateCompanionBuilder,
          $$WorldBooksTableUpdateCompanionBuilder,
          (
            WorldBookRow,
            BaseReferences<_$NonaAppDatabase, $WorldBooksTable, WorldBookRow>,
          ),
          WorldBookRow,
          PrefetchHooks Function()
        > {
  $$WorldBooksTableTableManager(_$NonaAppDatabase db, $WorldBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldBooksCompanion(
                id: id,
                name: name,
                description: description,
                enabled: enabled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldBooksCompanion.insert(
                id: id,
                name: name,
                description: description,
                enabled: enabled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorldBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $WorldBooksTable,
      WorldBookRow,
      $$WorldBooksTableFilterComposer,
      $$WorldBooksTableOrderingComposer,
      $$WorldBooksTableAnnotationComposer,
      $$WorldBooksTableCreateCompanionBuilder,
      $$WorldBooksTableUpdateCompanionBuilder,
      (
        WorldBookRow,
        BaseReferences<_$NonaAppDatabase, $WorldBooksTable, WorldBookRow>,
      ),
      WorldBookRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderGroupsTableCreateCompanionBuilder =
    ProviderGroupsCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<String?> color,
      Value<int> rowid,
    });
typedef $$ProviderGroupsTableUpdateCompanionBuilder =
    ProviderGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<String?> color,
      Value<int> rowid,
    });

class $$ProviderGroupsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $ProviderGroupsTable> {
  $$ProviderGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderGroupsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $ProviderGroupsTable> {
  $$ProviderGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderGroupsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $ProviderGroupsTable> {
  $$ProviderGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$ProviderGroupsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $ProviderGroupsTable,
          ProviderGroupRow,
          $$ProviderGroupsTableFilterComposer,
          $$ProviderGroupsTableOrderingComposer,
          $$ProviderGroupsTableAnnotationComposer,
          $$ProviderGroupsTableCreateCompanionBuilder,
          $$ProviderGroupsTableUpdateCompanionBuilder,
          (
            ProviderGroupRow,
            BaseReferences<
              _$NonaAppDatabase,
              $ProviderGroupsTable,
              ProviderGroupRow
            >,
          ),
          ProviderGroupRow,
          PrefetchHooks Function()
        > {
  $$ProviderGroupsTableTableManager(
    _$NonaAppDatabase db,
    $ProviderGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderGroupsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                color: color,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderGroupsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $ProviderGroupsTable,
      ProviderGroupRow,
      $$ProviderGroupsTableFilterComposer,
      $$ProviderGroupsTableOrderingComposer,
      $$ProviderGroupsTableAnnotationComposer,
      $$ProviderGroupsTableCreateCompanionBuilder,
      $$ProviderGroupsTableUpdateCompanionBuilder,
      (
        ProviderGroupRow,
        BaseReferences<
          _$NonaAppDatabase,
          $ProviderGroupsTable,
          ProviderGroupRow
        >,
      ),
      ProviderGroupRow,
      PrefetchHooks Function()
    >;
typedef $$SearchKeysTableCreateCompanionBuilder =
    SearchKeysCompanion Function({
      required String id,
      required String engineId,
      required String key,
      Value<bool> enabled,
      Value<int> failCount,
      Value<int?> lastUsedAt,
      Value<int?> failedAt,
      Value<int> rowid,
    });
typedef $$SearchKeysTableUpdateCompanionBuilder =
    SearchKeysCompanion Function({
      Value<String> id,
      Value<String> engineId,
      Value<String> key,
      Value<bool> enabled,
      Value<int> failCount,
      Value<int?> lastUsedAt,
      Value<int?> failedAt,
      Value<int> rowid,
    });

class $$SearchKeysTableFilterComposer
    extends Composer<_$NonaAppDatabase, $SearchKeysTable> {
  $$SearchKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failCount => $composableBuilder(
    column: $table.failCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAt => $composableBuilder(
    column: $table.failedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchKeysTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $SearchKeysTable> {
  $$SearchKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failCount => $composableBuilder(
    column: $table.failCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAt => $composableBuilder(
    column: $table.failedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchKeysTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $SearchKeysTable> {
  $$SearchKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get engineId =>
      $composableBuilder(column: $table.engineId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get failCount =>
      $composableBuilder(column: $table.failCount, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAt =>
      $composableBuilder(column: $table.failedAt, builder: (column) => column);
}

class $$SearchKeysTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $SearchKeysTable,
          SearchKeyRow,
          $$SearchKeysTableFilterComposer,
          $$SearchKeysTableOrderingComposer,
          $$SearchKeysTableAnnotationComposer,
          $$SearchKeysTableCreateCompanionBuilder,
          $$SearchKeysTableUpdateCompanionBuilder,
          (
            SearchKeyRow,
            BaseReferences<_$NonaAppDatabase, $SearchKeysTable, SearchKeyRow>,
          ),
          SearchKeyRow,
          PrefetchHooks Function()
        > {
  $$SearchKeysTableTableManager(_$NonaAppDatabase db, $SearchKeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchKeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> engineId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> failCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<int?> failedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchKeysCompanion(
                id: id,
                engineId: engineId,
                key: key,
                enabled: enabled,
                failCount: failCount,
                lastUsedAt: lastUsedAt,
                failedAt: failedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String engineId,
                required String key,
                Value<bool> enabled = const Value.absent(),
                Value<int> failCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<int?> failedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchKeysCompanion.insert(
                id: id,
                engineId: engineId,
                key: key,
                enabled: enabled,
                failCount: failCount,
                lastUsedAt: lastUsedAt,
                failedAt: failedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $SearchKeysTable,
      SearchKeyRow,
      $$SearchKeysTableFilterComposer,
      $$SearchKeysTableOrderingComposer,
      $$SearchKeysTableAnnotationComposer,
      $$SearchKeysTableCreateCompanionBuilder,
      $$SearchKeysTableUpdateCompanionBuilder,
      (
        SearchKeyRow,
        BaseReferences<_$NonaAppDatabase, $SearchKeysTable, SearchKeyRow>,
      ),
      SearchKeyRow,
      PrefetchHooks Function()
    >;
typedef $$QuickPhrasesTableCreateCompanionBuilder =
    QuickPhrasesCompanion Function({
      required String id,
      required String title,
      required String content,
      Value<bool> isGlobal,
      Value<String?> agentId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$QuickPhrasesTableUpdateCompanionBuilder =
    QuickPhrasesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<bool> isGlobal,
      Value<String?> agentId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$QuickPhrasesTableFilterComposer
    extends Composer<_$NonaAppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGlobal => $composableBuilder(
    column: $table.isGlobal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickPhrasesTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGlobal => $composableBuilder(
    column: $table.isGlobal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickPhrasesTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isGlobal =>
      $composableBuilder(column: $table.isGlobal, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$QuickPhrasesTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $QuickPhrasesTable,
          QuickPhraseRow,
          $$QuickPhrasesTableFilterComposer,
          $$QuickPhrasesTableOrderingComposer,
          $$QuickPhrasesTableAnnotationComposer,
          $$QuickPhrasesTableCreateCompanionBuilder,
          $$QuickPhrasesTableUpdateCompanionBuilder,
          (
            QuickPhraseRow,
            BaseReferences<
              _$NonaAppDatabase,
              $QuickPhrasesTable,
              QuickPhraseRow
            >,
          ),
          QuickPhraseRow,
          PrefetchHooks Function()
        > {
  $$QuickPhrasesTableTableManager(
    _$NonaAppDatabase db,
    $QuickPhrasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickPhrasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuickPhrasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuickPhrasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isGlobal = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickPhrasesCompanion(
                id: id,
                title: title,
                content: content,
                isGlobal: isGlobal,
                agentId: agentId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                Value<bool> isGlobal = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickPhrasesCompanion.insert(
                id: id,
                title: title,
                content: content,
                isGlobal: isGlobal,
                agentId: agentId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickPhrasesTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $QuickPhrasesTable,
      QuickPhraseRow,
      $$QuickPhrasesTableFilterComposer,
      $$QuickPhrasesTableOrderingComposer,
      $$QuickPhrasesTableAnnotationComposer,
      $$QuickPhrasesTableCreateCompanionBuilder,
      $$QuickPhrasesTableUpdateCompanionBuilder,
      (
        QuickPhraseRow,
        BaseReferences<_$NonaAppDatabase, $QuickPhrasesTable, QuickPhraseRow>,
      ),
      QuickPhraseRow,
      PrefetchHooks Function()
    >;
typedef $$InstructionInjectionsTableCreateCompanionBuilder =
    InstructionInjectionsCompanion Function({
      required String id,
      required String title,
      required String prompt,
      Value<String?> groupName,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$InstructionInjectionsTableUpdateCompanionBuilder =
    InstructionInjectionsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> prompt,
      Value<String?> groupName,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$InstructionInjectionsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $InstructionInjectionsTable> {
  $$InstructionInjectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstructionInjectionsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $InstructionInjectionsTable> {
  $$InstructionInjectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstructionInjectionsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $InstructionInjectionsTable> {
  $$InstructionInjectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$InstructionInjectionsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $InstructionInjectionsTable,
          InstructionInjectionRow,
          $$InstructionInjectionsTableFilterComposer,
          $$InstructionInjectionsTableOrderingComposer,
          $$InstructionInjectionsTableAnnotationComposer,
          $$InstructionInjectionsTableCreateCompanionBuilder,
          $$InstructionInjectionsTableUpdateCompanionBuilder,
          (
            InstructionInjectionRow,
            BaseReferences<
              _$NonaAppDatabase,
              $InstructionInjectionsTable,
              InstructionInjectionRow
            >,
          ),
          InstructionInjectionRow,
          PrefetchHooks Function()
        > {
  $$InstructionInjectionsTableTableManager(
    _$NonaAppDatabase db,
    $InstructionInjectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstructionInjectionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstructionInjectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstructionInjectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstructionInjectionsCompanion(
                id: id,
                title: title,
                prompt: prompt,
                groupName: groupName,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String prompt,
                Value<String?> groupName = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstructionInjectionsCompanion.insert(
                id: id,
                title: title,
                prompt: prompt,
                groupName: groupName,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstructionInjectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $InstructionInjectionsTable,
      InstructionInjectionRow,
      $$InstructionInjectionsTableFilterComposer,
      $$InstructionInjectionsTableOrderingComposer,
      $$InstructionInjectionsTableAnnotationComposer,
      $$InstructionInjectionsTableCreateCompanionBuilder,
      $$InstructionInjectionsTableUpdateCompanionBuilder,
      (
        InstructionInjectionRow,
        BaseReferences<
          _$NonaAppDatabase,
          $InstructionInjectionsTable,
          InstructionInjectionRow
        >,
      ),
      InstructionInjectionRow,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, BaseReferences<_$NonaAppDatabase, $TagsTable, TagRow>),
          TagRow,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$NonaAppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  TagsCompanion(id: id, name: name, color: color, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, BaseReferences<_$NonaAppDatabase, $TagsTable, TagRow>),
      TagRow,
      PrefetchHooks Function()
    >;
typedef $$GenerationRunsTableCreateCompanionBuilder =
    GenerationRunsCompanion Function({
      required String id,
      Value<String?> sessionId,
      Value<String?> messageId,
      Value<String> state,
      Value<int> stateRevision,
      Value<int> checkpointSeq,
      Value<String?> errorCode,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$GenerationRunsTableUpdateCompanionBuilder =
    GenerationRunsCompanion Function({
      Value<String> id,
      Value<String?> sessionId,
      Value<String?> messageId,
      Value<String> state,
      Value<int> stateRevision,
      Value<int> checkpointSeq,
      Value<String?> errorCode,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$GenerationRunsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $GenerationRunsTable> {
  $$GenerationRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateRevision => $composableBuilder(
    column: $table.stateRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkpointSeq => $composableBuilder(
    column: $table.checkpointSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GenerationRunsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $GenerationRunsTable> {
  $$GenerationRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateRevision => $composableBuilder(
    column: $table.stateRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkpointSeq => $composableBuilder(
    column: $table.checkpointSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GenerationRunsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $GenerationRunsTable> {
  $$GenerationRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get stateRevision => $composableBuilder(
    column: $table.stateRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get checkpointSeq => $composableBuilder(
    column: $table.checkpointSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GenerationRunsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $GenerationRunsTable,
          GenerationRunRow,
          $$GenerationRunsTableFilterComposer,
          $$GenerationRunsTableOrderingComposer,
          $$GenerationRunsTableAnnotationComposer,
          $$GenerationRunsTableCreateCompanionBuilder,
          $$GenerationRunsTableUpdateCompanionBuilder,
          (
            GenerationRunRow,
            BaseReferences<
              _$NonaAppDatabase,
              $GenerationRunsTable,
              GenerationRunRow
            >,
          ),
          GenerationRunRow,
          PrefetchHooks Function()
        > {
  $$GenerationRunsTableTableManager(
    _$NonaAppDatabase db,
    $GenerationRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenerationRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenerationRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenerationRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> stateRevision = const Value.absent(),
                Value<int> checkpointSeq = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenerationRunsCompanion(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                state: state,
                stateRevision: stateRevision,
                checkpointSeq: checkpointSeq,
                errorCode: errorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sessionId = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> stateRevision = const Value.absent(),
                Value<int> checkpointSeq = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GenerationRunsCompanion.insert(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                state: state,
                stateRevision: stateRevision,
                checkpointSeq: checkpointSeq,
                errorCode: errorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GenerationRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $GenerationRunsTable,
      GenerationRunRow,
      $$GenerationRunsTableFilterComposer,
      $$GenerationRunsTableOrderingComposer,
      $$GenerationRunsTableAnnotationComposer,
      $$GenerationRunsTableCreateCompanionBuilder,
      $$GenerationRunsTableUpdateCompanionBuilder,
      (
        GenerationRunRow,
        BaseReferences<
          _$NonaAppDatabase,
          $GenerationRunsTable,
          GenerationRunRow
        >,
      ),
      GenerationRunRow,
      PrefetchHooks Function()
    >;
typedef $$ChangeLogTableCreateCompanionBuilder =
    ChangeLogCompanion Function({
      Value<int> seq,
      required String entityType,
      required String entityId,
      required String op,
      required int tsMicros,
      Value<String?> payloadHash,
    });
typedef $$ChangeLogTableUpdateCompanionBuilder =
    ChangeLogCompanion Function({
      Value<int> seq,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> op,
      Value<int> tsMicros,
      Value<String?> payloadHash,
    });

class $$ChangeLogTableFilterComposer
    extends Composer<_$NonaAppDatabase, $ChangeLogTable> {
  $$ChangeLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tsMicros => $composableBuilder(
    column: $table.tsMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChangeLogTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $ChangeLogTable> {
  $$ChangeLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tsMicros => $composableBuilder(
    column: $table.tsMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChangeLogTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $ChangeLogTable> {
  $$ChangeLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<int> get tsMicros =>
      $composableBuilder(column: $table.tsMicros, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );
}

class $$ChangeLogTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $ChangeLogTable,
          ChangeLogRow,
          $$ChangeLogTableFilterComposer,
          $$ChangeLogTableOrderingComposer,
          $$ChangeLogTableAnnotationComposer,
          $$ChangeLogTableCreateCompanionBuilder,
          $$ChangeLogTableUpdateCompanionBuilder,
          (
            ChangeLogRow,
            BaseReferences<_$NonaAppDatabase, $ChangeLogTable, ChangeLogRow>,
          ),
          ChangeLogRow,
          PrefetchHooks Function()
        > {
  $$ChangeLogTableTableManager(_$NonaAppDatabase db, $ChangeLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<int> tsMicros = const Value.absent(),
                Value<String?> payloadHash = const Value.absent(),
              }) => ChangeLogCompanion(
                seq: seq,
                entityType: entityType,
                entityId: entityId,
                op: op,
                tsMicros: tsMicros,
                payloadHash: payloadHash,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String entityType,
                required String entityId,
                required String op,
                required int tsMicros,
                Value<String?> payloadHash = const Value.absent(),
              }) => ChangeLogCompanion.insert(
                seq: seq,
                entityType: entityType,
                entityId: entityId,
                op: op,
                tsMicros: tsMicros,
                payloadHash: payloadHash,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChangeLogTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $ChangeLogTable,
      ChangeLogRow,
      $$ChangeLogTableFilterComposer,
      $$ChangeLogTableOrderingComposer,
      $$ChangeLogTableAnnotationComposer,
      $$ChangeLogTableCreateCompanionBuilder,
      $$ChangeLogTableUpdateCompanionBuilder,
      (
        ChangeLogRow,
        BaseReferences<_$NonaAppDatabase, $ChangeLogTable, ChangeLogRow>,
      ),
      ChangeLogRow,
      PrefetchHooks Function()
    >;
typedef $$RouteEventsTableCreateCompanionBuilder =
    RouteEventsCompanion Function({
      Value<int> id,
      required String task,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<bool> success,
      Value<int> elapsedMs,
      Value<double> cost,
      required int createdAt,
    });
typedef $$RouteEventsTableUpdateCompanionBuilder =
    RouteEventsCompanion Function({
      Value<int> id,
      Value<String> task,
      Value<String?> providerId,
      Value<String?> modelId,
      Value<bool> success,
      Value<int> elapsedMs,
      Value<double> cost,
      Value<int> createdAt,
    });

class $$RouteEventsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $RouteEventsTable> {
  $$RouteEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RouteEventsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $RouteEventsTable> {
  $$RouteEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RouteEventsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $RouteEventsTable> {
  $$RouteEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get task =>
      $composableBuilder(column: $table.task, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RouteEventsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $RouteEventsTable,
          RouteEventRow,
          $$RouteEventsTableFilterComposer,
          $$RouteEventsTableOrderingComposer,
          $$RouteEventsTableAnnotationComposer,
          $$RouteEventsTableCreateCompanionBuilder,
          $$RouteEventsTableUpdateCompanionBuilder,
          (
            RouteEventRow,
            BaseReferences<_$NonaAppDatabase, $RouteEventsTable, RouteEventRow>,
          ),
          RouteEventRow,
          PrefetchHooks Function()
        > {
  $$RouteEventsTableTableManager(_$NonaAppDatabase db, $RouteEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RouteEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> task = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<bool> success = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => RouteEventsCompanion(
                id: id,
                task: task,
                providerId: providerId,
                modelId: modelId,
                success: success,
                elapsedMs: elapsedMs,
                cost: cost,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String task,
                Value<String?> providerId = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<bool> success = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<double> cost = const Value.absent(),
                required int createdAt,
              }) => RouteEventsCompanion.insert(
                id: id,
                task: task,
                providerId: providerId,
                modelId: modelId,
                success: success,
                elapsedMs: elapsedMs,
                cost: cost,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RouteEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $RouteEventsTable,
      RouteEventRow,
      $$RouteEventsTableFilterComposer,
      $$RouteEventsTableOrderingComposer,
      $$RouteEventsTableAnnotationComposer,
      $$RouteEventsTableCreateCompanionBuilder,
      $$RouteEventsTableUpdateCompanionBuilder,
      (
        RouteEventRow,
        BaseReferences<_$NonaAppDatabase, $RouteEventsTable, RouteEventRow>,
      ),
      RouteEventRow,
      PrefetchHooks Function()
    >;
typedef $$WorkflowsTableCreateCompanionBuilder =
    WorkflowsCompanion Function({
      required String id,
      required String name,
      required String triggerJson,
      required String actionsJson,
      Value<bool> enabled,
      Value<String?> agentId,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$WorkflowsTableUpdateCompanionBuilder =
    WorkflowsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> triggerJson,
      Value<String> actionsJson,
      Value<bool> enabled,
      Value<String?> agentId,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$WorkflowsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $WorkflowsTable> {
  $$WorkflowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerJson => $composableBuilder(
    column: $table.triggerJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkflowsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $WorkflowsTable> {
  $$WorkflowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerJson => $composableBuilder(
    column: $table.triggerJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkflowsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $WorkflowsTable> {
  $$WorkflowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get triggerJson => $composableBuilder(
    column: $table.triggerJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkflowsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $WorkflowsTable,
          WorkflowRow,
          $$WorkflowsTableFilterComposer,
          $$WorkflowsTableOrderingComposer,
          $$WorkflowsTableAnnotationComposer,
          $$WorkflowsTableCreateCompanionBuilder,
          $$WorkflowsTableUpdateCompanionBuilder,
          (
            WorkflowRow,
            BaseReferences<_$NonaAppDatabase, $WorkflowsTable, WorkflowRow>,
          ),
          WorkflowRow,
          PrefetchHooks Function()
        > {
  $$WorkflowsTableTableManager(_$NonaAppDatabase db, $WorkflowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> triggerJson = const Value.absent(),
                Value<String> actionsJson = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkflowsCompanion(
                id: id,
                name: name,
                triggerJson: triggerJson,
                actionsJson: actionsJson,
                enabled: enabled,
                agentId: agentId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String triggerJson,
                required String actionsJson,
                Value<bool> enabled = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkflowsCompanion.insert(
                id: id,
                name: name,
                triggerJson: triggerJson,
                actionsJson: actionsJson,
                enabled: enabled,
                agentId: agentId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkflowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $WorkflowsTable,
      WorkflowRow,
      $$WorkflowsTableFilterComposer,
      $$WorkflowsTableOrderingComposer,
      $$WorkflowsTableAnnotationComposer,
      $$WorkflowsTableCreateCompanionBuilder,
      $$WorkflowsTableUpdateCompanionBuilder,
      (
        WorkflowRow,
        BaseReferences<_$NonaAppDatabase, $WorkflowsTable, WorkflowRow>,
      ),
      WorkflowRow,
      PrefetchHooks Function()
    >;
typedef $$WorkflowRunsTableCreateCompanionBuilder =
    WorkflowRunsCompanion Function({
      required String id,
      required String workflowId,
      required String status,
      required int startedAt,
      Value<int?> finishedAt,
      Value<String?> error,
      Value<String?> resultJson,
      Value<int> rowid,
    });
typedef $$WorkflowRunsTableUpdateCompanionBuilder =
    WorkflowRunsCompanion Function({
      Value<String> id,
      Value<String> workflowId,
      Value<String> status,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<String?> error,
      Value<String?> resultJson,
      Value<int> rowid,
    });

class $$WorkflowRunsTableFilterComposer
    extends Composer<_$NonaAppDatabase, $WorkflowRunsTable> {
  $$WorkflowRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkflowRunsTableOrderingComposer
    extends Composer<_$NonaAppDatabase, $WorkflowRunsTable> {
  $$WorkflowRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkflowRunsTableAnnotationComposer
    extends Composer<_$NonaAppDatabase, $WorkflowRunsTable> {
  $$WorkflowRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );
}

class $$WorkflowRunsTableTableManager
    extends
        RootTableManager<
          _$NonaAppDatabase,
          $WorkflowRunsTable,
          WorkflowRunRow,
          $$WorkflowRunsTableFilterComposer,
          $$WorkflowRunsTableOrderingComposer,
          $$WorkflowRunsTableAnnotationComposer,
          $$WorkflowRunsTableCreateCompanionBuilder,
          $$WorkflowRunsTableUpdateCompanionBuilder,
          (
            WorkflowRunRow,
            BaseReferences<
              _$NonaAppDatabase,
              $WorkflowRunsTable,
              WorkflowRunRow
            >,
          ),
          WorkflowRunRow,
          PrefetchHooks Function()
        > {
  $$WorkflowRunsTableTableManager(
    _$NonaAppDatabase db,
    $WorkflowRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkflowRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkflowRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkflowRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workflowId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkflowRunsCompanion(
                id: id,
                workflowId: workflowId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                error: error,
                resultJson: resultJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workflowId,
                required String status,
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkflowRunsCompanion.insert(
                id: id,
                workflowId: workflowId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                error: error,
                resultJson: resultJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkflowRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$NonaAppDatabase,
      $WorkflowRunsTable,
      WorkflowRunRow,
      $$WorkflowRunsTableFilterComposer,
      $$WorkflowRunsTableOrderingComposer,
      $$WorkflowRunsTableAnnotationComposer,
      $$WorkflowRunsTableCreateCompanionBuilder,
      $$WorkflowRunsTableUpdateCompanionBuilder,
      (
        WorkflowRunRow,
        BaseReferences<_$NonaAppDatabase, $WorkflowRunsTable, WorkflowRunRow>,
      ),
      WorkflowRunRow,
      PrefetchHooks Function()
    >;

class $NonaAppDatabaseManager {
  final _$NonaAppDatabase _db;
  $NonaAppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageTokensTableTableManager get messageTokens =>
      $$MessageTokensTableTableManager(_db, _db.messageTokens);
  $$CompressedBlocksTableTableManager get compressedBlocks =>
      $$CompressedBlocksTableTableManager(_db, _db.compressedBlocks);
  $$UsageDailyTableTableManager get usageDaily =>
      $$UsageDailyTableTableManager(_db, _db.usageDaily);
  $$GenMediaTableTableManager get genMedia =>
      $$GenMediaTableTableManager(_db, _db.genMedia);
  $$KbLibrariesTableTableManager get kbLibraries =>
      $$KbLibrariesTableTableManager(_db, _db.kbLibraries);
  $$KbDocumentsTableTableManager get kbDocuments =>
      $$KbDocumentsTableTableManager(_db, _db.kbDocuments);
  $$KbChunksTableTableManager get kbChunks =>
      $$KbChunksTableTableManager(_db, _db.kbChunks);
  $$KbBigramsTableTableManager get kbBigrams =>
      $$KbBigramsTableTableManager(_db, _db.kbBigrams);
  $$KbVectorsTableTableManager get kbVectors =>
      $$KbVectorsTableTableManager(_db, _db.kbVectors);
  $$MemoriesTableTableManager get memories =>
      $$MemoriesTableTableManager(_db, _db.memories);
  $$MemorySpacesTableTableManager get memorySpaces =>
      $$MemorySpacesTableTableManager(_db, _db.memorySpaces);
  $$MemoryStateTableTableManager get memoryState =>
      $$MemoryStateTableTableManager(_db, _db.memoryState);
  $$WorldBookEntriesTableTableManager get worldBookEntries =>
      $$WorldBookEntriesTableTableManager(_db, _db.worldBookEntries);
  $$WorldBooksTableTableManager get worldBooks =>
      $$WorldBooksTableTableManager(_db, _db.worldBooks);
  $$ProviderGroupsTableTableManager get providerGroups =>
      $$ProviderGroupsTableTableManager(_db, _db.providerGroups);
  $$SearchKeysTableTableManager get searchKeys =>
      $$SearchKeysTableTableManager(_db, _db.searchKeys);
  $$QuickPhrasesTableTableManager get quickPhrases =>
      $$QuickPhrasesTableTableManager(_db, _db.quickPhrases);
  $$InstructionInjectionsTableTableManager get instructionInjections =>
      $$InstructionInjectionsTableTableManager(_db, _db.instructionInjections);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$GenerationRunsTableTableManager get generationRuns =>
      $$GenerationRunsTableTableManager(_db, _db.generationRuns);
  $$ChangeLogTableTableManager get changeLog =>
      $$ChangeLogTableTableManager(_db, _db.changeLog);
  $$RouteEventsTableTableManager get routeEvents =>
      $$RouteEventsTableTableManager(_db, _db.routeEvents);
  $$WorkflowsTableTableManager get workflows =>
      $$WorkflowsTableTableManager(_db, _db.workflows);
  $$WorkflowRunsTableTableManager get workflowRuns =>
      $$WorkflowRunsTableTableManager(_db, _db.workflowRuns);
}

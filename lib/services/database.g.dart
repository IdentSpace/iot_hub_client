// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppDataTable extends AppData with TableInfo<$AppDataTable, AppDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppDataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AppDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppDataData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $AppDataTable createAlias(String alias) {
    return $AppDataTable(attachedDatabase, alias);
  }
}

class AppDataData extends DataClass implements Insertable<AppDataData> {
  final String name;
  final String? value;
  const AppDataData({required this.name, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  AppDataCompanion toCompanion(bool nullToAbsent) {
    return AppDataCompanion(
      name: Value(name),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory AppDataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppDataData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String?>(value),
    };
  }

  AppDataData copyWith({
    String? name,
    Value<String?> value = const Value.absent(),
  }) => AppDataData(
    name: name ?? this.name,
    value: value.present ? value.value : this.value,
  );
  AppDataData copyWithCompanion(AppDataCompanion data) {
    return AppDataData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppDataData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppDataData &&
          other.name == this.name &&
          other.value == this.value);
}

class AppDataCompanion extends UpdateCompanion<AppDataData> {
  final Value<String> name;
  final Value<String?> value;
  final Value<int> rowid;
  const AppDataCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppDataCompanion.insert({
    required String name,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<AppDataData> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppDataCompanion copyWith({
    Value<String>? name,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return AppDataCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppDataCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TokensTable extends Tokens with TableInfo<$TokensTable, Token> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TokensTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
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
  static const VerificationMeta _expiredAtMeta = const VerificationMeta(
    'expiredAt',
  );
  @override
  late final GeneratedColumn<int> expiredAt = GeneratedColumn<int>(
    'expired_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    server,
    token,
    createdAt,
    expiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Token> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
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
    if (data.containsKey('expired_at')) {
      context.handle(
        _expiredAtMeta,
        expiredAt.isAcceptableOrUnknown(data['expired_at']!, _expiredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Token map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Token(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      expiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expired_at'],
      ),
    );
  }

  @override
  $TokensTable createAlias(String alias) {
    return $TokensTable(attachedDatabase, alias);
  }
}

class Token extends DataClass implements Insertable<Token> {
  final int id;
  final String? name;
  final String server;
  final String? token;
  final int createdAt;
  final int? expiredAt;
  const Token({
    required this.id,
    this.name,
    required this.server,
    this.token,
    required this.createdAt,
    this.expiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['server'] = Variable<String>(server);
    if (!nullToAbsent || token != null) {
      map['token'] = Variable<String>(token);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || expiredAt != null) {
      map['expired_at'] = Variable<int>(expiredAt);
    }
    return map;
  }

  TokensCompanion toCompanion(bool nullToAbsent) {
    return TokensCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      server: Value(server),
      token: token == null && nullToAbsent
          ? const Value.absent()
          : Value(token),
      createdAt: Value(createdAt),
      expiredAt: expiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiredAt),
    );
  }

  factory Token.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Token(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      server: serializer.fromJson<String>(json['server']),
      token: serializer.fromJson<String?>(json['token']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiredAt: serializer.fromJson<int?>(json['expiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'server': serializer.toJson<String>(server),
      'token': serializer.toJson<String?>(token),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiredAt': serializer.toJson<int?>(expiredAt),
    };
  }

  Token copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    String? server,
    Value<String?> token = const Value.absent(),
    int? createdAt,
    Value<int?> expiredAt = const Value.absent(),
  }) => Token(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    server: server ?? this.server,
    token: token.present ? token.value : this.token,
    createdAt: createdAt ?? this.createdAt,
    expiredAt: expiredAt.present ? expiredAt.value : this.expiredAt,
  );
  Token copyWithCompanion(TokensCompanion data) {
    return Token(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      server: data.server.present ? data.server.value : this.server,
      token: data.token.present ? data.token.value : this.token,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiredAt: data.expiredAt.present ? data.expiredAt.value : this.expiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Token(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('server: $server, ')
          ..write('token: $token, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiredAt: $expiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, server, token, createdAt, expiredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Token &&
          other.id == this.id &&
          other.name == this.name &&
          other.server == this.server &&
          other.token == this.token &&
          other.createdAt == this.createdAt &&
          other.expiredAt == this.expiredAt);
}

class TokensCompanion extends UpdateCompanion<Token> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String> server;
  final Value<String?> token;
  final Value<int> createdAt;
  final Value<int?> expiredAt;
  const TokensCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.server = const Value.absent(),
    this.token = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiredAt = const Value.absent(),
  });
  TokensCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required String server,
    this.token = const Value.absent(),
    required int createdAt,
    this.expiredAt = const Value.absent(),
  }) : server = Value(server),
       createdAt = Value(createdAt);
  static Insertable<Token> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? server,
    Expression<String>? token,
    Expression<int>? createdAt,
    Expression<int>? expiredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (server != null) 'server': server,
      if (token != null) 'token': token,
      if (createdAt != null) 'created_at': createdAt,
      if (expiredAt != null) 'expired_at': expiredAt,
    });
  }

  TokensCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<String>? server,
    Value<String?>? token,
    Value<int>? createdAt,
    Value<int?>? expiredAt,
  }) {
    return TokensCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      server: server ?? this.server,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiredAt.present) {
      map['expired_at'] = Variable<int>(expiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TokensCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('server: $server, ')
          ..write('token: $token, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiredAt: $expiredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppDataTable appData = $AppDataTable(this);
  late final $TokensTable tokens = $TokensTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [appData, tokens];
}

typedef $$AppDataTableCreateCompanionBuilder =
    AppDataCompanion Function({
      required String name,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$AppDataTableUpdateCompanionBuilder =
    AppDataCompanion Function({
      Value<String> name,
      Value<String?> value,
      Value<int> rowid,
    });

class $$AppDataTableFilterComposer
    extends Composer<_$AppDatabase, $AppDataTable> {
  $$AppDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppDataTableOrderingComposer
    extends Composer<_$AppDatabase, $AppDataTable> {
  $$AppDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppDataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppDataTable> {
  $$AppDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppDataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppDataTable,
          AppDataData,
          $$AppDataTableFilterComposer,
          $$AppDataTableOrderingComposer,
          $$AppDataTableAnnotationComposer,
          $$AppDataTableCreateCompanionBuilder,
          $$AppDataTableUpdateCompanionBuilder,
          (
            AppDataData,
            BaseReferences<_$AppDatabase, $AppDataTable, AppDataData>,
          ),
          AppDataData,
          PrefetchHooks Function()
        > {
  $$AppDataTableTableManager(_$AppDatabase db, $AppDataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppDataCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppDataCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppDataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppDataTable,
      AppDataData,
      $$AppDataTableFilterComposer,
      $$AppDataTableOrderingComposer,
      $$AppDataTableAnnotationComposer,
      $$AppDataTableCreateCompanionBuilder,
      $$AppDataTableUpdateCompanionBuilder,
      (AppDataData, BaseReferences<_$AppDatabase, $AppDataTable, AppDataData>),
      AppDataData,
      PrefetchHooks Function()
    >;
typedef $$TokensTableCreateCompanionBuilder =
    TokensCompanion Function({
      Value<int> id,
      Value<String?> name,
      required String server,
      Value<String?> token,
      required int createdAt,
      Value<int?> expiredAt,
    });
typedef $$TokensTableUpdateCompanionBuilder =
    TokensCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<String> server,
      Value<String?> token,
      Value<int> createdAt,
      Value<int?> expiredAt,
    });

class $$TokensTableFilterComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiredAt => $composableBuilder(
    column: $table.expiredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TokensTableOrderingComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiredAt => $composableBuilder(
    column: $table.expiredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiredAt =>
      $composableBuilder(column: $table.expiredAt, builder: (column) => column);
}

class $$TokensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TokensTable,
          Token,
          $$TokensTableFilterComposer,
          $$TokensTableOrderingComposer,
          $$TokensTableAnnotationComposer,
          $$TokensTableCreateCompanionBuilder,
          $$TokensTableUpdateCompanionBuilder,
          (Token, BaseReferences<_$AppDatabase, $TokensTable, Token>),
          Token,
          PrefetchHooks Function()
        > {
  $$TokensTableTableManager(_$AppDatabase db, $TokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<String?> token = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> expiredAt = const Value.absent(),
              }) => TokensCompanion(
                id: id,
                name: name,
                server: server,
                token: token,
                createdAt: createdAt,
                expiredAt: expiredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required String server,
                Value<String?> token = const Value.absent(),
                required int createdAt,
                Value<int?> expiredAt = const Value.absent(),
              }) => TokensCompanion.insert(
                id: id,
                name: name,
                server: server,
                token: token,
                createdAt: createdAt,
                expiredAt: expiredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TokensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TokensTable,
      Token,
      $$TokensTableFilterComposer,
      $$TokensTableOrderingComposer,
      $$TokensTableAnnotationComposer,
      $$TokensTableCreateCompanionBuilder,
      $$TokensTableUpdateCompanionBuilder,
      (Token, BaseReferences<_$AppDatabase, $TokensTable, Token>),
      Token,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppDataTableTableManager get appData =>
      $$AppDataTableTableManager(_db, _db.appData);
  $$TokensTableTableManager get tokens =>
      $$TokensTableTableManager(_db, _db.tokens);
}

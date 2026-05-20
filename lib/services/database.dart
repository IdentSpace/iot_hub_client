import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iot_hub_client/services/db/tokens.dart';
import 'package:iot_hub_client/services/db/app_data.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(tables: [AppData, Tokens])
class AppDatabase extends _$AppDatabase {
  AppDatabase.internal([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  static final AppDatabase _instance = AppDatabase.internal();
  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationSupportDirectory();
      final file = File(p.join(dbFolder.path, 'iotclient.sqlite'));

      return NativeDatabase(file);
    });
  }

  Future<void> insertToken(IHCToken token) async {
    await into(tokens).insert(
      TokensCompanion.insert(
        createdAt: DateTime.now().millisecondsSinceEpoch,
        server: token.server,
        token: Value(token.token),
        expiredAt: Value(token.expiredAt?.millisecondsSinceEpoch ?? 0),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteToken(String tokenToken) async {
    await (delete(
      tokens,
    )..where((filter) => filter.token.equals(tokenToken))).go();
  }

  Future<String> debugDirectory() async {
    final dir = await getApplicationSupportDirectory();
    foundation.debugPrint(dir.path);
    return dir.path;
  }
}

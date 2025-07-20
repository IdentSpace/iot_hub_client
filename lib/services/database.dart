import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iot_hub_client/services/db/tokens.dart';
import 'package:iot_hub_client/services/db/app_data.dart';

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
    return driftDatabase(
      name: 'iotclient.sqlite',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }

  Future<void> insertToken(IHCToken token) async {
    into(tokens).insert(
      TokensCompanion.insert(
        createdAt: DateTime.now().millisecondsSinceEpoch,
        server: token.server,
        token: Value(token.token),
        expiredAt: Value(token.expiredAt?.millisecondsSinceEpoch ?? 0),
      ),
    );
  }

  Future<String> debugDirectory() async {
    final dir = await getApplicationSupportDirectory();
    foundation.debugPrint(dir.path);
    return dir.path;
  }
}

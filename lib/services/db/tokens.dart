import 'package:drift/drift.dart';

class Tokens extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get server => text().unique()();
  TextColumn get token => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get expiredAt => integer().nullable()();
}

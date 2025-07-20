import 'package:drift/drift.dart';

class AppData extends Table {
  TextColumn get name => text().unique()();
  TextColumn get value => text().nullable()();
}

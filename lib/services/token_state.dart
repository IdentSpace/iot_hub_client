import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';

class TokenStore {
  static IHCToken? _token;
  static IHCToken? get token => _token;

  static void setToken(IHCToken token) {
    _token = token;
  }

  static void clear() {
    _token = null;
  }

  Future<void> setName(String name) async {
    final AppDatabase db = AppDatabase.instance;
    if (_token != null) {
      await (db.update(db.tokens)
            ..where((filter) => filter.token.equals(_token!.token)))
          .write(TokensCompanion(name: Value(name)));
    }
  }

  Future<String> getName() async {
    final AppDatabase db = AppDatabase.instance;

    if (_token != null) {
      final Token? tk =
          await (db.select(db.tokens)
                ..where((filter) => filter.token.equals(_token!.token)))
              .getSingleOrNull();

      if (tk != null) {
        return tk.name ?? '';
      }
    }

    return '';
  }

  static Future<void> logout() async {
    final AppDatabase db = AppDatabase.instance;

    if (_token != null) {
      await (db.delete(
        db.tokens,
      )..where((filter) => filter.token.equals(_token!.token))).go();
      clear();
    }
  }

  static Future<void> load() async {
    final AppDatabase db = AppDatabase.instance;
    final tokenlist = await (db.select(db.tokens)).get();

    if (tokenlist.isEmpty) {
      return;
    }

    final token = tokenlist[0];

    debugPrint(token.server);

    _token = IHCToken(token.token ?? '', token.server);
  }

  static bool has() {
    if (_token == null) {
      return false;
    }

    return true;
  }

  static String asString() {
    return _token.toString();
  }
}

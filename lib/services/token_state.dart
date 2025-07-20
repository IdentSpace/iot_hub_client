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

  static Future<void> load() async {
    final AppDatabase db = AppDatabase.instance;
    final token = await (db.select(db.tokens)).getSingleOrNull();

    debugPrint(token?.server ?? '');

    if (token == null) {
      return;
    }

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

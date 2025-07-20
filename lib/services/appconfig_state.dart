import 'package:flutter/foundation.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/token_state.dart';

class AppConfigStore {
  static String? _serverhost;
  static String? get serverhost => _serverhost;

  static void setServerHost(String? serverhost) {
    if (TokenStore.token != null) {
      TokenStore.setToken(IHCToken(TokenStore.token!.token, serverhost ?? ''));
    }

    _serverhost = serverhost;
  }

  static void load() {
    debugPrint("NOT IMPLEMENTED");
  }

  static void clear() {
    _serverhost = null;
  }
}

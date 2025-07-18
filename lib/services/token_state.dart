import 'package:iot_hub_client/api/iot_hub_core.dart';

class TokenStore {
  static IHCToken? _token;
  static IHCToken? get token => _token;

  static void setToken(IHCToken token) {
    _token = token;
  }

  static void clear() {
    _token = null;
  }
}

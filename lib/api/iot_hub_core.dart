import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iot_hub_client/api/models/device.dart';

class IHCToken {
  final String server;
  final String token;
  late DateTime createdAt;
  final DateTime? expiredAt = null;

  IHCToken(this.token, this.server) {
    createdAt = DateTime.now();
  }

  bool isNotExpired() {
    return true;
  }
}

class IHCResponse {}

class IHC {
  static IHCToken auth({
    required String server,
    required String username,
    required String password,
  }) {
    return IHCToken("TODOPLACEHOLDER", server);
  }

  // TODO: authWithCard()
  // TODO: getIHCState()
  // TODO: registerDevice()
  // TODO: updateDevice()

  static Future<List<Device>> getDevices({required IHCToken token}) async {
    final String path = '${token.server}/api/device/list';
    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    if (response.statusCode == 200) {
      final devices = jsonDecode(response.body);

      final List<Device> list = (devices['data']['device'] as List)
          .map((item) => Device.fromJsonIHC(item))
          .toList();

      return list;
    } else {
      debugPrint('Failed to load devices: ${response.statusCode}');

      return [];
    }
  }

  static Future<DeviceState?> getDeviceState({
    required IHCToken token,
    required String deviceId,
  }) async {
    final String path = '${token.server}/api/device/$deviceId/state';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    if (response.statusCode == 200) {
      final state = jsonDecode(response.body);

      debugPrint(state['data']['device'].toString());
      final devicestate = DeviceState.fromJsonIHC(state['data']['device']);
      debugPrint(devicestate.message);
      debugPrint(devicestate.powerState.toString());
      return devicestate;
    }

    return null;
  }

  static Future<bool> setDeviceOn({
    required IHCToken token,
    required String deviceId,
  }) async {
    final String path = '${token.server}/api/device/$deviceId/event?on=true';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    return true;
  }

  static Future<bool> setDeviceOff({
    required IHCToken token,
    required String deviceId,
  }) async {
    final String path = '${token.server}/api/device/$deviceId/event?on=false';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    return true;
  }
}

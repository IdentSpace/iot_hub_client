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

  bool isExpired() {
    if (expiredAt == null) return true;
    return DateTime.now().isAfter(expiredAt!);
  }

  @override
  String toString() {
    return '$server, ${createdAt.toIso8601String()}';
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

  // TODO: loadDeviceDriverAndTypeList
  // TODO: authWithCard()
  // TODO: getIHCState()
  // TODO: updateDevice()

  static Future<bool> registerDevice({
    required IHCToken token,
    required Device device,
  }) async {
    final String path = '${token.server}/api/device/register';

    final response = await http.post(
      Uri.parse(path),
      headers: {
        'Authorization': 'Bearer ${token.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_host': device.host,
        'device_name': device.name,
        'device_driver': device.driver,
        'device_type': device.type,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    debugPrint(response.statusCode.toString());
    debugPrint(response.body.toString());

    return false;
  }

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

      final devicestate = DeviceState.fromJsonIHC(state['data']['device']);
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

import 'dart:async';
import 'dart:io';

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

  void setServer(String server) {
    server = server;
  }

  bool isExpired() {
    if (expiredAt == null) return false;
    return !DateTime.now().isAfter(expiredAt!);
  }

  bool isValid() {
    if (server.isNotEmpty && !isExpired()) {
      return true;
    }

    debugPrint("Token ist not valid");
    return false;
  }

  @override
  String toString() {
    return '$server, ${createdAt.toIso8601String()}';
  }
}

class IHC {
  final IHCToken token;

  IHC(this.token);

  /// Generic GET request to IHC server
  Future<http.Response> requestGET(String path) async {
    final String pathFull = '${token.server}/api/$path';

    final http.Response response = await http.get(
      Uri.parse(pathFull),
      headers: {
        'Authorization': 'Bearer ${token.token}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      debugPrint('Request failed with status: ${response.statusCode}.');
    }

    return response;
  }

  /// Generic POST request to IHC server
  Future<http.Response> requestPOST(
    String path,
    Map<String, dynamic> body,
  ) async {
    final String pathFull = '${token.server}/api/$path';

    final http.Response response = await http.post(
      Uri.parse(pathFull),
      headers: {
        'Authorization': 'Bearer ${token.token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      debugPrint('Request failed with status: ${response.statusCode}.');
    }

    return response;
  }

  /// Get list of available device drivers from IHC server
  Future<List<Map<String, dynamic>>> deviceDriverList() async {
    final request = await requestGET('device/list/drivers');
    return List<Map<String, dynamic>>.from(
      jsonDecode(request.body)['data']['device_drivers'],
    );
  }

  /// Get list of available device types from IHC server
  Future<List<Map<String, dynamic>>> deviceTypeList() async {
    final request = await requestGET('device/list/types');
    return List<Map<String, dynamic>>.from(
      jsonDecode(request.body)['data']['device_types'],
    );
  }

  /// Register a new device on the IHC server
  Future<bool> registerDevice({required Device device}) async {
    if (!token.isValid()) return false;

    final response = await requestPOST('device/register/device', {
      'device_host': device.host,
      'device_name': device.name,
      'device_driver': device.driverId,
      'device_type': device.type,
    });

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  /// Update device on the IHC server
  Future<bool> updateDevice({required Device device}) async {
    if (!token.isValid()) return false;

    final response = await requestPOST('device/update', {
      'id': device.id,
      'device_host': device.host,
      'baudrate': device.baudrate,
      'channel': device.channel,
      'name': device.name,
      'device_driver': device.driverId,
      'device_type': device.type,
    });

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  /// Delete device on the IHC server
  Future<bool> deleteDevice({required String deviceId}) async {
    final response = await requestGET('device/$deviceId/delete');
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<void> restartThreads() async {
    await requestGET('config/restart/threads');
  }

  Future<List<Map<String, dynamic>>> getConfigList() async {
    final response = await requestGET('config/list');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']['config']);
    }

    return [];
  }

  Future<void> setConfigValue({
    required String name,
    required String value,
  }) async {
    await requestPOST('config/set', {'name': name, 'value': value});
  }

  Future<List<Device>> getDevices() async {
    final response = await requestGET('device/list');

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

  // OLD ----
  static Future<IHCToken?> auth({
    required String server,
    required String username,
    required String password,
  }) async {
    try {
      final String path = '$server/auth/login';

      final response = await http.post(
        Uri.parse(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      debugPrint(response.statusCode.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IHCToken(data["data"]["access_token"], server);
      }

      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // TODO: loadDeviceDriverAndTypeList
  // TODO: authWithCard()
  // TODO: getIHCState()
  static Future<DeviceState?> getDeviceState({
    required IHCToken token,
    required String deviceId,
  }) async {
    if (!token.isValid()) {
      return DeviceState(
        state: 'NODATA',
        message: "Invalid Token",
        rawData: '',
        powerState: false,
      );
    }

    debugPrint("CALL DEVICE STATE");

    final String path = '${token.server}/api/device/$deviceId/state';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    if (response.statusCode == 200) {
      debugPrint(response.body);
      final state = jsonDecode(response.body);

      final DeviceState devicestate = DeviceState.fromJsonIHC(
        state['data']['device'],
      );
      return devicestate;
    }

    return null;
  }

  static Future<bool> setDeviceOn({
    required IHCToken token,
    required String deviceId,
  }) async {
    final String path =
        '${token.server}/api/device/$deviceId/event?cmd=switch&arg=on';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    debugPrint(response.body);

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  static Future<bool> setDeviceOff({
    required IHCToken token,
    required String deviceId,
  }) async {
    final String path =
        '${token.server}/api/device/$deviceId/event?cmd=switch&arg=off';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Authorization': 'Bearer ${token.token}'},
    );

    debugPrint(response.body);

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  static void sendTelnetNegotiation(Socket socket) {
    socket.add([
      0xFF, 0xFA, 0x2C, 0x32, 0x00, 0xFF, 0xF0, // NVT 1
      0xFF, 0xFA, 0x2C, 0x32, 0x30, 0xFF, 0xF0, // NVT 2
    ]);
  }

  static Future<String?> readNFC({bool demo = false}) async {
    final completer = Completer<String?>();

    try {
      final socket = await Socket.connect("192.168.51.160", 8002);
      debugPrint("Verbunden");

      sendTelnetNegotiation(socket);

      socket.listen(
        (onData) {
          final message = utf8.decode(onData).trim();
          debugPrint("Nachricht: $message");

          if (message.contains('UID=')) {
            final uid = message.split('UID=').last;
            debugPrint(uid);
            completer.complete(uid);
            socket.destroy();
          }
        },
        onError: (error) {
          completer.completeError(error);
          debugPrint(error.toString());
          socket.destroy();
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      completer.completeError(e);
      return null;
    }

    return completer.future;
  }
}

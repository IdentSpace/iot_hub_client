import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iot_hub_client/api/iot_hub_core.dart';

/// Commands are selected by device type, never by a vendor-specific driver.
enum DeviceActionKind { power, movement, nfc, status }

DeviceActionKind deviceActionKind(String? type) => switch (type) {
  'lamp' || 'machine' || 'heater' => DeviceActionKind.power,
  'door' || 'parking_barrier' => DeviceActionKind.movement,
  'nfcreader' => DeviceActionKind.nfc,
  _ => DeviceActionKind.status,
};

class DeviceActionState {
  final String? state;
  final String? message;
  final bool? power;
  final Map<String, dynamic> data;

  DeviceActionState(Map<String, dynamic> json)
    : state = json['state'] as String?,
      message = json['message'] as String?,
      power = json['power_state'] as bool?,
      data = json;

  bool get hasError =>
      const ['error', 'nodata', 'offline'].contains(state?.toLowerCase());
}

class DeviceActions {
  final IHCToken token;
  final http.Client _client;

  DeviceActions(this.token, {http.Client? client})
    : _client = client ?? http.Client();

  void close() => _client.close();

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> query,
  ) async {
    final base = token.server.replaceFirst(RegExp(r'/+$'), '');
    final response = await _client
        .get(
          Uri.parse('$base/api/device/$path').replace(queryParameters: query),
          headers: {
            'Authorization': 'Bearer ${token.token}',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (HTTP ${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['type'] != 'IHCApiResponse') {
      throw Exception('Invalid IOHub response');
    }
    final errors = body['errors'];
    if ((errors is Map && errors.isNotEmpty) ||
        (errors is List && errors.isNotEmpty) ||
        (errors is String && errors.isNotEmpty) ||
        body['message'] == 'error') {
      throw Exception('IOHub rejected the request');
    }
    if (body['data'] is! Map<String, dynamic>) {
      throw Exception('Missing IOHub response data');
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<DeviceActionState> state(String id) async {
    final data = await _request('state', {'uuid': id});
    final device = data['device'];
    if (device is! Map<String, dynamic>) {
      throw Exception('Missing device state');
    }
    return DeviceActionState(device);
  }

  Future<void> send(String id, String command, [String? argument]) async {
    await _request('event', {
      'uuid': id,
      'cmd': command,
      if (argument != null) 'arg': argument,
    });
  }
}

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
    : state = json['connection'] as String?,
      message = json['message'] as String?,
      power = (json['values'] as Map?)?['power'] as bool?,
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
    String path, {
    Map<String, dynamic>? command,
  }) async {
    final base = token.server.replaceFirst(RegExp(r'/+$'), '');
    final request = http.Request(
      command == null ? 'GET' : 'POST',
      Uri.parse('$base/api/v2/devices/$path'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer ${token.token}',
      'Accept': 'application/json',
      if (command != null) 'Content-Type': 'application/json',
    });
    if (command != null) request.body = jsonEncode(command);
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (HTTP ${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid IOHub response');
    }
    final errors = body['errors'];
    if ((errors is Map && errors.isNotEmpty) ||
        (errors is List && errors.isNotEmpty) ||
        (errors is String && errors.isNotEmpty) ||
        body['message'] == 'error') {
      throw Exception('IOHub rejected the request');
    }
    return body;
  }

  Future<DeviceActionState> state(String id) async {
    return DeviceActionState(
      await _request('${Uri.encodeComponent(id)}/state'),
    );
  }

  Future<bool> hasCamera(String id) async {
    final data = await _request('${Uri.encodeComponent(id)}/capabilities');
    return (data['capabilities'] as List?)?.contains('camera') ?? false;
  }

  Future<void> send(String id, String command, [String? argument]) async {
    final result = await _request(
      '${Uri.encodeComponent(id)}/commands',
      command: {'cmd': command, if (argument != null) 'arg': argument},
    );
    if (result['success'] != true) throw Exception('Command failed');
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iot_hub_client/api/iot_hub_core.dart';

class NfcReader {
  final IHCToken token;
  final http.Client _client;

  NfcReader(this.token, {http.Client? client})
    : _client = client ?? http.Client();

  void close() => _client.close();

  Future<Object> waitForCard() async {
    final base = token.server.replaceFirst(RegExp(r'/+$'), '');
    final response = await _client
        .get(
          Uri.parse(
            '$base/auth/wait-for-card',
          ).replace(queryParameters: {'timeout': '20'}),
          headers: {
            'Authorization': 'Bearer ${token.token}',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('NFC request failed (HTTP ${response.statusCode})');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['type'] != 'IHCApiResponse') {
      throw Exception('Invalid NFC response');
    }
    if (body['message'] == 'timeout') {
      throw TimeoutException('No card received');
    }
    final errors = body['errors'];
    if (body['message'] != 'success' ||
        (errors is Map && errors.isNotEmpty) ||
        (errors is List && errors.isNotEmpty) ||
        (errors is String && errors.isNotEmpty)) {
      throw Exception('NFC request rejected');
    }
    final data = body['data'];
    if (data == null ||
        (data is Map && data.isEmpty) ||
        (data is List && data.isEmpty) ||
        (data is String && data.trim().isEmpty)) {
      throw Exception('No card data received');
    }
    return data as Object;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/nfc_reader.dart';

void main() {
  NfcReader reader(Map<String, dynamic> body, {int status = 200}) => NfcReader(
    IHCToken('test-token', 'http://localhost:8006/'),
    client: MockClient((request) async {
      expect(request.url.path, '/auth/wait-for-card');
      expect(request.url.queryParameters, {'timeout': '20'});
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(jsonEncode(body), status);
    }),
  );

  test(
    'Returns received card data without assuming a UID field name',
    () async {
      final service = reader({
        'type': 'IHCApiResponse',
        'message': 'success',
        'data': {'uid': 'ABC123'},
        'errors': {},
      });
      addTearDown(service.close);
      expect(await service.waitForCard(), {'uid': 'ABC123'});
    },
  );

  test(
    'The observed server timeout is a timeout, not a successful read',
    () async {
      final service = reader({
        'type': 'IHCApiResponse',
        'message': 'timeout',
        'data': {},
        'errors': {},
      });
      addTearDown(service.close);
      await expectLater(
        service.waitForCard(),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test('Empty data and HTTP errors cannot report a received card', () async {
    final empty = reader({
      'type': 'IHCApiResponse',
      'message': 'success',
      'data': {},
      'errors': {},
    });
    final unauthorized = reader({}, status: 401);
    addTearDown(empty.close);
    addTearDown(unauthorized.close);
    await expectLater(empty.waitForCard(), throwsException);
    await expectLater(unauthorized.waitForCard(), throwsException);
  });
}

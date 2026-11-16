import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';
import 'package:iot_hub_client/views/admin/device_register_update.dart';

http.Response envelope({
  String message = 'success',
  Map<String, dynamic> data = const {},
  Map<String, dynamic> errors = const {},
}) => http.Response(
  jsonEncode({
    'type': 'IHCApiResponse',
    'message': message,
    'data': data,
    'errors': errors,
  }),
  200,
);

void main() {
  final token = IHCToken('test', 'http://localhost:8006');
  final camera = Device(
    id: '',
    host: '0',
    driverId: 10,
    type: 20,
    name: 'Local camera',
    state: null,
  );

  test(
    'Registration preserves host zero and checks application errors in HTTP 200',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/device/register/device');
        expect(jsonDecode(request.body), {
          'device_host': '0',
          'device_name': 'Local camera',
          'device_driver': 10,
          'device_type': 20,
        });
        return envelope(
          message: 'error',
          errors: {'device': 'Registration rejected'},
        );
      });
      addTearDown(client.close);
      await expectLater(
        IHC(token, client: client).registerDevice(device: camera),
        throwsA(
          isA<IHCRequestException>().having(
            (e) => e.message,
            'message',
            'Registration rejected',
          ),
        ),
      );
    },
  );

  test('FastAPI validation errors identify the missing field', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': [
            {
              'loc': ['body', 'device_type'],
              'msg': 'Input should be a valid integer',
            },
          ],
        }),
        422,
      ),
    );
    addTearDown(client.close);
    await expectLater(
      IHC(token, client: client).registerDevice(device: camera),
      throwsA(
        isA<IHCRequestException>().having(
          (e) => e.message,
          'message',
          contains('device_type'),
        ),
      ),
    );
  });

  testWidgets(
    'Local camera form validates selections, displays errors and allows retry',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saves = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/list/drivers')) {
          return envelope(
            data: {
              'device_drivers': [
                {'id': 10, 'name': 'local_camera'},
              ],
            },
          );
        }
        if (request.url.path.endsWith('/list/types')) {
          return envelope(
            data: {
              'device_types': [
                {'id': 20, 'name': 'camera'},
              ],
            },
          );
        }
        saves++;
        expect(jsonDecode(request.body)['device_host'], '0');
        return saves == 1
            ? envelope(
                message: 'error',
                errors: {'device': 'Registration rejected'},
              )
            : envelope(
                data: {
                  'device': {'id': 'new-camera'},
                },
              );
      });
      addTearDown(client.close);
      final api = IHC(token, client: client);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DeviceRegisterUpdate(api: api),
                  ),
                ),
                child: const Text('Add camera'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add camera'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Local camera');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(find.text('Select a driver'), findsOneWidget);
      expect(find.text('Select a device type'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('local_camera').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('camera').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Registration rejected'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(find.text('Add camera'), findsOneWidget);
      expect(find.byType(DeviceRegisterUpdate), findsNothing);
    },
  );
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/views/admin/device_register_update.dart';
import 'package:iot_hub_client/widgets/hardware_host_picker.dart';

http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  final token = IHCToken('test-token', 'http://localhost:8006/');

  test(
    'Hardware helpers use v2 and preserve string camera and serial hosts',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.url.path.endsWith('/cameras')) {
          expect(request.url.path, '/api/v2/hardware/cameras');
          expect(request.url.queryParameters, {'max_index': '4'});
          return jsonResponse({
            'available': true,
            'items': [
              {
                'host': '0',
                'description': 'Local camera 0',
                'driver': 'local_camera',
              },
            ],
            'issues': [
              {'host': '1', 'reason': 'probe_timeout'},
            ],
            'message': 'Only readable cameras are listed.',
          });
        }
        expect(request.url.path, '/api/v2/hardware/serial');
        return jsonResponse({
          'items': [
            {
              'host': '/dev/ttyUSB0',
              'description': null,
              'manufacturer': 'Adapter',
            },
          ],
        });
      });
      addTearDown(client.close);
      final api = IHC(token, client: client);
      final cameras = await api.hardwareDevices(cameras: true);
      expect(cameras.items.single.host, '0');
      expect(cameras.skipped, 1);
      final serial = await api.hardwareDevices(cameras: false);
      expect(serial.items.single.host, '/dev/ttyUSB0');
      expect(serial.available, isTrue);
    },
  );

  test(
    'Unavailable discovery differs from unsupported and malformed responses',
    () async {
      for (final response in [
        jsonResponse({'detail': 'Not found'}, 404),
        jsonResponse({'items': 'invalid'}),
        jsonResponse({'detail': 'Failed'}, 503),
      ]) {
        final client = MockClient((_) async => response);
        try {
          await expectLater(
            IHC(token, client: client).hardwareDevices(cameras: true),
            throwsA(isA<IHCRequestException>()),
          );
        } finally {
          client.close();
        }
      }
      final client = MockClient(
        (_) async => jsonResponse({
          'available': false,
          'items': [],
          'issues': [],
          'message': 'Camera support missing',
        }),
      );
      addTearDown(client.close);
      expect(
        (await IHC(
          token,
          client: client,
        ).hardwareDevices(cameras: true)).available,
        isFalse,
      );
    },
  );

  testWidgets(
    'Picking a host preserves manual editing and cancelling preserves input',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var searches = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/list/drivers')) {
          return jsonResponse({
            'data': {'device_drivers': []},
          });
        }
        if (request.url.path.endsWith('/list/types')) {
          return jsonResponse({
            'data': {'device_types': []},
          });
        }
        searches++;
        return request.url.path.endsWith('/cameras')
            ? jsonResponse({
                'available': true,
                'items': [
                  {
                    'host': '0',
                    'description': 'Local camera 0',
                    'driver': 'local_camera',
                  },
                ],
                'issues': [],
                'message': '',
              })
            : jsonResponse({
                'items': [
                  {'host': 'COM4', 'description': 'USB serial'},
                ],
              });
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceRegisterUpdate(api: IHC(token, client: client)),
        ),
      );
      await tester.pumpAndSettle();
      final host = find.byType(TextFormField).at(1);
      await tester.enterText(host, 'manual-host');
      expect(searches, 0);
      await tester.tap(find.text('Find local cameras'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('0')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(host).controller!.text, '0');
      await tester.enterText(host, '/dev/video2');
      await tester.tap(find.text('Find local cameras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(host).controller!.text,
        '/dev/video2',
      );
      await tester.tap(find.text('Find serial ports'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COM4'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(host).controller!.text, 'COM4');
      await tester.enterText(host, 'custom-host');
      expect(
        tester.widget<TextFormField>(host).controller!.text,
        'custom-host',
      );
    },
  );

  testWidgets('Failed search can retry and closing a running search is safe', (
    tester,
  ) async {
    var searches = 0;
    final pending = Completer<http.Response>();
    final client = MockClient((_) async {
      searches++;
      if (searches == 1) return jsonResponse({}, 503);
      return pending.future;
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showHardwareHostPicker(
                context,
                api: IHC(token, client: client),
                cameras: true,
              ),
              child: const Text('Search'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 503'), findsOneWidget);
    await tester.tap(find.text('Search again'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    pending.complete(
      jsonResponse({'available': true, 'items': [], 'issues': []}),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(searches, 2);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/camera.dart';
import 'package:iot_hub_client/services/device_actions.dart';

void main() {
  final jpeg = [255, 216, 1, 2, 255, 217];
  final token = IHCToken('secret', 'http://localhost:8006/');

  test('Snapshot uses v2, bearer authentication and binary JPEG', () async {
    final service = CameraService(
      token,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v2/devices/camera-1/snapshot');
        expect(request.headers['Authorization'], 'Bearer secret');
        expect(request.headers['Accept'], 'image/jpeg');
        return http.Response.bytes(
          jpeg,
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }),
    );
    addTearDown(service.close);
    expect(await service.snapshot('camera-1'), jpeg);
  });

  test('MJPEG frames survive boundaries split across network chunks', () async {
    final bytes = <int>[
      ...ascii.encode(
        '--frame\r\nContent-Type: image/jpeg\r\nContent-Length: 6\r\n\r\n',
      ),
      ...jpeg,
      ...ascii.encode('\r\n--frame\r\nContent-Type: image/jpeg\r\n\r\n'),
      ...jpeg,
      ...ascii.encode('\r\n--frame--\r\n'),
    ];
    final service = CameraService(
      token,
      client: MockClient.streaming((request, _) async {
        expect(request.url.path, '/api/v2/devices/camera-1/stream');
        expect(request.headers['Authorization'], 'Bearer secret');
        return http.StreamedResponse(
          Stream.fromIterable(bytes.map((b) => [b])),
          200,
          headers: {
            'content-type': 'multipart/x-mixed-replace; boundary="frame"',
          },
        );
      }),
    );
    addTearDown(service.close);
    expect(await service.frames('camera-1').toList(), [jpeg, jpeg]);
  });

  test('Camera failures and non-JPEG responses are rejected', () async {
    for (final response in [
      http.Response('{}', 504),
      http.Response('{}', 200, headers: {'content-type': 'application/json'}),
      http.Response('broken', 200, headers: {'content-type': 'image/jpeg'}),
    ]) {
      final service = CameraService(
        token,
        client: MockClient((_) async => response),
      );
      try {
        await expectLater(service.snapshot('camera-1'), throwsException);
      } finally {
        service.close();
      }
    }
  });

  test(
    'Camera detection uses capabilities without requiring a camera type',
    () async {
      final service = DeviceActions(
        token,
        client: MockClient((request) async {
          expect(request.url.path, '/api/v2/devices/camera-1/capabilities');
          return http.Response(
            jsonEncode({
              'capabilities': ['camera'],
              'commands': [],
              'state_fields': [],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      expect(await service.hasCamera('camera-1'), isTrue);
    },
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/device_actions.dart';
import 'package:iot_hub_client/widgets/io_action.dart';

void main() {
  test(
    'Unknown power remains unknown when the device reports an error',
    () async {
      final service = DeviceActions(
        IHCToken('test', 'http://localhost:8006'),
        client: MockClient((request) async {
          expect(request.url.path, '/api/device/state');
          expect(request.url.queryParameters['uuid'], 'device-1');
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response(
            jsonEncode({
              'type': 'IHCApiResponse',
              'data': {
                'device': {
                  'state': 'error',
                  'message': 'ERROR COMMUNICATING',
                  'power_state': null,
                },
              },
              'errors': {},
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final state = await service.state('device-1');
      expect(state.power, isNull);
      expect(state.hasError, isTrue);
    },
  );

  test('Command errors are surfaced even with HTTP 200', () async {
    final service = DeviceActions(
      IHCToken('test', 'http://localhost:8006'),
      client: MockClient((request) async {
        expect(request.url.queryParameters, {
          'uuid': 'device-1',
          'cmd': 'switch',
          'arg': 'on',
        });
        return http.Response(
          jsonEncode({
            'type': 'IHCApiResponse',
            'data': {},
            'errors': {'device': 'offline'},
          }),
          200,
        );
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.send('device-1', 'switch', 'on'),
      throwsException,
    );
  });

  test('HTTP failures cannot be treated as successful commands', () async {
    final service = DeviceActions(
      IHCToken('test', 'http://localhost:8006'),
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(service.close);
    await expectLater(service.send('device-1', 'open'), throwsException);
  });

  testWidgets('Unknown power disables switching but allows refreshing', (
    tester,
  ) async {
    var toggles = 0;
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IOAction(
            kind: DeviceActionKind.power,
            isOn: null,
            busy: false,
            available: true,
            onRefresh: () => refreshes++,
            onStatus: () {},
            onToggle: () => toggles++,
            onMove: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Power state unknown'));
    await tester.tap(find.byTooltip('Refresh status'));
    expect(toggles, 0);
    expect(refreshes, 1);
  });

  testWidgets('Movement callbacks run on tap and are blocked while busy', (
    tester,
  ) async {
    final commands = <String>[];
    Widget app(bool busy) => MaterialApp(
      home: Scaffold(
        body: IOAction(
          kind: DeviceActionKind.movement,
          isOn: null,
          busy: busy,
          available: true,
          onRefresh: () {},
          onStatus: () {},
          onToggle: () {},
          onMove: commands.add,
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    expect(commands, isEmpty);
    await tester.tap(find.byTooltip('Open'));
    await tester.tap(find.byTooltip('Close'));
    expect(commands, ['open', 'close']);
    await tester.pumpWidget(app(true));
    expect(find.byTooltip('Open'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

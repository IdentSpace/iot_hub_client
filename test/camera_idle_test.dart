import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/device_actions.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/widgets/device_control.dart';

void main() {
  for (final detail in [false, true]) {
    testWidgets(
      '${detail ? 'Detail' : 'List'} refresh does not read camera state or images',
      (tester) async {
        final token = IHCToken('test', 'http://localhost:8006');
        TokenStore.setToken(token);
        addTearDown(TokenStore.clear);
        final paths = <String>[];
        final actions = DeviceActions(
          token,
          client: MockClient((request) async {
            paths.add(request.url.path);
            return http.Response(
              jsonEncode({
                'capabilities': ['camera'],
              }),
              200,
            );
          }),
        );
        final device = IOHDevice(
          id: 'camera-1',
          name: 'Camera',
          typeSlug: 'camera',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: detail
                    ? DeviceControl(device: device, actions: actions)
                    : DeviceListItem(device: device, actions: actions),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Ready for snapshot or stream'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byTooltip('Refresh status'));
        await tester.tap(find.byTooltip('Refresh status'));
        await tester.pumpAndSettle();
        expect(paths, [
          '/api/v2/devices/camera-1/capabilities',
          '/api/v2/devices/camera-1/capabilities',
        ]);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

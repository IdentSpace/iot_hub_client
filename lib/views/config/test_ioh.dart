import 'package:flutter/material.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/io_view.dart';

class TestIOH extends StatelessWidget {
  final token = TokenStore.token;

  TestIOH({super.key});

  @override
  Widget build(BuildContext context) {
    final IOHubClient ioHubClient = IOHubClient(
      token!.server,
      token?.token ?? '',
    );

    return IOHView(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final a = await ioHubClient.state();
              debugPrint(a.toString());
            },
            child: Text("state"),
          ),
          ElevatedButton(
            onPressed: () async {
              final a = await ioHubClient.deviceList();
            },
            child: Text("deviceList"),
          ),
        ],
      ),
    );
  }
}

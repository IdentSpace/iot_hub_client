import 'package:flutter/material.dart';
import 'package:iot_hub_client/views/admin/devices.dart';

// TODO: Statemanagment
// TODO: DB for AppData

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AdminDevices(title: 'Devices'),
    );
  }
}

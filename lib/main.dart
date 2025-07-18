import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';

// TODO: DB for AppData

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = IHC.auth(
    server: "http://192.168.51.235:8005",
    username: "username",
    password: "password",
  );

  TokenStore.setToken(token);

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
      home: const DeviceList(title: 'Devices'),
      navigatorObservers: [routeObserver],
    );
  }
}

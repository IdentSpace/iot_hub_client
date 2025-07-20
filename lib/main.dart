import 'package:flutter/material.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/views/login.dart';

// TODO: DB for AppData

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase db = AppDatabase.instance;
  db.debugDirectory();
  await TokenStore.load();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(TokenStore.asString());

    return MaterialApp(
      title: 'IoT Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: !TokenStore.has() ? const Login() : const DeviceList(),
      navigatorObservers: [routeObserver],
    );
  }
}

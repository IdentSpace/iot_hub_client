import 'package:flutter/material.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/login_select_token.dart';

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
    return MaterialApp(
      title: 'IOHub Dash',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF343A40),
          onPrimary: Colors.white,
          secondary: Color(0xFF626B73),
          surface: Colors.white,
          onSurface: Color(0xFF20252A),
          onSurfaceVariant: Color(0xFF626B73),
          outline: Color(0xFF858E96),
          outlineVariant: Color(0xFFDEE2E6),
          surfaceContainerHighest: Color(0xFFEEF0F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF20252A),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFDEE2E6)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: LoginSelectToken(),
      navigatorObservers: [routeObserver],
    );
  }
}

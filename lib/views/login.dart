import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/database.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

// TODO: Implement fast login with QR Code
class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String _errorText = '';

  String _serverHost = '';
  String _username = '';
  String _password = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      _errorText = '';
    });

    _formKey.currentState!.save();

    final token = await IHC.auth(
      server: _serverHost,
      username: _username,
      password: _password,
    );

    setState(() => isLoading = false);

    if (token == null) {
      setState(() {
        _errorText = "Login failure, wrong data";
      });
      return;
    }

    TokenStore.setToken(token);

    final AppDatabase db = AppDatabase.instance;
    await db.insertToken(token);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("IoT Hub", style: TextStyle(fontSize: 30)),
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(labelText: "Server"),
                        onSaved: (value) => _serverHost = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Server is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(labelText: "Username"),
                        onSaved: (value) => _username = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(labelText: "Password"),
                        onSaved: (value) => _password = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        _errorText,
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              )
                            : Text("Login"),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
            Text("IdentSpace"),
          ],
        ),
      ),
    );
  }
}

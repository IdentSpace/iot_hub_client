import 'package:flutter/material.dart';
import 'package:iot_hub_client/services/appconfig_state.dart';

class ConfigApp extends StatefulWidget {
  const ConfigApp({super.key});

  @override
  State<ConfigApp> createState() => _ConfigAppState();
}

class _ConfigAppState extends State<ConfigApp> {
  final _formKey = GlobalKey<FormState>();

  String? _serverHost = AppConfigStore.serverhost;

  void _saveConfigs() {
    debugPrint("SAVE");
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AppConfigStore.setServerHost(_serverHost);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Config App")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Server Host"),
                    onSaved: (value) => _serverHost = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Server host is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              ElevatedButton(onPressed: _saveConfigs, child: Text("Save")),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';
import 'package:iot_hub_client/services/token_state.dart';

class DeviceRegister extends StatefulWidget {
  const DeviceRegister({super.key});

  @override
  State<DeviceRegister> createState() => _DeviceRegisterState();
}

class _DeviceRegisterState extends State<DeviceRegister> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  String _deviceName = '';
  String _deviceHost = '';
  String? _deviceType;
  String? _deviceDriver;

  final List<String> _deviceTypes = [
    'heater',
    'light',
    'machine',
    'door',
    'other',
  ];

  final List<String> _deviceDrivers = ['shelly_http', 'nfc', 'ids_locker'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    _formKey.currentState!.save();

    final registerSate = await IHC.registerDevice(
      token: TokenStore.token!,
      device: Device(
        id: '',
        host: _deviceHost,
        driver: _deviceDriver,
        type: _deviceType,
        name: _deviceName,
        state: null,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: registerSate ? Text('Device added') : Text("Error by saving"),
      ),
    );

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Regsiter new device")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: "Device Name"),
                        onSaved: (value) => _deviceName = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Device name is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      TextFormField(
                        decoration: InputDecoration(labelText: "Device Host"),
                        onSaved: (value) => _deviceHost = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Device host ist required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Device Type'),
                        value: _deviceType,
                        items: _deviceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _deviceType = value),
                        validator: (value) => value == null ? 'Select' : null,
                        onSaved: (value) => _deviceType = value,
                      ),
                      SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Device Driver'),
                        value: _deviceDriver,
                        items: _deviceDrivers.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _deviceDriver = value),
                        validator: (value) => value == null ? 'Select' : null,
                        onSaved: (value) => _deviceDriver = value,
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              )
                            : Text("Save"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

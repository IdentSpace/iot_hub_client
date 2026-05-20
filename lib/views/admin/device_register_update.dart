import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/views/io_view.dart';
import 'package:iot_hub_client/widgets/io_card.dart';
import 'package:iot_hub_client/widgets/io_material.dart';

class DeviceRegisterUpdate extends StatefulWidget {
  const DeviceRegisterUpdate({super.key, this.device});
  final IOHDevice? device;

  @override
  State<DeviceRegisterUpdate> createState() => _DeviceRegisterState();
}

class _DeviceRegisterState extends State<DeviceRegisterUpdate> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _driverList = [];
  List<Map<String, dynamic>> _typeList = [];
  int? _selectedDriver;
  int? _selectedType;

  String stateText = "Unknown";

  bool isUpdate = false;

  bool isLoading = false;
  IHC ihc = IHC(TokenStore.token!);

  String? _deviceName;
  String? _deviceHost;
  int? _deviceBaudrate;
  int _deviceChannel = 0;

  Future<void> _deviceEvent(String cmd, String? arg) async {
    if (widget.device == null) {
      return;
    }

    final token = TokenStore.token;
    if (token == null) {
      return;
    }

    await IOHubClient(
      token.server,
      token.token,
    ).getDeviceEvent(widget.device!, cmd, arg);
  }

  Future<void> _getDeviceState() async {
    debugPrint("Getting device state for device ${widget.device?.id}");
    if (widget.device == null) {
      debugPrint("No device specified for getting state");
      return;
    }
    final token = TokenStore.token;
    if (token == null) {
      debugPrint("No token available for getting device state");
      return;
    }

    final IOHDeviceState? deviceState = await IOHubClient(
      token.server,
      token.token,
    ).getDeviceState(widget.device!);

    if (deviceState == null) {
      debugPrint("Failed to get device state");
      setState(() {
        stateText = "Error getting state";
      });
      return;
    }

    setState(() {
      stateText = deviceState.toString();
    });
  }

  Future<void> _loadDriversAndTypes() async {
    final drivers = await ihc.deviceDriverList();
    final types = await ihc.deviceTypeList();
    setState(() {
      _driverList = drivers;
      _typeList = types;

      if (widget.device != null) {
        _selectedType = widget.device!.typeId;
        _selectedDriver = widget.device!.driverId;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDriversAndTypes();
    isUpdate = widget.device != null && widget.device!.id.isNotEmpty;

    if (widget.device != null) {
      _deviceName = widget.device!.name;
      _deviceHost = widget.device!.host;
      _deviceChannel = widget.device!.channel ?? 0;
      _deviceBaudrate = widget.device!.baudrate;
    }
  }

  /// Update device on the IHC server
  Future<void> _update() async {
    setState(() => isLoading = true);
    _formKey.currentState!.save();

    final updateState = await ihc.updateDevice(
      device: Device(
        id: widget.device!.id,
        host: _deviceHost,
        channel: _deviceChannel,
        baudrate: _deviceBaudrate,
        driverId: _selectedDriver,
        type: _selectedType,
        name: _deviceName,
        state: null,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: updateState ? Text('Device updated') : Text("Error by saving"),
      ),
    );

    setState(() => isLoading = false);
    return;
  }

  /// Register new device on the IHC server
  Future<void> _register() async {
    setState(() => isLoading = true);
    _formKey.currentState!.save();

    final registerSate = await ihc.registerDevice(
      device: Device(
        id: '',
        host: _deviceHost,
        channel: _deviceChannel,
        baudrate: _deviceBaudrate,
        driverId: _selectedDriver,
        type: _selectedType,
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

  /// Submit form for register or update
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);
    _formKey.currentState!.save();

    if (isUpdate) {
      await _update();
    } else {
      await _register();
    }

    setState(() => isLoading = false);
  }

  /// Delete device from IHC server
  Future<void> _delete() async {
    if (widget.device == null) {
      return;
    }

    setState(() => isLoading = true);

    final deleteState = await ihc.deleteDevice(deviceId: widget.device!.id);

    if (!mounted) return;

    if (!deleteState) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error by deleting")));

      setState(() => isLoading = false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceList()),
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label kopiert!"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IOHView(
      title: "Regsiter new device",
      body: Column(
        children: [
          if (widget.device != null) ...[
            IOCard(
              title: 'Controll',
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Bewegen:"),
                      SizedBox(width: 40),
                      ElevatedButton(
                        onPressed: () => _deviceEvent("open", null),
                        child: Text('Hochfahren'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _deviceEvent("close", null),
                        child: Text('Runterfahren'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text("Status:"),
                      SizedBox(width: 40),
                      ElevatedButton(
                        onPressed: _getDeviceState,
                        child: Text('Get Status'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(stateText),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
          IOCard(
            title: 'Settings',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () => _copy(
                              widget.device?.id ?? 'New Device',
                              'Device ID',
                            ),
                          ),
                          Text(widget.device?.id ?? 'New Device'),
                        ],
                      ),

                      SizedBox(height: 20),
                      formFieldContainer(
                        label: "Device Name",
                        formField: TextFormField(
                          initialValue: _deviceName,
                          decoration: ioInputDecoration(),
                          onSaved: (value) => _deviceName = value ?? '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Device name is required';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      formFieldContainer(
                        label: "Host",
                        formField: TextFormField(
                          initialValue: _deviceHost,
                          decoration: ioInputDecoration(),
                          onSaved: (value) => _deviceHost = value ?? '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Device host ist required';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      formFieldContainer(
                        label: "Driver",
                        formField: DropdownButtonFormField<int>(
                          decoration: ioInputDecoration(),
                          initialValue: _selectedDriver,
                          items: _driverList.map((driver) {
                            return DropdownMenuItem<int>(
                              value: driver['id'],
                              child: Text(driver['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDriver = value),
                          // validator: (value) => value == null ? 'Select' : null,
                          onSaved: (value) => _selectedDriver = value,
                        ),
                      ),
                      SizedBox(height: 20),

                      formFieldContainer(
                        label: "Type",
                        formField: DropdownButtonFormField<int>(
                          decoration: ioInputDecoration(),
                          initialValue: _selectedType,
                          items: _typeList.map((type) {
                            debugPrint(type.toString());
                            return DropdownMenuItem<int>(
                              value: type['id'],
                              child: Text(type['name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedType = value),
                          // validator: (value) => value == null ? 'Select' : null,
                          onSaved: (value) => _selectedType = value,
                        ),
                      ),
                      SizedBox(height: 20),

                      formFieldContainer(
                        label: "Baudrate",
                        formField: TextFormField(
                          initialValue: _deviceBaudrate == null
                              ? ''
                              : _deviceBaudrate.toString(),
                          keyboardType: TextInputType.number,
                          decoration: ioInputDecoration(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (value) => _deviceBaudrate = value != null
                              ? int.tryParse(value)
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),

                      formFieldContainer(
                        label: "Channel",
                        formField: TextFormField(
                          initialValue: _deviceChannel.toString(),
                          keyboardType: TextInputType.number,
                          decoration: ioInputDecoration(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (value) => _deviceChannel = value != null
                              ? int.tryParse(value) ?? 0
                              : 0,
                        ),
                      ),
                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: isLoading || !isUpdate ? null : _delete,
                            child: isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                : Text("Delete"),
                          ),

                          SizedBox(width: 10),

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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

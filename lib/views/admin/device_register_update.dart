import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/device.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_list.dart';
import 'package:iot_hub_client/widgets/io_card.dart';
import 'package:iot_hub_client/widgets/device_control.dart';
import 'package:iot_hub_client/widgets/io_material.dart';
import 'package:iot_hub_client/widgets/hardware_host_picker.dart';

class DeviceRegisterUpdate extends StatefulWidget {
  const DeviceRegisterUpdate({super.key, this.device, this.api});
  final IHC? api;
  final IOHDevice? device;

  @override
  State<DeviceRegisterUpdate> createState() => _DeviceRegisterState();
}

class _DeviceRegisterState extends State<DeviceRegisterUpdate> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();

  List<Map<String, dynamic>> _driverList = [];
  List<Map<String, dynamic>> _typeList = [];
  int? _selectedDriver;
  int? _selectedType;

  bool isUpdate = false;

  bool isLoading = false;
  late final IHC ihc = widget.api ?? IHC(TokenStore.token!);
  String? _saveError;
  String? _optionsError;

  String? _deviceName;
  String? _deviceHost;
  static const _standardBaudrates = <int>[
    300,
    600,
    1200,
    2400,
    4800,
    9600,
    14400,
    19200,
    28800,
    38400,
    57600,
    115200,
    230400,
    460800,
    921600,
  ];
  int? _deviceBaudrate;

  List<int> get _baudrateOptions => <int>{
    ..._standardBaudrates,
    if (_deviceBaudrate != null) _deviceBaudrate!,
  }.toList()..sort();
  int _deviceChannel = 0;
  bool _uuidWithHyphens = false;

  bool get _hasUuid => RegExp(
    r'^[0-9a-fA-F]{32}$',
  ).hasMatch((widget.device?.id ?? '').replaceAll('-', ''));

  String get _displayUuid {
    final id = widget.device?.id ?? 'New Device';
    if (!_hasUuid) return id;
    final compact = id.replaceAll('-', '');
    if (!_uuidWithHyphens) return compact;
    return '${compact.substring(0, 8)}-${compact.substring(8, 12)}-'
        '${compact.substring(12, 16)}-${compact.substring(16, 20)}-'
        '${compact.substring(20)}';
  }

  Future<void> _loadDriversAndTypes() async {
    try {
      final drivers = await ihc.deviceDriverList();
      final types = await ihc.deviceTypeList();
      if (!mounted) return;
      setState(() {
        _driverList = drivers;
        _typeList = types;
        _optionsError = null;
        if (widget.device != null) {
          _selectedType = widget.device!.typeId;
          _selectedDriver = widget.device!.driverId;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _optionsError = 'Could not load drivers and device types.',
        );
      }
    }
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
    _hostController.text = _deviceHost ?? '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _selectHardwareHost(bool cameras) async {
    final host = await showHardwareHostPicker(
      context,
      api: ihc,
      cameras: cameras,
    );
    if (!mounted || host == null) return;
    _hostController.value = TextEditingValue(
      text: host,
      selection: TextSelection.collapsed(offset: host.length),
    );
  }

  Future<void> _submit() async {
    if (isLoading || !_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      isLoading = true;
      _saveError = null;
    });
    try {
      final device = Device(
        id: widget.device?.id ?? '',
        host: _deviceHost,
        channel: _deviceChannel,
        baudrate: _deviceBaudrate,
        driverId: _selectedDriver,
        type: _selectedType,
        name: _deviceName,
        state: null,
      );
      final saved = isUpdate
          ? await ihc.updateDevice(device: device)
          : await ihc.registerDevice(device: device);
      if (!saved) throw const IHCRequestException('Could not save device');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUpdate ? 'Device updated' : 'Device added')),
      );
      if (!isUpdate && Navigator.of(context).canPop()) {
        Navigator.pop(context, true);
      }
    } on IHCRequestException catch (error) {
      if (mounted) setState(() => _saveError = error.message);
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _saveError =
              'The server did not respond in time. Check the device list before saving again.',
        );
      }
    } on SocketException {
      if (mounted) {
        setState(
          () => _saveError =
              'Could not connect to the server. Check the connection and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Could not save device. Check the connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
    return Scaffold(
      appBar: AppBar(title: Text(isUpdate ? 'Edit device' : 'Add device')),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 16,
                    overflowSpacing: 12,
                    children: [
                      if (isUpdate)
                        TextButton.icon(
                          onPressed: isLoading ? null : _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      FilledButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_optionsError != null) ...[
                    Text(
                      _optionsError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadDriversAndTypes,
                      child: const Text('Retry loading drivers and types'),
                    ),
                  ],
                  if (widget.device != null) ...[
                    DeviceControl(device: widget.device!, enabled: !isLoading),
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
                                    tooltip: 'Copy UUID',
                                    onPressed: _hasUuid
                                        ? () => _copy(_displayUuid, 'Device ID')
                                        : null,
                                  ),
                                  Expanded(child: Text(_displayUuid)),
                                  if (_hasUuid)
                                    IconButton(
                                      tooltip: _uuidWithHyphens
                                          ? 'Show without hyphens'
                                          : 'Show with hyphens',
                                      isSelected: _uuidWithHyphens,
                                      onPressed: () => setState(
                                        () => _uuidWithHyphens =
                                            !_uuidWithHyphens,
                                      ),
                                      icon: const Icon(Icons.compare_arrows),
                                    ),
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
                                  controller: _hostController,
                                  decoration: ioInputDecoration(),
                                  onSaved: (value) =>
                                      _deviceHost = value?.trim() ?? '',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Device host is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () => _selectHardwareHost(false),
                                      icon: const Icon(Icons.usb),
                                      label: const Text('Find serial ports'),
                                    ),
                                    TextButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () => _selectHardwareHost(true),
                                      icon: const Icon(Icons.videocam_outlined),
                                      label: const Text('Find local cameras'),
                                    ),
                                  ],
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
                                  validator: (value) =>
                                      value == null ? 'Select a driver' : null,
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
                                    return DropdownMenuItem<int>(
                                      value: type['id'],
                                      child: Text(type['name'] ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedType = value),
                                  validator: (value) => value == null
                                      ? 'Select a device type'
                                      : null,
                                  onSaved: (value) => _selectedType = value,
                                ),
                              ),
                              SizedBox(height: 20),

                              formFieldContainer(
                                label: "Baudrate",
                                formField: DropdownButtonFormField<int>(
                                  initialValue: _deviceBaudrate,
                                  decoration: ioInputDecoration(),
                                  hint: const Text('Select baudrate'),
                                  isExpanded: true,
                                  items: _baudrateOptions
                                      .map(
                                        (rate) => DropdownMenuItem<int>(
                                          value: rate,
                                          child: Text('$rate'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (value) => setState(
                                          () => _deviceBaudrate = value,
                                        ),
                                  onSaved: (value) => _deviceBaudrate = value,
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
                                  onSaved: (value) =>
                                      _deviceChannel = value != null
                                      ? int.tryParse(value) ?? 0
                                      : 0,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

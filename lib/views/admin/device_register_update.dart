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

  bool isUpdate = false;

  bool isLoading = false;
  IHC ihc = IHC(TokenStore.token!);

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
    final drivers = await ihc.deviceDriverList();
    final types = await ihc.deviceTypeList();
    if (!mounted) return;
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

    if (!mounted) return;
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

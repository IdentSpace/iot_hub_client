import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/api/models/hardware.dart';

Future<String?> showHardwareHostPicker(
  BuildContext context, {
  required IHC api,
  required bool cameras,
}) => showDialog<String>(
  context: context,
  builder: (_) => _HardwareHostPicker(api: api, cameras: cameras),
);

class _HardwareHostPicker extends StatefulWidget {
  final IHC api;
  final bool cameras;
  const _HardwareHostPicker({required this.api, required this.cameras});

  @override
  State<_HardwareHostPicker> createState() => _HardwareHostPickerState();
}

class _HardwareHostPickerState extends State<_HardwareHostPicker> {
  HardwareDevices? _devices;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await widget.api.hardwareDevices(cameras: widget.cameras);
      if (mounted) setState(() => _devices = devices);
    } on IHCRequestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error =
              'Hardware search timed out. Try again or enter the host manually.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not reach the IOHub server. Try again or enter the host manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.cameras ? 'Local cameras' : 'Serial ports'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Devices connected to the IOHub server.'),
            const SizedBox(height: 12),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(
                widget.cameras
                    ? 'Searching cameras… This can take up to 30 seconds.'
                    : 'Searching serial ports…',
              ),
            ] else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_devices != null) ...[
              if (!_devices!.available)
                const Text(
                  'Camera discovery is unavailable on this IOHub server. You can enter the host manually.',
                )
              else ...[
                if (_devices!.items.isEmpty)
                  Text(
                    widget.cameras
                        ? 'No readable cameras found. Busy cameras may be missing; you can enter the host manually.'
                        : 'No serial ports found. You can enter the host manually.',
                  ),
                for (final device in _devices!.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      widget.cameras ? Icons.videocam_outlined : Icons.usb,
                    ),
                    title: Text(device.host),
                    subtitle: Text(
                      [device.description, device.manufacturer]
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                    ),
                    onTap: () => Navigator.pop(context, device.host),
                  ),
                if (widget.cameras && _devices!.skipped > 0)
                  Text(
                    '${_devices!.skipped} camera sources could not be read. They may be busy or unavailable.',
                  ),
              ],
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _loading ? null : _load,
        child: const Text('Search again'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}

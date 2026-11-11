import 'package:flutter/material.dart';
import 'package:iot_hub_client/services/device_actions.dart';

/// Presentation only: the device row owns requests, state and errors.
class IOAction extends StatelessWidget {
  final DeviceActionKind kind;
  final bool? isOn;
  final bool busy;
  final bool available;
  final VoidCallback? onReadNfc;
  final VoidCallback onRefresh;
  final VoidCallback onStatus;
  final VoidCallback onToggle;
  final ValueChanged<String> onMove;

  const IOAction({
    super.key,
    required this.kind,
    required this.isOn,
    required this.busy,
    required this.available,
    this.onReadNfc,
    required this.onRefresh,
    required this.onStatus,
    required this.onToggle,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (kind == DeviceActionKind.power)
          IconButton(
            tooltip: isOn == null
                ? 'Power state unknown'
                : isOn!
                ? 'Turn off'
                : 'Turn on',
            onPressed: available && isOn != null ? onToggle : null,
            icon: Icon(
              isOn == true ? Icons.toggle_on : Icons.toggle_off,
              size: 32,
            ),
          ),
        if (kind == DeviceActionKind.movement) ...[
          IconButton(
            tooltip: 'Open',
            onPressed: available ? () => onMove('open') : null,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: available ? () => onMove('close') : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
        if (kind == DeviceActionKind.nfc)
          IconButton(
            tooltip: 'Read NFC card',
            onPressed: onReadNfc,
            icon: const Icon(Icons.nfc),
          ),
        if (kind == DeviceActionKind.status || kind == DeviceActionKind.nfc)
          IconButton(
            tooltip: 'Show status',
            onPressed: onStatus,
            icon: const Icon(Icons.info_outline),
          ),
        IconButton(
          tooltip: 'Refresh status',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

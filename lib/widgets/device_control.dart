import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/services/device_actions.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/widgets/dialog_nfc.dart';
import 'package:iot_hub_client/widgets/io_action.dart';
import 'package:iot_hub_client/widgets/io_card.dart';

class DeviceControl extends StatefulWidget {
  final IOHDevice device;
  final bool enabled;

  const DeviceControl({super.key, required this.device, this.enabled = true});

  @override
  State<DeviceControl> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  DeviceActions? _actions;
  DeviceActionState? _state;
  String? _error;
  bool _busy = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    final token = TokenStore.token;
    if (token != null) _actions = DeviceActions(token);
    _refresh();
  }

  @override
  void dispose() {
    _actions?.close();
    super.dispose();
  }

  Future<void> _refresh() => _run();

  Future<void> _run([String? command, String? argument]) async {
    if (_busy || !widget.enabled) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var sent = false;
    try {
      final actions = _actions;
      if (actions == null) throw Exception('No account selected');
      if (command != null) {
        await actions.send(widget.device.id, command, argument);
        sent = true;
      }
      final state = await actions.state(widget.device.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = state.hasError ? state.message ?? 'Device unavailable' : null;
      });
      if (command != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.hasError
                  ? 'Command sent, but the device reports an error.'
                  : 'Command sent; status updated.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = null;
        _error = command == null
            ? 'Could not load device status'
            : sent
            ? 'Command sent; status could not be refreshed'
            : 'Command failed; refresh status before trying again';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = deviceActionKind(widget.device.typeSlug);
    final theme = Theme.of(context);
    final status = _error != null
        ? 'Unavailable'
        : _state == null
        ? 'Loading status...'
        : kind == DeviceActionKind.power
        ? (_state!.power == null
              ? 'Power state unknown'
              : _state!.power!
              ? 'On'
              : 'Off')
        : _state!.state ?? 'Status available';
    return IOCard(
      title: 'Control',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.device.typeSlug ?? 'base'} / $status',
            style: theme.textTheme.titleMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: IOAction(
              kind: kind,
              isOn: _state?.power,
              busy: _busy || !widget.enabled,
              available: _state != null && !_state!.hasError && _error == null,
              onRefresh: _refresh,
              onToggle: () => _run('switch', _state!.power! ? 'off' : 'on'),
              onMove: _run,
              onStatus: () => setState(() => _showDetails = !_showDetails),
              onReadNfc: TokenStore.token == null
                  ? null
                  : () => showNfcDialog(context, token: TokenStore.token!),
            ),
          ),
          if (kind == DeviceActionKind.power ||
              kind == DeviceActionKind.movement)
            TextButton.icon(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _showDetails ? 'Hide status details' : 'Show status details',
              ),
            ),
          if (_showDetails) ...[
            const SizedBox(height: 12),
            SelectableText(
              _state == null
                  ? _error ?? 'No status available'
                  : const JsonEncoder.withIndent('  ').convert(_state!.data),
            ),
          ],
        ],
      ),
    );
  }
}

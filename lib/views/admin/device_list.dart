import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:io_hub_sdk_dart/io_hub_sdk_dart.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/main.dart';
import 'package:iot_hub_client/services/token_state.dart';
import 'package:iot_hub_client/views/admin/device_register_update.dart';
import 'package:iot_hub_client/views/config/config_overview.dart';
import 'package:iot_hub_client/services/device_actions.dart';
import 'package:iot_hub_client/widgets/io_action.dart';
import 'package:iot_hub_client/widgets/dialog_nfc.dart';
import 'package:iot_hub_client/widgets/io_card.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  State<DeviceList> createState() => _AdminDevicesState();
}

class _AdminDevicesState extends State<DeviceList> with RouteAware {
  List<IOHDevice> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  Future<void> _getDevices() async {
    setState(() => isLoading = true);

    final token = TokenStore.token;

    if (token == null) {
      return setState(() => isLoading = false);
    }

    final loadedDevices = await IOHubClient(
      token.server,
      token.token,
    ).deviceList();
    if (!mounted) return;
    setState(() {
      devices = loadedDevices;
      isLoading = false;
    });
  }

  Future<void> _restartThreads() async {
    final token = TokenStore.token;
    if (token == null) {
      return;
    }

    await IHC(token).restartThreads();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _getDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Device list"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigOverview()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 144),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return DeviceListItem(
                      key: ValueKey(devices[index].id),
                      device: devices[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'restartThreads',
            tooltip: 'Restart threads',
            onPressed: _restartThreads,
            child: const Icon(Icons.restart_alt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addDevice',
            tooltip: 'Add device',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeviceRegisterUpdate()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class DeviceListItem extends StatefulWidget {
  final IOHDevice device;
  const DeviceListItem({super.key, required this.device});

  @override
  State<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<DeviceListItem> {
  DeviceActions? _actions;
  DeviceActionState? _state;
  bool _busy = false;
  String? _error;

  DeviceActionKind get _kind => deviceActionKind(widget.device.typeSlug);

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

  @override
  void didUpdateWidget(covariant DeviceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) _refresh();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_actions == null) throw Exception('No account selected');
      final state = await _actions!.state(widget.device.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = state.hasError ? state.message ?? 'Device unavailable' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = null;
        _error = 'Could not load device status';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send(String command, [String? argument]) async {
    if (_busy || _actions == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    bool sent = false;
    try {
      await _actions!.send(widget.device.id, command, argument);
      sent = true;
      final state = await _actions!.state(widget.device.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = state.hasError ? state.message ?? 'Device unavailable' : null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.hasError
                ? 'Command sent, but the device reports an error.'
                : 'Command sent; status updated.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = null;
        _error = sent
            ? 'Command sent; status could not be refreshed'
            : 'Command failed; refresh status before trying again';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showStatus() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.device.name ?? 'Device status'),
        content: SingleChildScrollView(
          child: SelectableText(
            _state == null
                ? _error ?? 'No status available'
                : const JsonEncoder.withIndent('  ').convert(_state!.data),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _error != null
        ? 'Unavailable'
        : _state == null
        ? 'Loading status?'
        : _kind == DeviceActionKind.power
        ? (_state!.power == null
              ? 'Power state unknown'
              : _state!.power!
              ? 'On'
              : 'Off')
        : _state!.state ?? 'Status available';
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.device.name ?? 'Unnamed device',
          style: theme.textTheme.titleMedium,
        ),
        Text(widget.device.host ?? 'No host', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          '${widget.device.typeSlug ?? 'base'} ? $status',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _error != null
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
    final actions = IOAction(
      kind: _kind,
      isOn: _state?.power,
      busy: _busy,
      available: _state != null && !_state!.hasError && _error == null,
      onReadNfc: TokenStore.token == null
          ? null
          : () => showNfcDialog(context, token: TokenStore.token!),
      onRefresh: _refresh,
      onStatus: _showStatus,
      onToggle: () => _send('switch', _state!.power! ? 'off' : 'on'),
      onMove: _send,
    );
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceRegisterUpdate(device: widget.device),
        ),
      ),
      child: IOCard(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child:
            MediaQuery.sizeOf(context).width < 420 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 8),
                  actions,
                ],
              ),
      ),
    );
  }
}

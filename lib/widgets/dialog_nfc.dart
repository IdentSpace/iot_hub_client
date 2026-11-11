import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/nfc_reader.dart';

Future<void> showNfcDialog(BuildContext context, {required IHCToken token}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NfcDialog(token: token),
    );

class _NfcDialog extends StatefulWidget {
  final IHCToken token;
  const _NfcDialog({required this.token});

  @override
  State<_NfcDialog> createState() => _NfcDialogState();
}

class _NfcDialogState extends State<_NfcDialog> {
  NfcReader? _reader;
  bool _waiting = true;
  Object? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _wait();
  }

  @override
  void dispose() {
    _reader?.close();
    super.dispose();
  }

  Future<void> _wait() async {
    _reader?.close();
    final reader = NfcReader(widget.token);
    _reader = reader;
    setState(() {
      _waiting = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await reader.waitForCard();
      if (!mounted) return;
      setState(() => _result = result);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'No NFC card received within 20 seconds.');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not read an NFC card. Check the hub connection and try again.',
      );
    } finally {
      reader.close();
      if (mounted) setState(() => _waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Read NFC card'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waiting applies to all NFC readers connected to this hub.',
          ),
          const SizedBox(height: 24),
          if (_waiting) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            const Text('Hold a card against a connected NFC reader...'),
          ] else if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else ...[
            const Text('NFC card received'),
            const SizedBox(height: 12),
            SelectableText(
              _result is String
                  ? _result as String
                  : const JsonEncoder.withIndent('  ').convert(_result),
            ),
          ],
        ],
      ),
    ),
    actions: [
      if (!_waiting)
        TextButton(onPressed: _wait, child: const Text('Read again')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(_waiting ? 'Cancel' : 'Close'),
      ),
    ],
  );
}

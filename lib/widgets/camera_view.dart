import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/services/camera.dart';

class CameraView extends StatefulWidget {
  final String deviceId;
  final IHCToken token;
  const CameraView({super.key, required this.deviceId, required this.token});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraService? _service;
  StreamSubscription<Uint8List>? _subscription;
  Uint8List? _image;
  String? _error;
  bool _busy = false;
  bool _streaming = false;
  int _generation = 0;

  void _stop() {
    _generation++;
    _service?.close();
    _service = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _busy = false;
    _streaming = false;
  }

  Future<void> _snapshot() async {
    _stop();
    final generation = _generation;
    final service = _service = CameraService(widget.token);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await service.snapshot(widget.deviceId);
      if (mounted && generation == _generation) setState(() => _image = image);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'Could not load snapshot. Please try again.');
      }
    } finally {
      service.close();
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  void _start() {
    _stop();
    final generation = _generation;
    final service = _service = CameraService(widget.token);
    setState(() {
      _streaming = true;
      _busy = true;
      _error = null;
      _image = null;
    });
    _subscription = service
        .frames(widget.deviceId)
        .listen(
          (image) {
            if (mounted && generation == _generation) {
              setState(() {
                _image = image;
                _busy = false;
              });
            }
          },
          onError: (Object error) {
            if (mounted && generation == _generation) {
              setState(() {
                _stop();
                _error = 'Camera stream interrupted. Please try again.';
              });
            }
          },
          onDone: () {
            if (mounted && generation == _generation) {
              setState(() {
                _stop();
                _error = 'Camera stream ended.';
              });
            }
          },
          cancelOnError: true,
        );
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deviceId != oldWidget.deviceId ||
        widget.token != oldWidget.token) {
      _stop();
      _image = null;
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _image != null
              ? Image.memory(
                  _image!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Invalid camera image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : Center(
                  child: _busy
                      ? const CircularProgressIndicator()
                      : const Icon(
                          Icons.videocam_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                ),
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: _busy || _streaming ? null : _snapshot,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Snapshot'),
          ),
          TextButton.icon(
            onPressed: _streaming
                ? () => setState(_stop)
                : _busy
                ? null
                : _start,
            icon: Icon(_streaming ? Icons.stop : Icons.play_arrow),
            label: Text(_streaming ? 'Stop stream' : 'Start stream'),
          ),
        ],
      ),
    ],
  );
}

Future<void> showCameraDialog(
  BuildContext context, {
  required String deviceId,
  required String name,
  required IHCToken token,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(name),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: CameraView(deviceId: deviceId, token: token),
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

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:iot_hub_client/api/iot_hub_core.dart';

/// Each viewer owns a client so closing it also aborts an active stream.
class CameraService {
  final IHCToken token;
  final http.Client _client;
  static const _timeout = Duration(seconds: 15);
  static const _maxFrameBytes = 16 * 1024 * 1024;

  CameraService(this.token, {http.Client? client})
    : _client = client ?? http.Client();

  void close() => _client.close();

  Future<http.StreamedResponse> _get(String id, String mode) async {
    final base = token.server.replaceFirst(RegExp(r'/+$'), '');
    final request = http.Request(
      'GET',
      Uri.parse('$base/api/v2/devices/${Uri.encodeComponent(id)}/$mode'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer ${token.token}',
      'Accept': mode == 'snapshot' ? 'image/jpeg' : 'multipart/x-mixed-replace',
    });
    final response = await _client.send(request).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Camera request failed (HTTP ${response.statusCode})');
    }
    return response;
  }

  Future<Uint8List> _readFrame(Stream<List<int>> bytes) async {
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in bytes.timeout(_timeout)) {
      if (buffer.length + chunk.length > _maxFrameBytes) {
        throw Exception('Camera image exceeds 16 MiB');
      }
      buffer.add(chunk);
    }
    final frame = buffer.takeBytes();
    if (frame.length < 4 ||
        frame[0] != 0xff ||
        frame[1] != 0xd8 ||
        frame[frame.length - 2] != 0xff ||
        frame.last != 0xd9) {
      throw Exception('Invalid camera JPEG');
    }
    return frame;
  }

  Future<Uint8List> snapshot(String id) async {
    final response = await _get(id, 'snapshot');
    final type = ContentType.parse(response.headers['content-type'] ?? '');
    if (type.mimeType != 'image/jpeg') throw Exception('Expected a JPEG image');
    return _readFrame(response.stream);
  }

  Stream<Uint8List> frames(String id) async* {
    final response = await _get(id, 'stream');
    final type = ContentType.parse(response.headers['content-type'] ?? '');
    final boundary = type.parameters['boundary'];
    if (type.mimeType != 'multipart/x-mixed-replace' ||
        boundary == null ||
        boundary.isEmpty) {
      throw Exception('Invalid camera stream');
    }
    await for (final part
        in response.stream
            .timeout(_timeout)
            .transform(MimeMultipartTransformer(boundary))) {
      yield await _readFrame(part);
    }
  }
}

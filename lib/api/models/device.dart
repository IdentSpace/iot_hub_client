import 'package:iot_hub_client/api/iot_hub_core.dart';
import 'package:iot_hub_client/utils/helpers.dart';

class DeviceState {
  final String? state;
  final String? message;
  final dynamic rawData;
  final bool powerState;
  late DateTime timestamp;

  DeviceState({
    required this.state,
    required this.message,
    required this.rawData,
    required this.powerState,
  }) {
    timestamp = DateTime.now();
  }

  factory DeviceState.fromJsonIHC(Map<String, dynamic> json) {
    return DeviceState(
      state: json['state'] as String?,
      message: json['message'] as String?,
      rawData: json['raw_data'],
      powerState: json['power_state'] == null
          ? false
          : json['power_state'] as bool,
    );
  }
}

class Device {
  final String id;
  final String? host;
  final int? baudrate;
  final int? channel;
  final int? driverId;
  final String? driverName;
  final int? type;
  final String? name;
  DeviceState? state;

  Device({
    required this.id,
    required this.host,
    required this.driverId,
    this.baudrate,
    this.channel,
    this.driverName,
    required this.type,
    required this.name,
    required this.state,
  });

  Future<void> updateState(IHCToken token) async {
    state = await IHC.getDeviceState(token: token, deviceId: id);
  }

  factory Device.fromJsonIHC(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      host: json['device_host'] as String?,
      baudrate: Parser.asInt(json['baudrate']),
      channel: Parser.asInt(json['channel']) ?? 0,
      driverId: Parser.asInt(json['device_driver']),
      driverName: json['device_driver_name'] as String?,
      type: Parser.asInt(json['device_type']),
      name: json['name'] as String?,
      state: null,
    );
  }
}

class HardwareHost {
  final String host;
  final String? description;
  final String? manufacturer;

  const HardwareHost({required this.host, this.description, this.manufacturer});

  factory HardwareHost.fromJson(Map<String, dynamic> json) => HardwareHost(
    host: json['host'] as String,
    description: json['description'] as String?,
    manufacturer: json['manufacturer'] as String?,
  );
}

class HardwareDevices {
  final List<HardwareHost> items;
  final bool available;
  final String? message;
  final int skipped;

  const HardwareDevices({
    required this.items,
    this.available = true,
    this.message,
    this.skipped = 0,
  });

  factory HardwareDevices.fromJson(Map<String, dynamic> json) =>
      HardwareDevices(
        items: (json['items'] as List)
            .map((item) => HardwareHost.fromJson(item as Map<String, dynamic>))
            .toList(),
        available: json['available'] as bool? ?? true,
        message: json['message'] as String?,
        skipped: (json['issues'] as List?)?.length ?? 0,
      );
}

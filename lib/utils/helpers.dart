class Parser {
  static String? asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

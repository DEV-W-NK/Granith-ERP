class DbValue {
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      if (seconds is num) {
        final millis =
            (seconds * 1000).round() +
            (nanoseconds is num ? (nanoseconds / 1000000).round() : 0);
        return DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toLocal();
      }
    }
    return null;
  }

  static dynamic toPrimitive(dynamic value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is List) return value.map(toPrimitive).toList();
    if (value is Map) {
      return value.map(
        (key, inner) => MapEntry(key.toString(), toPrimitive(inner)),
      );
    }
    return value;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, toPrimitive(value)));
  }
}

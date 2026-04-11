import 'package:cloud_firestore/cloud_firestore.dart';

class DbValue {
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static dynamic toPrimitive(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is List) return value.map(toPrimitive).toList();
    if (value is Map) {
      return value.map((key, inner) => MapEntry(key, toPrimitive(inner)));
    }
    return value;
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, toPrimitive(value)));
  }
}

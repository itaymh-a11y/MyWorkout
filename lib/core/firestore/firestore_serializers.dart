import 'package:cloud_firestore/cloud_firestore.dart';

/// המרות Timestamp ↔ DateTime עבור Firestore.
abstract final class FirestoreSerializers {
  static DateTime? timestampToDate(Timestamp? value) => value?.toDate();

  static Timestamp? dateToTimestamp(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    return defaultValue;
  }

  static List<String> toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

/// ארוחה שנרשמה ליום מסוים. הערכים מועתקים ולא תלויים בתבנית.
class MealLog {
  const MealLog({
    required this.id,
    required this.dayKey,
    required this.name,
    required this.kcal,
    required this.proteinG,
    this.carbsG,
    this.fatG,
    this.portionGrams,
    this.templateId,
    this.source = sourceManual,
    required this.createdAt,
  });

  static const sourceManual = 'manual';

  final String id;
  final String dayKey;
  final String name;
  final int kcal;
  final double proteinG;
  final double? carbsG;
  final double? fatG;

  /// כמה גרם נאכלו. אם הרישום הגיע ממנה שמורה, הערכים כבר מותאמים לכמות הזו.
  final double? portionGrams;
  final String? templateId;
  final String source;
  final DateTime createdAt;

  factory MealLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MealLog.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory MealLog.fromMap(Map<String, dynamic> map, {required String id}) {
    return MealLog(
      id: id,
      dayKey: map['dayKey'] as String? ?? '',
      name: map['name'] as String? ?? '',
      kcal: FirestoreSerializers.toInt(map['kcal']) ?? 0,
      proteinG: FirestoreSerializers.toDouble(map['proteinG']) ?? 0,
      carbsG: FirestoreSerializers.toDouble(map['carbsG']),
      fatG: FirestoreSerializers.toDouble(map['fatG']),
      portionGrams: FirestoreSerializers.toDouble(map['portionGrams']),
      templateId: map['templateId'] as String?,
      source: map['source'] as String? ?? sourceManual,
      createdAt: FirestoreSerializers.timestampToDate(
            map['createdAt'] as Timestamp?,
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'name': name,
      'kcal': kcal,
      'proteinG': proteinG,
      if (carbsG != null) 'carbsG': carbsG,
      if (fatG != null) 'fatG': fatG,
      if (portionGrams != null) 'portionGrams': portionGrams,
      if (templateId != null) 'templateId': templateId,
      'source': source,
      'createdAt': FirestoreSerializers.dateToTimestamp(createdAt),
    };
  }
}

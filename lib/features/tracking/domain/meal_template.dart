import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

/// ארוחה שמורה לשימוש חוזר. עריכה כאן לא משנה רישומים קודמים.
class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.name,
    required this.kcal,
    required this.proteinG,
    this.carbsG,
    this.fatG,
    this.portionGrams,
  });

  final String id;
  final String name;
  final int kcal;
  final double proteinG;
  final double? carbsG;
  final double? fatG;

  /// המשקל שעליו מחושבים הערכים. אכילה בכמות אחרת מכפילה לפיו.
  final double? portionGrams;

  factory MealTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MealTemplate.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory MealTemplate.fromMap(Map<String, dynamic> map, {required String id}) {
    return MealTemplate(
      id: id,
      name: map['name'] as String? ?? '',
      kcal: FirestoreSerializers.toInt(map['kcal']) ?? 0,
      proteinG: FirestoreSerializers.toDouble(map['proteinG']) ?? 0,
      carbsG: FirestoreSerializers.toDouble(map['carbsG']),
      fatG: FirestoreSerializers.toDouble(map['fatG']),
      portionGrams: FirestoreSerializers.toDouble(map['portionGrams']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kcal': kcal,
      'proteinG': proteinG,
      if (carbsG != null) 'carbsG': carbsG,
      if (fatG != null) 'fatG': fatG,
      if (portionGrams != null) 'portionGrams': portionGrams,
    };
  }
}

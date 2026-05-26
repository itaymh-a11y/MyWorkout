import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

/// הגדרת קטגוריית תרגיל (מערכת או מותאמת אישית).
class ExerciseCategoryDef {
  const ExerciseCategoryDef({
    required this.id,
    required this.nameHe,
    this.iconKey = 'custom',
    this.order = 0,
    this.isSystem = false,
  });

  final String id;
  final String nameHe;
  final String iconKey;
  final int order;
  final bool isSystem;

  factory ExerciseCategoryDef.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExerciseCategoryDef.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory ExerciseCategoryDef.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return ExerciseCategoryDef(
      id: id,
      nameHe: map['nameHe'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'custom',
      order: FirestoreSerializers.toInt(map['order']) ?? 0,
      isSystem: FirestoreSerializers.toBool(map['isSystem']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameHe': nameHe,
      'iconKey': iconKey,
      'order': order,
      'isSystem': isSystem,
    };
  }

  ExerciseCategoryDef copyWith({
    String? id,
    String? nameHe,
    String? iconKey,
    int? order,
    bool? isSystem,
  }) {
    return ExerciseCategoryDef(
      id: id ?? this.id,
      nameHe: nameHe ?? this.nameHe,
      iconKey: iconKey ?? this.iconKey,
      order: order ?? this.order,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}

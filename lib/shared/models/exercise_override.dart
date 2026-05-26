import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// התאמה אישית מלאה לתרגיל מובנה — פרופיל + ברירות מחדל (לא משנה את המאגר הגלובלי).
class ExerciseOverride {
  const ExerciseOverride({
    required this.builtinExerciseId,
    this.name,
    this.categoryId,
    this.exerciseType,
    this.muscleTags,
    this.defaultSets,
    this.defaultReps,
    this.defaultWeightKg,
    this.defaultRestSec,
    this.defaultTimeSec,
    this.updatedAt,
  });

  final String builtinExerciseId;
  final String? name;
  final String? categoryId;
  final ExerciseType? exerciseType;
  final List<String>? muscleTags;
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeightKg;
  final int? defaultRestSec;
  final int? defaultTimeSec;
  final DateTime? updatedAt;

  factory ExerciseOverride.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExerciseOverride.fromMap(
      doc.data() ?? {},
      builtinExerciseId: doc.id,
    );
  }

  factory ExerciseOverride.fromMap(
    Map<String, dynamic> map, {
    required String builtinExerciseId,
  }) {
    final typeRaw = map['exerciseType'] as String?;
    return ExerciseOverride(
      builtinExerciseId: builtinExerciseId,
      name: map['name'] as String?,
      categoryId: map['categoryId'] as String? ?? map['category'] as String?,
      exerciseType: typeRaw != null
          ? ExerciseType.fromFirestore(typeRaw)
          : null,
      muscleTags: map['muscleTags'] != null
          ? FirestoreSerializers.toStringList(map['muscleTags'])
          : null,
      defaultSets: FirestoreSerializers.toInt(map['defaultSets']),
      defaultReps: FirestoreSerializers.toInt(map['defaultReps']),
      defaultWeightKg: FirestoreSerializers.toDouble(map['defaultWeightKg']),
      defaultRestSec: FirestoreSerializers.toInt(map['defaultRestSec']),
      defaultTimeSec: FirestoreSerializers.toInt(map['defaultTimeSec']),
      updatedAt: FirestoreSerializers.timestampToDate(
        map['updatedAt'] as Timestamp?,
      ),
    );
  }

  /// יוצר override מלא מתרגיל (לשמירה אחרי עריכת פרופיל מובנה).
  factory ExerciseOverride.fromExercise(Exercise exercise) {
    return ExerciseOverride(
      builtinExerciseId: exercise.id,
      name: exercise.name,
      categoryId: exercise.categoryId,
      exerciseType: exercise.exerciseType,
      muscleTags: List<String>.from(exercise.muscleTags),
      defaultSets: exercise.defaultSets,
      defaultReps: exercise.defaultReps,
      defaultWeightKg: exercise.defaultWeightKg,
      defaultRestSec: exercise.defaultRestSec,
      defaultTimeSec: exercise.defaultTimeSec,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'builtinExerciseId': builtinExerciseId,
      'name': name,
      'categoryId': categoryId,
      if (categoryId != null) 'category': categoryId,
      if (exerciseType != null) 'exerciseType': exerciseType!.firestoreValue,
      if (muscleTags != null) 'muscleTags': muscleTags,
      if (defaultSets != null) 'defaultSets': defaultSets,
      if (defaultReps != null) 'defaultReps': defaultReps,
      if (defaultWeightKg != null) 'defaultWeightKg': defaultWeightKg,
      if (defaultRestSec != null) 'defaultRestSec': defaultRestSec,
      if (defaultTimeSec != null) 'defaultTimeSec': defaultTimeSec,
      'updatedAt': FirestoreSerializers.dateToTimestamp(
        updatedAt ?? DateTime.now(),
      ),
    };
  }

  Exercise applyTo(Exercise base) {
    return base.copyWith(
      name: name ?? base.name,
      categoryId: categoryId ?? base.categoryId,
      exerciseType: exerciseType ?? base.exerciseType,
      muscleTags: muscleTags ?? base.muscleTags,
      defaultSets: defaultSets ?? base.defaultSets,
      defaultReps: defaultReps ?? base.defaultReps,
      defaultWeightKg: defaultWeightKg ?? base.defaultWeightKg,
      defaultRestSec: defaultRestSec ?? base.defaultRestSec,
      defaultTimeSec: defaultTimeSec ?? base.defaultTimeSec,
      hasPersonalDefaults: true,
    );
  }
}

extension ExerciseMerge on Exercise {
  Exercise withOverride(ExerciseOverride? override) {
    if (override == null) return this;
    return override.applyTo(this);
  }
}

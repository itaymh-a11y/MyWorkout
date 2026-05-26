import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// תרגיל בתוך תוכנית — יעדים ספציפיים לתוכנית.
class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.order,
    required this.exerciseType,
    this.setsCount = 3,
    this.targetWeightKg,
    this.targetReps,
    this.targetTimeSec,
    this.restSec,
  });

  final String id;
  final String exerciseId;
  final String exerciseName;
  final int order;
  final ExerciseType exerciseType;
  final int setsCount;
  final double? targetWeightKg;
  final int? targetReps;
  final int? targetTimeSec;
  final int? restSec;

  factory PlanExercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PlanExercise.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory PlanExercise.fromMap(Map<String, dynamic> map, {required String id}) {
    return PlanExercise(
      id: id,
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      order: FirestoreSerializers.toInt(map['order']) ?? 0,
      exerciseType: ExerciseType.fromFirestore(map['exerciseType'] as String?),
      setsCount: FirestoreSerializers.toInt(map['setsCount']) ?? 3,
      targetWeightKg: FirestoreSerializers.toDouble(map['targetWeightKg']),
      targetReps: FirestoreSerializers.toInt(map['targetReps']),
      targetTimeSec: FirestoreSerializers.toInt(map['targetTimeSec']),
      restSec: FirestoreSerializers.toInt(map['restSec']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'order': order,
      'exerciseType': exerciseType.firestoreValue,
      'setsCount': setsCount,
      if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
      if (targetReps != null) 'targetReps': targetReps,
      if (targetTimeSec != null) 'targetTimeSec': targetTimeSec,
      if (restSec != null) 'restSec': restSec,
    };
  }

  PlanExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    int? order,
    ExerciseType? exerciseType,
    int? setsCount,
    double? targetWeightKg,
    int? targetReps,
    int? targetTimeSec,
    int? restSec,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      order: order ?? this.order,
      exerciseType: exerciseType ?? this.exerciseType,
      setsCount: setsCount ?? this.setsCount,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetReps: targetReps ?? this.targetReps,
      targetTimeSec: targetTimeSec ?? this.targetTimeSec,
      restSec: restSec ?? this.restSec,
    );
  }
}

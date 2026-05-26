import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// סט בודד שבוצע באימון — snapshot של יעד + ביצוע בפועל.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.setIndex,
    this.targetWeightKg,
    this.targetReps,
    this.targetTimeSec,
    this.actualWeightKg,
    this.actualReps,
    this.actualTimeSec,
    this.completed = false,
  });

  final String id;
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final int setIndex;
  final double? targetWeightKg;
  final int? targetReps;
  final int? targetTimeSec;
  final double? actualWeightKg;
  final int? actualReps;
  final int? actualTimeSec;
  final bool completed;

  factory WorkoutSet.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkoutSet.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map, {required String id}) {
    return WorkoutSet(
      id: id,
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      exerciseType: ExerciseType.fromFirestore(map['exerciseType'] as String?),
      setIndex: FirestoreSerializers.toInt(map['setIndex']) ?? 1,
      targetWeightKg: FirestoreSerializers.toDouble(map['targetWeightKg']),
      targetReps: FirestoreSerializers.toInt(map['targetReps']),
      targetTimeSec: FirestoreSerializers.toInt(map['targetTimeSec']),
      actualWeightKg: FirestoreSerializers.toDouble(map['actualWeightKg']),
      actualReps: FirestoreSerializers.toInt(map['actualReps']),
      actualTimeSec: FirestoreSerializers.toInt(map['actualTimeSec']),
      completed: FirestoreSerializers.toBool(map['completed']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'exerciseType': exerciseType.firestoreValue,
      'setIndex': setIndex,
      if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
      if (targetReps != null) 'targetReps': targetReps,
      if (targetTimeSec != null) 'targetTimeSec': targetTimeSec,
      if (actualWeightKg != null) 'actualWeightKg': actualWeightKg,
      if (actualReps != null) 'actualReps': actualReps,
      if (actualTimeSec != null) 'actualTimeSec': actualTimeSec,
      'completed': completed,
    };
  }
}

import 'package:myworkout/shared/models/exercise_type.dart';

/// שורת סט במהלך אימון לייב.
class LiveSetEntry {
  const LiveSetEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.setIndex,
    required this.isLastSetOfExercise,
    this.targetWeightKg,
    this.targetReps,
    this.targetTimeSec,
    this.actualWeightKg,
    this.actualReps,
    this.actualTimeSec,
    this.previousWeightKg,
    this.previousReps,
    this.previousTimeSec,
    this.restSec,
    this.completed = false,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final int setIndex;
  final bool isLastSetOfExercise;
  final double? targetWeightKg;
  final int? targetReps;
  final int? targetTimeSec;
  final double? actualWeightKg;
  final int? actualReps;
  final int? actualTimeSec;
  final double? previousWeightKg;
  final int? previousReps;
  final int? previousTimeSec;
  final int? restSec;
  final bool completed;

  LiveSetEntry copyWith({
    double? actualWeightKg,
    int? actualReps,
    int? actualTimeSec,
    bool? completed,
    bool clearActualWeight = false,
    bool clearActualReps = false,
    bool clearActualTime = false,
  }) {
    return LiveSetEntry(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseType: exerciseType,
      setIndex: setIndex,
      isLastSetOfExercise: isLastSetOfExercise,
      targetWeightKg: targetWeightKg,
      targetReps: targetReps,
      targetTimeSec: targetTimeSec,
      actualWeightKg:
          clearActualWeight ? null : (actualWeightKg ?? this.actualWeightKg),
      actualReps: clearActualReps ? null : (actualReps ?? this.actualReps),
      actualTimeSec:
          clearActualTime ? null : (actualTimeSec ?? this.actualTimeSec),
      previousWeightKg: previousWeightKg,
      previousReps: previousReps,
      previousTimeSec: previousTimeSec,
      restSec: restSec,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseType': exerciseType.firestoreValue,
        'setIndex': setIndex,
        'isLastSetOfExercise': isLastSetOfExercise,
        'targetWeightKg': targetWeightKg,
        'targetReps': targetReps,
        'targetTimeSec': targetTimeSec,
        'actualWeightKg': actualWeightKg,
        'actualReps': actualReps,
        'actualTimeSec': actualTimeSec,
        'previousWeightKg': previousWeightKg,
        'previousReps': previousReps,
        'previousTimeSec': previousTimeSec,
        'restSec': restSec,
        'completed': completed,
      };

  factory LiveSetEntry.fromJson(Map<String, dynamic> json) {
    return LiveSetEntry(
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? '',
      exerciseType: ExerciseType.fromFirestore(json['exerciseType'] as String?),
      setIndex: json['setIndex'] as int? ?? 1,
      isLastSetOfExercise: json['isLastSetOfExercise'] as bool? ?? false,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      targetReps: json['targetReps'] as int?,
      targetTimeSec: json['targetTimeSec'] as int?,
      actualWeightKg: (json['actualWeightKg'] as num?)?.toDouble(),
      actualReps: json['actualReps'] as int?,
      actualTimeSec: json['actualTimeSec'] as int?,
      previousWeightKg: (json['previousWeightKg'] as num?)?.toDouble(),
      previousReps: json['previousReps'] as int?,
      previousTimeSec: json['previousTimeSec'] as int?,
      restSec: json['restSec'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

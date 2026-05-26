import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_set.dart';

/// שורת סט לעריכה בהזנה ידנית.
class ManualSetRow {
  ManualSetRow({
    required this.setIndex,
    this.targetWeightKg,
    this.targetReps,
    this.targetTimeSec,
    this.actualWeightKg,
    this.actualReps,
    this.actualTimeSec,
    this.completed = true,
  });

  final int setIndex;
  final double? targetWeightKg;
  final int? targetReps;
  final int? targetTimeSec;
  double? actualWeightKg;
  int? actualReps;
  int? actualTimeSec;
  bool completed;

  ManualSetRow copyWith({
    double? actualWeightKg,
    int? actualReps,
    int? actualTimeSec,
    bool? completed,
    bool clearWeight = false,
    bool clearReps = false,
    bool clearTime = false,
  }) {
    return ManualSetRow(
      setIndex: setIndex,
      targetWeightKg: targetWeightKg,
      targetReps: targetReps,
      targetTimeSec: targetTimeSec,
      actualWeightKg: clearWeight ? null : (actualWeightKg ?? this.actualWeightKg),
      actualReps: clearReps ? null : (actualReps ?? this.actualReps),
      actualTimeSec: clearTime ? null : (actualTimeSec ?? this.actualTimeSec),
      completed: completed ?? this.completed,
    );
  }

  bool get hasAnyActual =>
      actualWeightKg != null || actualReps != null || actualTimeSec != null;
}

/// תרגיל עם סטים לעריכה ידנית.
class ManualExerciseBlock {
  ManualExerciseBlock({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  List<ManualSetRow> sets;

  static ManualExerciseBlock fromPlanExercise(PlanExercise pe) {
    final sets = <ManualSetRow>[];
    for (var i = 1; i <= pe.setsCount; i++) {
      sets.add(
        ManualSetRow(
          setIndex: i,
          targetWeightKg: pe.targetWeightKg,
          targetReps: pe.targetReps,
          targetTimeSec: pe.targetTimeSec,
          actualWeightKg: pe.targetWeightKg,
          actualReps: pe.targetReps,
          actualTimeSec: pe.targetTimeSec,
        ),
      );
    }
    return ManualExerciseBlock(
      exerciseId: pe.exerciseId,
      exerciseName: pe.exerciseName,
      exerciseType: pe.exerciseType,
      sets: sets,
    );
  }

  void addSet() {
    final last = sets.isEmpty ? null : sets.last;
    sets = [
      ...sets,
      ManualSetRow(
        setIndex: sets.length + 1,
        targetWeightKg: last?.targetWeightKg,
        targetReps: last?.targetReps,
        targetTimeSec: last?.targetTimeSec,
        actualWeightKg: last?.actualWeightKg,
        actualReps: last?.actualReps,
        actualTimeSec: last?.actualTimeSec,
      ),
    ];
  }

  void removeSet(int index) {
    if (index < 0 || index >= sets.length) return;
    final next = List<ManualSetRow>.from(sets)..removeAt(index);
    sets = [
      for (var i = 0; i < next.length; i++)
        ManualSetRow(
          setIndex: i + 1,
          targetWeightKg: next[i].targetWeightKg,
          targetReps: next[i].targetReps,
          targetTimeSec: next[i].targetTimeSec,
          actualWeightKg: next[i].actualWeightKg,
          actualReps: next[i].actualReps,
          actualTimeSec: next[i].actualTimeSec,
          completed: next[i].completed,
        ),
    ];
  }
}

List<ManualExerciseBlock> blocksFromPlanExercises(List<PlanExercise> list) {
  final sorted = List<PlanExercise>.from(list)
    ..sort((a, b) => a.order.compareTo(b.order));
  return sorted.map(ManualExerciseBlock.fromPlanExercise).toList();
}

List<WorkoutSet> toWorkoutSets(List<ManualExerciseBlock> blocks) {
  final result = <WorkoutSet>[];
  for (final block in blocks) {
    for (final row in block.sets) {
      if (!row.hasAnyActual) continue;
      result.add(
        WorkoutSet(
          id: '',
          exerciseId: block.exerciseId,
          exerciseName: block.exerciseName,
          exerciseType: block.exerciseType,
          setIndex: row.setIndex,
          targetWeightKg: row.targetWeightKg,
          targetReps: row.targetReps,
          targetTimeSec: row.targetTimeSec,
          actualWeightKg: row.actualWeightKg,
          actualReps: row.actualReps,
          actualTimeSec: row.actualTimeSec,
          completed: row.completed,
        ),
      );
    }
  }
  return result;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/features/exercises/domain/exercise_stats.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

void main() {
  test('ממוצע משקל וחזרות לאימון בגרף', () {
    final session = WorkoutSession(
      id: 's1',
      planId: 'p1',
      planName: 'A',
      startedAt: DateTime(2025, 5, 1),
      endedAt: DateTime(2025, 5, 1, 1),
      durationSec: 3600,
    );
    final history = ExerciseSessionHistory(
      session: session,
      sets: [
        WorkoutSet(
          id: '1',
          exerciseId: 'builtin_bench',
          exerciseName: 'לחיצה',
          exerciseType: ExerciseType.weightReps,
          setIndex: 1,
          actualWeightKg: 40,
          actualReps: 10,
          completed: true,
        ),
        WorkoutSet(
          id: '2',
          exerciseId: 'builtin_bench',
          exerciseName: 'לחיצה',
          exerciseType: ExerciseType.weightReps,
          setIndex: 2,
          actualWeightKg: 50,
          actualReps: 8,
          completed: true,
        ),
        WorkoutSet(
          id: '3',
          exerciseId: 'builtin_bench',
          exerciseName: 'לחיצה',
          exerciseType: ExerciseType.weightReps,
          setIndex: 3,
          actualWeightKg: 60,
          actualReps: 6,
          completed: true,
        ),
      ],
    );

    final point = chartPointFromSession(history);
    expect(point.avgWeightKg, 50);
    expect(point.avgReps, 8);
  });

  test('PR משקל וחזרות', () {
    final sets = [
      WorkoutSet(
        id: '1',
        exerciseId: 'builtin_bench',
        exerciseName: 'לחיצה',
        exerciseType: ExerciseType.weightReps,
        setIndex: 1,
        actualWeightKg: 60,
        actualReps: 8,
        completed: true,
      ),
      WorkoutSet(
        id: '2',
        exerciseId: 'builtin_bench',
        exerciseName: 'לחיצה',
        exerciseType: ExerciseType.weightReps,
        setIndex: 2,
        actualWeightKg: 62.5,
        actualReps: 6,
        completed: true,
      ),
    ];

    final pr = computePersonalRecords(sets, ExerciseType.weightReps);
    expect(pr.maxWeightKg, 62.5);
    expect(pr.maxReps, 8);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_ref.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_set.dart';

void main() {
  group('ExerciseRef', () {
    test('parse builtin prefix', () {
      final ref = ExerciseRef.parse('builtin_bench_press');
      expect(ref.isBuiltin, isTrue);
      expect(ref.rawId, 'bench_press');
      expect(ref.compositeId, 'builtin_bench_press');
    });

    test('parse user prefix', () {
      final ref = ExerciseRef.parse('user_abc123');
      expect(ref.isBuiltin, isFalse);
      expect(ref.rawId, 'abc123');
    });
  });

  group('Exercise', () {
    test('toMap and fromMap roundtrip', () {
      final original = Exercise(
        id: 'squat',
        source: ExerciseSource.builtin,
        name: 'סקוואט',
        categoryId: 'legs',
        exerciseType: ExerciseType.weightReps,
        muscleTags: const ['רגליים'],
        defaultSets: 4,
        defaultReps: 8,
        defaultWeightKg: 70,
        defaultRestSec: 120,
      );

      final map = original.toMap(includeCreatedAt: false);
      final restored = Exercise.fromMap(
        map,
        id: original.id,
        source: ExerciseSource.builtin,
      );

      expect(restored.name, original.name);
      expect(restored.categoryId, original.categoryId);
      expect(restored.exerciseType, original.exerciseType);
      expect(restored.defaultWeightKg, original.defaultWeightKg);
    });
  });

  group('WorkoutSet', () {
    test('toMap contains required fields', () {
      final set = WorkoutSet(
        id: 's1',
        exerciseId: 'builtin_bench_press',
        exerciseName: 'לחיצת חזה',
        exerciseType: ExerciseType.weightReps,
        setIndex: 1,
        targetWeightKg: 60,
        targetReps: 8,
        actualWeightKg: 62.5,
        actualReps: 8,
        completed: true,
      );

      final map = set.toMap();
      expect(map['exerciseId'], 'builtin_bench_press');
      expect(map['completed'], isTrue);
      expect(map['actualWeightKg'], 62.5);
    });
  });
}

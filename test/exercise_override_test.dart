import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_override.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

void main() {
  test('override משנה פרופיל מלא לתרגיל מובנה', () {
    const base = Exercise(
      id: 'bench_press',
      source: ExerciseSource.builtin,
      name: 'לחיצת חזה',
      categoryId: 'push',
      exerciseType: ExerciseType.weightReps,
      defaultSets: 4,
      defaultReps: 8,
      defaultWeightKg: 60,
    );

    const override = ExerciseOverride(
      builtinExerciseId: 'bench_press',
      name: 'לחיצת חזה שלי',
      categoryId: 'pull',
      defaultReps: 5,
      defaultWeightKg: 72.5,
    );

    final merged = base.withOverride(override);

    expect(merged.name, 'לחיצת חזה שלי');
    expect(merged.categoryId, 'pull');
    expect(merged.defaultReps, 5);
    expect(merged.defaultWeightKg, 72.5);
    expect(merged.hasPersonalDefaults, isTrue);
  });
}

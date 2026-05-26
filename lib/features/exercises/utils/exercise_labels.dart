import 'package:flutter/material.dart';
import 'package:myworkout/shared/models/exercise_category_def.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

extension ExerciseTypeLabel on ExerciseType {
  String get labelHe => switch (this) {
        ExerciseType.weightReps => 'משקל + חזרות',
        ExerciseType.repsOnly => 'חזרות בלבד',
        ExerciseType.time => 'זמן',
      };
}

extension ExerciseSourceLabel on ExerciseSource {
  String get labelHe => switch (this) {
        ExerciseSource.builtin => 'מובנה',
        ExerciseSource.custom => 'מותאם אישית',
      };
}

IconData iconForCategoryKey(String iconKey) {
  return switch (iconKey) {
    'push' => Icons.arrow_upward_rounded,
    'pull' => Icons.arrow_downward_rounded,
    'legs' => Icons.directions_run_rounded,
    'core' => Icons.self_improvement_rounded,
    'cardio' => Icons.favorite_rounded,
    _ => Icons.fitness_center_rounded,
  };
}

IconData categoryIcon(ExerciseCategoryDef category) =>
    iconForCategoryKey(category.iconKey);

String categoryName(
  String categoryId,
  Map<String, ExerciseCategoryDef> lookup,
) {
  return lookup[categoryId]?.nameHe ?? categoryId;
}

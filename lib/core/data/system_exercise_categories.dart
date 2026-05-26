import 'package:myworkout/shared/models/exercise_category_def.dart';

/// 5 קטגוריות מערכת — נטענות ל-Firestore של המשתמש בפעם הראשונה.
abstract final class SystemExerciseCategories {
  static const List<ExerciseCategoryDef> all = [
    ExerciseCategoryDef(
      id: 'push',
      nameHe: 'דחיפה',
      iconKey: 'push',
      order: 1,
      isSystem: true,
    ),
    ExerciseCategoryDef(
      id: 'pull',
      nameHe: 'משיכה',
      iconKey: 'pull',
      order: 2,
      isSystem: true,
    ),
    ExerciseCategoryDef(
      id: 'legs',
      nameHe: 'רגליים',
      iconKey: 'legs',
      order: 3,
      isSystem: true,
    ),
    ExerciseCategoryDef(
      id: 'core',
      nameHe: 'בטן',
      iconKey: 'core',
      order: 4,
      isSystem: true,
    ),
    ExerciseCategoryDef(
      id: 'cardio',
      nameHe: 'אירובי',
      iconKey: 'cardio',
      order: 5,
      isSystem: true,
    ),
  ];
}

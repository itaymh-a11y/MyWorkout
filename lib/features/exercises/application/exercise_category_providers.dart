import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/exercises/data/exercise_category_repository.dart';
import 'package:myworkout/shared/models/exercise_category_def.dart';

final exerciseCategoryRepositoryProvider =
    Provider<ExerciseCategoryRepository>((ref) {
  return ExerciseCategoryRepository();
});

final exerciseCategoriesProvider =
    StreamProvider<List<ExerciseCategoryDef>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(exerciseCategoryRepositoryProvider).watchCategories(uid);
});

final exerciseCategoryMapProvider =
    Provider<Map<String, ExerciseCategoryDef>>((ref) {
  final categories = ref.watch(exerciseCategoriesProvider);
  return categories.maybeWhen(
    data: (list) => {for (final c in list) c.id: c},
    orElse: () => {},
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_override.dart';

/// מסנן רשימת התרגילים (חיפוש + קטגוריה).
class ExerciseListFilter {
  const ExerciseListFilter({
    this.searchQuery = '',
    this.categoryId,
  });

  final String searchQuery;
  final String? categoryId;

  ExerciseListFilter copyWith({
    String? searchQuery,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return ExerciseListFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

final exerciseListFilterProvider =
    StateProvider<ExerciseListFilter>((ref) => const ExerciseListFilter());

final builtinExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchBuiltinExercises();
});

final exerciseOverridesProvider =
    StreamProvider<Map<String, ExerciseOverride>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(exerciseRepositoryProvider).watchExerciseOverrides(uid);
});

final mergedBuiltinExercisesProvider =
    Provider<AsyncValue<List<Exercise>>>((ref) {
  final builtins = ref.watch(builtinExercisesProvider);
  final overrides = ref.watch(exerciseOverridesProvider);
  final repo = ref.watch(exerciseRepositoryProvider);

  if (builtins.isLoading || overrides.isLoading) {
    return const AsyncValue.loading();
  }
  if (builtins.hasError) {
    return AsyncValue.error(builtins.error!, builtins.stackTrace!);
  }
  if (overrides.hasError) {
    return AsyncValue.error(overrides.error!, overrides.stackTrace!);
  }

  final merged = repo.applyOverrides(builtins.value!, overrides.value!);
  return AsyncValue.data(merged);
});

final userExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(exerciseRepositoryProvider).watchUserExercises(uid);
});

final allExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final builtin = ref.watch(mergedBuiltinExercisesProvider);
  final user = ref.watch(userExercisesProvider);

  if (builtin.isLoading || user.isLoading) {
    return const AsyncValue.loading();
  }
  if (builtin.hasError) return AsyncValue.error(builtin.error!, builtin.stackTrace!);
  if (user.hasError) return AsyncValue.error(user.error!, user.stackTrace!);

  final merged = [...builtin.value!, ...user.value!]
    ..sort((a, b) => a.name.compareTo(b.name));
  return AsyncValue.data(merged);
});

final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final all = ref.watch(allExercisesProvider);
  final filter = ref.watch(exerciseListFilterProvider);

  return all.whenData((exercises) {
    var result = exercises;

    if (filter.categoryId != null) {
      result =
          result.where((e) => e.categoryId == filter.categoryId).toList();
    }

    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((e) {
        final nameMatch = e.name.toLowerCase().contains(query);
        final tagMatch = e.muscleTags.any(
          (t) => t.toLowerCase().contains(query),
        );
        return nameMatch || tagMatch;
      }).toList();
    }

    return result;
  });
});

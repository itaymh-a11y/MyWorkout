import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/exercises/domain/exercise_stats.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

final exerciseStatsProvider = StreamProvider.family<
    ExerciseStatsData,
    ({String exerciseId, ExerciseType type})>((ref, params) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(sessionRepositoryProvider).watchExerciseStats(
        uid,
        params.exerciseId,
        params.type,
      );
});

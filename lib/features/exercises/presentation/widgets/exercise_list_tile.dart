import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_category_avatar.dart';
import 'package:myworkout/features/exercises/utils/exercise_labels.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

class ExerciseListTile extends ConsumerWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryLookup = ref.watch(exerciseCategoryMapProvider);
    final categoryLabel = categoryName(exercise.categoryId, categoryLookup);
    final isCustom = exercise.source == ExerciseSource.custom;

    final subtitleParts = <String>[
      categoryLabel,
      exercise.exerciseType.labelHe,
    ];
    if (exercise.exerciseType == ExerciseType.weightReps &&
        exercise.defaultWeightKg != null) {
      subtitleParts.add('${exercise.defaultWeightKg} ק"ג');
    }
    if (exercise.exerciseType != ExerciseType.time) {
      subtitleParts.add('${exercise.defaultReps} חזרות');
    }

    return ListTile(
      leading: ExerciseCategoryAvatar(categoryId: exercise.categoryId),
      title: Text(exercise.name),
      subtitle: Text(
        subtitleParts.join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isCustom
          ? Chip(
              label: Text(
                exercise.source.labelHe,
                style: theme.textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )
          : exercise.hasPersonalDefaults
              ? Icon(Icons.tune, size: 20, color: theme.colorScheme.primary)
              : Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
      onTap: onTap,
    );
  }
}

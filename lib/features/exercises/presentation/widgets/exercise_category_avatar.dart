import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/features/exercises/utils/exercise_labels.dart';

/// אייקון גנרי לפי קטגוריית תרגיל.
class ExerciseCategoryAvatar extends ConsumerWidget {
  const ExerciseCategoryAvatar({
    super.key,
    required this.categoryId,
    this.radius = 24,
  });

  final String categoryId;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(exerciseCategoryMapProvider);
    final category = lookup[categoryId];
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        category != null
            ? categoryIcon(category)
            : iconForCategoryKey('custom'),
        color: colorScheme.onPrimaryContainer,
        size: radius,
      ),
    );
  }
}

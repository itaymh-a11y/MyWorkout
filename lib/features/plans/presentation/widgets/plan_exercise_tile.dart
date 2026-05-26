import 'package:flutter/material.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';

class PlanExerciseTile extends StatelessWidget {
  const PlanExerciseTile({
    super.key,
    required this.index,
    required this.exercise,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final PlanExercise exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _targetsSummary() {
    final parts = <String>['${exercise.setsCount} סטים'];
    switch (exercise.exerciseType) {
      case ExerciseType.weightReps:
        if (exercise.targetWeightKg != null) {
          parts.add('${exercise.targetWeightKg} ק"ג');
        }
        if (exercise.targetReps != null) {
          parts.add('${exercise.targetReps} חזרות');
        }
      case ExerciseType.repsOnly:
        if (exercise.targetReps != null) {
          parts.add('${exercise.targetReps} חזרות');
        }
      case ExerciseType.time:
        if (exercise.targetTimeSec != null) {
          final s = exercise.targetTimeSec!;
          final m = s ~/ 60;
          final r = s % 60;
          parts.add(m > 0 ? '$m:${r.toString().padLeft(2, '0')} דק׳' : '$r שנ׳');
        }
    }
    if (exercise.restSec != null) {
      parts.add('מנוחה ${exercise.restSec}ש׳');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle,
            color: theme.colorScheme.outline,
          ),
        ),
        title: Text('${exercise.order}. ${exercise.exerciseName}'),
        subtitle: Text(
          _targetsSummary(),
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

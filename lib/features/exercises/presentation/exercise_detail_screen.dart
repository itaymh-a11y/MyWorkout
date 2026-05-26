import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/features/exercises/presentation/exercise_form_screen.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_category_avatar.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_stats_tab.dart';
import 'package:myworkout/features/exercises/utils/exercise_labels.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  bool get _isCustom => exercise.source == ExerciseSource.custom;
  bool get _isBuiltin => exercise.source == ExerciseSource.builtin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(exercise.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'פרופיל'),
              Tab(text: 'סטטיסטיקה'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'עריכה',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.of(context).push<Exercise>(
                  MaterialPageRoute(
                    builder: (_) => ExerciseFormScreen(exercise: exercise),
                  ),
                );
                if (updated != null && context.mounted) {
                  Navigator.of(context).pop(updated);
                }
              },
            ),
            if (_isCustom)
              IconButton(
                tooltip: 'מחיקה',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            if (_isBuiltin && exercise.hasPersonalDefaults)
              IconButton(
                tooltip: 'איפוס לברירת מחדל',
                icon: const Icon(Icons.restore),
                onPressed: () => _confirmReset(context, ref),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            _ExerciseProfileTab(exercise: exercise),
            ExerciseStatsTab(
              exerciseId: exercise.compositeId,
              exerciseType: exercise.exerciseType,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('איפוס פרופיל'),
        content: Text('להחזיר את "${exercise.name}" לפרופיל המקורי?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('איפוס'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final uid = ref.read(currentUidProvider);
    await ref
        .read(exerciseRepositoryProvider)
        .resetBuiltinOverride(uid, exercise.id);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הוחזר לפרופיל המקורי')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת תרגיל'),
        content: Text('למחוק את "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final uid = ref.read(currentUidProvider);
    await ref
        .read(exerciseRepositoryProvider)
        .deleteUserExercise(uid, exercise.id);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('התרגיל נמחק')),
      );
    }
  }
}

class _ExerciseProfileTab extends ConsumerWidget {
  const _ExerciseProfileTab({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryLookup = ref.watch(exerciseCategoryMapProvider);
    final categoryLabel = categoryName(exercise.categoryId, categoryLookup);
    final isBuiltin = exercise.source == ExerciseSource.builtin;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ExerciseCategoryAvatar(
            categoryId: exercise.categoryId,
            radius: 40,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Chip(label: Text(exercise.source.labelHe)),
              if (exercise.hasPersonalDefaults)
                Chip(
                  avatar: Icon(
                    Icons.tune,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('התאמה אישית'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('פרטים'),
        _InfoRow(label: 'קטגוריה', value: categoryLabel),
        _InfoRow(label: 'סוג', value: exercise.exerciseType.labelHe),
        if (exercise.muscleTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('שרירים פעילים', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in exercise.muscleTags) Chip(label: Text(tag)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle('ברירות מחדל'),
        if (isBuiltin && exercise.hasPersonalDefaults)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'הפרופיל מותאם אישית עבורך.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        _InfoRow(label: 'סטים', value: '${exercise.defaultSets}'),
        if (exercise.exerciseType != ExerciseType.time)
          _InfoRow(label: 'חזרות', value: '${exercise.defaultReps}'),
        if (exercise.exerciseType == ExerciseType.weightReps &&
            exercise.defaultWeightKg != null)
          _InfoRow(
            label: 'משקל יעד',
            value: '${exercise.defaultWeightKg} ק"ג',
          ),
        if (exercise.exerciseType == ExerciseType.time &&
            exercise.defaultTimeSec != null)
          _InfoRow(
            label: 'זמן יעד',
            value: _formatSeconds(exercise.defaultTimeSec!),
          ),
        if (exercise.defaultRestSec != null)
          _InfoRow(
            label: 'מנוחה ייעודית',
            value: '${exercise.defaultRestSec} שניות',
          ),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '$m דק׳ ${s > 0 ? '$s שנ׳' : ''}'.trim();
    return '$s שניות';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

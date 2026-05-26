import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/plans/data/plan_repository.dart';
import 'package:myworkout/features/plans/presentation/plan_detail_screen.dart';
import 'package:myworkout/features/plans/presentation/widgets/plan_list_tile.dart';
import 'package:myworkout/features/workout/application/session_list_providers.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final theme = Theme.of(context);

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין תוכניות עדיין',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'לחץ + ליצירת תוכנית אימון ראשונה',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = List.of(plans)
          ..sort((a, b) {
            if (a.isStarred != b.isStarred) {
              return a.isStarred ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          });

        return RefreshIndicator(
          color: AppColors.ember,
          onRefresh: () async {
            ref.invalidate(plansProvider);
            ref.invalidate(allSessionsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final plan = sorted[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _PlanListTileWithCount(
                plan: plan,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlanDetailScreen(
                        planId: plan.id,
                        planName: plan.name,
                      ),
                    ),
                  );
                },
                onStarToggle: () => _toggleStar(context, ref, plan),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('שגיאה: $error'),
        ),
      ),
    );
  }

  Future<void> _toggleStar(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
  ) async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(planRepositoryProvider);

    try {
      await repo.setStarred(
        uid,
        plan.id,
        starred: !plan.isStarred,
      );
    } on PlanRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

class _PlanListTileWithCount extends ConsumerWidget {
  const _PlanListTileWithCount({
    required this.plan,
    required this.onTap,
    required this.onStarToggle,
  });

  final WorkoutPlan plan;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(planExercisesProvider(plan.id));
    final sessionCount = ref.watch(planCompletedSessionCountProvider(plan.id));

    final count = exercisesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return PlanListTile(
      plan: plan,
      exerciseCount: count,
      completedSessionCount: sessionCount,
      onTap: onTap,
      onStarToggle: onStarToggle,
    );
  }
}

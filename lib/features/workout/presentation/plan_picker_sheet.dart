import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/workout/application/workout_starter.dart';

/// בחירת תוכנית להתחלת אימון לייב.
class PlanPickerSheet extends ConsumerWidget {
  const PlanPickerSheet({super.key, required this.hostContext});

  /// Context של המסך שפתח את הגיליון (בית) — נשאר תקף אחרי סגירת ה-sheet.
  final BuildContext hostContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlanPickerSheet(hostContext: context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'בחר תוכנית אימון',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Center(
                      child: Text('צור תוכנית קודם בטאב תוכניות'),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: plans.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return ListTile(
                        leading: Icon(
                          plan.isStarred ? Icons.star : Icons.fitness_center,
                          color: plan.isStarred ? Colors.amber.shade700 : null,
                        ),
                        title: Text(plan.name),
                        subtitle: Text(
                          'מנוחה ${plan.defaultRestSec} שניות',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          startWorkoutFromPlan(hostContext, ref, plan.id);
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('שגיאה: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';
import 'package:myworkout/features/workout/presentation/live_workout_screen.dart';

/// מתחיל אימון מתוכנית — משותף לבית, בוחר תוכניות וכו'.
Future<void> startWorkoutFromPlan(
  BuildContext context,
  WidgetRef ref,
  String planId,
) async {
  if (!context.mounted) return;

  if (ref.read(sessionControllerProvider) != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('כבר יש אימון פעיל')),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LiveWorkoutScreen()),
    );
    return;
  }

  var loadingOpen = false;
  if (context.mounted) {
    loadingOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  try {
    final uid = ref.read(currentUidProvider);
    final plans = await ref.read(plansProvider.future);
    final plan = plans.firstWhere((p) => p.id == planId);
    final exercises = await ref
        .read(planRepositoryProvider)
        .fetchPlanExercises(uid, planId);

    if (loadingOpen && context.mounted) {
      Navigator.of(context).pop();
      loadingOpen = false;
    }

    if (!context.mounted) return;

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'לתוכנית אין תרגילים — היכנס לתוכנית והוסף תרגילים לפני האימון',
          ),
        ),
      );
      return;
    }

    await ref.read(sessionControllerProvider.notifier).startWorkout(
          uid: uid,
          plan: plan,
          planExercises: exercises,
        );

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LiveWorkoutScreen()),
    );
  } catch (e) {
    if (loadingOpen && context.mounted) {
      Navigator.of(context).pop();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא הצלחנו להתחיל אימון: $e')),
      );
    }
  }
}

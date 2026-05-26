import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

final plansProvider = StreamProvider<List<WorkoutPlan>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(planRepositoryProvider).watchPlans(uid);
});

final planExercisesProvider =
    StreamProvider.family<List<PlanExercise>, String>((ref, planId) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(planRepositoryProvider).watchPlanExercises(uid, planId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/home/domain/weekly_summary.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/plans/data/plan_repository.dart';
import 'package:myworkout/features/workout/application/session_list_providers.dart';
import 'package:myworkout/features/workout/data/session_repository.dart';
import 'package:myworkout/shared/models/workout_plan.dart';
import 'package:myworkout/shared/models/workout_session.dart';

/// סיכום אימונים לשבוע הנוכחי (מסך בית).
final weeklyWorkoutSummaryProvider = Provider<WeeklyWorkoutSummary?>((ref) {
  final sessions = ref.watch(currentWeekSessionsProvider).valueOrNull;
  if (sessions == null) return null;
  return buildWeeklySummary(sessions);
});

/// עד 3 תוכניות מסומנות בכוכב — לדשבורד הבית.
final starredPlansProvider = Provider<List<WorkoutPlan>>((ref) {
  final async = ref.watch(plansProvider);
  return async.maybeWhen(
    data: (plans) {
      final starred = plans.where((p) => p.isStarred).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return starred.take(PlanRepository.maxStarredPlans).toList();
    },
    orElse: () => const [],
  );
});

Stream<SessionWithSets?> _watchLastSessionForPlan(
  SessionRepository repo,
  String uid,
  String planId,
) async* {
  await for (final sessions in repo.watchSessions(uid)) {
    final forPlan = sessions
        .where(
          (s) => s.planId == planId && s.status == SessionStatus.completed,
        )
        .toList();
    if (forPlan.isEmpty) {
      yield null;
      continue;
    }
    forPlan.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    yield await repo.getSessionWithSets(uid, forPlan.first.id);
  }
}

/// האימון האחרון שהושלם לתוכנית — מתעדכן בזמן אמת מ-Firestore.
final lastSessionForPlanProvider =
    StreamProvider.family<SessionWithSets?, String>((ref, planId) {
  final uid = ref.watch(currentUidProvider);
  final repo = ref.watch(sessionRepositoryProvider);
  return _watchLastSessionForPlan(repo, uid, planId);
});

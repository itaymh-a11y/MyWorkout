import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/shared/models/workout_session.dart';

/// כל האימונים שהושלמו (זמן אמת).
final allSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(sessionRepositoryProvider).watchSessions(uid);
});

/// אימונים בשבוע הנוכחי (ראשון–שבת).
final currentWeekSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final weekStart = startOfWeek(DateTime.now());
  final weekEnd = weekStart.add(const Duration(days: 7));
  return ref.watch(sessionRepositoryProvider).watchSessionsInRange(
        uid,
        start: weekStart,
        end: weekEnd,
      );
});

/// מספר אימונים שהושלמו לכל תוכנית (מזהה תוכנית → כמות).
final sessionCountByPlanProvider = Provider<Map<String, int>>((ref) {
  final sessions = ref.watch(allSessionsProvider).valueOrNull ?? [];
  final counts = <String, int>{};
  for (final s in sessions) {
    if (s.status != SessionStatus.completed) continue;
    counts[s.planId] = (counts[s.planId] ?? 0) + 1;
  }
  return counts;
});

final planCompletedSessionCountProvider =
    Provider.family<int, String>((ref, planId) {
  return ref.watch(sessionCountByPlanProvider)[planId] ?? 0;
});

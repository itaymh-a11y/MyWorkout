import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/shared/models/workout_session.dart';

/// סיכום אימונים לשבוע הנוכחי.
class WeeklyWorkoutSummary {
  const WeeklyWorkoutSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalWorkouts,
    required this.byPlan,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalWorkouts;
  final List<PlanWeekSessionCount> byPlan;
}

class PlanWeekSessionCount {
  const PlanWeekSessionCount({
    required this.planId,
    required this.planName,
    required this.count,
  });

  final String planId;
  final String planName;
  final int count;
}

WeeklyWorkoutSummary buildWeeklySummary(List<WorkoutSession> sessions) {
  final weekStart = startOfWeek(DateTime.now());
  final weekEnd = weekStart.add(const Duration(days: 7));

  final completed =
      sessions.where((s) => s.status == SessionStatus.completed).toList();

  final byPlanMap = <String, PlanWeekSessionCount>{};
  for (final s in completed) {
    final existing = byPlanMap[s.planId];
    if (existing != null) {
      byPlanMap[s.planId] = PlanWeekSessionCount(
        planId: s.planId,
        planName: s.planName,
        count: existing.count + 1,
      );
    } else {
      byPlanMap[s.planId] = PlanWeekSessionCount(
        planId: s.planId,
        planName: s.planName,
        count: 1,
      );
    }
  }

  final byPlan = byPlanMap.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.planName.compareTo(b.planName);
    });

  return WeeklyWorkoutSummary(
    weekStart: weekStart,
    weekEnd: weekEnd,
    totalWorkouts: completed.length,
    byPlan: byPlan,
  );
}

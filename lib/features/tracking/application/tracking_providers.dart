import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/data/goals_repository.dart';
import 'package:myworkout/features/tracking/data/meal_repository.dart';
import 'package:myworkout/features/tracking/data/water_repository.dart';
import 'package:myworkout/features/tracking/data/weight_repository.dart';
import 'package:myworkout/features/tracking/domain/daily_goals.dart';
import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/meal_template.dart';
import 'package:myworkout/features/tracking/domain/water_day.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';
import 'package:myworkout/features/tracking/domain/workout_burn.dart';
import 'package:myworkout/features/workout/application/session_list_providers.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository();
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository();
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository();
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository();
});

final goalsProvider = StreamProvider<DailyGoals>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(goalsRepositoryProvider).watchGoals(uid);
});

final mealTemplatesProvider = StreamProvider<List<MealTemplate>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(mealRepositoryProvider).watchTemplates(uid);
});

final mealsForDayProvider =
    StreamProvider.family<List<MealLog>, String>((ref, day) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(mealRepositoryProvider).watchLogsOnDay(uid, day);
});

final waterForDayProvider = StreamProvider.family<WaterDay, String>((ref, day) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(waterRepositoryProvider).watchDay(uid, day);
});

class DayKeyRange {
  const DayKeyRange({required this.start, required this.end});

  final String start;
  final String end;

  @override
  bool operator ==(Object other) =>
      other is DayKeyRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

final mealsInRangeProvider =
    StreamProvider.family<List<MealLog>, DayKeyRange>((ref, range) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(mealRepositoryProvider).watchLogsInRange(
        uid,
        startDay: range.start,
        endDay: range.end,
      );
});

final waterInRangeProvider =
    StreamProvider.family<List<WaterDay>, DayKeyRange>((ref, range) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(waterRepositoryProvider).watchDaysInRange(
        uid,
        startDay: range.start,
        endDay: range.end,
      );
});

final weightLogsProvider = StreamProvider<List<WeightLog>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(weightRepositoryProvider).watchLogs(uid);
});

final todayKeyProvider = Provider<String>((ref) {
  return dayKey(DateTime.now());
});

WeightLog? latestWeight(List<WeightLog> logs) {
  if (logs.isEmpty) return null;
  return logs.reduce(
    (a, b) => a.weighedAt.isAfter(b.weighedAt) ? a : b,
  );
}

/// השקילה האחרונה ביום [day] או לפניו — לחישוב שריפת האימון.
double? bodyWeightOnOrBefore(List<WeightLog> logs, String day) {
  WeightLog? match;
  for (final log in logs) {
    if (log.dayKey.compareTo(day) > 0) continue;
    if (match == null || log.weighedAt.isAfter(match.weighedAt)) {
      match = log;
    }
  }
  return match?.kg;
}

/// קלוריות שהאימונים של היום מוסיפים ליעד האכילה.
final workoutBurnForDayProvider =
    FutureProvider.family<int, String>((ref, day) async {
  final sessions = ref.watch(allSessionsProvider).valueOrNull ?? const [];
  final onDay = sessions
      .where(
        (session) =>
            session.status == SessionStatus.completed &&
            dayKey(session.startedAt.toLocal()) == day,
      )
      .toList();
  if (onDay.isEmpty) return 0;

  final uid = ref.watch(currentUidProvider);
  final repo = ref.watch(sessionRepositoryProvider);
  final weightKg = bodyWeightOnOrBefore(
    ref.watch(weightLogsProvider).valueOrNull ?? const [],
    day,
  );

  final inputs = <({int durationSec, List<WorkoutSet> sets})>[];
  for (final session in onDay) {
    final loaded = await repo.getSessionWithSets(uid, session.id);
    inputs.add((
      durationSec: session.durationSec,
      sets: loaded?.sets ?? const [],
    ));
  }
  return estimateDayWorkoutKcal(sessions: inputs, bodyWeightKg: weightKg);
});

WeightLog? weightOnDay(List<WeightLog> logs, String day) {
  WeightLog? match;
  for (final log in logs) {
    if (log.dayKey != day) continue;
    if (match == null || log.weighedAt.isAfter(match.weighedAt)) {
      match = log;
    }
  }
  return match;
}

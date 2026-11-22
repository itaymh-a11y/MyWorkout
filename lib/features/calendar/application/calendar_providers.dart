import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/shared/models/workout_session.dart';

/// תחילת השבוע הנוכחי בלוח (יום ראשון).
final calendarWeekStartProvider = StateProvider<DateTime>((ref) {
  return startOfWeek(DateTime.now());
});

/// היום הנבחר בלוח (ברירת מחדל: היום).
final calendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// אימונים בשבוע הנבחר.
final sessionsInWeekProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final weekStart = ref.watch(calendarWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 7));
  return ref.watch(sessionRepositoryProvider).watchSessionsInRange(
        uid,
        start: weekStart,
        end: weekEnd,
      );
});

/// מקבץ אימונים לפי יום מקומי.
final sessionsByDayInWeekProvider =
    Provider<Map<String, List<WorkoutSession>>>((ref) {
  final sessions = ref.watch(sessionsInWeekProvider).valueOrNull ?? [];
  final map = <String, List<WorkoutSession>>{};
  for (final s in sessions) {
    final key = dayKey(s.startedAt.toLocal());
    map.putIfAbsent(key, () => []);
    map[key]!.add(s);
  }
  for (final list in map.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return map;
});

/// אימונים של היום הנבחר.
final sessionsOnSelectedDayProvider = Provider<List<WorkoutSession>>((ref) {
  final selected = ref.watch(calendarSelectedDayProvider);
  final byDay = ref.watch(sessionsByDayInWeekProvider);
  return byDay[dayKey(selected)] ?? const [];
});

class DayMarkers {
  const DayMarkers({
    this.hasMeal = false,
    this.hasWater = false,
    this.hasWeight = false,
  });

  final bool hasMeal;
  final bool hasWater;
  final bool hasWeight;

  bool get hasExtra => hasMeal || hasWater || hasWeight;
}

final calendarWeekRangeProvider = Provider<DayKeyRange>((ref) {
  final start = ref.watch(calendarWeekStartProvider);
  final end = start.add(const Duration(days: 6));
  return DayKeyRange(start: dayKey(start), end: dayKey(end));
});

/// סימון ימים בשבוע הנבחר שיש בהם ארוחה, מים או שקילה.
final calendarDayMarkersProvider = Provider<Map<String, DayMarkers>>((ref) {
  final range = ref.watch(calendarWeekRangeProvider);
  final meals = ref.watch(mealsInRangeProvider(range)).valueOrNull ?? const [];
  final water = ref.watch(waterInRangeProvider(range)).valueOrNull ?? const [];
  final weights = ref.watch(weightLogsProvider).valueOrNull ?? const [];

  final mealDays = meals.map((meal) => meal.dayKey).toSet();
  final waterDays =
      water.where((day) => day.hasWater).map((day) => day.dayKey).toSet();
  final weightDays = weights
      .map((log) => log.dayKey)
      .where((key) => key.compareTo(range.start) >= 0 && key.compareTo(range.end) <= 0)
      .toSet();

  final keys = {...mealDays, ...waterDays, ...weightDays};
  return {
    for (final key in keys)
      key: DayMarkers(
        hasMeal: mealDays.contains(key),
        hasWater: waterDays.contains(key),
        hasWeight: weightDays.contains(key),
      ),
  };
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
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

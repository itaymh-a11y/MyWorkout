import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_set.dart';

/// עיצוב תאריך קצר לתצוגה (RTL).
String formatSessionDate(DateTime dt) {
  const months = [
    'ינו׳',
    'פבר׳',
    'מרץ',
    'אפר׳',
    'מאי',
    'יונ׳',
    'יול׳',
    'אוג׳',
    'ספט׳',
    'אוק׳',
    'נוב׳',
    'דצמ׳',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String formatDuration(int sec) {
  final m = sec ~/ 60;
  if (m < 60) return '$m דק׳';
  final h = m ~/ 60;
  final rm = m % 60;
  return rm > 0 ? '$h ש׳ $rm דק׳' : '$h ש׳';
}

String formatSetActual(WorkoutSet set) {
  switch (set.exerciseType) {
    case ExerciseType.weightReps:
      final w = set.actualWeightKg?.toString() ?? '-';
      final r = set.actualReps?.toString() ?? '-';
      return '$w ק"ג × $r';
    case ExerciseType.repsOnly:
      return '${set.actualReps ?? '-'} חזרות';
    case ExerciseType.time:
      final t = set.actualTimeSec;
      if (t == null) return '-';
      final m = t ~/ 60;
      final s = t % 60;
      if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
      return '${s}ש׳';
  }
}

/// סיכום אימון לפי תרגילים (שם → שורות סטים).
Map<String, List<String>> groupSetsByExercise(List<WorkoutSet> sets) {
  final map = <String, List<String>>{};
  for (final set in sets) {
    map.putIfAbsent(set.exerciseName, () => []);
    map[set.exerciseName]!.add(formatSetActual(set));
  }
  return map;
}

/// תחילת שבוע לפי לוח עברי-ישראלי: **יום ראשון** 00:00.
/// סוף השבוע (לא כולל): [startOfWeek] + 7 ימים → מכסה א׳–ש׳.
DateTime startOfWeek(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  // Dart: Monday=1 … Sunday=7
  final offset = local.weekday == DateTime.sunday ? 0 : local.weekday;
  return local.subtract(Duration(days: offset));
}

/// האם [date] נופל בשבוע שמתחיל ב-[weekStart] (א׳–ש׳, weekStart כלול, weekEnd לא).
bool isInWeek(DateTime date, DateTime weekStart, DateTime weekEnd) {
  final local = DateTime(date.year, date.month, date.day);
  return !local.isBefore(weekStart) && local.isBefore(weekEnd);
}

/// מפתח יום מקומי לקיבוץ.
String dayKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

const hebrewWeekdays = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];

/// טווח תאריכים לשבוע (לכותרת סיכום).
String formatWeekRange(DateTime weekStart, DateTime weekEnd) {
  const months = [
    'ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יונ׳',
    'יול׳', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳',
  ];
  final end = weekEnd.subtract(const Duration(days: 1));
  if (weekStart.month == end.month) {
    return '${weekStart.day}–${end.day} ${months[weekStart.month - 1]}';
  }
  return '${weekStart.day} ${months[weekStart.month - 1]} – ${end.day} ${months[end.month - 1]}';
}

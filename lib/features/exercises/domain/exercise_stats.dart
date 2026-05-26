import 'dart:math' as math;

import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

/// אימון בודד שבו בוצע תרגיל מסוים.
class ExerciseSessionHistory {
  const ExerciseSessionHistory({
    required this.session,
    required this.sets,
  });

  final WorkoutSession session;
  final List<WorkoutSet> sets;
}

/// שיאים אישיים לתרגיל (לפי סוג).
class ExercisePersonalRecords {
  const ExercisePersonalRecords({
    this.maxWeightKg,
    this.maxReps,
    this.maxTimeSec,
  });

  final double? maxWeightKg;
  final int? maxReps;
  final int? maxTimeSec;
}

class ExerciseStatsData {
  const ExerciseStatsData({
    required this.history,
    required this.records,
  });

  final List<ExerciseSessionHistory> history;
  final ExercisePersonalRecords records;
}

/// ממוצעי ביצוע לאימון בודד — לציור גרף התקדמות לפי תאריך.
class SessionChartPoint {
  const SessionChartPoint({
    required this.date,
    this.avgWeightKg,
    this.avgReps,
    this.avgTimeSec,
  });

  final DateTime date;
  final double? avgWeightKg;
  final double? avgReps;
  final double? avgTimeSec;
}

double? _averageDoubles(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}

/// ממוצע משקל / חזרות / זמן של כל הסטים באימון.
SessionChartPoint chartPointFromSession(ExerciseSessionHistory h) {
  final sets = h.sets.where((s) => s.completed).toList();
  final source = sets.isEmpty ? h.sets : sets;

  return SessionChartPoint(
    date: h.session.startedAt,
    avgWeightKg: _averageDoubles(
      source.map((s) => s.actualWeightKg).whereType<double>(),
    ),
    avgReps: _averageDoubles(
      source.map((s) => s.actualReps).whereType<int>().map((r) => r.toDouble()),
    ),
    avgTimeSec: _averageDoubles(
      source.map((s) => s.actualTimeSec).whereType<int>().map((t) => t.toDouble()),
    ),
  );
}

/// נקודות לגרף לפי תאריך אימון (ישן → חדש).
List<SessionChartPoint> chartPointsFromHistory(
  List<ExerciseSessionHistory> history,
) {
  final sorted = List<ExerciseSessionHistory>.from(history)
    ..sort((a, b) => a.session.startedAt.compareTo(b.session.startedAt));

  return sorted.map(chartPointFromSession).toList();
}

/// טווח ציר Y עם מרווח — כדי ששינוי קטן בין אימונים ייראה בגרף.
({double minY, double maxY}) chartYRange(
  Iterable<double> values, {
  double minFloor = 0,
}) {
  final list = values.toList();
  if (list.isEmpty) return (minY: minFloor, maxY: 10);

  final dataMin = list.reduce((a, b) => a < b ? a : b);
  final dataMax = list.reduce((a, b) => a > b ? a : b);
  final span = dataMax - dataMin;
  final padding = span == 0 ? math.max(dataMax * 0.1, 1) : span * 0.15;

  return (
    minY: math.max(minFloor, dataMin - padding),
    maxY: dataMax + padding,
  );
}

ExercisePersonalRecords computePersonalRecords(
  List<WorkoutSet> sets,
  ExerciseType type,
) {
  final completed = sets.where((s) => s.completed).toList();
  if (completed.isEmpty) {
    return sets.isEmpty
        ? const ExercisePersonalRecords()
        : _computeFromAll(sets, type);
  }
  return _computeFromAll(completed, type);
}

ExercisePersonalRecords _computeFromAll(
  List<WorkoutSet> sets,
  ExerciseType type,
) {
  switch (type) {
    case ExerciseType.weightReps:
      double? maxW;
      int? maxR;
      for (final s in sets) {
        if (s.actualWeightKg != null) {
          maxW = maxW == null
              ? s.actualWeightKg
              : (s.actualWeightKg! > maxW ? s.actualWeightKg : maxW);
        }
        if (s.actualReps != null) {
          maxR = maxR == null
              ? s.actualReps
              : (s.actualReps! > maxR ? s.actualReps : maxR);
        }
      }
      return ExercisePersonalRecords(maxWeightKg: maxW, maxReps: maxR);
    case ExerciseType.repsOnly:
      int? maxR;
      for (final s in sets) {
        if (s.actualReps != null) {
          maxR = maxR == null
              ? s.actualReps
              : (s.actualReps! > maxR ? s.actualReps : maxR);
        }
      }
      return ExercisePersonalRecords(maxReps: maxR);
    case ExerciseType.time:
      int? maxT;
      for (final s in sets) {
        if (s.actualTimeSec != null) {
          maxT = maxT == null
              ? s.actualTimeSec
              : (s.actualTimeSec! > maxT ? s.actualTimeSec : maxT);
        }
      }
      return ExercisePersonalRecords(maxTimeSec: maxT);
  }
}

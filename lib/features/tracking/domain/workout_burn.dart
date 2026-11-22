import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_set.dart';

/// משקל גוף לחישוב כשעדיין אין שקילה שמורה.
const defaultBurnBodyWeightKg = 75.0;

/// הערכת שריפה לאימון אחד. זו הערכה לפי משך ועצימות, לא מדידה.
///
/// קק״ל ≈ MET × משקל גוף × שעות. אימון כוח רגיל נע סביב MET 4:
/// כ-20 דקות עם כ-9 סטים, במשקל 75 ק״ג, יוצאים בערך 100 קק״ל.
int estimateSessionKcal({
  required int durationSec,
  required List<WorkoutSet> sets,
  double? bodyWeightKg,
}) {
  if (durationSec <= 0) return 0;

  final minutes = durationSec / 60;
  final hours = minutes / 60;
  final kg = (bodyWeightKg != null && bodyWeightKg > 0)
      ? bodyWeightKg
      : defaultBurnBodyWeightKg;

  final done = sets.where((set) => set.completed).toList();
  var tonnage = 0.0;
  var cardioSec = 0;
  for (final set in done) {
    if (set.exerciseType == ExerciseType.time) {
      cardioSec += set.actualTimeSec ?? 0;
      continue;
    }
    final reps = set.actualReps ?? 0;
    final weight = set.actualWeightKg ?? 0;
    if (reps > 0 && weight > 0) tonnage += weight * reps;
  }

  final double met;
  if (done.isEmpty && cardioSec == 0) {
    met = 4;
  } else {
    final setsPerMin = done.length / minutes;
    var value = 3.5 + ((setsPerMin - 0.25) * 2.2);
    final tonnagePerSet = done.isEmpty ? 0.0 : tonnage / done.length;
    if (tonnagePerSet > 400) {
      value += 0.4;
    } else if (tonnagePerSet > 200) {
      value += 0.2;
    }
    if (cardioSec > 0) {
      final share = (cardioSec / 60 / minutes).clamp(0.0, 1.0);
      value += share * 2;
    }
    met = value.clamp(3.0, 8.0);
  }

  return (met * kg * hours).round();
}

int estimateDayWorkoutKcal({
  required Iterable<({int durationSec, List<WorkoutSet> sets})> sessions,
  double? bodyWeightKg,
}) {
  var total = 0;
  for (final session in sessions) {
    total += estimateSessionKcal(
      durationSec: session.durationSec,
      sets: session.sets,
      bodyWeightKg: bodyWeightKg,
    );
  }
  return total;
}

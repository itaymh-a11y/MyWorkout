/// סוג תרגיל — קובע אילו שדות מוצגים בלייב ובהיסטוריה.
enum ExerciseType {
  weightReps('weight_reps'),
  repsOnly('reps_only'),
  time('time');

  const ExerciseType(this.firestoreValue);

  final String firestoreValue;

  static ExerciseType fromFirestore(String? value) {
    return ExerciseType.values.firstWhere(
      (e) => e.firestoreValue == value,
      orElse: () => ExerciseType.weightReps,
    );
  }
}

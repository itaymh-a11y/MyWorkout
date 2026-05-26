/// מקור התרגיל — מובנה (גלובלי) או מותאם אישית.
enum ExerciseSource {
  builtin('builtin'),
  custom('custom');

  const ExerciseSource(this.firestoreValue);

  final String firestoreValue;

  static ExerciseSource fromFirestore(String? value) {
    return ExerciseSource.values.firstWhere(
      (e) => e.firestoreValue == value,
      orElse: () => ExerciseSource.custom,
    );
  }
}

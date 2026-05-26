import 'package:myworkout/shared/models/exercise_source.dart';

/// מזהה תרגיל אחיד: `builtin_<id>` או `user_<id>`.
class ExerciseRef {
  const ExerciseRef({
    required this.source,
    required this.rawId,
  });

  factory ExerciseRef.builtin(String rawId) {
    return ExerciseRef(source: ExerciseSource.builtin, rawId: rawId);
  }

  factory ExerciseRef.user(String rawId) {
    return ExerciseRef(source: ExerciseSource.custom, rawId: rawId);
  }

  factory ExerciseRef.parse(String compositeId) {
    if (compositeId.startsWith('builtin_')) {
      return ExerciseRef.builtin(
        compositeId.substring('builtin_'.length),
      );
    }
    if (compositeId.startsWith('user_')) {
      return ExerciseRef.user(compositeId.substring('user_'.length));
    }
    // תאימות לאחור: מזהה ללא קידומת = מותאם אישית
    return ExerciseRef.user(compositeId);
  }

  final ExerciseSource source;
  final String rawId;

  bool get isBuiltin => source == ExerciseSource.builtin;

  String get compositeId => '${source == ExerciseSource.builtin ? 'builtin' : 'user'}_$rawId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseRef &&
          source == other.source &&
          rawId == other.rawId;

  @override
  int get hashCode => Object.hash(source, rawId);
}

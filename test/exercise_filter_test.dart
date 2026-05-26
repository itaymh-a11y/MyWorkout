import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

Exercise _exercise(String name, String categoryId) {
  return Exercise(
    id: name,
    source: ExerciseSource.builtin,
    name: name,
    categoryId: categoryId,
    exerciseType: ExerciseType.weightReps,
  );
}

void main() {
  test('סינון חיפוש וקטגוריה', () {
    final exercises = [
      _exercise('לחיצת חזה', 'push'),
      _exercise('מתח', 'pull'),
      _exercise('סקוואט', 'legs'),
    ];

    var result =
        exercises.where((e) => e.categoryId == 'push').toList();
    expect(result, hasLength(1));
    expect(result.first.name, 'לחיצת חזה');

    const query = 'מת';
    result = exercises.where((e) {
      return e.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
    expect(result, hasLength(1));
    expect(result.first.name, 'מתח');
  });
}

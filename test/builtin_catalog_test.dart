import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/features/exercises/data/builtin_exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BuiltinExerciseCatalog.clearCache);

  test('נטענים 40 תרגילי כוח מה-assets', () async {
    final exercises = await BuiltinExerciseCatalog.load();
    expect(exercises.length, 40);
    expect(exercises.every((e) => e.name.isNotEmpty), isTrue);
    expect(
      exercises.every((e) => e.muscleTags.isNotEmpty),
      isTrue,
      reason: 'לכל תרגיל יש תגיות שריר',
    );
  });
}

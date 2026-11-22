import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/features/tracking/domain/daily_goals.dart';
import 'package:myworkout/features/tracking/domain/meal_template.dart';
import 'package:myworkout/features/tracking/presentation/meal_form_screen.dart';
import 'package:myworkout/features/tracking/domain/workout_burn.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_set.dart';
import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';

void main() {
  MealLog meal({
    required String id,
    int kcal = 0,
    double proteinG = 0,
    double? carbsG = 0,
    double? fatG,
  }) {
    return MealLog(
      id: id,
      dayKey: '2026-11-22',
      name: id,
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      createdAt: DateTime(2026, 11, 22),
    );
  }

  test('sumMeals מסכם קלוריות חלבון ופחמימות', () {
    final totals = sumMeals([
      meal(id: 'a', kcal: 400, proteinG: 30, carbsG: 40, fatG: 10),
      meal(id: 'b', kcal: 250, proteinG: 12.5, carbsG: 20),
    ]);
    expect(totals.kcal, 650);
    expect(totals.proteinG, 42.5);
    expect(totals.carbsG, 60);
    expect(totals.fatG, 10);
    expect(totals.mealCount, 2);
    expect(sumMeals(const []).isEmpty, isTrue);
  });

  test('מנה של 100 גרם שנאכלת ב-200 גרם מכפילה את הערכים', () {
    final doubled = scalePortion(
      kcal: 180,
      proteinG: 12,
      carbsG: 20,
      fatG: 6,
      baseGrams: 100,
      eatenGrams: 200,
    );
    expect(doubled.kcal, 360);
    expect(doubled.proteinG, 24);
    expect(doubled.carbsG, 40);
    expect(doubled.fatG, 12);

    final half = scalePortion(
      kcal: 180,
      proteinG: 12,
      carbsG: null,
      fatG: null,
      baseGrams: 100,
      eatenGrams: 50,
    );
    expect(half.kcal, 90);
    expect(half.proteinG, 6);
    expect(half.carbsG, isNull);
    expect(half.fatG, isNull);
  });

  testWidgets('טופס ארוחה מאפשר פחמימות אופציונליות ומשקל', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MealFormScreen.log(dayKey: '2026-11-22'),
        ),
      ),
    );
    expect(find.text('פחמימות (אופציונלי)'), findsOneWidget);
    expect(find.text('משקל המנה (אופציונלי)'), findsOneWidget);
  });

  testWidgets('שינוי גרמים במנה שמורה מעדכן קלוריות', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MealFormScreen.log(
            dayKey: '2026-11-22',
            template: const MealTemplate(
              id: 'yogurt',
              name: 'יוגורט',
              kcal: 100,
              proteinG: 10,
              carbsG: 12,
              portionGrams: 100,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(1), '200');
    await tester.pump();
    final kcal = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .elementAt(2);
    expect(kcal.controller!.text, '200');
  });

  test('isWeighInDue לפי מרווח ימים', () {
    final today = DateTime(2026, 11, 22);
    expect(
      isWeighInDue(today: today, lastWeighIn: null, everyDays: 7),
      isTrue,
    );
    expect(
      isWeighInDue(today: today, lastWeighIn: today, everyDays: 7),
      isFalse,
    );
    expect(
      isWeighInDue(
        today: today,
        lastWeighIn: DateTime(2026, 11, 16),
        everyDays: 7,
      ),
      isFalse,
    );
    expect(
      isWeighInDue(
        today: today,
        lastWeighIn: DateTime(2026, 11, 15),
        everyDays: 7,
      ),
      isTrue,
    );
  });

  test('weightStatusLabel מתאר את המצב הבא', () {
    final today = DateTime(2026, 11, 22);
    expect(
      weightStatusLabel(today: today, lastWeighIn: null, everyDays: 7),
      'עדיין לא נרשמה שקילה',
    );
    expect(
      weightStatusLabel(today: today, lastWeighIn: today, everyDays: 7),
      'נשקלת היום',
    );
    expect(
      weightStatusLabel(
        today: today,
        lastWeighIn: DateTime(2026, 11, 21),
        everyDays: 7,
      ),
      'השקילה הבאה בעוד 6 ימים',
    );
    expect(
      weightStatusLabel(
        today: today,
        lastWeighIn: DateTime(2026, 11, 15),
        everyDays: 7,
      ),
      'הגיע הזמן להישקל',
    );
  });

  test('weightTrendPoints שומר נקודה אחת ליום', () {
    final points = weightTrendPoints([
      WeightLog(
        id: '1',
        dayKey: '2026-11-01',
        weighedAt: DateTime(2026, 11, 1, 8),
        kg: 80,
      ),
      WeightLog(
        id: '2',
        dayKey: '2026-11-01',
        weighedAt: DateTime(2026, 11, 1, 20),
        kg: 79.5,
      ),
      WeightLog(
        id: '3',
        dayKey: '2026-11-08',
        weighedAt: DateTime(2026, 11, 8),
        kg: 79,
      ),
    ]);
    expect(points, hasLength(2));
    expect(points.first.kg, 79.5);
    expect(points.last.kg, 79);
  });

  test('אימון של 20 דקות ותשעה סטים מוסיף כ-100 קלוריות', () {
    final sets = [
      for (var i = 0; i < 9; i++)
        WorkoutSet(
          id: '$i',
          exerciseId: 'ex${i ~/ 3}',
          exerciseName: 'תרגיל',
          exerciseType: ExerciseType.weightReps,
          setIndex: i,
          actualWeightKg: 40,
          actualReps: 10,
          completed: true,
        ),
    ];
    final kcal = estimateSessionKcal(
      durationSec: 20 * 60,
      sets: sets,
      bodyWeightKg: 75,
    );
    expect(kcal, inInclusiveRange(90, 110));

    final heavier = estimateSessionKcal(
      durationSec: 20 * 60,
      sets: sets,
      bodyWeightKg: 90,
    );
    expect(heavier, greaterThan(kcal));
    expect(
      estimateSessionKcal(durationSec: 0, sets: sets, bodyWeightKg: 75),
      0,
    );
  });

  test('המרות ליטרים וימי שקילה', () {
    expect(formatLitersFromMl(0), '0');
    expect(formatLitersFromMl(250), '0.25');
    expect(formatLitersFromMl(1500), '1.5');
    expect(formatLitersFromMl(2000), '2');
    expect(litersTextToMl('2.5'), 2500);
    expect(litersTextToMl('2,5'), 2500);
    expect(litersTextToMl(''), isNull);
    expect(DailyGoals.normalizeWeighInDays(3), 3);
    expect(DailyGoals.normalizeWeighInDays(5), 7);
    expect(weighInIntervalLabel(7), 'פעם בשבוע');
  });
}

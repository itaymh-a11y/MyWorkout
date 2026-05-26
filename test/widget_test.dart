import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/core/navigation/app_shell.dart';
import 'package:myworkout/features/exercises/application/exercise_list_providers.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

void main() {
  testWidgets('מציג את ארבעת הטאבים בניווט התחתון', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredExercisesProvider.overrideWith(
            (ref) => const AsyncValue.data([]),
          ),
          plansProvider.overrideWith(
            (ref) => Stream.value(const <WorkoutPlan>[]),
          ),
        ],
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    expect(find.text('בית'), findsWidgets);
    expect(find.text('לוח'), findsOneWidget);
    expect(find.text('תרגילים'), findsOneWidget);
    expect(find.text('תוכניות'), findsOneWidget);
  });
}

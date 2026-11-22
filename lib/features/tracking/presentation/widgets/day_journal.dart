import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/features/calendar/presentation/manual_session_screen.dart';
import 'package:myworkout/features/calendar/presentation/session_detail_screen.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';
import 'package:myworkout/features/tracking/presentation/meal_form_screen.dart';
import 'package:myworkout/features/tracking/presentation/saved_meals_screen.dart';
import 'package:myworkout/features/tracking/presentation/weight_form_screen.dart';
import 'package:myworkout/features/tracking/presentation/widgets/water_controls.dart';
import 'package:myworkout/features/workout/application/session_delete.dart';
import 'package:myworkout/shared/models/workout_session.dart';

class DayJournal extends ConsumerWidget {
  const DayJournal({
    super.key,
    required this.day,
    required this.sessions,
  });

  final DateTime day;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = dayKey(day);
    final mealsAsync = ref.watch(mealsForDayProvider(key));
    final weightsAsync = ref.watch(weightLogsProvider);
    final goal = ref.watch(goalsProvider).valueOrNull?.calorieGoalKcal;
    final burn = ref.watch(workoutBurnForDayProvider(key)).valueOrNull ?? 0;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Text(
          formatSessionDate(day),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'אימונים',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          Text(
            'אין אימונים ביום זה',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final session in sessions) ...[
            _SessionTile(session: session),
            const SizedBox(height: 8),
          ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => ManualSessionScreen.open(context, initialDate: day),
            icon: const Icon(Icons.history_edu),
            label: const Text('הוסף אימון ידני'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ארוחות',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        mealsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('שגיאה בטעינת ארוחות: $error'),
          data: (meals) {
            final totals = sumMeals(meals);
            final allowance = goal == null ? null : goal + burn;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (burn > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      allowance == null
                          ? 'מהאימון: כ־$burn קק״ל נוספות ליעד'
                          : 'נאכל ${totals.kcal} מתוך $allowance · יעד $goal + כ־$burn מהאימון',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (meals.isEmpty)
                  Text(
                    'אין ארוחות ביום זה',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Text(
                    '${totals.kcal} קק״ל · חלבון ${formatGrams(totals.proteinG)} ג׳ · פחמימות ${formatGrams(totals.carbsG)} ג׳',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final meal in meals) ...[
                    _MealTile(meal: meal),
                    const SizedBox(height: 8),
                  ],
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          MealFormScreen.openLog(context, dayKey: key),
                      icon: const Icon(Icons.restaurant),
                      label: const Text('הוסף ארוחה'),
                    ),
                    TextButton(
                      onPressed: () =>
                          SavedMealsScreen.open(context, dayKey: key),
                      child: const Text('ארוחות שמורות'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'שתייה',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        WaterControls(dayKey: key, showGoal: false),
        const SizedBox(height: 16),
        Text(
          'משקל',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        weightsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('שגיאה בטעינת משקל: $error'),
          data: (logs) {
            final log = weightOnDay(logs, key);
            if (log == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'לא נשקלת ביום זה',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => WeightFormScreen.open(context, dayKey: key),
                    child: const Text('הזן משקל'),
                  ),
                ],
              );
            }
            return _WeightTile(log: log);
          },
        ),
      ],
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = context.brand;
    final time = session.startedAt.toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) => confirmAndDeleteSession(
        context,
        ref,
        sessionId: session.id,
        planName: session.planName,
      ),
      child: AccentCard(
        accent: ContentAccent.workout,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: brand.contentSurface(ContentAccent.workout),
            child: Icon(Icons.fitness_center, color: brand.workout, size: 22),
          ),
          title: Text(session.planName),
          subtitle: Text('$timeStr · ${formatDuration(session.durationSec)}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SessionDetailScreen(sessionId: session.id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MealTile extends ConsumerWidget {
  const _MealTile({required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grams = meal.portionGrams == null
        ? ''
        : '${formatGrams(meal.portionGrams!)} ג׳ · ';
    final carbs = meal.carbsG == null
        ? ''
        : ' · פחמימות ${formatGrams(meal.carbsG!)} ג׳';
    final fat = meal.fatG == null ? '' : ' · שומן ${formatGrams(meal.fatG!)} ג׳';
    return AccentCard(
      accent: ContentAccent.workout,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(meal.name),
        subtitle: Text(
          '$grams${meal.kcal} קק״ל · חלבון ${formatGrams(meal.proteinG)} ג׳$carbs$fat',
        ),
        trailing: IconButton(
          tooltip: 'מחיקה',
          onPressed: () async {
            try {
              final uid = ref.read(currentUidProvider);
              await ref.read(mealRepositoryProvider).deleteLog(uid, meal.id);
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('לא נמחק: $error')),
                );
              }
            }
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _WeightTile extends ConsumerWidget {
  const _WeightTile({required this.log});

  final WeightLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AccentCard(
      accent: ContentAccent.plan,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${formatGrams(log.kg)} ק״ג'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'עריכה',
              onPressed: () =>
                  WeightFormScreen.open(context, dayKey: log.dayKey),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'מחיקה',
              onPressed: () async {
                try {
                  final uid = ref.read(currentUidProvider);
                  await ref
                      .read(weightRepositoryProvider)
                      .deleteLog(uid, log.id);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('לא נמחק: $error')),
                    );
                  }
                }
              },
              icon: Icon(Icons.delete_outline, color: AppColors.silverDark),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/core/widgets/section_header.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/presentation/goals_screen.dart';
import 'package:myworkout/features/tracking/presentation/meal_form_screen.dart';
import 'package:myworkout/features/tracking/presentation/saved_meals_screen.dart';
import 'package:myworkout/features/tracking/presentation/weight_form_screen.dart';
import 'package:myworkout/features/tracking/presentation/weight_trend_screen.dart';
import 'package:myworkout/features/tracking/presentation/widgets/water_controls.dart';

class TodayDashboard extends ConsumerWidget {
  const TodayDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'היום',
                subtitle: 'תזונה, מים ומשקל',
                icon: Icons.today,
                accent: ContentAccent.calendar,
              ),
            ),
            TextButton(
              onPressed: () => GoalsScreen.open(context),
              child: const Text('יעדים'),
            ),
          ],
        ),
        _CalorieCard(dayKey: day),
        const SizedBox(height: 12),
        const _WaterSection(),
        const SizedBox(height: 12),
        _WeightCard(dayKey: day),
      ],
    );
  }
}

class _WaterSection extends ConsumerWidget {
  const _WaterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'שתייה',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        WaterControls(dayKey: day),
      ],
    );
  }
}

class _CalorieCard extends ConsumerWidget {
  const _CalorieCard({required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsForDayProvider(dayKey));
    final goalsAsync = ref.watch(goalsProvider);
    final burnAsync = ref.watch(workoutBurnForDayProvider(dayKey));
    final theme = Theme.of(context);

    if (mealsAsync.isLoading || goalsAsync.isLoading) {
      return const AccentCard(
        accent: ContentAccent.workout,
        child: LinearProgressIndicator(),
      );
    }
    if (mealsAsync.hasError) {
      return AccentCard(
        accent: ContentAccent.workout,
        child: Text('לא נטענו ארוחות: ${mealsAsync.error}'),
      );
    }
    if (goalsAsync.hasError) {
      return AccentCard(
        accent: ContentAccent.workout,
        child: Text('לא נטענו יעדים: ${goalsAsync.error}'),
      );
    }

    final meals = mealsAsync.value!;
    final goals = goalsAsync.value!;
    final totals = sumMeals(meals);
    final goal = goals.calorieGoalKcal;
    final burn = burnAsync.valueOrNull ?? 0;

    return AccentCard(
      accent: ContentAccent.workout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ארוחות', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (goal == null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => GoalsScreen.open(context),
                child: const Text('הגדר יעד קלורי'),
              ),
            )
          else ...[
            Text(
              '${totals.kcal} / ${goal + burn} קק״ל',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.emberDark,
              ),
            ),
            if (burn > 0) ...[
              const SizedBox(height: 4),
              Text(
                'יעד $goal + כ־$burn מהאימון',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.navy,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (totals.kcal / (goal + burn)).clamp(0.0, 1.0),
                minHeight: 8,
                color: AppColors.ember,
                backgroundColor: AppColors.emberLight,
              ),
            ),
            if (totals.kcal > goal + burn)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'מעל היעד',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.emberDark,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'חלבון ${formatGrams(totals.proteinG)} ג׳ · פחמימות ${formatGrams(totals.carbsG)} ג׳',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (meals.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final meal in meals) _MealRow(meal: meal),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => MealFormScreen.openLog(context, dayKey: dayKey),
                child: const Text('הוסף ארוחה'),
              ),
              OutlinedButton(
                onPressed: () => SavedMealsScreen.open(context, dayKey: dayKey),
                child: const Text('ארוחות שמורות'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealRow extends ConsumerWidget {
  const _MealRow({required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            meal.portionGrams == null
                ? '${meal.name} · ${meal.kcal} קק״ל'
                : '${meal.name} · ${formatGrams(meal.portionGrams!)} ג׳ · ${meal.kcal} קק״ל',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
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
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard({required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(weightLogsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final theme = Theme.of(context);

    if (logsAsync.isLoading || goalsAsync.isLoading) {
      return const AccentCard(
        accent: ContentAccent.plan,
        child: LinearProgressIndicator(),
      );
    }
    if (logsAsync.hasError) {
      return AccentCard(
        accent: ContentAccent.plan,
        child: Text('לא נטען משקל: ${logsAsync.error}'),
      );
    }

    final latest = latestWeight(logsAsync.value!);
    final every = goalsAsync.valueOrNull?.weighInEveryDays ??
        7;
    final status = weightStatusLabel(
      today: DateTime.now(),
      lastWeighIn: latest?.weighedAt,
      everyDays: every,
    );

    return AccentCard(
      accent: ContentAccent.plan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('משקל', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (latest != null)
            Text(
              '${formatGrams(latest.kg)} ק״ג · ${formatSessionDate(latest.weighedAt)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          const SizedBox(height: 4),
          Text(status, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => WeightFormScreen.open(context, dayKey: dayKey),
                child: const Text('הזן משקל'),
              ),
              OutlinedButton(
                onPressed: () => WeightTrendScreen.open(context),
                child: const Text('מגמה'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

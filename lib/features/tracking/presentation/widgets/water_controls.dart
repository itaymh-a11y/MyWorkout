import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/presentation/goals_screen.dart';

class WaterControls extends ConsumerWidget {
  const WaterControls({
    super.key,
    required this.dayKey,
    this.showGoal = true,
  });

  final String dayKey;
  final bool showGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterForDayProvider(dayKey));
    final goalsAsync = ref.watch(goalsProvider);
    final theme = Theme.of(context);

    if (waterAsync.isLoading || (showGoal && goalsAsync.isLoading)) {
      return const AccentCard(
        accent: ContentAccent.calendar,
        child: LinearProgressIndicator(),
      );
    }
    if (waterAsync.hasError) {
      return AccentCard(
        accent: ContentAccent.calendar,
        child: Text('לא נטענה שתייה: ${waterAsync.error}'),
      );
    }

    final water = waterAsync.value!;
    final goalMl = goalsAsync.valueOrNull?.waterGoalMl;
    final hasGoal = showGoal && goalMl != null && goalMl > 0;
    final progress = hasGoal ? (water.totalMl / goalMl).clamp(0.0, 1.0) : null;

    return AccentCard(
      accent: ContentAccent.calendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasGoal
                ? '${formatLitersFromMl(water.totalMl)} / ${formatLitersFromMl(goalMl)} ל׳'
                : '${formatLitersFromMl(water.totalMl)} ל׳',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: AppColors.navyMid,
                backgroundColor: AppColors.silverLight,
              ),
            ),
          ],
          if (showGoal && !hasGoal) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => GoalsScreen.open(context),
                child: const Text('הגדר יעד מים'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _add(context, ref, 250),
                child: const Text('+250 מ״ל'),
              ),
              FilledButton.tonal(
                onPressed: () => _add(context, ref, 500),
                child: const Text('+500 מ״ל'),
              ),
              if (water.sipsMl.isNotEmpty)
                TextButton(
                  onPressed: () => _undo(context, ref),
                  child: const Text('בטל מנה'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, int ml) async {
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(waterRepositoryProvider).addSip(uid, dayKey, ml);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נוסף: $error')),
        );
      }
    }
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(waterRepositoryProvider).removeLastSip(uid, dayKey);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא בוטל: $error')),
        );
      }
    }
  }
}

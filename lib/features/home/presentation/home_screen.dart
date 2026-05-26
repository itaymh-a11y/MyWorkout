import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/core/widgets/section_header.dart';
import 'package:myworkout/features/home/application/home_providers.dart';
import 'package:myworkout/features/home/presentation/widgets/starred_plan_card.dart';
import 'package:myworkout/features/home/presentation/widgets/weekly_summary_card.dart';
import 'package:myworkout/features/workout/application/session_list_providers.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/plans/data/plan_repository.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';
import 'package:myworkout/features/workout/presentation/live_workout_screen.dart';
import 'package:myworkout/features/workout/presentation/plan_picker_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isWorkoutActiveProvider);
    final starred = ref.watch(starredPlansProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.ember,
      onRefresh: () async {
        ref.invalidate(plansProvider);
        ref.invalidate(currentWeekSessionsProvider);
        ref.invalidate(allSessionsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isActive)
            AccentCard(
              accent: ContentAccent.workout,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.emberLight,
                  child: Icon(Icons.play_circle_fill, color: AppColors.ember),
                ),
                title: const Text('יש אימון פעיל'),
                subtitle: const Text('המשך מהבאנר למעלה או מהכפתור'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiveWorkoutScreen(),
                    ),
                  );
                },
              ),
            ),
          const WeeklySummaryCard(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (isActive) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LiveWorkoutScreen(),
                  ),
                );
              } else {
                PlanPickerSheet.show(context);
              }
            },
            icon: Icon(isActive ? Icons.play_arrow : Icons.bolt),
            label: Text(isActive ? 'המשך אימון' : 'התחל אימון (כל התוכניות)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'תוכניות מועדפות',
            subtitle:
                'סמן עד ${PlanRepository.maxStarredPlans} תוכניות בכוכב בטאב תוכניות',
            accent: ContentAccent.plan,
            icon: Icons.star,
          ),
          const SizedBox(height: 8),
          if (starred.isEmpty)
            AccentCard(
              accent: ContentAccent.plan,
              child: Column(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 40,
                    color: AppColors.silver,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'אין תוכניות מועדפות',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'לחץ על הכוכב ליד תוכנית בטאב תוכניות כדי להציג אותה כאן',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            for (final plan in starred) StarredPlanCard(plan: plan),
        ],
      ),
    );
  }
}

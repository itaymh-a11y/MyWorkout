import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/features/home/domain/weekly_summary.dart';
import 'package:myworkout/features/workout/application/session_list_providers.dart';

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(currentWeekSessionsProvider);
    final theme = Theme.of(context);
    final brand = context.brand;

    return weekAsync.when(
      loading: () => const AccentCard(
        accent: ContentAccent.workout,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => AccentCard(
        accent: ContentAccent.workout,
        child: Text('לא נטען סיכום שבועי: $e'),
      ),
      data: (sessions) {
        final summary = buildWeeklySummary(sessions);
        return AccentCard(
          accent: ContentAccent.workout,
          color: AppColors.emberMuted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_view_week,
                      color: brand.workout,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'סיכום השבוע',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ראשון – שבת · ${formatWeekRange(summary.weekStart, summary.weekEnd)}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.totalWorkouts == 0
                    ? 'עדיין לא בוצעו אימונים השבוע'
                    : 'ביצעת ${summary.totalWorkouts} אימונים השבוע',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.emberDark,
                ),
              ),
              if (summary.byPlan.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                for (final row in summary.byPlan)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: brand.workout,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            row.planName,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ember,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${row.count}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

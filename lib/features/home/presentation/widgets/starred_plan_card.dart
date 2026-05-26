import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/features/home/application/home_providers.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

class StarredPlanCard extends ConsumerWidget {
  const StarredPlanCard({
    super.key,
    required this.plan,
  });

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastSessionForPlanProvider(plan.id));
    final theme = Theme.of(context);
    final brand = context.brand;

    return AccentCard(
      accent: ContentAccent.plan,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: brand.star, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          lastAsync.when(
            data: (data) {
              if (data == null) {
                return Text(
                  'עדיין לא בוצע אימון עם תוכנית זו',
                  style: theme.textTheme.bodyMedium,
                );
              }
              final session = data.session;
              final grouped = groupSetsByExercise(data.sets);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: brand.contentSurface(ContentAccent.workout),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'אימון אחרון: ${formatSessionDate(session.startedAt)} · ${formatDuration(session.durationSec)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: brand.workout,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in grouped.entries) ...[
                    Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: brand.exercise,
                      ),
                    ),
                    Text(
                      entry.value.join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'לא נטען סיכום: $e',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

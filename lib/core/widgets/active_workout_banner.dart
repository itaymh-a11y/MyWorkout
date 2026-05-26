import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';
import 'package:myworkout/features/workout/presentation/live_workout_screen.dart';

/// באנר אימון פעיל — מוצג מעל כל הטאבים.
class ActiveWorkoutBanner extends ConsumerWidget {
  const ActiveWorkoutBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    if (session == null) return const SizedBox.shrink();

    ref.watch(workoutTickProvider);

    return Material(
      color: AppColors.ember,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LiveWorkoutScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'אימון פעיל',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${session.elapsedMinutes} דק׳ · ${session.planName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

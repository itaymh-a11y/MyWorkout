import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';
import 'package:myworkout/features/workout/presentation/widgets/live_set_row.dart';
import 'package:myworkout/features/workout/presentation/widgets/rest_timer_overlay.dart';

class LiveWorkoutScreen extends ConsumerWidget {
  const LiveWorkoutScreen({super.key});

  String _formatElapsed(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('סיום אימון'),
        content: const Text('לסיים ולשמור את האימון?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('סיום'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ref.read(sessionControllerProvider.notifier).finishWorkout();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ביטול אימון'),
        content: const Text('למחוק את הטיוטה ולבטל את האימון?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('לא'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('בטל אימון'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(sessionControllerProvider.notifier).cancelWorkout();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(workoutTickProvider);
    final session = ref.watch(sessionControllerProvider);

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('אין אימון פעיל')),
      );
    }

    final controller = ref.read(sessionControllerProvider.notifier);
    String? currentExercise;
    final children = <Widget>[];

    for (var i = 0; i < session.sets.length; i++) {
      final entry = session.sets[i];
      if (entry.exerciseName != currentExercise) {
        currentExercise = entry.exerciseName;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.brand.contentSurface(ContentAccent.exercise),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  right: BorderSide(
                    color: context.brand.exercise,
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                entry.exerciseName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
              ),
            ),
          ),
        );
      }

      children.add(
        LiveSetRow(
          key: ValueKey('${entry.exerciseId}_${entry.setIndex}'),
          entry: entry,
          onChanged: (updated) => controller.updateSet(i, updated),
          onToggleComplete: () => controller.toggleSetComplete(i),
        ),
      );

      final isLastOfExercise = i == session.sets.length - 1 ||
          session.sets[i + 1].exerciseId != entry.exerciseId;
      if (isLastOfExercise) {
        children.add(
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => controller.addSetForExercise(entry.exerciseId),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('הוסף סט'),
            ),
          ),
        );
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('יציאה מאימון'),
            content: const Text(
              'האימון נשמר כטיוטה. לצאת מהמסך?\n(תוכל להמשיך מהבאנר)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('המשך אימון'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('יציאה'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.warmBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.planName),
            Text(
              _formatElapsed(session.elapsedSec),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmCancel(context, ref),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('בטל'),
          ),
          FilledButton(
            onPressed: () => _confirmFinish(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('סיום'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: children,
          ),
          const RestTimerOverlay(),
        ],
      ),
    ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';

/// טיימר מנוחה צף עם +30 / -30 / דילוג.
class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(workoutTickProvider);
    final session = ref.watch(sessionControllerProvider);
    if (session == null || !session.isResting) {
      return const SizedBox.shrink();
    }

    final remaining = session.restRemainingSec ?? 0;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'מנוחה',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!session.restAlarmEnabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    'צליל סיום מנוחה כבוי',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  _formatTime(remaining),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .adjustRest(-30),
                      child: const Text('-30'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .skipRest(),
                      child: const Text('דילוג'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .adjustRest(30),
                      child: const Text('+30'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

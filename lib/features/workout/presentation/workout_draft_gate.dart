import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/workout/application/session_providers.dart';
import 'package:myworkout/features/workout/presentation/live_workout_screen.dart';

/// בודק טיוטה ישנה מ-24 שעות בפתיחת האפליקציה.
class WorkoutDraftGate extends ConsumerStatefulWidget {
  const WorkoutDraftGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WorkoutDraftGate> createState() => _WorkoutDraftGateState();
}

class _WorkoutDraftGateState extends ConsumerState<WorkoutDraftGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStaleDraft());
  }

  Future<void> _checkStaleDraft() async {
    if (_checked) return;
    _checked = true;

    final controller = ref.read(sessionControllerProvider.notifier);
    await controller.loadDraftIfNeeded();
    final stale = await controller.shouldPromptStaleDraft();
    if (!stale || !mounted) return;

    final draft = ref.read(sessionControllerProvider);
    if (draft == null) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('טיוטת אימון ישנה'),
        content: Text(
          'נמצאה טיוטה מ-${draft.planName} שלא נסגרה.\nלהמשיך או למחוק?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('מחק'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: const Text('המשך אימון'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'delete') {
      await controller.discardStaleDraft();
      await controller.cancelWorkout();
    } else if (action == 'continue') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LiveWorkoutScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

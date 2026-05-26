import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/workout/application/session_controller.dart';
import 'package:myworkout/features/workout/domain/live_workout_state.dart';

final sessionControllerProvider =
    StateNotifierProvider<SessionController, LiveWorkoutState?>((ref) {
  return SessionController(ref);
});

/// טיק כל שנייה כשיש אימון פעיל — לסטופר וטיימר מנוחה מבוססי שעון.
final workoutTickProvider = StreamProvider<void>((ref) {
  final active = ref.watch(sessionControllerProvider);
  if (active == null) {
    return const Stream.empty();
  }

  return Stream.periodic(const Duration(seconds: 1), (_) {
    ref.read(sessionControllerProvider.notifier).onTick();
  });
});

final isWorkoutActiveProvider = Provider<bool>((ref) {
  return ref.watch(sessionControllerProvider) != null;
});

final workoutElapsedMinutesProvider = Provider<int>((ref) {
  ref.watch(workoutTickProvider);
  return ref.watch(sessionControllerProvider)?.elapsedMinutes ?? 0;
});

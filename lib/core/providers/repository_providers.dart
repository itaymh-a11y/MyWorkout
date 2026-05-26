import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/auth/application/auth_providers.dart';
import 'package:myworkout/features/exercises/data/exercise_repository.dart';
import 'package:myworkout/features/plans/data/plan_repository.dart';
import 'package:myworkout/features/workout/data/session_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

/// מזהה המשתמש המחובר — זורק אם אין התחברות.
final currentUidProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('User must be signed in');
  }
  return user.uid;
});

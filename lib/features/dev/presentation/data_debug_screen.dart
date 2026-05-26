import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

/// מסך בדיקות לשלב 2 — CRUD ידני מול Firestore.
class DataDebugScreen extends ConsumerStatefulWidget {
  const DataDebugScreen({super.key});

  @override
  ConsumerState<DataDebugScreen> createState() => _DataDebugScreenState();
}

class _DataDebugScreenState extends ConsumerState<DataDebugScreen> {
  final _logs = <String>[];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} $message');
    });
  }

  Future<void> _run(Future<void> Function() action, String successLabel) async {
    try {
      await action();
      _log('✓ $successLabel');
    } catch (e) {
      _log('✗ $successLabel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('בדיקות נתונים (שלב 2)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run(() async {
                    final list = await ref
                        .read(exerciseRepositoryProvider)
                        .fetchBuiltinExercisesOnce();
                    _log('  → נמצאו ${list.length} תרגילים מובנים');
                    if (list.isEmpty) {
                      throw Exception(
                        'אין תרגילים — הרץ scripts/seed-builtin.mjs',
                      );
                    }
                  }, 'טען תרגילים מובנים'),
                  child: const Text('Builtin'),
                ),
                FilledButton(
                  onPressed: () => _run(() async {
                    final id = await ref
                        .read(exerciseRepositoryProvider)
                        .createUserExercise(
                          uid,
                          Exercise(
                            id: '',
                            source: ExerciseSource.custom,
                            name: 'תרגיל בדיקה ${DateTime.now().millisecond}',
                            categoryId: 'push',
                            exerciseType: ExerciseType.weightReps,
                            muscleTags: const ['חזה'],
                            defaultSets: 3,
                            defaultReps: 10,
                            defaultWeightKg: 20,
                          ),
                        );
                    _log('  → נוצר user exercise: $id');
                  }, 'צור תרגיל מותאם'),
                  child: const Text('תרגיל+'),
                ),
                FilledButton(
                  onPressed: () => _run(() async {
                    final builtin = await ref
                        .read(exerciseRepositoryProvider)
                        .fetchBuiltinExercisesOnce();
                    if (builtin.isEmpty) {
                      throw Exception('אין builtin — seed קודם');
                    }
                    final bench = builtin.firstWhere(
                      (e) => e.id == 'bench_press',
                      orElse: () => builtin.first,
                    );

                    final planRepo = ref.read(planRepositoryProvider);
                    final planId = await planRepo.createPlan(
                      uid,
                      WorkoutPlan(
                        id: '',
                        name: 'תוכנית בדיקה',
                        defaultRestSec: 90,
                      ),
                    );

                    await planRepo.setPlanExercises(
                      uid,
                      planId,
                      [
                        PlanExercise(
                          id: 'order_001',
                          exerciseId: bench.compositeId,
                          exerciseName: bench.name,
                          order: 1,
                          exerciseType: bench.exerciseType,
                          setsCount: 3,
                          targetWeightKg: 60,
                          targetReps: 8,
                        ),
                      ],
                    );
                    _log('  → תוכנית: $planId');
                  }, 'צור תוכנית לדוגמה'),
                  child: const Text('תוכנית+'),
                ),
                FilledButton(
                  onPressed: () => _run(() async {
                    final sessionRepo = ref.read(sessionRepositoryProvider);
                    final started = DateTime.now().subtract(
                      const Duration(minutes: 45),
                    );
                    final ended = DateTime.now();
                    final sessionId = await sessionRepo.saveCompletedSession(
                      uid,
                      WorkoutSession(
                        id: '',
                        planId: 'debug_plan',
                        planName: 'אימון בדיקה',
                        startedAt: started,
                        endedAt: ended,
                        durationSec: ended.difference(started).inSeconds,
                      ),
                      [
                        WorkoutSet(
                          id: '',
                          exerciseId: 'builtin_bench_press',
                          exerciseName: 'לחיצת חזה',
                          exerciseType: ExerciseType.weightReps,
                          setIndex: 1,
                          targetWeightKg: 60,
                          targetReps: 8,
                          actualWeightKg: 62.5,
                          actualReps: 8,
                          completed: true,
                        ),
                        WorkoutSet(
                          id: '',
                          exerciseId: 'builtin_bench_press',
                          exerciseName: 'לחיצת חזה',
                          exerciseType: ExerciseType.weightReps,
                          setIndex: 2,
                          targetWeightKg: 60,
                          targetReps: 8,
                          actualWeightKg: 62.5,
                          actualReps: 7,
                          completed: true,
                        ),
                      ],
                    );
                    _log('  → session: $sessionId');
                  }, 'שמור אימון לדוגמה'),
                  child: const Text('Session+'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'לחץ על כפתור לבדיקה.\nuid: $uid',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _logs[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

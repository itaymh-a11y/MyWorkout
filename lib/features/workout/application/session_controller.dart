import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/workout/application/rest_alarm_player.dart';
import 'package:myworkout/features/workout/data/session_repository.dart';
import 'package:myworkout/features/workout/data/workout_draft_repository.dart';
import 'package:myworkout/features/workout/domain/live_set_entry.dart';
import 'package:myworkout/features/workout/domain/live_workout_state.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

class SessionController extends StateNotifier<LiveWorkoutState?> {
  SessionController(this._ref) : super(null);

  final Ref _ref;
  final _draftRepo = WorkoutDraftRepository();
  final _restAlarmPlayer = RestAlarmPlayer();
  bool _restAlarmPlayed = false;
  bool _draftLoaded = false;

  @override
  void dispose() {
    _restAlarmPlayer.dispose();
    super.dispose();
  }

  WorkoutDraftRepository get draftRepository => _draftRepo;

  /// טוען טיוטה מ-Hive פעם אחת (לא ב-constructor — כדי לא לשבור טסטים).
  Future<void> loadDraftIfNeeded() async {
    if (_draftLoaded) return;
    _draftLoaded = true;
    try {
      final draft = await _draftRepo.loadDraft();
      if (draft != null) {
        state = draft;
      }
    } catch (_) {
      // Hive לא זמין — מדלגים.
    }
  }

  Future<bool> shouldPromptStaleDraft() async {
    final draft = await _draftRepo.loadDraft();
    if (draft == null) return false;
    return _draftRepo.isOlderThan24Hours(draft);
  }

  Future<void> discardStaleDraft() => _draftRepo.clearDraft();

  Future<void> resumeDraft(LiveWorkoutState draft) async {
    state = draft;
    await _persistDraft();
  }

  Future<void> startWorkout({
    required String uid,
    required WorkoutPlan plan,
    required List<PlanExercise> planExercises,
  }) async {
    SessionWithSets? previous;
    try {
      previous = await _ref
          .read(sessionRepositoryProvider)
          .getLastCompletedSessionForPlan(uid, plan.id);
    } catch (_) {
      // אם Firestore נכשל (למשל אינדקס חסר) — ממשיכים בלי רמזים מאימון קודם.
      previous = null;
    }

    final prevMap = <String, WorkoutSet>{};
    if (previous != null) {
      for (final s in previous.sets.where((set) => set.completed)) {
        prevMap['${s.exerciseId}_${s.setIndex}'] = s;
      }
    }

    final liveSets = <LiveSetEntry>[];
    for (var i = 0; i < planExercises.length; i++) {
      final pe = planExercises[i];
      for (var s = 1; s <= pe.setsCount; s++) {
        final key = '${pe.exerciseId}_$s';
        final prev = prevMap[key];

        liveSets.add(
          LiveSetEntry(
            exerciseId: pe.exerciseId,
            exerciseName: pe.exerciseName,
            exerciseType: pe.exerciseType,
            setIndex: s,
            isLastSetOfExercise: false,
            targetWeightKg: pe.targetWeightKg,
            targetReps: pe.targetReps,
            targetTimeSec: pe.targetTimeSec,
            actualWeightKg: pe.targetWeightKg,
            actualReps: pe.targetReps,
            actualTimeSec: pe.targetTimeSec,
            previousWeightKg: prev?.actualWeightKg,
            previousReps: prev?.actualReps,
            previousTimeSec: prev?.actualTimeSec,
            restSec: pe.restSec ?? plan.defaultRestSec,
            completed: false,
          ),
        );
      }
    }

    // Fix isLastSetOfExercise per exercise group
    final fixed = _markLastSetsPerExercise(liveSets);

    state = LiveWorkoutState(
      uid: uid,
      planId: plan.id,
      planName: plan.name,
      defaultRestSec: plan.defaultRestSec,
      startedAt: DateTime.now(),
      sets: fixed,
    );
    await _persistDraft();
  }

  List<LiveSetEntry> _markLastSetsPerExercise(List<LiveSetEntry> sets) {
    if (sets.isEmpty) return sets;
    final result = <LiveSetEntry>[];
    for (var i = 0; i < sets.length; i++) {
      final current = sets[i];
      final nextDifferent = i == sets.length - 1 ||
          sets[i + 1].exerciseId != current.exerciseId;
      result.add(
        LiveSetEntry(
          exerciseId: current.exerciseId,
          exerciseName: current.exerciseName,
          exerciseType: current.exerciseType,
          setIndex: current.setIndex,
          isLastSetOfExercise: nextDifferent,
          targetWeightKg: current.targetWeightKg,
          targetReps: current.targetReps,
          targetTimeSec: current.targetTimeSec,
          actualWeightKg: current.actualWeightKg,
          actualReps: current.actualReps,
          actualTimeSec: current.actualTimeSec,
          previousWeightKg: current.previousWeightKg,
          previousReps: current.previousReps,
          previousTimeSec: current.previousTimeSec,
          restSec: current.restSec,
          completed: current.completed,
        ),
      );
    }
    return result;
  }

  void onTick() {
    final current = state;
    if (current == null) return;

    if (current.isResting) {
      state = current.copyWith();
      return;
    }

    if (current.restEndsAt != null &&
        !DateTime.now().isBefore(current.restEndsAt!)) {
      _onRestFinished();
      state = current.copyWith(clearRest: true);
      _persistDraft();
      return;
    }

    state = current.copyWith();
  }

  void _onRestFinished() {
    if (_restAlarmPlayed) return;
    _restAlarmPlayed = true;
    final enabled = state?.restAlarmEnabled ?? true;
    if (!enabled) return;

    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
    _restAlarmPlayer.play();
  }

  void toggleRestAlarm() {
    if (state == null) return;
    final next = !state!.restAlarmEnabled;
    if (!next) {
      _restAlarmPlayer.stop();
    }
    state = state!.copyWith(restAlarmEnabled: next);
    _persistDraft();
  }

  Future<void> updateSet(int index, LiveSetEntry updated) async {
    if (state == null) return;
    final sets = List<LiveSetEntry>.from(state!.sets);
    sets[index] = updated;
    state = state!.copyWith(sets: sets);
    await _persistDraft();
  }

  /// מוסיף סט נוסף בסוף קבוצת התרגיל (מעתיק יעדים/ביצוע מהסט האחרון).
  Future<void> addSetForExercise(String exerciseId) async {
    if (state == null) return;
    final sets = List<LiveSetEntry>.from(state!.sets);
    final lastIndex = sets.lastIndexWhere((s) => s.exerciseId == exerciseId);
    if (lastIndex < 0) return;

    final last = sets[lastIndex];
    final newSet = LiveSetEntry(
      exerciseId: last.exerciseId,
      exerciseName: last.exerciseName,
      exerciseType: last.exerciseType,
      setIndex: last.setIndex + 1,
      isLastSetOfExercise: true,
      targetWeightKg: last.targetWeightKg,
      targetReps: last.targetReps,
      targetTimeSec: last.targetTimeSec,
      actualWeightKg: last.actualWeightKg,
      actualReps: last.actualReps,
      actualTimeSec: last.actualTimeSec,
      previousWeightKg: last.previousWeightKg,
      previousReps: last.previousReps,
      previousTimeSec: last.previousTimeSec,
      restSec: last.restSec,
      completed: false,
    );

    sets.insert(lastIndex + 1, newSet);
    state = state!.copyWith(sets: _markLastSetsPerExercise(sets));
    await _persistDraft();
  }

  Future<void> toggleSetComplete(int index) async {
    if (state == null) return;
    final sets = List<LiveSetEntry>.from(state!.sets);
    final entry = sets[index];
    final newCompleted = !entry.completed;
    sets[index] = entry.copyWith(completed: newCompleted);
    state = state!.copyWith(sets: sets, clearRest: true);

    if (newCompleted && !entry.isLastSetOfExercise) {
      final restSec = entry.restSec ?? state!.defaultRestSec;
      final ends = DateTime.now().add(Duration(seconds: restSec));
      state = state!.copyWith(
        restEndsAt: ends,
        restStartedAt: DateTime.now(),
        restDurationSec: restSec,
      );
      _restAlarmPlayed = false;
    }

    await _persistDraft();
  }

  void skipRest() {
    if (state == null) return;
    _restAlarmPlayer.stop();
    _restAlarmPlayed = true;
    state = state!.copyWith(clearRest: true);
    _persistDraft();
  }

  void adjustRest(int deltaSec) {
    if (state == null || state!.restEndsAt == null) return;
    final newEnd = state!.restEndsAt!.add(Duration(seconds: deltaSec));
    final newDuration = (state!.restDurationSec + deltaSec).clamp(0, 9999);
    state = state!.copyWith(
      restEndsAt: newEnd,
      restDurationSec: newDuration,
    );
    _persistDraft();
  }

  Future<String?> finishWorkout() async {
    final current = state;
    if (current == null) return null;

    final ended = DateTime.now();
    final durationSec = ended.difference(current.startedAt).inSeconds;

    final session = WorkoutSession(
      id: '',
      planId: current.planId,
      planName: current.planName,
      startedAt: current.startedAt,
      endedAt: ended,
      durationSec: durationSec,
    );

    final firestoreSets = current.sets.map((e) {
      final didComplete = e.completed;
      return WorkoutSet(
        id: '',
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        exerciseType: e.exerciseType,
        setIndex: e.setIndex,
        targetWeightKg: e.targetWeightKg,
        targetReps: e.targetReps,
        targetTimeSec: e.targetTimeSec,
        // סט שלא סומן כבוצע נשמר כ"לא בוצע" ללא ביצוע בפועל.
        actualWeightKg: didComplete ? e.actualWeightKg : null,
        actualReps: didComplete ? e.actualReps : null,
        actualTimeSec: didComplete ? e.actualTimeSec : null,
        completed: didComplete,
      );
    }).toList();

    final sessionId = await _ref.read(sessionRepositoryProvider).saveCompletedSession(
          current.uid,
          session,
          firestoreSets,
        );

    await _restAlarmPlayer.stop();
    await _draftRepo.clearDraft();
    state = null;
    return sessionId;
  }

  Future<void> cancelWorkout() async {
    await _restAlarmPlayer.stop();
    await _draftRepo.clearDraft();
    state = null;
  }

  Future<void> _persistDraft() async {
    if (state != null) {
      await _draftRepo.saveDraft(state!);
    }
  }
}

/// תצוגת ביצוע מהאימון האחרון (עמודה ייעודית במסך אימון פעיל).
String previousPerformanceForSet(LiveSetEntry entry) {
  switch (entry.exerciseType) {
    case ExerciseType.weightReps:
      if (entry.previousWeightKg == null && entry.previousReps == null) {
        return '—';
      }
      return '${_fmtWeight(entry.previousWeightKg)} ק"ג × ${_fmtInt(entry.previousReps)}';
    case ExerciseType.repsOnly:
      if (entry.previousReps == null) return '—';
      return '${entry.previousReps} חזרות';
    case ExerciseType.time:
      if (entry.previousTimeSec == null) return '—';
      return _fmtTime(entry.previousTimeSec!);
  }
}

String _fmtWeight(double? kg) {
  if (kg == null) return '-';
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  return kg.toString();
}

String _fmtInt(int? n) => n?.toString() ?? '-';

String _fmtTime(int sec) {
  final m = sec ~/ 60;
  final s = sec % 60;
  if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
  return '$sש׳';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/exercises/domain/exercise_stats.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/workout_session.dart';
import 'package:myworkout/shared/models/workout_set.dart';

class SessionWithSets {
  const SessionWithSets({required this.session, required this.sets});

  final WorkoutSession session;
  final List<WorkoutSet> sets;
}

class SessionRepository {
  SessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _firestore.collection(FirestorePaths.userSessions(uid));

  CollectionReference<Map<String, dynamic>> _sets(
    String uid,
    String sessionId,
  ) =>
      _firestore.collection(FirestorePaths.sessionSets(uid, sessionId));

  Stream<List<WorkoutSession>> watchSessions(String uid) {
    return _sessions(uid)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(WorkoutSession.fromFirestore).toList(),
        );
  }

  Stream<List<WorkoutSession>> watchSessionsInRange(
    String uid, {
    required DateTime start,
    required DateTime end,
  }) {
    return _sessions(uid)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(WorkoutSession.fromFirestore).toList(),
        );
  }

  /// האימון האחרון שהושלם עבור תוכנית מסוימת.
  ///
  /// מסנן לפי [planId] בלבד (ללא orderBy מורכב) וממיין בזיכרון —
  /// כך לא נדרש אינדקס מורכב ב-Firestore לפני האימון הראשון.
  Future<SessionWithSets?> getLastCompletedSessionForPlan(
    String uid,
    String planId,
  ) async {
    final snapshot =
        await _sessions(uid).where('planId', isEqualTo: planId).get();

    if (snapshot.docs.isEmpty) return null;

    final completed = snapshot.docs
        .map(WorkoutSession.fromFirestore)
        .where((s) => s.status == SessionStatus.completed)
        .toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    if (completed.isEmpty) return null;

    final session = completed.first;
    final sessionDoc = snapshot.docs.firstWhere((d) => d.id == session.id);
    final setsSnapshot = await _sets(uid, sessionDoc.id)
        .orderBy('setIndex')
        .get();

    return SessionWithSets(
      session: WorkoutSession.fromFirestore(sessionDoc),
      sets: setsSnapshot.docs.map(WorkoutSet.fromFirestore).toList(),
    );
  }

  Future<SessionWithSets?> getSessionWithSets(
    String uid,
    String sessionId,
  ) async {
    final sessionDoc = await _sessions(uid).doc(sessionId).get();
    if (!sessionDoc.exists) return null;

    final setsSnapshot = await _sets(uid, sessionId)
        .orderBy('setIndex')
        .get();

    return SessionWithSets(
      session: WorkoutSession.fromFirestore(sessionDoc),
      sets: setsSnapshot.docs.map(WorkoutSet.fromFirestore).toList(),
    );
  }

  /// שומר אימון שהושלם + כל הסטים בבת אחת (Immutable).
  Future<String> saveCompletedSession(
    String uid,
    WorkoutSession session,
    List<WorkoutSet> sets,
  ) async {
    final sessionRef = session.id.isNotEmpty
        ? _sessions(uid).doc(session.id)
        : _sessions(uid).doc();

    final batch = _firestore.batch();

    batch.set(sessionRef, session.toMap());

    for (var i = 0; i < sets.length; i++) {
      final set = sets[i];
      final setRef = set.id.isNotEmpty
          ? _sets(uid, sessionRef.id).doc(set.id)
          : _sets(uid, sessionRef.id).doc();
      batch.set(setRef, set.toMap());
    }

    await batch.commit();
    return sessionRef.id;
  }

  /// היסטוריה ושיאים לתרגיל — סורק אימונים ומסנן סטים בזיכרון (ללא אינדקס collection group).
  Stream<ExerciseStatsData> watchExerciseStats(
    String uid,
    String exerciseId,
    ExerciseType exerciseType,
  ) async* {
    await for (final sessions in watchSessions(uid)) {
      final history = <ExerciseSessionHistory>[];

      for (final session in sessions) {
        if (session.status != SessionStatus.completed) continue;

        final setsSnapshot = await _sets(uid, session.id).get();
        final matching = setsSnapshot.docs
            .map(WorkoutSet.fromFirestore)
            .where((s) => s.exerciseId == exerciseId)
            .toList();
        if (matching.isEmpty) continue;

        matching.sort((a, b) => a.setIndex.compareTo(b.setIndex));
        history.add(ExerciseSessionHistory(session: session, sets: matching));
      }

      history.sort((a, b) => b.session.startedAt.compareTo(a.session.startedAt));
      final allSets = history.expand((h) => h.sets).toList();
      yield ExerciseStatsData(
        history: history,
        records: computePersonalRecords(allSets, exerciseType),
      );
    }
  }

  /// מוחק אימון וכל הסטים שלו מ-Firestore.
  Future<void> deleteSession(String uid, String sessionId) async {
    final setsSnapshot = await _sets(uid, sessionId).get();
    final batch = _firestore.batch();
    for (final doc in setsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessions(uid).doc(sessionId));
    await batch.commit();
  }
}

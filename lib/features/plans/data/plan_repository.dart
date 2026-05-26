import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

class PlanRepository {
  PlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int maxStarredPlans = 3;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _plans(String uid) =>
      _firestore.collection(FirestorePaths.userPlans(uid));

  CollectionReference<Map<String, dynamic>> _planExercises(
    String uid,
    String planId,
  ) =>
      _firestore.collection(FirestorePaths.planExercises(uid, planId));

  Stream<List<WorkoutPlan>> watchPlans(String uid) {
    return _plans(uid).orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(WorkoutPlan.fromFirestore)
              .toList(),
        );
  }

  Stream<List<PlanExercise>> watchPlanExercises(String uid, String planId) {
    return _planExercises(uid, planId)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PlanExercise.fromFirestore).toList(),
        );
  }

  Future<List<PlanExercise>> fetchPlanExercises(String uid, String planId) async {
    final snapshot =
        await _planExercises(uid, planId).orderBy('order').get();
    return snapshot.docs.map(PlanExercise.fromFirestore).toList();
  }

  Future<String> createPlan(String uid, WorkoutPlan plan) async {
    final docRef =
        plan.id.isNotEmpty ? _plans(uid).doc(plan.id) : _plans(uid).doc();
    await docRef.set(plan.toMap());
    return docRef.id;
  }

  Future<void> updatePlan(String uid, WorkoutPlan plan) async {
    await _plans(uid).doc(plan.id).update({
      ...plan.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String uid, String planId) async {
    final exercises = await _planExercises(uid, planId).get();
    final batch = _firestore.batch();
    for (final doc in exercises.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_plans(uid).doc(planId));
    await batch.commit();
  }

  Future<void> setPlanExercises(
    String uid,
    String planId,
    List<PlanExercise> exercises,
  ) async {
    final existing = await _planExercises(uid, planId).get();
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final exercise in exercises) {
      final docId = exercise.id.isNotEmpty
          ? exercise.id
          : 'order_${exercise.order.toString().padLeft(3, '0')}';
      batch.set(_planExercises(uid, planId).doc(docId), exercise.toMap());
    }

    await batch.commit();
  }

  Future<int> countStarredPlans(String uid, {String? excludePlanId}) async {
    final snapshot =
        await _plans(uid).where('isStarred', isEqualTo: true).get();
    if (excludePlanId == null) return snapshot.docs.length;
    return snapshot.docs.where((d) => d.id != excludePlanId).length;
  }

  /// מסמן תוכנית כמועדפת — עד [maxStarredPlans] במקביל.
  Future<void> setStarred(
    String uid,
    String planId, {
    required bool starred,
  }) async {
    if (starred) {
      final count = await countStarredPlans(uid, excludePlanId: planId);
      if (count >= maxStarredPlans) {
        throw PlanRepositoryException(
          'ניתן לסמן עד $maxStarredPlans תוכניות פעילות (כוכב).',
        );
      }
    }
    await _plans(uid).doc(planId).update({
      'isStarred': starred,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class PlanRepositoryException implements Exception {
  PlanRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

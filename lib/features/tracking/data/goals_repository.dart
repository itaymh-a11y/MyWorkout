import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/tracking/domain/daily_goals.dart';

class GoalsRepository {
  GoalsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.doc(FirestorePaths.userGoals(uid));

  Stream<DailyGoals> watchGoals(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return const DailyGoals();
      return DailyGoals.fromMap(snapshot.data() ?? {});
    });
  }

  Future<void> saveGoals(String uid, DailyGoals goals) {
    return _doc(uid).set(goals.toMap());
  }
}

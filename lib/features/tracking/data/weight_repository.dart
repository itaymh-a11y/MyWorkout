import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';

class WeightRepository {
  WeightRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection(FirestorePaths.weightLogs(uid));

  Stream<List<WeightLog>> watchLogs(String uid) {
    return _logs(uid).orderBy('weighedAt').snapshots().map(
          (snapshot) => snapshot.docs.map(WeightLog.fromFirestore).toList(),
        );
  }

  /// שקילה אחת ליום: שמירה חוזרת לאותו יום מחליפה את הקודמת.
  Future<void> upsertForDay({
    required String uid,
    required String dayKey,
    required DateTime weighedAt,
    required double kg,
  }) async {
    final existing =
        await _logs(uid).where('dayKey', isEqualTo: dayKey).limit(1).get();
    final data = WeightLog(
      id: existing.docs.isEmpty ? '' : existing.docs.first.id,
      dayKey: dayKey,
      weighedAt: weighedAt,
      kg: kg,
    ).toMap();
    if (existing.docs.isEmpty) {
      await _logs(uid).doc().set(data);
    } else {
      await existing.docs.first.reference.set(data);
    }
  }

  Future<void> deleteLog(String uid, String logId) {
    return _logs(uid).doc(logId).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_paths.dart';
import 'package:myworkout/features/tracking/domain/water_day.dart';

class WaterRepository {
  WaterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _days(String uid) =>
      _firestore.collection(FirestorePaths.waterDays(uid));

  DocumentReference<Map<String, dynamic>> _day(String uid, String dayKey) =>
      _firestore.doc(FirestorePaths.waterDay(uid, dayKey));

  Stream<WaterDay> watchDay(String uid, String dayKey) {
    return _day(uid, dayKey).snapshots().map((snapshot) {
      if (!snapshot.exists) return WaterDay(dayKey: dayKey);
      return WaterDay.fromMap(snapshot.data() ?? {}, dayKey: dayKey);
    });
  }

  Stream<List<WaterDay>> watchDaysInRange(
    String uid, {
    required String startDay,
    required String endDay,
  }) {
    return _days(uid)
        .where('dayKey', isGreaterThanOrEqualTo: startDay)
        .where('dayKey', isLessThanOrEqualTo: endDay)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WaterDay.fromMap(doc.data(), dayKey: doc.id))
              .toList(),
        );
  }

  Future<void> addSip(String uid, String dayKey, int ml) {
    return _firestore.runTransaction((tx) async {
      final ref = _day(uid, dayKey);
      final snapshot = await tx.get(ref);
      final current = snapshot.exists
          ? WaterDay.fromMap(snapshot.data() ?? {}, dayKey: dayKey)
          : WaterDay(dayKey: dayKey);
      tx.set(ref, {
        'dayKey': dayKey,
        'sipsMl': [...current.sipsMl, ml],
      });
    });
  }

  Future<void> removeLastSip(String uid, String dayKey) {
    return _firestore.runTransaction((tx) async {
      final ref = _day(uid, dayKey);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      final current = WaterDay.fromMap(snapshot.data() ?? {}, dayKey: dayKey);
      if (current.sipsMl.isEmpty) return;
      tx.set(ref, {
        'dayKey': dayKey,
        'sipsMl': current.sipsMl.sublist(0, current.sipsMl.length - 1),
      });
    });
  }
}

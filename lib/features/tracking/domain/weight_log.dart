import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

class WeightLog {
  const WeightLog({
    required this.id,
    required this.dayKey,
    required this.weighedAt,
    required this.kg,
  });

  final String id;
  final String dayKey;
  final DateTime weighedAt;
  final double kg;

  factory WeightLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WeightLog.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory WeightLog.fromMap(Map<String, dynamic> map, {required String id}) {
    return WeightLog(
      id: id,
      dayKey: map['dayKey'] as String? ?? '',
      weighedAt: FirestoreSerializers.timestampToDate(
            map['weighedAt'] as Timestamp?,
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kg: FirestoreSerializers.toDouble(map['kg']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'weighedAt': FirestoreSerializers.dateToTimestamp(weighedAt),
      'kg': kg,
    };
  }
}

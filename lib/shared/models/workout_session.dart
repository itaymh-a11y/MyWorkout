import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

/// אימון שהושלם — Immutable ב-Firestore (status: completed).
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.status = SessionStatus.completed,
  });

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final SessionStatus status;

  factory WorkoutSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkoutSession.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map, {required String id}) {
    return WorkoutSession(
      id: id,
      planId: map['planId'] as String? ?? '',
      planName: map['planName'] as String? ?? '',
      startedAt: FirestoreSerializers.timestampToDate(
            map['startedAt'] as Timestamp?,
          ) ??
          DateTime.now(),
      endedAt: FirestoreSerializers.timestampToDate(
            map['endedAt'] as Timestamp?,
          ) ??
          DateTime.now(),
      durationSec: FirestoreSerializers.toInt(map['durationSec']) ?? 0,
      status: SessionStatus.fromFirestore(map['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'startedAt': FirestoreSerializers.dateToTimestamp(startedAt),
      'endedAt': FirestoreSerializers.dateToTimestamp(endedAt),
      'durationSec': durationSec,
      'status': status.firestoreValue,
    };
  }
}

enum SessionStatus {
  completed('completed');

  const SessionStatus(this.firestoreValue);

  final String firestoreValue;

  static SessionStatus fromFirestore(String? value) {
    return SessionStatus.values.firstWhere(
      (e) => e.firestoreValue == value,
      orElse: () => SessionStatus.completed,
    );
  }
}

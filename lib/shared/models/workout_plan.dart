import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';

/// תוכנית אימון (תבנית).
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    this.isStarred = false,
    this.defaultRestSec = 90,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final bool isStarred;
  final int defaultRestSec;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkoutPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WorkoutPlan.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map, {required String id}) {
    return WorkoutPlan(
      id: id,
      name: map['name'] as String? ?? '',
      isStarred: FirestoreSerializers.toBool(map['isStarred']),
      defaultRestSec: FirestoreSerializers.toInt(map['defaultRestSec']) ?? 90,
      createdAt: FirestoreSerializers.timestampToDate(
        map['createdAt'] as Timestamp?,
      ),
      updatedAt: FirestoreSerializers.timestampToDate(
        map['updatedAt'] as Timestamp?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final now = Timestamp.now();
    return {
      'name': name,
      'isStarred': isStarred,
      'defaultRestSec': defaultRestSec,
      'createdAt': createdAt != null
          ? FirestoreSerializers.dateToTimestamp(createdAt)
          : now,
      'updatedAt': FirestoreSerializers.dateToTimestamp(updatedAt) ?? now,
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? name,
    bool? isStarred,
    int? defaultRestSec,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      isStarred: isStarred ?? this.isStarred,
      defaultRestSec: defaultRestSec ?? this.defaultRestSec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

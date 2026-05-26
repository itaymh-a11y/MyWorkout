import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myworkout/core/firestore/firestore_serializers.dart';
import 'package:myworkout/shared/models/exercise_ref.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// תרגיל — מובנה (builtin) או מותאם אישית (users/{uid}/exercises).
class Exercise {
  const Exercise({
    required this.id,
    required this.source,
    required this.name,
    required this.categoryId,
    required this.exerciseType,
    this.muscleTags = const [],
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeightKg,
    this.defaultRestSec,
    this.defaultTimeSec,
    this.createdAt,
    this.hasPersonalDefaults = false,
  });

  final String id;
  final ExerciseSource source;
  final String name;
  final String categoryId;
  final ExerciseType exerciseType;
  final List<String> muscleTags;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeightKg;
  final int? defaultRestSec;
  final int? defaultTimeSec;
  final DateTime? createdAt;

  /// true כשלמשתמש יש התאמה אישית לתרגיל מובנה.
  final bool hasPersonalDefaults;

  ExerciseRef get ref => switch (source) {
        ExerciseSource.builtin => ExerciseRef.builtin(id),
        ExerciseSource.custom => ExerciseRef.user(id),
      };

  String get compositeId => ref.compositeId;

  factory Exercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required ExerciseSource source,
  }) {
    return Exercise.fromMap(doc.data() ?? {}, id: doc.id, source: source);
  }

  factory Exercise.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required ExerciseSource source,
  }) {
    return Exercise(
      id: id,
      source: source,
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ??
          map['category'] as String? ??
          'push',
      exerciseType: ExerciseType.fromFirestore(map['exerciseType'] as String?),
      muscleTags: FirestoreSerializers.toStringList(map['muscleTags']),
      defaultSets: FirestoreSerializers.toInt(map['defaultSets']) ?? 3,
      defaultReps: FirestoreSerializers.toInt(map['defaultReps']) ?? 10,
      defaultWeightKg: FirestoreSerializers.toDouble(map['defaultWeightKg']),
      defaultRestSec: FirestoreSerializers.toInt(map['defaultRestSec']),
      defaultTimeSec: FirestoreSerializers.toInt(map['defaultTimeSec']),
      createdAt: FirestoreSerializers.timestampToDate(
        map['createdAt'] as Timestamp?,
      ),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'name': name,
      'categoryId': categoryId,
      'category': categoryId,
      'exerciseType': exerciseType.firestoreValue,
      'muscleTags': muscleTags,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      if (defaultWeightKg != null) 'defaultWeightKg': defaultWeightKg,
      if (defaultRestSec != null) 'defaultRestSec': defaultRestSec,
      if (defaultTimeSec != null) 'defaultTimeSec': defaultTimeSec,
      if (includeCreatedAt && createdAt != null)
        'createdAt': FirestoreSerializers.dateToTimestamp(createdAt),
    };
  }

  Exercise copyWith({
    String? id,
    ExerciseSource? source,
    String? name,
    String? categoryId,
    ExerciseType? exerciseType,
    List<String>? muscleTags,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeightKg,
    int? defaultRestSec,
    int? defaultTimeSec,
    DateTime? createdAt,
    bool? hasPersonalDefaults,
  }) {
    return Exercise(
      id: id ?? this.id,
      source: source ?? this.source,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      exerciseType: exerciseType ?? this.exerciseType,
      muscleTags: muscleTags ?? this.muscleTags,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeightKg: defaultWeightKg ?? this.defaultWeightKg,
      defaultRestSec: defaultRestSec ?? this.defaultRestSec,
      defaultTimeSec: defaultTimeSec ?? this.defaultTimeSec,
      createdAt: createdAt ?? this.createdAt,
      hasPersonalDefaults: hasPersonalDefaults ?? this.hasPersonalDefaults,
    );
  }
}

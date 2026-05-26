import 'package:myworkout/features/workout/domain/live_set_entry.dart';

/// מצב אימון לייב פעיל.
class LiveWorkoutState {
  const LiveWorkoutState({
    required this.uid,
    required this.planId,
    required this.planName,
    required this.defaultRestSec,
    required this.startedAt,
    required this.sets,
    this.restEndsAt,
    this.restStartedAt,
    this.restDurationSec = 0,
  });

  final String uid;
  final String planId;
  final String planName;
  final int defaultRestSec;
  final DateTime startedAt;
  final List<LiveSetEntry> sets;
  final DateTime? restEndsAt;
  final DateTime? restStartedAt;
  final int restDurationSec;

  bool get isActive => true;
  bool get isResting =>
      restEndsAt != null && DateTime.now().isBefore(restEndsAt!);

  int get elapsedSec => DateTime.now().difference(startedAt).inSeconds;

  int get elapsedMinutes => elapsedSec ~/ 60;

  int? get restRemainingSec {
    if (restEndsAt == null) return null;
    final left = restEndsAt!.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  LiveWorkoutState copyWith({
    List<LiveSetEntry>? sets,
    DateTime? restEndsAt,
    DateTime? restStartedAt,
    int? restDurationSec,
    bool clearRest = false,
  }) {
    return LiveWorkoutState(
      uid: uid,
      planId: planId,
      planName: planName,
      defaultRestSec: defaultRestSec,
      startedAt: startedAt,
      sets: sets ?? this.sets,
      restEndsAt: clearRest ? null : (restEndsAt ?? this.restEndsAt),
      restStartedAt:
          clearRest ? null : (restStartedAt ?? this.restStartedAt),
      restDurationSec: restDurationSec ?? this.restDurationSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'planId': planId,
        'planName': planName,
        'defaultRestSec': defaultRestSec,
        'startedAt': startedAt.toIso8601String(),
        'sets': sets.map((s) => s.toJson()).toList(),
        'restEndsAt': restEndsAt?.toIso8601String(),
        'restStartedAt': restStartedAt?.toIso8601String(),
        'restDurationSec': restDurationSec,
      };

  factory LiveWorkoutState.fromJson(Map<String, dynamic> json) {
    return LiveWorkoutState(
      uid: json['uid'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      defaultRestSec: json['defaultRestSec'] as int? ?? 90,
      startedAt: DateTime.parse(json['startedAt'] as String),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => LiveSetEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      restEndsAt: json['restEndsAt'] != null
          ? DateTime.parse(json['restEndsAt'] as String)
          : null,
      restStartedAt: json['restStartedAt'] != null
          ? DateTime.parse(json['restStartedAt'] as String)
          : null,
      restDurationSec: json['restDurationSec'] as int? ?? 0,
    );
  }
}

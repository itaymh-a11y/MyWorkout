/// יעדים יומיים של המשתמש. ערך חסר = היעד עדיין לא הוגדר.
class DailyGoals {
  const DailyGoals({
    this.calorieGoalKcal,
    this.waterGoalMl,
    this.weighInEveryDays = defaultWeighInDays,
  });

  static const defaultWeighInDays = 7;
  static const weighInIntervals = [1, 3, 7, 14];

  final int? calorieGoalKcal;
  final int? waterGoalMl;
  final int weighInEveryDays;

  bool get hasCalorieGoal =>
      calorieGoalKcal != null && calorieGoalKcal! > 0;

  bool get hasWaterGoal => waterGoalMl != null && waterGoalMl! > 0;

  factory DailyGoals.fromMap(Map<String, dynamic> map) {
    return DailyGoals(
      calorieGoalKcal: _positiveInt(map['calorieGoalKcal']),
      waterGoalMl: _positiveInt(map['waterGoalMl']),
      weighInEveryDays: normalizeWeighInDays(map['weighInEveryDays']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calorieGoalKcal': calorieGoalKcal,
      'waterGoalMl': waterGoalMl,
      'weighInEveryDays': weighInEveryDays,
    };
  }

  DailyGoals copyWith({
    int? calorieGoalKcal,
    int? waterGoalMl,
    int? weighInEveryDays,
    bool clearCalorieGoal = false,
    bool clearWaterGoal = false,
  }) {
    return DailyGoals(
      calorieGoalKcal:
          clearCalorieGoal ? null : (calorieGoalKcal ?? this.calorieGoalKcal),
      waterGoalMl: clearWaterGoal ? null : (waterGoalMl ?? this.waterGoalMl),
      weighInEveryDays: weighInEveryDays ?? this.weighInEveryDays,
    );
  }

  static int normalizeWeighInDays(dynamic value) {
    final days = value is int ? value : int.tryParse('$value');
    if (days != null && weighInIntervals.contains(days)) return days;
    return defaultWeighInDays;
  }

  static int? _positiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse('$value');
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

String weighInIntervalLabel(int days) {
  return switch (days) {
    1 => 'כל יום',
    3 => 'כל 3 ימים',
    7 => 'פעם בשבוע',
    14 => 'כל שבועיים',
    _ => 'כל $days ימים',
  };
}

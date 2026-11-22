import 'package:myworkout/features/tracking/domain/meal_log.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';

class DayNutritionTotals {
  const DayNutritionTotals({
    this.kcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.mealCount = 0,
  });

  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;

  bool get isEmpty => mealCount == 0;
}

DayNutritionTotals sumMeals(List<MealLog> meals) {
  var kcal = 0;
  var protein = 0.0;
  var carbs = 0.0;
  var fat = 0.0;
  for (final meal in meals) {
    kcal += meal.kcal;
    protein += meal.proteinG;
    carbs += meal.carbsG ?? 0;
    fat += meal.fatG ?? 0;
  }
  return DayNutritionTotals(
    kcal: kcal,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
    mealCount: meals.length,
  );
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// הגיע זמן שקילה אם אין שקילה, או שעברו לפחות [everyDays] ימים מהאחרונה.
bool isWeighInDue({
  required DateTime today,
  required DateTime? lastWeighIn,
  required int everyDays,
}) {
  if (lastWeighIn == null) return true;
  final todayDate = dateOnly(today);
  final lastDate = dateOnly(lastWeighIn);
  return todayDate.difference(lastDate).inDays >= everyDays;
}

/// טקסט סטטוס לכרטיס המשקל בבית.
String weightStatusLabel({
  required DateTime today,
  required DateTime? lastWeighIn,
  required int everyDays,
}) {
  if (lastWeighIn == null) return 'עדיין לא נרשמה שקילה';
  final days = dateOnly(today).difference(dateOnly(lastWeighIn)).inDays;
  if (days >= everyDays) return 'הגיע הזמן להישקל';
  if (days <= 0) return 'נשקלת היום';
  final left = everyDays - days;
  if (left <= 1) return 'השקילה הבאה מחר';
  return 'השקילה הבאה בעוד $left ימים';
}

/// נקודה אחת ליום בגרף — השקילה האחרונה של אותו יום.
class WeightTrendPoint {
  const WeightTrendPoint({required this.day, required this.kg});

  final DateTime day;
  final double kg;
}

List<WeightTrendPoint> weightTrendPoints(List<WeightLog> logs) {
  final byDay = <String, WeightLog>{};
  final sorted = List<WeightLog>.of(logs)
    ..sort((a, b) => a.weighedAt.compareTo(b.weighedAt));
  for (final log in sorted) {
    byDay[log.dayKey] = log;
  }
  final points = byDay.values.toList()
    ..sort((a, b) => a.weighedAt.compareTo(b.weighedAt));
  return [
    for (final log in points)
      WeightTrendPoint(
        day: DateTime(log.weighedAt.year, log.weighedAt.month, log.weighedAt.day),
        kg: log.kg,
      ),
  ];
}

/// ערכי תזונה אחרי התאמה לכמות שנאכלה.
class PortionNutrition {
  const PortionNutrition({
    required this.kcal,
    required this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final int kcal;
  final double proteinG;
  final double? carbsG;
  final double? fatG;
}

/// מכפיל את ערכי המנה לפי היחס בין הגרמים שנאכלו למשקל השמור.
PortionNutrition scalePortion({
  required int kcal,
  required double proteinG,
  double? carbsG,
  double? fatG,
  required double baseGrams,
  required double eatenGrams,
}) {
  if (baseGrams <= 0 || eatenGrams <= 0) {
    return PortionNutrition(
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }
  final factor = eatenGrams / baseGrams;
  double? scale(double? value) => value == null ? null : value * factor;
  return PortionNutrition(
    kcal: (kcal * factor).round(),
    proteinG: proteinG * factor,
    carbsG: scale(carbsG),
    fatG: scale(fatG),
  );
}

String formatGrams(double grams) {
  if (grams == grams.roundToDouble()) return grams.toInt().toString();
  return grams.toStringAsFixed(1);
}

String formatLitersFromMl(int ml) {
  if (ml == 0) return '0';
  final liters = ml / 1000;
  final fixed = liters.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

double? parseDecimal(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

int? parseWhole(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

/// ליטרים שהמשתמש הקליד → מיליליטר, מעוגל.
int? litersTextToMl(String raw) {
  final liters = parseDecimal(raw);
  if (liters == null || liters <= 0) return null;
  return (liters * 1000).round();
}

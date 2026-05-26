import 'package:flutter_test/flutter_test.dart';
import 'package:myworkout/core/utils/session_format.dart';

void main() {
  test('startOfWeek מחזיר יום ראשון', () {
    // יום רביעי 28 מאי 2026
    final wed = DateTime(2026, 5, 28);
    final start = startOfWeek(wed);
    expect(start.weekday, DateTime.sunday);
    expect(start.day, 24);
    expect(start.month, 5);

    final sat = DateTime(2026, 5, 30);
    expect(startOfWeek(sat).day, 24);

    final sun = DateTime(2026, 5, 24);
    expect(startOfWeek(sun).day, 24);
  });

  test('formatWeekRange מציג עד שבת כולל', () {
    final start = DateTime(2026, 5, 24); // ראשון
    final end = start.add(const Duration(days: 7));
    final label = formatWeekRange(start, end);
    expect(label, contains('30')); // שבת
  });
}

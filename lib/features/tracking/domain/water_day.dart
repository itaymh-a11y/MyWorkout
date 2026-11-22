/// שתייה של יום אחד, כרשימת מנות כדי שאפשר להסיר את האחרונה.
class WaterDay {
  const WaterDay({
    required this.dayKey,
    this.sipsMl = const [],
  });

  final String dayKey;
  final List<int> sipsMl;

  int get totalMl => sipsMl.fold(0, (sum, sip) => sum + sip);

  bool get hasWater => totalMl > 0;

  factory WaterDay.fromMap(Map<String, dynamic> map, {required String dayKey}) {
    final raw = map['sipsMl'];
    final sips = <int>[];
    if (raw is List) {
      for (final item in raw) {
        final ml = item is int ? item : int.tryParse('$item');
        if (ml != null && ml > 0) sips.add(ml);
      }
    }
    return WaterDay(
      dayKey: map['dayKey'] as String? ?? dayKey,
      sipsMl: sips,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'sipsMl': sipsMl,
    };
  }
}

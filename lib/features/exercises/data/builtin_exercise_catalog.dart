import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_source.dart';

/// מאגר תרגילים מובנים מקומי (assets) — נטען כש-Firestore ריק.
abstract final class BuiltinExerciseCatalog {
  static const _assetPath = 'assets/seed/builtin_exercises.json';

  static List<Exercise>? _cache;

  static Future<List<Exercise>> load() async {
    if (_cache != null) return _cache!;

    final jsonString = await rootBundle.loadString(_assetPath);
    final rawList = jsonDecode(jsonString) as List<dynamic>;

    _cache = rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map.remove('id') as String;
      return Exercise.fromMap(
        map,
        id: id,
        source: ExerciseSource.builtin,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _cache!;
  }

  /// מאפס מטמון (למשל אחרי hot reload בפיתוח).
  static void clearCache() => _cache = null;
}

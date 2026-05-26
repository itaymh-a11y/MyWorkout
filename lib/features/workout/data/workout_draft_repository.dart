import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:myworkout/features/workout/domain/live_workout_state.dart';

const _boxName = 'workout_draft_box';
const _draftKey = 'active_draft';

/// שמירה מקומית של טיוטת אימון (Hive).
class WorkoutDraftRepository {
  Box<String>? _box;

  Future<Box<String>> _open() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  Future<void> saveDraft(LiveWorkoutState state) async {
    final box = await _open();
    await box.put(_draftKey, jsonEncode(state.toJson()));
  }

  Future<LiveWorkoutState?> loadDraft() async {
    final box = await _open();
    final raw = box.get(_draftKey);
    if (raw == null) return null;
    return LiveWorkoutState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clearDraft() async {
    final box = await _open();
    await box.delete(_draftKey);
  }

  bool isOlderThan24Hours(LiveWorkoutState draft) {
    return DateTime.now().difference(draft.startedAt).inHours >= 24;
  }
}

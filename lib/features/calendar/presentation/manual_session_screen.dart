import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/calendar/domain/manual_session_entry.dart';
import 'package:myworkout/features/calendar/presentation/widgets/manual_set_row.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/plans/presentation/widgets/exercise_picker_sheet.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';
import 'package:myworkout/shared/models/workout_session.dart';

/// הזנת אימון שהושלם בעבר — תאריך, שעה, תוכנית וסטים.
class ManualSessionScreen extends ConsumerStatefulWidget {
  const ManualSessionScreen({
    super.key,
    this.initialDate,
  });

  final DateTime? initialDate;

  static Future<bool?> open(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualSessionScreen(initialDate: initialDate),
      ),
    );
  }

  @override
  ConsumerState<ManualSessionScreen> createState() => _ManualSessionScreenState();
}

class _ManualSessionScreenState extends ConsumerState<ManualSessionScreen> {
  late DateTime _date;
  late TimeOfDay _startTime;
  final _durationCtrl = TextEditingController(text: '60');
  String? _planId;
  String? _planName;
  List<ManualExerciseBlock> _blocks = [];
  bool _loadingExercises = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
    final now = TimeOfDay.now();
    _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'בחר תאריך אימון',
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'בחר שעת התחלה',
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _onPlanChanged(String? planId, List<WorkoutPlan> plans) async {
    if (planId == null) {
      setState(() {
        _planId = null;
        _planName = null;
        _blocks = [];
      });
      return;
    }
    if (planId == _planId) return;

    final plan = plans.firstWhere((p) => p.id == planId);
    setState(() {
      _planId = planId;
      _planName = plan.name;
      _loadingExercises = true;
      _blocks = [];
    });

    try {
      final exercises = await ref.read(planExercisesProvider(planId).future);
      if (!mounted || _planId != planId) return;
      setState(() {
        _blocks = blocksFromPlanExercises(exercises);
        _loadingExercises = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingExercises = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בטעינת תרגילים: $e')),
      );
    }
  }

  Future<void> _addExercise() async {
    final excluded = _blocks.map((b) => b.exerciseId).toSet();
    final picked = await ExercisePickerSheet.show(
      context,
      excludedExerciseIds: excluded,
    );
    if (picked == null || !mounted) return;
    setState(() => _blocks = [..._blocks, _blockFromExercise(picked)]);
  }

  ManualExerciseBlock _blockFromExercise(Exercise exercise) {
    final sets = <ManualSetRow>[];
    for (var i = 1; i <= exercise.defaultSets; i++) {
      sets.add(
        ManualSetRow(
          setIndex: i,
          targetWeightKg: exercise.defaultWeightKg,
          targetReps: exercise.defaultReps,
          targetTimeSec: exercise.defaultTimeSec,
          actualWeightKg: exercise.defaultWeightKg,
          actualReps: exercise.defaultReps,
          actualTimeSec: exercise.defaultTimeSec,
        ),
      );
    }
    return ManualExerciseBlock(
      exerciseId: exercise.compositeId,
      exerciseName: exercise.name,
      exerciseType: exercise.exerciseType,
      sets: sets,
    );
  }

  void _updateBlock(int blockIndex, ManualExerciseBlock block) {
    setState(() {
      _blocks = [
        for (var i = 0; i < _blocks.length; i++)
          if (i == blockIndex) block else _blocks[i],
      ];
    });
  }

  Future<void> _save() async {
    if (_planId == null || _planName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('בחר תוכנית אימון')),
      );
      return;
    }

    final sets = toWorkoutSets(_blocks);
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הזן לפחות סט אחד עם נתונים')),
      );
      return;
    }

    final durationMin = int.tryParse(_durationCtrl.text.trim()) ?? 60;
    final startedAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endedAt = startedAt.add(Duration(minutes: durationMin.clamp(1, 600)));
    final durationSec = endedAt.difference(startedAt).inSeconds;

    setState(() => _saving = true);
    try {
      final uid = ref.read(currentUidProvider);
      final session = WorkoutSession(
        id: '',
        planId: _planId!,
        planName: _planName!,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: durationSec,
      );
      await ref.read(sessionRepositoryProvider).saveCompletedSession(
            uid,
            session,
            sets,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בשמירה: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _timeLabel(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הוסף אימון ידני'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('שמור'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'מתי בוצע האימון?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('תאריך'),
                    trailing: Text(formatSessionDate(_date)),
                    onTap: _pickDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('שעת התחלה'),
                    trailing: Text(_timeLabel(_startTime)),
                    onTap: _pickTime,
                  ),
                  TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'משך (דקות)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: plansAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('שגיאה בטעינת תוכניות: $e'),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Text('אין תוכניות — צור תוכנית בטאב תוכניות');
                }
                return DropdownMenu<String>(
                  width: MediaQuery.sizeOf(context).width - 24,
                  label: const Text('תוכנית אימון'),
                  initialSelection: _planId,
                  dropdownMenuEntries: [
                    for (final p in plans)
                      DropdownMenuEntry(value: p.id, label: p.name),
                  ],
                  onSelected: (id) => _onPlanChanged(id, plans),
                );
              },
            ),
          ),
          if (_loadingExercises)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_planId != null && !_loadingExercises) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'תרגילים וסטים',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('תרגיל'),
                  ),
                ],
              ),
            ),
            if (_blocks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'אין תרגילים בתוכנית — הוסף תרגילים מהכפתור למעלה',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            for (var bi = 0; bi < _blocks.length; bi++) ...[
              _ExerciseSection(
                block: _blocks[bi],
                onBlockChanged: (b) => _updateBlock(bi, b),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.block,
    required this.onBlockChanged,
  });

  final ManualExerciseBlock block;
  final ValueChanged<ManualExerciseBlock> onBlockChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            block.exerciseName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (var si = 0; si < block.sets.length; si++)
          ManualSetRowWidget(
            row: block.sets[si],
            exerciseType: block.exerciseType,
            onChanged: (updated) {
              final nextSets = List<ManualSetRow>.from(block.sets);
              nextSets[si] = updated;
              onBlockChanged(
                ManualExerciseBlock(
                  exerciseId: block.exerciseId,
                  exerciseName: block.exerciseName,
                  exerciseType: block.exerciseType,
                  sets: nextSets,
                ),
              );
            },
            onRemove: block.sets.length > 1
                ? () {
                    final copy = ManualExerciseBlock(
                      exerciseId: block.exerciseId,
                      exerciseName: block.exerciseName,
                      exerciseType: block.exerciseType,
                      sets: List<ManualSetRow>.from(block.sets),
                    );
                    copy.removeSet(si);
                    onBlockChanged(copy);
                  }
                : null,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            onPressed: () {
              final copy = ManualExerciseBlock(
                exerciseId: block.exerciseId,
                exerciseName: block.exerciseName,
                exerciseType: block.exerciseType,
                sets: List<ManualSetRow>.from(block.sets),
              );
              copy.addSet();
              onBlockChanged(copy);
            },
            icon: const Icon(Icons.add),
            label: const Text('הוסף סט'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

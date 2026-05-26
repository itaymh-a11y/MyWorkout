import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';

/// עריכת יעדים לתרגיל בתוך תוכנית.
class PlanExerciseEditorSheet extends StatefulWidget {
  const PlanExerciseEditorSheet({
    super.key,
    required this.exercise,
    required this.planDefaultRestSec,
  });

  final PlanExercise exercise;
  final int planDefaultRestSec;

  static Future<PlanExercise?> show(
    BuildContext context, {
    required PlanExercise exercise,
    required int planDefaultRestSec,
  }) {
    return showModalBottomSheet<PlanExercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlanExerciseEditorSheet(
        exercise: exercise,
        planDefaultRestSec: planDefaultRestSec,
      ),
    );
  }

  @override
  State<PlanExerciseEditorSheet> createState() =>
      _PlanExerciseEditorSheetState();
}

class _PlanExerciseEditorSheetState extends State<PlanExerciseEditorSheet> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _timeMinController;
  late final TextEditingController _timeSecController;
  late final TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _setsController = TextEditingController(text: '${e.setsCount}');
    _repsController = TextEditingController(text: '${e.targetReps ?? 10}');
    _weightController = TextEditingController(
      text: e.targetWeightKg?.toString() ?? '',
    );
    final timeSec = e.targetTimeSec ?? 60;
    _timeMinController = TextEditingController(text: '${timeSec ~/ 60}');
    _timeSecController = TextEditingController(text: '${timeSec % 60}');
    _restController = TextEditingController(
      text: e.restSec?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _timeMinController.dispose();
    _timeSecController.dispose();
    _restController.dispose();
    super.dispose();
  }

  PlanExercise _buildResult() {
    final e = widget.exercise;
    final sets = int.parse(_setsController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final min = int.tryParse(_timeMinController.text.trim()) ?? 0;
    final sec = int.tryParse(_timeSecController.text.trim()) ?? 0;
    final rest = int.tryParse(_restController.text.trim());

    return PlanExercise(
      id: e.id,
      exerciseId: e.exerciseId,
      exerciseName: e.exerciseName,
      order: e.order,
      exerciseType: e.exerciseType,
      setsCount: sets,
      targetReps: e.exerciseType != ExerciseType.time ? reps : null,
      targetWeightKg:
          e.exerciseType == ExerciseType.weightReps ? weight : null,
      targetTimeSec: e.exerciseType == ExerciseType.time ? min * 60 + sec : null,
      restSec: rest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.exercise.exerciseType;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exercise.exerciseName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _setsController,
              decoration: const InputDecoration(
                labelText: 'מספר סטים',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (type != ExerciseType.time) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: 'חזרות יעד',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            if (type == ExerciseType.weightReps) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'משקל יעד (ק"ג)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            if (type == ExerciseType.time) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeMinController,
                      decoration: const InputDecoration(
                        labelText: 'דקות',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeSecController,
                      decoration: const InputDecoration(
                        labelText: 'שניות',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _restController,
              decoration: InputDecoration(
                labelText: 'מנוחה ייעודית (שניות, ריק = ${widget.planDefaultRestSec})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, _buildResult()),
              child: const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }
}

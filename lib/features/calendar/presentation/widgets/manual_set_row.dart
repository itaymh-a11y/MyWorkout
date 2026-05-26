import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myworkout/features/calendar/domain/manual_session_entry.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

class ManualSetRowWidget extends StatefulWidget {
  const ManualSetRowWidget({
    super.key,
    required this.row,
    required this.exerciseType,
    required this.onChanged,
    this.onRemove,
  });

  final ManualSetRow row;
  final ExerciseType exerciseType;
  final void Function(ManualSetRow updated) onChanged;
  final VoidCallback? onRemove;

  @override
  State<ManualSetRowWidget> createState() => _ManualSetRowWidgetState();
}

class _ManualSetRowWidgetState extends State<ManualSetRowWidget> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _timeCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: _text(widget.row.actualWeightKg));
    _repsCtrl = TextEditingController(text: _text(widget.row.actualReps));
    _timeCtrl = TextEditingController(text: _text(widget.row.actualTimeSec));
  }

  @override
  void didUpdateWidget(ManualSetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.actualWeightKg != widget.row.actualWeightKg) {
      _sync(_weightCtrl, widget.row.actualWeightKg);
    }
    if (oldWidget.row.actualReps != widget.row.actualReps) {
      _sync(_repsCtrl, widget.row.actualReps);
    }
    if (oldWidget.row.actualTimeSec != widget.row.actualTimeSec) {
      _sync(_timeCtrl, widget.row.actualTimeSec);
    }
  }

  void _sync(TextEditingController ctrl, num? value) {
    final next = _text(value);
    if (ctrl.text != next) ctrl.text = next;
  }

  String _text(num? v) => v?.toString() ?? '';

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _emitWeight(String v) {
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    widget.onChanged(
      widget.row.copyWith(
        actualWeightKg: parsed,
        clearWeight: v.trim().isEmpty,
      ),
    );
  }

  void _emitReps(String v) {
    final parsed = int.tryParse(v.trim());
    widget.onChanged(
      widget.row.copyWith(
        actualReps: parsed,
        clearReps: v.trim().isEmpty,
      ),
    );
  }

  void _emitTime(String v) {
    final parsed = int.tryParse(v.trim());
    widget.onChanged(
      widget.row.copyWith(
        actualTimeSec: parsed,
        clearTime: v.trim().isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: widget.row.completed
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.row.completed,
              onChanged: (_) {
                widget.onChanged(
                  widget.row.copyWith(completed: !widget.row.completed),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 28,
                child: Text(
                  '${widget.row.setIndex}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(child: _buildFields(context)),
            if (widget.onRemove != null)
              IconButton(
                tooltip: 'הסר סט',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    switch (widget.exerciseType) {
      case ExerciseType.weightReps:
        return Row(
          children: [
            Expanded(
              child: _ValueField(
                controller: _weightCtrl,
                label: 'ק"ג (יעד ${widget.row.targetWeightKg ?? '-'})',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onChanged: _emitWeight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ValueField(
                controller: _repsCtrl,
                label: 'חזרות (יעד ${widget.row.targetReps ?? '-'})',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _emitReps,
              ),
            ),
          ],
        );
      case ExerciseType.repsOnly:
        return _ValueField(
          controller: _repsCtrl,
          label: 'חזרות (יעד ${widget.row.targetReps ?? '-'})',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _emitReps,
        );
      case ExerciseType.time:
        return _ValueField(
          controller: _timeCtrl,
          label: 'שניות (יעד ${widget.row.targetTimeSec ?? '-'})',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _emitTime,
        );
    }
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.onChanged,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

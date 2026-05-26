import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/features/workout/application/session_controller.dart';
import 'package:myworkout/features/workout/domain/live_set_entry.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

class LiveSetRow extends StatefulWidget {
  const LiveSetRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onToggleComplete,
  });

  final LiveSetEntry entry;
  final void Function(LiveSetEntry updated) onChanged;
  final VoidCallback onToggleComplete;

  @override
  State<LiveSetRow> createState() => _LiveSetRowState();
}

class _LiveSetRowState extends State<LiveSetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _timeCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: _text(widget.entry.actualWeightKg));
    _repsCtrl = TextEditingController(text: _text(widget.entry.actualReps));
    _timeCtrl = TextEditingController(text: _text(widget.entry.actualTimeSec));
  }

  @override
  void didUpdateWidget(LiveSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.actualWeightKg != widget.entry.actualWeightKg) {
      _syncController(_weightCtrl, widget.entry.actualWeightKg);
    }
    if (oldWidget.entry.actualReps != widget.entry.actualReps) {
      _syncController(_repsCtrl, widget.entry.actualReps);
    }
    if (oldWidget.entry.actualTimeSec != widget.entry.actualTimeSec) {
      _syncController(_timeCtrl, widget.entry.actualTimeSec);
    }
  }

  void _syncController(TextEditingController ctrl, num? value) {
    final next = _text(value);
    if (ctrl.text != next) {
      ctrl.text = next;
    }
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
    widget.onChanged(widget.entry.copyWith(
      actualWeightKg: parsed,
      clearActualWeight: v.trim().isEmpty,
    ));
  }

  void _emitReps(String v) {
    final parsed = int.tryParse(v.trim());
    widget.onChanged(widget.entry.copyWith(
      actualReps: parsed,
      clearActualReps: v.trim().isEmpty,
    ));
  }

  void _emitTime(String v) {
    final parsed = int.tryParse(v.trim());
    widget.onChanged(widget.entry.copyWith(
      actualTimeSec: parsed,
      clearActualTime: v.trim().isEmpty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = previousHintForSet(widget.entry);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: widget.entry.completed ? AppColors.emberMuted : AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.entry.completed
              ? AppColors.ember.withValues(alpha: 0.4)
              : AppColors.silverLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.entry.completed,
              onChanged: (_) => widget.onToggleComplete(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 28,
                child: Text(
                  '${widget.entry.setIndex}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(child: _buildFields(context, hint)),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context, String? hint) {
    switch (widget.entry.exerciseType) {
      case ExerciseType.weightReps:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ValueField(
                    controller: _weightCtrl,
                    label: 'ק"ג (יעד ${widget.entry.targetWeightKg ?? '-'})',
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
                    label: 'חזרות (יעד ${widget.entry.targetReps ?? '-'})',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: _emitReps,
                  ),
                ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        );
      case ExerciseType.repsOnly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ValueField(
              controller: _repsCtrl,
              label: 'חזרות (יעד ${widget.entry.targetReps ?? '-'})',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _emitReps,
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        );
      case ExerciseType.time:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ValueField(
              controller: _timeCtrl,
              label: 'שניות (יעד ${widget.entry.targetTimeSec ?? '-'})',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _emitTime,
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
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

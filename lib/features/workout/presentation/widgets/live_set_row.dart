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
    this.showColumnHeaders = false,
  });

  final LiveSetEntry entry;
  final void Function(LiveSetEntry updated) onChanged;
  final VoidCallback onToggleComplete;
  final bool showColumnHeaders;

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
    final previousText = previousPerformanceForSet(widget.entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showColumnHeaders) _ColumnHeaders(type: widget.entry.exerciseType),
        Card(
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
                Expanded(
                  child: _buildFields(
                    context,
                    previousText: previousText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFields(
    BuildContext context, {
    required String previousText,
  }) {
    final previous = _PreviousPerformanceCell(text: previousText);

    switch (widget.entry.exerciseType) {
      case ExerciseType.weightReps:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 8),
            Expanded(child: previous),
          ],
        );
      case ExerciseType.repsOnly:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ValueField(
                controller: _repsCtrl,
                label: 'חזרות (יעד ${widget.entry.targetReps ?? '-'})',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _emitReps,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: previous),
          ],
        );
      case ExerciseType.time:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ValueField(
                controller: _timeCtrl,
                label: 'שניות (יעד ${widget.entry.targetTimeSec ?? '-'})',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _emitTime,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: previous),
          ],
        );
    }
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.type});

  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.navy.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        );

    Widget header(String text) => Expanded(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: style,
          ),
        );

    final children = switch (type) {
      ExerciseType.weightReps => [
          header('ק"ג'),
          header('חזרות'),
          header('האימון האחרון'),
        ],
      ExerciseType.repsOnly => [
          header('חזרות'),
          header('האימון האחרון'),
        ],
      ExerciseType.time => [
          header('זמן'),
          header('האימון האחרון'),
        ],
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 20, 4),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PreviousPerformanceCell extends StatelessWidget {
  const _PreviousPerformanceCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = text != '—';

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'האימון האחרון',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        border: OutlineInputBorder(),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: hasData ? AppColors.ember : theme.colorScheme.onSurfaceVariant,
          fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
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

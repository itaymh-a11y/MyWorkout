import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/exercise_category_def.dart';
import 'package:myworkout/shared/models/exercise_override.dart';
import 'package:myworkout/shared/models/exercise_source.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// יצירה / עריכה של תרגיל — מותאם אישית או פרופיל מלא של תרגיל מובנה.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exercise});

  final Exercise? exercise;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _muscleTagsController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _timeMinController;
  late final TextEditingController _timeSecController;
  late final TextEditingController _restController;

  late String _categoryId;
  late ExerciseType _exerciseType;
  bool _isSaving = false;

  bool get _isEditing => widget.exercise != null;

  bool get _isBuiltinOverride =>
      widget.exercise?.source == ExerciseSource.builtin;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _muscleTagsController = TextEditingController(
      text: e?.muscleTags.join(', ') ?? '',
    );
    _setsController = TextEditingController(text: '${e?.defaultSets ?? 3}');
    _repsController = TextEditingController(text: '${e?.defaultReps ?? 10}');
    _weightController = TextEditingController(
      text: e?.defaultWeightKg?.toString() ?? '',
    );
    final timeSec = e?.defaultTimeSec ?? 60;
    _timeMinController = TextEditingController(text: '${timeSec ~/ 60}');
    _timeSecController = TextEditingController(text: '${timeSec % 60}');
    _restController = TextEditingController(
      text: e?.defaultRestSec?.toString() ?? '',
    );
    _categoryId = e?.categoryId ?? 'push';
    _exerciseType = e?.exerciseType ?? ExerciseType.weightReps;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _muscleTagsController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _timeMinController.dispose();
    _timeSecController.dispose();
    _restController.dispose();
    super.dispose();
  }

  List<String> _parseMuscleTags() {
    return _muscleTagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  int? _parseOptionalInt(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  double? _parseOptionalDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  int _totalTimeSec() {
    final min = int.tryParse(_timeMinController.text.trim()) ?? 0;
    final sec = int.tryParse(_timeSecController.text.trim()) ?? 0;
    return min * 60 + sec;
  }

  Exercise _buildExerciseFromForm({required String id, required ExerciseSource source}) {
    final sets = int.parse(_setsController.text.trim());
    final reps = int.tryParse(_repsController.text.trim()) ?? 10;

    return Exercise(
      id: id,
      source: source,
      name: _nameController.text.trim(),
      categoryId: _categoryId,
      exerciseType: _exerciseType,
      muscleTags: _parseMuscleTags(),
      defaultSets: sets,
      defaultReps: reps,
      defaultWeightKg: _exerciseType == ExerciseType.weightReps
          ? _parseOptionalDouble(_weightController.text)
          : null,
      defaultTimeSec:
          _exerciseType == ExerciseType.time ? _totalTimeSec() : null,
      defaultRestSec: _parseOptionalInt(_restController.text),
      createdAt: widget.exercise?.createdAt,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uid = ref.read(currentUidProvider);
    final repo = ref.read(exerciseRepositoryProvider);

    try {
      if (_isBuiltinOverride) {
        final edited = _buildExerciseFromForm(
          id: widget.exercise!.id,
          source: ExerciseSource.builtin,
        );
        final override = ExerciseOverride.fromExercise(edited);
        await repo.saveBuiltinOverride(uid, widget.exercise!.id, override);
        if (mounted) Navigator.of(context).pop(edited.copyWith(hasPersonalDefaults: true));
      } else {
        final exercise = _buildExerciseFromForm(
          id: widget.exercise?.id ?? '',
          source: ExerciseSource.custom,
        );

        if (_isEditing) {
          await repo.updateUserExercise(uid, exercise);
          if (mounted) Navigator.of(context).pop(exercise);
        } else {
          final newId = await repo.createUserExercise(uid, exercise);
          if (mounted) {
            Navigator.of(context).pop(exercise.copyWith(id: newId));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    final title = _isBuiltinOverride
        ? 'עריכת פרופיל תרגיל'
        : (_isEditing ? 'עריכת תרגיל' : 'תרגיל חדש');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isBuiltinOverride)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'עריכה אישית של "${widget.exercise!.name}" — השינויים נשמרים רק עבורך.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (_isBuiltinOverride) const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'שם התרגיל',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'נא להזין שם' : null,
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => _CategoryDropdown(
                categories: categories,
                value: _categoryId,
                onChanged: (id) {
                  if (id != null) setState(() => _categoryId = id);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('שגיאה בטעינת קטגוריות: $e'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExerciseType>(
              value: _exerciseType,
              decoration: const InputDecoration(
                labelText: 'סוג תרגיל',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ExerciseType.weightReps,
                  child: Text('משקל + חזרות'),
                ),
                DropdownMenuItem(
                  value: ExerciseType.repsOnly,
                  child: Text('חזרות בלבד'),
                ),
                DropdownMenuItem(
                  value: ExerciseType.time,
                  child: Text('זמן'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _exerciseType = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _muscleTagsController,
              decoration: const InputDecoration(
                labelText: 'שרירים (מופרדים בפסיק)',
                hintText: 'לדוגמה: חזה, כתפיים',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ברירות מחדל',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _setsController,
              decoration: const InputDecoration(
                labelText: 'מספר סטים',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'לפחות סט אחד';
                return null;
              },
            ),
            if (_exerciseType != ExerciseType.time) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(
                  labelText: 'חזרות',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            if (_exerciseType == ExerciseType.weightReps) ...[
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
            if (_exerciseType == ExerciseType.time) ...[
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _restController,
              decoration: const InputDecoration(
                labelText: 'מנוחה ייעודית (שניות, אופציונלי)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'שמור שינויים' : 'צור תרגיל'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<ExerciseCategoryDef> categories;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        categories.any((c) => c.id == value) ? value : categories.firstOrNull?.id;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: const InputDecoration(
        labelText: 'קטגוריה',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final c in categories)
          DropdownMenuItem(value: c.id, child: Text(c.nameHe)),
      ],
      onChanged: onChanged,
    );
  }
}

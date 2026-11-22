import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/meal_template.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';

class MealFormScreen extends ConsumerStatefulWidget {
  const MealFormScreen.log({
    super.key,
    required this.dayKey,
    this.template,
  }) : editingTemplate = null;

  const MealFormScreen.editTemplate({
    super.key,
    required MealTemplate template,
  })  : dayKey = null,
        template = null,
        editingTemplate = template;

  final String? dayKey;
  final MealTemplate? template;
  final MealTemplate? editingTemplate;

  static void openLog(
    BuildContext context, {
    required String dayKey,
    MealTemplate? template,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MealFormScreen.log(dayKey: dayKey, template: template),
      ),
    );
  }

  static void openTemplate(BuildContext context, MealTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MealFormScreen.editTemplate(template: template),
      ),
    );
  }

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _grams;
  double? _baseGrams;
  int? _baseKcal;
  double? _baseProtein;
  double? _baseCarbs;
  double? _baseFat;
  var _saveAsTemplate = false;
  var _saving = false;

  bool get _editingTemplate => widget.editingTemplate != null;

  MealTemplate? get _seed => widget.editingTemplate ?? widget.template;

  @override
  void initState() {
    super.initState();
    final seed = _seed;
    _name = TextEditingController(text: seed?.name ?? '');
    _kcal = TextEditingController(text: seed == null ? '' : '${seed.kcal}');
    _protein = TextEditingController(
      text: seed == null ? '' : formatGrams(seed.proteinG),
    );
    _carbs = TextEditingController(
      text: seed?.carbsG == null ? '' : formatGrams(seed!.carbsG!),
    );
    _fat = TextEditingController(
      text: seed?.fatG == null ? '' : formatGrams(seed!.fatG!),
    );
    _grams = TextEditingController(
      text: seed?.portionGrams == null ? '' : formatGrams(seed!.portionGrams!),
    );
    final base = widget.template?.portionGrams;
    if (!_editingTemplate && base != null && base > 0 && seed != null) {
      _baseGrams = base;
      _baseKcal = seed.kcal;
      _baseProtein = seed.proteinG;
      _baseCarbs = seed.carbsG;
      _baseFat = seed.fatG;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _grams.dispose();
    super.dispose();
  }

  bool get _scalesWithGrams => _baseGrams != null;

  void _applyPortion(String raw) {
    if (!_scalesWithGrams) return;
    final eaten = parseDecimal(raw);
    final scaled = eaten == null || eaten <= 0
        ? PortionNutrition(
            kcal: _baseKcal!,
            proteinG: _baseProtein!,
            carbsG: _baseCarbs,
            fatG: _baseFat,
          )
        : scalePortion(
            kcal: _baseKcal!,
            proteinG: _baseProtein!,
            carbsG: _baseCarbs,
            fatG: _baseFat,
            baseGrams: _baseGrams!,
            eatenGrams: eaten,
          );
    _kcal.text = '${scaled.kcal}';
    _protein.text = formatGrams(scaled.proteinG);
    _carbs.text = scaled.carbsG == null ? '' : formatGrams(scaled.carbsG!);
    _fat.text = scaled.fatG == null ? '' : formatGrams(scaled.fatG!);
  }

  String? _validateAmount(String? value, {required bool required}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'שדה חובה' : null;
    final amount = parseDecimal(text);
    if (amount == null || amount < 0) return 'הכנס מספר חיובי';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final kcal = parseWhole(_kcal.text.trim()) ?? 0;
    final protein = parseDecimal(_protein.text) ?? 0;
    final carbsText = _carbs.text.trim();
    final carbs = carbsText.isEmpty ? null : parseDecimal(carbsText);
    final fatText = _fat.text.trim();
    final fat = fatText.isEmpty ? null : parseDecimal(fatText);
    final gramsText = _grams.text.trim();
    final grams = gramsText.isEmpty ? null : parseDecimal(gramsText);
    final repo = ref.read(mealRepositoryProvider);
    final uid = ref.read(currentUidProvider);

    try {
      if (_editingTemplate) {
        await repo.updateTemplate(
          uid,
          MealTemplate(
            id: widget.editingTemplate!.id,
            name: name,
            kcal: kcal,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            portionGrams: grams,
          ),
        );
      } else {
        await repo.addLog(
          uid: uid,
          dayKey: widget.dayKey!,
          name: name,
          kcal: kcal,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          portionGrams: grams,
          templateId: widget.template?.id,
        );
        if (_saveAsTemplate) {
          await repo.saveTemplate(
            uid: uid,
            name: name,
            kcal: kcal,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            portionGrams: grams,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נשמר: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.dayKey == null ? null : parseDayKey(widget.dayKey!);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingTemplate ? 'עריכת ארוחה שמורה' : 'ארוחה'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (day != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'נשמר ליום ${formatSessionDate(day)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'שם המנה',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'שדה חובה';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _applyPortion,
              decoration: InputDecoration(
                labelText: _scalesWithGrams
                    ? 'כמות שנאכלה'
                    : 'משקל המנה (אופציונלי)',
                border: const OutlineInputBorder(),
                suffixText: 'גרם',
                helperText: _scalesWithGrams
                    ? 'המנה השמורה היא ל־${formatGrams(_baseGrams!)} גרם. שינוי הכמות מעדכן את הערכים.'
                    : 'הערכים למטה מתייחסים לכמות הזו',
              ),
              validator: (value) {
                final error = _validateAmount(value, required: false);
                if (error != null) return error;
                final amount = parseDecimal(value ?? '');
                if (amount != null && amount == 0) return 'הכנס משקל גדול מאפס';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kcal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'קלוריות',
                border: OutlineInputBorder(),
                suffixText: 'קק״ל',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'שדה חובה';
                final kcal = parseWhole(text);
                if (kcal == null || kcal < 0) return 'הכנס מספר חיובי';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _protein,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'חלבון',
                border: OutlineInputBorder(),
                suffixText: 'גרם',
              ),
              validator: (value) => _validateAmount(value, required: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carbs,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'פחמימות (אופציונלי)',
                border: OutlineInputBorder(),
                suffixText: 'גרם',
              ),
              validator: (value) => _validateAmount(value, required: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fat,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'שומן (אופציונלי)',
                border: OutlineInputBorder(),
                suffixText: 'גרם',
              ),
              validator: (value) => _validateAmount(value, required: false),
            ),
            if (!_editingTemplate && widget.template == null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveAsTemplate,
                onChanged: (value) =>
                    setState(() => _saveAsTemplate = value ?? false),
                title: const Text('שמור לשימוש חוזר'),
                subtitle: const Text('אפשר יהיה לבחור את הארוחה בלי להקליד שוב'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_editingTemplate ? 'שמור ארוחה' : 'הוסף ליום'),
            ),
          ],
        ),
      ),
    );
  }
}

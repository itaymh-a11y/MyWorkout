import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/daily_goals.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
    );
  }

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _caloriesController = TextEditingController();
  final _litersController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _interval = DailyGoals.defaultWeighInDays;
  var _ready = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final goals = await ref.read(goalsProvider.future);
      if (!mounted) return;
      setState(() {
        if (goals.calorieGoalKcal != null) {
          _caloriesController.text = '${goals.calorieGoalKcal}';
        }
        if (goals.waterGoalMl != null) {
          _litersController.text = formatLitersFromMl(goals.waterGoalMl!);
        }
        _interval = goals.weighInEveryDays;
        _ready = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _ready = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא נטענו יעדים: $error')),
      );
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final calorieText = _caloriesController.text.trim();
      final waterText = _litersController.text.trim();
      final goals = DailyGoals(
        calorieGoalKcal: calorieText.isEmpty ? null : parseWhole(calorieText),
        waterGoalMl: waterText.isEmpty ? null : litersTextToMl(waterText),
        weighInEveryDays: _interval,
      );
      final uid = ref.read(currentUidProvider);
      await ref.read(goalsRepositoryProvider).saveGoals(uid, goals);
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
    return Scaffold(
      appBar: AppBar(title: const Text('יעדים')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'היעדים מוצגים בבית ומשמשים את הסיכום היומי. אפשר להשאיר שדה ריק אם עדיין אין יעד.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'יעד קלוריות ליום',
                      border: OutlineInputBorder(),
                      suffixText: 'קק״ל',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final kcal = parseWhole(text);
                      if (kcal == null || kcal <= 0) {
                        return 'הכנס מספר גדול מאפס';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _litersController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'יעד שתייה ליום',
                      border: OutlineInputBorder(),
                      suffixText: 'ליטר',
                      hintText: '2.5',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      if (litersTextToMl(text) == null) {
                        return 'הכנס כמות גדולה מאפס';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'תדירות שקילה',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final days in DailyGoals.weighInIntervals)
                        ChoiceChip(
                          label: Text(weighInIntervalLabel(days)),
                          selected: _interval == days,
                          onSelected: (_) => setState(() => _interval = days),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('שמור יעדים'),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/meal_template.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/presentation/meal_form_screen.dart';

class SavedMealsScreen extends ConsumerWidget {
  const SavedMealsScreen({super.key, required this.dayKey});

  final String dayKey;

  static void open(BuildContext context, {required String dayKey}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedMealsScreen(dayKey: dayKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(mealTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ארוחות שמורות')),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('שגיאה: $error')),
        data: (meals) {
          if (meals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'אין ארוחות שמורות.\nבהוספת ארוחה אפשר לסמן "שמור לשימוש חוזר".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: meals.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return ListTile(
                title: Text(meal.name),
                subtitle: Text(_subtitle(meal)),
                onTap: () => MealFormScreen.openLog(
                  context,
                  dayKey: dayKey,
                  template: meal,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'עריכת הארוחה השמורה',
                      onPressed: () =>
                          MealFormScreen.openTemplate(context, meal),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'מחיקה',
                      onPressed: () => _delete(context, ref, meal),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _subtitle(MealTemplate meal) {
    final grams = meal.portionGrams == null
        ? ''
        : '${formatGrams(meal.portionGrams!)} ג׳ · ';
    final carbs = meal.carbsG == null
        ? ''
        : ' · ${formatGrams(meal.carbsG!)} ג׳ פחמימה';
    return '$grams${meal.kcal} קק״ל · ${formatGrams(meal.proteinG)} ג׳ חלבון$carbs';
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MealTemplate meal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('למחוק ארוחה שמורה?'),
        content: Text('"${meal.name}" תימחק מהרשימה. ארוחות שכבר נרשמו יישארו.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(mealRepositoryProvider).deleteTemplate(uid, meal.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נמחק: $error')),
        );
      }
    }
  }
}

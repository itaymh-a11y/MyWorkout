import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/features/exercises/data/exercise_category_repository.dart';
import 'package:myworkout/features/exercises/utils/exercise_labels.dart';
import 'package:myworkout/shared/models/exercise_category_def.dart';

/// ניהול קטגוריות תרגילים — עריכה, הוספה ומחיקה.
class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול קטגוריות'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('קטגוריה חדשה'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('אין קטגוריות'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(categoryIcon(category)),
                ),
                title: Text(category.nameHe),
                subtitle: Text(
                  category.isSystem ? 'קטגוריית מערכת' : 'קטגוריה מותאמת',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showCategoryDialog(
                        context,
                        ref,
                        category: category,
                      ),
                    ),
                    if (!category.isSystem)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _confirmDelete(context, ref, category),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    ExerciseCategoryDef? category,
  }) async {
    final controller = TextEditingController(text: category?.nameHe ?? '');
    final isEdit = category != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'עריכת קטגוריה' : 'קטגוריה חדשה'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'שם הקטגוריה',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final uid = ref.read(currentUidProvider);
    final repo = ref.read(exerciseCategoryRepositoryProvider);
    final name = controller.text.trim();

    try {
      if (isEdit && category != null) {
        await repo.updateCategory(
          uid,
          category.copyWith(nameHe: name),
        );
      } else {
        await repo.createCategory(
          uid,
          ExerciseCategoryDef(id: '', nameHe: name),
        );
      }
    } on ExerciseCategoryRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExerciseCategoryDef category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת קטגוריה'),
        content: Text('למחוק את "${category.nameHe}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final uid = ref.read(currentUidProvider);
    try {
      await ref
          .read(exerciseCategoryRepositoryProvider)
          .deleteCategory(uid, category.id);
    } on ExerciseCategoryRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

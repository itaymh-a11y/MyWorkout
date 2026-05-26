import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/exercises/application/exercise_list_providers.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_list_tile.dart';
import 'package:myworkout/shared/models/exercise.dart';

/// בחירת תרגיל מבנק התרגילים להוספה לתוכנית.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.excludedExerciseIds,
  });

  final Set<String> excludedExerciseIds;

  static Future<Exercise?> show(
    BuildContext context, {
    required Set<String> excludedExerciseIds,
  }) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ExercisePickerSheet(
        excludedExerciseIds: excludedExerciseIds,
      ),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allExercisesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'הוסף תרגיל לתוכנית',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                hintText: 'חיפוש...',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: allAsync.when(
                data: (exercises) {
                  var list = exercises
                      .where(
                        (e) => !widget.excludedExerciseIds.contains(e.compositeId),
                      )
                      .toList();

                  if (_query.isNotEmpty) {
                    list = list.where((e) {
                      return e.name.toLowerCase().contains(_query) ||
                          e.muscleTags.any(
                            (t) => t.toLowerCase().contains(_query),
                          );
                    }).toList();
                  }

                  if (list.isEmpty) {
                    return const Center(child: Text('לא נמצאו תרגילים'));
                  }

                  return ListView.separated(
                    controller: scrollController,
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = list[index];
                      return ExerciseListTile(
                        exercise: exercise,
                        onTap: () => Navigator.pop(context, exercise),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('שגיאה: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

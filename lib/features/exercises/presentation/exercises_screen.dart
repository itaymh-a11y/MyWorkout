import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/features/exercises/application/exercise_category_providers.dart';
import 'package:myworkout/features/exercises/application/exercise_list_providers.dart';
import 'package:myworkout/features/exercises/presentation/exercise_detail_screen.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_list_tile.dart';
import 'package:myworkout/shared/models/exercise.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetail(Exercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredExercisesProvider);
    final filter = ref.watch(exerciseListFilterProvider);
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            controller: _searchController,
            hintText: 'חיפוש תרגיל או שריר...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(exerciseListFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: '');
                  },
                ),
            ],
            onChanged: (value) {
              ref.read(exerciseListFilterProvider.notifier).state =
                  filter.copyWith(searchQuery: value);
            },
          ),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) => SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FilterChip(
                    label: const Text('הכל'),
                    selected: filter.categoryId == null,
                    onSelected: (_) {
                      ref.read(exerciseListFilterProvider.notifier).state =
                          filter.copyWith(clearCategory: true);
                    },
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(category.nameHe),
                      selected: filter.categoryId == category.id,
                      onSelected: (selected) {
                        ref.read(exerciseListFilterProvider.notifier).state =
                            filter.copyWith(
                          categoryId: selected ? category.id : null,
                          clearCategory: !selected,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          loading: () => const SizedBox(
            height: 44,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: filtered.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return _EmptyState(
                  hasFilter: filter.searchQuery.isNotEmpty ||
                      filter.categoryId != null,
                );
              }

              return RefreshIndicator(
                color: AppColors.ember,
                onRefresh: () async {
                  ref.invalidate(builtinExercisesProvider);
                  ref.invalidate(exerciseOverridesProvider);
                  ref.invalidate(userExercisesProvider);
                  ref.invalidate(exerciseCategoriesProvider);
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ExerciseListTile(
                        exercise: exercise,
                        onTap: () => _openDetail(exercise),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'שגיאה בטעינת תרגילים',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'לא נמצאו תרגילים' : 'אין תרגילים עדיין',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'נסה חיפוש אחר או הסר את הסינון'
                  : 'מאגר התרגילים נטען מהאפליקציה.\nניתן גם להוסיף תרגיל מותאם בכפתור +',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

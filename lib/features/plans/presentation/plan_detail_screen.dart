import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/plans/application/plan_providers.dart';
import 'package:myworkout/features/plans/presentation/plan_form_screen.dart';
import 'package:myworkout/features/plans/presentation/widgets/exercise_picker_sheet.dart';
import 'package:myworkout/features/plans/presentation/widgets/plan_exercise_editor_sheet.dart';
import 'package:myworkout/features/plans/presentation/widgets/plan_exercise_tile.dart';
import 'package:myworkout/shared/models/exercise.dart';
import 'package:myworkout/shared/models/plan_exercise.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({
    super.key,
    required this.planId,
    this.planName,
  });

  final String planId;
  final String? planName;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  List<PlanExercise>? _localExercises;

  WorkoutPlan? _findPlan(List<WorkoutPlan> plans) {
    for (final p in plans) {
      if (p.id == widget.planId) return p;
    }
    return null;
  }

  Future<void> _persistExercises(
    WorkoutPlan plan,
    List<PlanExercise> exercises,
  ) async {
    final uid = ref.read(currentUidProvider);
    final normalized = <PlanExercise>[];
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      normalized.add(
        PlanExercise(
          id: 'order_${(i + 1).toString().padLeft(3, '0')}',
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          order: i + 1,
          exerciseType: e.exerciseType,
          setsCount: e.setsCount,
          targetWeightKg: e.targetWeightKg,
          targetReps: e.targetReps,
          targetTimeSec: e.targetTimeSec,
          restSec: e.restSec,
        ),
      );
    }
    await ref
        .read(planRepositoryProvider)
        .setPlanExercises(uid, plan.id, normalized);
    setState(() => _localExercises = normalized);
  }

  PlanExercise _fromExercise(Exercise exercise, int order) {
    return PlanExercise(
      id: 'order_${order.toString().padLeft(3, '0')}',
      exerciseId: exercise.compositeId,
      exerciseName: exercise.name,
      order: order,
      exerciseType: exercise.exerciseType,
      setsCount: exercise.defaultSets,
      targetReps: exercise.defaultReps,
      targetWeightKg: exercise.defaultWeightKg,
      targetTimeSec: exercise.defaultTimeSec,
      restSec: exercise.defaultRestSec,
    );
  }

  Future<void> _addExercise(WorkoutPlan plan, List<PlanExercise> current) async {
    final excluded = current.map((e) => e.exerciseId).toSet();
    final picked = await ExercisePickerSheet.show(
      context,
      excludedExerciseIds: excluded,
    );
    if (picked == null || !mounted) return;

    var draft = _fromExercise(picked, current.length + 1);
    final edited = await PlanExerciseEditorSheet.show(
      context,
      exercise: draft,
      planDefaultRestSec: plan.defaultRestSec,
    );
    if (edited == null || !mounted) return;

    draft = edited.copyWith(order: current.length + 1);
    await _persistExercises(plan, [...current, draft]);
  }

  Future<void> _editExercise(
    WorkoutPlan plan,
    List<PlanExercise> current,
    PlanExercise item,
  ) async {
    final edited = await PlanExerciseEditorSheet.show(
      context,
      exercise: item,
      planDefaultRestSec: plan.defaultRestSec,
    );
    if (edited == null || !mounted) return;

    final updated = current
        .map((e) => e.order == item.order ? edited.copyWith(order: item.order) : e)
        .toList();
    await _persistExercises(plan, updated);
  }

  Future<void> _removeExercise(
    WorkoutPlan plan,
    List<PlanExercise> current,
    PlanExercise item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('הסרת תרגיל'),
        content: Text('להסיר את "${item.exerciseName}" מהתוכנית?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('הסר'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final updated = current.where((e) => e.order != item.order).toList();
    await _persistExercises(plan, updated);
  }

  Future<void> _confirmDeletePlan(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת תוכנית'),
        content: Text('למחוק את "${plan.name}"?'),
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

    if (confirmed != true || !mounted) return;

    final uid = ref.read(currentUidProvider);
    await ref.read(planRepositoryProvider).deletePlan(uid, plan.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final exercisesAsync = ref.watch(planExercisesProvider(widget.planId));

    return plansAsync.when(
      data: (plans) {
        final plan = _findPlan(plans);
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.planName ?? 'תוכנית')),
            body: const Center(child: Text('התוכנית לא נמצאה')),
          );
        }

        return exercisesAsync.when(
          data: (remoteExercises) {
            final exercises = _localExercises ?? remoteExercises;

            return Scaffold(
              appBar: AppBar(
                title: Text(plan.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'ערוך תוכנית',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlanFormScreen(plan: plan),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'מחק תוכנית',
                    onPressed: () => _confirmDeletePlan(plan),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _addExercise(plan, exercises),
                icon: const Icon(Icons.add),
                label: const Text('הוסף תרגיל'),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (plan.isStarred)
                          Icon(Icons.star, color: Colors.amber.shade700),
                        if (plan.isStarred) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'מנוחה ברירת מחדל: ${plan.defaultRestSec} שניות',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text('${exercises.length} תרגילים'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: exercises.isEmpty
                        ? Center(
                            child: Text(
                              'אין תרגילים בתוכנית.\nלחץ "הוסף תרגיל".',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: exercises.length,
                            onReorder: (oldIndex, newIndex) async {
                              if (newIndex > oldIndex) newIndex--;
                              final list = List<PlanExercise>.from(exercises);
                              final item = list.removeAt(oldIndex);
                              list.insert(newIndex, item);
                              await _persistExercises(plan, list);
                            },
                            itemBuilder: (context, index) {
                              final item = exercises[index];
                              return PlanExerciseTile(
                                key: ValueKey(
                                  '${item.exerciseId}_${item.order}',
                                ),
                                index: index,
                                exercise: item,
                                onTap: () =>
                                    _editExercise(plan, exercises, item),
                                onDelete: () =>
                                    _removeExercise(plan, exercises, item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: Text(plan.name)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: Text(plan.name)),
            body: Center(child: Text('שגיאה: $e')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.planName ?? 'תוכנית')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(widget.planName ?? 'תוכנית')),
        body: Center(child: Text('שגיאה: $e')),
      ),
    );
  }
}

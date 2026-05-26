import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/workout/application/session_delete.dart';
import 'package:myworkout/features/workout/data/session_repository.dart';
import 'package:myworkout/shared/models/workout_set.dart';

final sessionDetailProvider =
    FutureProvider.family<SessionWithSets?, String>((ref, sessionId) async {
  final uid = ref.watch(currentUidProvider);
  return ref.read(sessionRepositoryProvider).getSessionWithSets(uid, sessionId);
});

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String planName,
  ) async {
    final deleted = await confirmAndDeleteSession(
      context,
      ref,
      sessionId: sessionId,
      planName: planName,
    );
    if (deleted && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('פרטי אימון'),
        actions: [
          detailAsync.maybeWhen(
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'מחק אימון',
                onPressed: () => _delete(context, ref, data.session.planName),
                icon: const Icon(Icons.delete_outline),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('האימון לא נמצא'));
          }
          final session = data.session;
          final grouped = _groupSets(data.sets);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                session.planName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${formatSessionDate(session.startedAt)} · ${formatDuration(session.durationSec)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              for (final entry in grouped.entries) ...[
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                for (final set in entry.value)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${set.setIndex}'),
                      ),
                      title: Text(formatSetActual(set)),
                      subtitle: set.completed
                          ? null
                          : const Text('לא סומן כהושלם'),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _delete(context, ref, session.planName),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'מחק אימון',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
      ),
    );
  }

  Map<String, List<WorkoutSet>> _groupSets(List<WorkoutSet> sets) {
    final map = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      map.putIfAbsent(s.exerciseName, () => []);
      map[s.exerciseName]!.add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    }
    return map;
  }
}

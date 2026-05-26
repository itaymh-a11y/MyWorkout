import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/calendar/presentation/session_detail_screen.dart';
import 'package:myworkout/features/exercises/application/exercise_stats_providers.dart';
import 'package:myworkout/features/exercises/domain/exercise_stats.dart';
import 'package:myworkout/shared/models/exercise_type.dart';
import 'package:myworkout/features/exercises/presentation/widgets/exercise_progress_chart.dart';
import 'package:myworkout/shared/widgets/async_value_view.dart';

class ExerciseStatsTab extends ConsumerWidget {
  const ExerciseStatsTab({
    super.key,
    required this.exerciseId,
    required this.exerciseType,
  });

  final String exerciseId;
  final ExerciseType exerciseType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      exerciseStatsProvider((exerciseId: exerciseId, type: exerciseType)),
    );

    return AsyncValueView(
      value: statsAsync,
      emptyMessage: 'עדיין לא בוצע תרגיל זה באימונים',
      onRetry: () => ref.invalidate(
        exerciseStatsProvider((exerciseId: exerciseId, type: exerciseType)),
      ),
      data: (stats) {
        if (stats.history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('עדיין לא בוצע תרגיל זה באימונים'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RecordsCard(records: stats.records, type: exerciseType),
            const SizedBox(height: 16),
            ExerciseProgressChart(
                history: stats.history,
                exerciseType: exerciseType,
              ),
            const SizedBox(height: 24),
            Text(
              'היסטוריית אימונים',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            for (final item in stats.history)
              _HistoryCard(
                item: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SessionDetailScreen(
                        sessionId: item.session.id,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records, required this.type});

  final ExercisePersonalRecords records;
  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];

    switch (type) {
      case ExerciseType.weightReps:
        if (records.maxWeightKg != null) {
          rows.add(_prRow('שיא משקל', '${records.maxWeightKg} ק"ג'));
        }
        if (records.maxReps != null) {
          rows.add(_prRow('שיא חזרות', '${records.maxReps}'));
        }
      case ExerciseType.repsOnly:
        if (records.maxReps != null) {
          rows.add(_prRow('שיא חזרות', '${records.maxReps}'));
        }
      case ExerciseType.time:
        if (records.maxTimeSec != null) {
          rows.add(_prRow('שיא זמן', _formatTime(records.maxTimeSec!)));
        }
    }

    if (rows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'אין עדיין שיאים — סמן סטים כהושלמו באימון',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'שיאים אישיים (PR)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _prRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
    return '$s שניות';
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final ExerciseSessionHistory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = item.session;
    final summary = item.sets.map(formatSetActual).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(session.planName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatSessionDate(session.startedAt)} · ${formatDuration(session.durationSec)}',
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

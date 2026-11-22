import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';
import 'package:myworkout/features/tracking/domain/weight_log.dart';
import 'package:myworkout/features/tracking/presentation/widgets/weight_trend_chart.dart';

class WeightTrendScreen extends ConsumerWidget {
  const WeightTrendScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeightTrendScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(weightLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('מגמת משקל')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('שגיאה: $error')),
        data: (logs) {
          final points = weightTrendPoints(logs);
          final newestFirst = List<WeightLog>.of(logs)
            ..sort((a, b) => b.weighedAt.compareTo(a.weighedAt));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WeightTrendChart(points: points),
              const SizedBox(height: 16),
              if (newestFirst.isEmpty)
                const SizedBox.shrink()
              else
                for (final log in newestFirst)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${formatGrams(log.kg)} ק״ג'),
                    subtitle: Text(formatSessionDate(log.weighedAt)),
                    trailing: IconButton(
                      tooltip: 'מחיקה',
                      onPressed: () => _delete(context, ref, log),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WeightLog log,
  ) async {
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(weightRepositoryProvider).deleteLog(uid, log.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נמחק: $error')),
        );
      }
    }
  }
}

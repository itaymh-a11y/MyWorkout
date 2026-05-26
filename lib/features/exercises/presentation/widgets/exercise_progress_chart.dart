import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/exercises/domain/exercise_stats.dart';
import 'package:myworkout/shared/models/exercise_type.dart';

/// גרף התקדמות: ציר X = תאריך אימון, ציר Y = ממוצע סטים לאותו אימון.
class ExerciseProgressChart extends StatelessWidget {
  const ExerciseProgressChart({
    super.key,
    required this.history,
    required this.exerciseType,
  });

  final List<ExerciseSessionHistory> history;
  final ExerciseType exerciseType;

  @override
  Widget build(BuildContext context) {
    final points = chartPointsFromHistory(history);
    if (points.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final weightColor = theme.colorScheme.primary;
    final repsColor = theme.colorScheme.tertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'מגמת התקדמות',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: switch (exerciseType) {
                ExerciseType.weightReps => _DualAxisChart(
                    points: points,
                    weightColor: weightColor,
                    repsColor: repsColor,
                  ),
                ExerciseType.repsOnly => _SingleSeriesChart(
                    points: points,
                    color: repsColor,
                    value: (p) => p.avgReps,
                    yLabel: (v) => _formatAvg(v),
                    legend: 'חזרות ממוצעות לאימון',
                  ),
                ExerciseType.time => _SingleSeriesChart(
                    points: points,
                    color: weightColor,
                    value: (p) => p.avgTimeSec,
                    yLabel: (v) {
                      final sec = v.toInt();
                      final m = sec ~/ 60;
                      final s = sec % 60;
                      if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
                      return '$s';
                    },
                    legend: 'זמן ממוצע לאימון (שניות)',
                  ),
              },
            ),
            const SizedBox(height: 8),
            if (exerciseType == ExerciseType.weightReps)
              _LegendRow(
                items: [
                  _LegendItem(color: weightColor, label: 'משקל ממוצע (ק"ג)'),
                  _LegendItem(color: repsColor, label: 'חזרות ממוצעות'),
                ],
              )
            else if (exerciseType == ExerciseType.repsOnly)
              _LegendRow(
                items: [
                  _LegendItem(color: repsColor, label: 'חזרות ממוצעות לאימון'),
                ],
              )
            else
              _LegendRow(
                items: [
                  _LegendItem(color: weightColor, label: 'זמן ממוצע לאימון'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DualAxisChart extends StatelessWidget {
  const _DualAxisChart({
    required this.points,
    required this.weightColor,
    required this.repsColor,
  });

  final List<SessionChartPoint> points;
  final Color weightColor;
  final Color repsColor;

  @override
  Widget build(BuildContext context) {
    final weightSpots = <FlSpot>[];
    final repsSpots = <FlSpot>[];

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.avgWeightKg != null) {
        weightSpots.add(FlSpot(i.toDouble(), p.avgWeightKg!));
      }
      if (p.avgReps != null) {
        repsSpots.add(FlSpot(i.toDouble(), p.avgReps!));
      }
    }

    if (weightSpots.isEmpty && repsSpots.isEmpty) {
      return const Center(child: Text('אין נתונים לגרף'));
    }

    final weightRange = chartYRange(weightSpots.map((s) => s.y));
    final repsRange = chartYRange(repsSpots.map((s) => s.y));

    final double minY;
    final double maxY;
    final List<FlSpot> scaledRepsSpots;
    final double repsToAxisScale;

    if (weightSpots.isNotEmpty && repsSpots.isNotEmpty) {
      minY = weightRange.minY;
      maxY = weightRange.maxY;
      repsToAxisScale =
          (maxY - minY) / math.max(repsRange.maxY - repsRange.minY, 1);
      scaledRepsSpots = repsSpots
          .map(
            (s) => FlSpot(s.x, minY + (s.y - repsRange.minY) * repsToAxisScale),
          )
          .toList();
    } else if (weightSpots.isNotEmpty) {
      minY = weightRange.minY;
      maxY = weightRange.maxY;
      repsToAxisScale = 1;
      scaledRepsSpots = const [];
    } else {
      minY = repsRange.minY;
      maxY = repsRange.maxY;
      repsToAxisScale = 1;
      scaledRepsSpots = repsSpots;
    }

    final maxX = math.max(1, points.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: true,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: repsSpots.isNotEmpty,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (repsSpots.isEmpty) return const SizedBox.shrink();
                final reps = repsRange.minY +
                    (value - minY) / math.max(repsToAxisScale, 0.001);
                return Text(
                  _formatAvg(reps),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: weightSpots.isNotEmpty,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _formatAvg(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _bottomDateLabel(value.toInt(), points),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) {
              if (touched.isEmpty) return [];
              final i = touched.first.x.toInt();
              if (i < 0 || i >= points.length) return [];
              final p = points[i];
              final lines = <String>[formatSessionDate(p.date)];
              if (p.avgWeightKg != null) {
                lines.add('ממוצע ${p.avgWeightKg!.toStringAsFixed(1)} ק"ג');
              }
              if (p.avgReps != null) {
                lines.add('ממוצע ${_formatAvg(p.avgReps!)} חזרות');
              }
              return [
                LineTooltipItem(
                  lines.join('\n'),
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ];
            },
          ),
        ),
        lineBarsData: [
          if (weightSpots.isNotEmpty)
            LineChartBarData(
              spots: weightSpots,
              isCurved: false,
              color: weightColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: weightColor.withValues(alpha: 0.08),
              ),
            ),
          if (scaledRepsSpots.isNotEmpty)
            LineChartBarData(
              spots: scaledRepsSpots,
              isCurved: false,
              color: repsColor,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: repsColor,
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );
  }
}

class _SingleSeriesChart extends StatelessWidget {
  const _SingleSeriesChart({
    required this.points,
    required this.color,
    required this.value,
    required this.yLabel,
    required this.legend,
  });

  final List<SessionChartPoint> points;
  final Color color;
  final double? Function(SessionChartPoint) value;
  final String Function(double) yLabel;
  final String legend;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final v = value(points[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('אין נתונים לגרף'));
    }

    final yRange = chartYRange(spots.map((s) => s.y));
    final maxX = math.max(1, points.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: yRange.minY,
        maxY: yRange.maxY,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                yLabel(v),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) => _bottomDateLabel(v.toInt(), points),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAvg(double v) {
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toStringAsFixed(1);
}

Widget _bottomDateLabel(int index, List<SessionChartPoint> points) {
  if (index < 0 || index >= points.length) {
    return const SizedBox.shrink();
  }
  final d = points[index].date;
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      '${d.day}/${d.month}',
      style: const TextStyle(fontSize: 10),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

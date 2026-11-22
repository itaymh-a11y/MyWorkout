import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({super.key, required this.points});

  final List<WeightTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('עדיין אין שקילות להצגה')),
      );
    }

    final weights = points.map((p) => p.kg).toList();
    final minKg = weights.reduce((a, b) => a < b ? a : b);
    final maxKg = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxKg - minKg) < 1 ? 1.0 : (maxKg - minKg) * 0.2;
    final minY = minKg - padding;
    final maxY = maxKg + padding;
    final maxX = points.length == 1 ? 1.0 : (points.length - 1).toDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.silverLight,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.silverLight),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(1),
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
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (value != index.toDouble()) return const SizedBox.shrink();
                  final day = points[index].day;
                  return Text(
                    '${day.day}.${day.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    () {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= points.length) {
                        return null;
                      }
                      final point = points[index];
                      return LineTooltipItem(
                        '${formatSessionDate(point.day)}\n${formatGrams(point.kg)} ק״ג',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }(),
                ];
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].kg),
              ],
              isCurved: false,
              color: AppColors.navy,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.navy.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}

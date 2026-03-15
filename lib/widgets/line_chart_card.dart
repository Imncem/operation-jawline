import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.values,
    required this.color,
    this.interpretation,
    this.decimals = 1,
  });

  final String title;
  final List<double> values;
  final Color color;
  final String? interpretation;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final fixedDecimals = decimals.clamp(0, 6);
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }
    final trendText = _trendText(values);
    final latestText = values.isEmpty
        ? '--'
        : values.last.toStringAsFixed(fixedDecimals);
    final minText = values.isEmpty
        ? '--'
        : values.reduce((a, b) => a < b ? a : b).toStringAsFixed(fixedDecimals);
    final maxText = values.isEmpty
        ? '--'
        : values.reduce((a, b) => a > b ? a : b).toStringAsFixed(fixedDecimals);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: spots.length < 2
                  ? const Center(child: Text('No trend data'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            color: color,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('Trend: $trendText',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('Latest: $latestText',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('Min/Max: $minText / $maxText',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if ((interpretation ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                interpretation!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _trendText(List<double> points) {
    if (points.length < 2) return 'Insufficient data';
    final delta = points.last - points.first;
    if (delta.abs() < 0.2) return 'Stable';
    if (delta > 0) return 'Rising';
    return 'Falling';
  }
}

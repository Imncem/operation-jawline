import 'package:flutter/material.dart';

import '../models/daily_mission_record.dart';

class DailyMissionCard extends StatelessWidget {
  const DailyMissionCard({
    super.key,
    required this.record,
    required this.xpMaxToday,
  });

  final DailyMissionRecord record;
  final int xpMaxToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (record.completion * 100).round();

    return Card(
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Mission',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: record.completion.clamp(0, 1),
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '$percent% completion',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: record.checkInDone
                      ? 'Check-in: Done'
                      : 'Check-in: Not done',
                  good: record.checkInDone,
                ),
                _StatusChip(
                  label: 'Workout: ${_workoutLabel(record)}',
                  good: record.workoutPercent >= 0.99,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'XP earned today: ${record.xpAwarded} / $xpMaxToday',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _workoutLabel(DailyMissionRecord record) {
    if (record.workoutSkipped) return 'Skipped';
    if (record.workoutPercent >= 0.99) return 'Completed';
    if (record.workoutPercent > 0) return 'In progress';
    return 'Not started';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.good,
  });

  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = good ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

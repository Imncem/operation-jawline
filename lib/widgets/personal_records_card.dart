import 'package:flutter/material.dart';

import '../models/personal_records.dart';
import '../session/time_accounting.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _red = Color(0xFFEF5350);
const _purple = Color(0xFFB39DDB);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class PersonalRecordsCard extends StatelessWidget {
  const PersonalRecordsCard({super.key, required this.records});

  final PersonalRecords records;

  @override
  Widget build(BuildContext context) {
    final items = [
      _RecordItem(
        tag: '01',
        label: 'LONGEST PROTOCOL',
        value: formatMmSs(records.longestProtocolSec.value),
        dateKey: records.longestProtocolSec.dateKey,
        accent: _blue,
        icon: Icons.timer_outlined,
      ),
      _RecordItem(
        tag: '02',
        label: 'BEST COMPLETION',
        value: '${records.bestCompletionPercent.value}%',
        dateKey: records.bestCompletionPercent.dateKey,
        accent: _green,
        icon: Icons.verified_outlined,
      ),
      _RecordItem(
        tag: '03',
        label: 'FASTEST FULL PROTOCOL',
        value: records.fastestFullProtocolSec.value == 0
            ? '--'
            : formatMmSs(records.fastestFullProtocolSec.value),
        dateKey: records.fastestFullProtocolSec.dateKey,
        accent: _amber,
        icon: Icons.bolt,
      ),
      _RecordItem(
        tag: '04',
        label: 'MOST PROTOCOLS / WEEK',
        value: '${records.mostProtocolsInWeek.value}',
        dateKey: records.mostProtocolsInWeek.dateKey,
        accent: _red,
        icon: Icons.calendar_view_week_outlined,
      ),
      _RecordItem(
        tag: '05',
        label: 'BEST DISCIPLINE CHAIN',
        value: '${records.bestChain.value} DAYS',
        dateKey: records.bestChain.dateKey,
        accent: _purple,
        icon: Icons.link,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : BorderSide(color: item.accent.withValues(alpha: 0.08)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Tag + icon block
                SizedBox(
                  width: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tag,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: item.accent.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(item.icon,
                          size: 14, color: item.accent.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: item.accent.withValues(alpha: 0.2)),
                const SizedBox(width: 12),

                // Label
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: _text.withValues(alpha: 0.45),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // Value + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.value == '--' ? _dim : _text,
                        letterSpacing: 1,
                      ),
                    ),
                    if (item.dateKey != null)
                      Text(
                        item.dateKey!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: item.accent.withValues(alpha: 0.55),
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _RecordItem {
  final String tag;
  final String label;
  final String value;
  final String? dateKey;
  final Color accent;
  final IconData icon;

  const _RecordItem({
    required this.tag,
    required this.label,
    required this.value,
    required this.dateKey,
    required this.accent,
    required this.icon,
  });
}

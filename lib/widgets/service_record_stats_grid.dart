import 'package:flutter/material.dart';

import '../models/service_record_summary.dart';
import '../session/time_accounting.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _red = Color(0xFFEF5350);
const _purple = Color(0xFFB39DDB);
const _surface = Color(0xFF111411);
const _text = Color(0xFFCDD4C0);

class ServiceRecordStatsGrid extends StatelessWidget {
  const ServiceRecordStatsGrid({super.key, required this.stats});

  final CareerStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTileData(
        tag: '01',
        label: 'MISSIONS\nCOMPLETED',
        value: '${stats.missionsCompleted}',
        accent: _green,
        icon: Icons.check_circle_outline,
      ),
      _StatTileData(
        tag: '02',
        label: 'PROTOCOLS\nEXECUTED',
        value: '${stats.protocolsExecuted}',
        accent: _amber,
        icon: Icons.play_arrow_rounded,
      ),
      _StatTileData(
        tag: '03',
        label: 'TIME ON\nTARGET',
        value: formatMmSs(stats.totalTimeOnTargetSec),
        accent: _blue,
        icon: Icons.timer_outlined,
      ),
      _StatTileData(
        tag: '04',
        label: 'BEST\nCHAIN',
        value: '${stats.bestDisciplineChain}D',
        accent: _amber,
        icon: Icons.link,
      ),
      _StatTileData(
        tag: '05',
        label: 'PERFECT\nPROTOCOLS',
        value: '${stats.perfectProtocols}',
        accent: _red,
        icon: Icons.verified_outlined,
      ),
      _StatTileData(
        tag: '06',
        label: 'PROMOTIONS\nACHIEVED',
        value: '${stats.promotionsAchieved}',
        accent: _purple,
        icon: Icons.military_tech_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) => _StatTile(data: tiles[index]),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _StatTileData {
  final String tag;
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _StatTileData({
    required this.tag,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final _StatTileData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: data.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.tag,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: data.accent.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              Icon(
                data.icon,
                size: 13,
                color: data.accent.withValues(alpha: 0.6),
              ),
            ],
          ),
          const Spacer(),
          // Value
          Text(
            data.value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _text,
              letterSpacing: 1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            data.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: _text.withValues(alpha: 0.35),
              letterSpacing: 1.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

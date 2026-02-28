import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bloc/mission/mission_bloc.dart';
import '../bloc/mission/mission_state.dart';
import '../models/daily_check_in.dart';
import '../progression/ranks.dart';
import '../services/leveling.dart';
import '../services/mission_progress_service.dart';
import '../widgets/daily_mission_card.dart';
import '../widgets/rise_in.dart';
import '../widgets/rank_badge.dart';
import 'intel_report_screen.dart';
import 'settings_screen.dart';

class MissionControlScreen extends StatelessWidget {
  const MissionControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        final latest = snapshot.latestCheckIn;
        final showChainAlert =
            snapshot.chainCompromised && !_isSameCalendarDay(latest?.lastCheckIn);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // ── Header ──────────────────────────────────────────────
            _SectionHeader(
              tag: 'FIELD REPORT',
              title: 'AGENT STATUS',
              subtitle: 'Mission Control online. Maintain discipline.',
            ),
            const SizedBox(height: 20),

            // ── Chain Compromised Alert ──────────────────────────────
            if (showChainAlert) ...[
              RiseIn(
                delay: const Duration(milliseconds: 40),
                child: _ChainCompromisedAlert(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Rank Badge ───────────────────────────────────────────
            RiseIn(
              delay: const Duration(milliseconds: 90),
              child: Consumer(
                builder: (context, ref, _) {
                  final progress = ref.watch(userProgressProvider).valueOrNull;
                  final level = progress?.level ?? snapshot.disciplineChain;
                  final rank = progress?.rankName ?? rankForLevel(level);
                  final toNext = levelsToNextRank(level);
                  return _TacticalCard(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CornerTag(label: 'RANK'),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RankBadge(
                                rank: rank,
                                progress: inRankProgressForLevel(level),
                                trailingText: 'LVL $level',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          toNext == 0
                              ? 'TOP RANK TIER'
                              : '$toNext LEVEL(S) TO NEXT RANK',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            color:
                                const Color(0xFFCDD4C0).withValues(alpha: 0.55),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            RiseIn(
              delay: const Duration(milliseconds: 120),
              child: Consumer(
                builder: (context, ref, _) {
                  final todayAsync = ref.watch(todayMissionProvider);
                  final progressAsync = ref.watch(userProgressProvider);

                  return todayAsync.when(
                    data: (record) {
                      final chain =
                          progressAsync.valueOrNull?.disciplineChain ??
                              snapshot.disciplineChain;
                      final xpMax = computeDailyXP(
                        dailyMissionCompletion: 1.0,
                        disciplineChain: chain,
                      );
                      return DailyMissionCard(
                          record: record, xpMaxToday: xpMax);
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Divider Label ────────────────────────────────────────
            _DividerLabel(label: 'BIOMETRIC READINGS'),
            const SizedBox(height: 12),

            // ── Stats Grid ───────────────────────────────────────────
            RiseIn(
              delay: const Duration(milliseconds: 150),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  _TacticalStatCard(
                    tag: '01',
                    label: 'BODY MASS',
                    value: _weightLabel(latest),
                    icon: Icons.monitor_weight_outlined,
                    accent: const Color(0xFFD4A017),
                  ),
                  _TacticalStatCard(
                    tag: '02',
                    label: 'ENERGY LVL',
                    value: latest == null ? '--' : '${latest.energyLevel}/10',
                    icon: Icons.bolt,
                    accent: const Color(0xFF4CAF50),
                  ),
                  _TacticalStatCard(
                    tag: '03',
                    label: 'HYDRATION',
                    value: latest == null
                        ? '--'
                        : '${latest.waterLiters.toStringAsFixed(1)} L',
                    icon: Icons.water_drop_outlined,
                    accent: const Color(0xFF29B6F6),
                  ),
                  _TacticalStatCard(
                    tag: '04',
                    label: 'DISCIPLINE',
                    value: '${snapshot.disciplineChain} DAYS',
                    icon: Icons.link,
                    accent: const Color(0xFFD4A017),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Divider Label ────────────────────────────────────────
            _DividerLabel(label: 'THREAT ASSESSMENT'),
            const SizedBox(height: 12),

            // ── Puffiness Status ─────────────────────────────────────
            RiseIn(
              delay: const Duration(milliseconds: 210),
              child: _TacticalStatusRow(
                tag: 'PUFFINESS',
                value: snapshot.puffinessStatus,
                icon: Icons.shield_moon_outlined,
              ),
            ),
            const SizedBox(height: 20),

            // ── Footer timestamp ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IntelReportScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Intel Report'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _TimestampFooter(
              latest: latest,
            ),
          ],
        );
      },
    );
  }

  static String _weightLabel(DailyCheckIn? checkIn) {
    final weight = checkIn?.weightKg;
    if (weight == null) return '--';
    return '${weight.toStringAsFixed(1)} KG';
  }

  static bool _isSameCalendarDay(DateTime? value) {
    if (value == null) return false;
    final now = DateTime.now();
    return now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.tag,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              color: const Color(0xFFD4A017),
            ),
            const SizedBox(width: 8),
            Text(
              tag,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFFD4A017),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCDD4C0),
            letterSpacing: 4,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: const Color(0xFFCDD4C0).withValues(alpha: 0.45),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Chain Compromised Alert ──────────────────────────────────────────────────

class _ChainCompromisedAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '⚠  CHAIN COMPROMISED — REBUILD IMMEDIATELY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.red,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Card (generic container) ───────────────────────────────────────

class _TacticalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _TacticalCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        border:
            Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}

// ─── Corner Tag ───────────────────────────────────────────────────────────────

class _CornerTag extends StatelessWidget {
  final String label;

  const _CornerTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          color: Color(0xFFD4A017),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ─── Divider Label ────────────────────────────────────────────────────────────

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: const Color(0xFFD4A017)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Color(0xFFD4A017),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFD4A017).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

// ─── Tactical Stat Card ───────────────────────────────────────────────────────

class _TacticalStatCard extends StatelessWidget {
  final String tag;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _TacticalStatCard({
    required this.tag,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isNull = value == '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        border: Border.all(
          color:
              isNull ? const Color(0xFF2A2E28) : accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: accent.withValues(alpha: isNull ? 0.3 : 0.7),
                  letterSpacing: 1,
                ),
              ),
              Icon(
                icon,
                size: 14,
                color: accent.withValues(alpha: isNull ? 0.3 : 0.8),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isNull ? const Color(0xFF3A4238) : const Color(0xFFCDD4C0),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: const Color(0xFFCDD4C0).withValues(alpha: 0.4),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Status Row ──────────────────────────────────────────────────────

class _TacticalStatusRow extends StatelessWidget {
  final String tag;
  final String value;
  final IconData icon;

  const _TacticalStatusRow({
    required this.tag,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        border: Border.all(
          color: const Color(0xFFD4A017).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: const Color(0xFFD4A017).withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFFD4A017),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCDD4C0),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timestamp Footer ─────────────────────────────────────────────────────────

class _TimestampFooter extends StatelessWidget {
  final DailyCheckIn? latest;

  const _TimestampFooter({required this.latest});

  @override
  Widget build(BuildContext context) {
    final hasCheckIn = latest != null;
    final label = hasCheckIn
        ? 'LAST TRANSMISSION // ${_dateLabel(latest!.lastCheckIn)}'
        : 'NO TRANSMISSION LOGGED — DAILY REPORT REQUIRED';

    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: hasCheckIn
                ? const Color(0xFF4CAF50)
                : Colors.red.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: hasCheckIn
                ? const Color(0xFFCDD4C0).withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  static String _dateLabel(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

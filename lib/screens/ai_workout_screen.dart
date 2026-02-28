import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bloc/mission/mission_bloc.dart';
import '../bloc/mission/mission_state.dart';
import '../models/enums.dart';
import '../models/recommendation_response.dart';
import '../models/workout_item.dart';
import '../models/workout_status.dart';
import '../services/mission_progress_service.dart';
import '../services/sfx_service.dart';
import '../session/session_step.dart';
import '../services/workout_recommender.dart';
import '../widgets/rise_in.dart';
import 'protocol_active_screen.dart';

// ── Palette constants ─────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class AIWorkoutScreen extends StatelessWidget {
  AIWorkoutScreen({super.key});

  final WorkoutRecommender _recommender = WorkoutRecommender();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        final latest = state.snapshot.latestCheckIn;
        final checkIn = latest?.copyWith(
          disciplineChain: state.snapshot.disciplineChain,
        );

        return FutureBuilder<RecommendationResponse>(
          future: _recommender.recommendWithProgress(checkIn),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final recommendation = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Header ───────────────────────────────────────────────
                _TacticalSectionHeader(
                  tag: 'AI NEURAL INTERFACE',
                  title: 'ZENITH',
                  subtitle:
                      'Rule-based tactical programming from latest check-in.',
                ),
                const SizedBox(height: 20),

                // ── Readiness Badge ──────────────────────────────────────
                RiseIn(
                  delay: const Duration(milliseconds: 70),
                  child: _ReadinessBadge(recommendation: recommendation),
                ),
                const SizedBox(height: 20),

                // ── Warm-up ──────────────────────────────────────────────
                _PhaseHeader(tag: '01', label: 'WARM-UP PROTOCOL'),
                const SizedBox(height: 10),
                RiseIn(
                  delay: const Duration(milliseconds: 110),
                  child: _TacticalSectionCard(
                      items: recommendation.workoutPlan.warmup),
                ),
                const SizedBox(height: 16),

                // ── Main ─────────────────────────────────────────────────
                _PhaseHeader(tag: '02', label: 'MAIN OBJECTIVE'),
                const SizedBox(height: 10),
                RiseIn(
                  delay: const Duration(milliseconds: 150),
                  child: _TacticalSectionCard(
                      items: recommendation.workoutPlan.main),
                ),

                // ── Finisher ─────────────────────────────────────────────
                if (recommendation.workoutPlan.finisher != null) ...[
                  const SizedBox(height: 16),
                  _PhaseHeader(tag: '03', label: 'FINISHER // OPTIONAL'),
                  const SizedBox(height: 10),
                  RiseIn(
                    delay: const Duration(milliseconds: 190),
                    child: _TacticalSectionCard(
                      items: [recommendation.workoutPlan.finisher!],
                      accent: _red,
                    ),
                  ),
                ],

                // ── Cooldown ─────────────────────────────────────────────
                const SizedBox(height: 16),
                _PhaseHeader(
                    tag: recommendation.workoutPlan.finisher != null
                        ? '04'
                        : '03',
                    label: 'COOLDOWN PROTOCOL'),
                const SizedBox(height: 10),
                RiseIn(
                  delay: const Duration(milliseconds: 220),
                  child: _TacticalSectionCard(
                    items: recommendation.workoutPlan.cooldown,
                    accent: _blue,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Safety Notes ─────────────────────────────────────────
                _BulletsDivider(label: 'SAFETY PROTOCOLS'),
                const SizedBox(height: 10),
                RiseIn(
                  delay: const Duration(milliseconds: 250),
                  child: _TacticalBulletsCard(
                    lines: recommendation.workoutPlan.safetyNotes,
                    accent: _red,
                    icon: Icons.shield_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Why this plan ────────────────────────────────────────
                _BulletsDivider(label: 'MISSION RATIONALE'),
                const SizedBox(height: 10),
                RiseIn(
                  delay: const Duration(milliseconds: 280),
                  child: _TacticalBulletsCard(
                    lines: recommendation.workoutPlan.explanations,
                    accent: _amber,
                    icon: Icons.psychology_outlined,
                  ),
                ),
                const SizedBox(height: 28),

                // ── CTA ──────────────────────────────────────────────────
                RiseIn(
                  delay: const Duration(milliseconds: 320),
                  child: _LaunchButton(recommendation: recommendation),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _TacticalSectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;

  const _TacticalSectionHeader({
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
            Container(width: 3, height: 14, color: _amber),
            const SizedBox(width: 8),
            Text(
              tag,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _amber,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'ZENITH',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _text,
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
            color: _text.withValues(alpha: 0.45),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Readiness Badge ──────────────────────────────────────────────────────────

class _ReadinessBadge extends StatelessWidget {
  final RecommendationResponse recommendation;

  const _ReadinessBadge({required this.recommendation});

  Color _laneColor(TrainingLane lane) {
    switch (lane) {
      case TrainingLane.hard:
        return _green;
      case TrainingLane.moderate:
        return _amber;
      case TrainingLane.light:
      case TrainingLane.recovery:
        return _red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readiness = recommendation.readiness;
    final score = readiness.readinessScore;
    final laneColor = _laneColor(readiness.lane);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: laneColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: score + lane
          Row(
            children: [
              // Score block
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: laneColor.withValues(alpha: 0.1),
                  border: Border.all(color: laneColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: laneColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      'SCORE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: laneColor.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READINESS LANE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: _text.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      readiness.lane.label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: laneColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Divider
          Container(height: 1, color: laneColor.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          // Focus + Duration
          Row(
            children: [
              Expanded(
                child: _ReadinessStat(
                  label: 'FOCUS',
                  value: readiness.focus.label.toUpperCase(),
                  accent: laneColor,
                ),
              ),
              Container(width: 1, height: 36, color: _dim),
              Expanded(
                child: _ReadinessStat(
                  label: 'DURATION',
                  value: '${readiness.durationMinutes} MIN',
                  accent: laneColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ReadinessStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: _text.withValues(alpha: 0.4),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Header ─────────────────────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final String tag;
  final String label;

  const _PhaseHeader({required this.tag, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          tag,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 10, color: _amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: _amber.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}

// ─── Bullets Divider ──────────────────────────────────────────────────────────

class _BulletsDivider extends StatelessWidget {
  final String label;

  const _BulletsDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: _amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: _amber.withValues(alpha: 0.2))),
      ],
    );
  }
}

// ─── Tactical Section Card ────────────────────────────────────────────────────

class _TacticalSectionCard extends StatelessWidget {
  final List<WorkoutItem> items;
  final Color accent;

  const _TacticalSectionCard({
    required this.items,
    this.accent = _green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return _WorkoutRow(
              item: item, accent: accent, isLast: isLast, index: index);
        }),
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutItem item;
  final Color accent;
  final bool isLast;
  final int index;

  const _WorkoutRow({
    required this.item,
    required this.accent,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final details = _buildDetails(item);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.1)),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index
          SizedBox(
            width: 22,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: accent.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _text,
                    letterSpacing: 1,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: details
                        .map((d) => _DetailChip(label: d, accent: accent))
                        .toList(),
                  ),
                ],
                if (item.note != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '▸ ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: accent.withValues(alpha: 0.6),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.note!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: _text.withValues(alpha: 0.5),
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildDetails(WorkoutItem item) {
    final details = <String>[];
    if (item.sets != null) details.add('${item.sets} SETS');
    if (item.reps != null) details.add(item.reps!.toUpperCase());
    if (item.time != null) details.add(item.time!.toUpperCase());
    if (item.restSec != null) details.add('REST ${item.restSec}S');
    return details;
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _DetailChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: accent.withValues(alpha: 0.9),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Tactical Bullets Card ────────────────────────────────────────────────────

class _TacticalBulletsCard extends StatelessWidget {
  final List<String> lines;
  final Color accent;
  final IconData icon;

  const _TacticalBulletsCard({
    required this.lines,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: List.generate(lines.length, (index) {
          final isLast = index == lines.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: accent.withValues(alpha: 0.1)),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '▸',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lines[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _text.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Launch Button ────────────────────────────────────────────────────────────

class _LaunchButton extends StatefulWidget {
  final RecommendationResponse recommendation;

  const _LaunchButton({required this.recommendation});

  @override
  State<_LaunchButton> createState() => _LaunchButtonState();
}

class _LaunchButtonState extends State<_LaunchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            SfxService.tap();
            _launch(context);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _pressed
                  ? _green.withValues(alpha: 0.2)
                  : _green.withValues(alpha: 0.1),
              border: Border.all(color: _green, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, color: _green, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'INITIATE PROTOCOL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _green,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _skipWorkout(context),
          child: const Text('SKIP WORKOUT'),
        ),
      ],
    );
  }

  Future<void> _skipWorkout(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final mission = container.read(missionServiceProvider);
    await mission.updateWorkoutEffort(
      DateTime.now(),
      plannedSec: widget.recommendation.readiness.durationMinutes * 60,
      actualSec: 0,
      status: WorkoutStatus.skipped,
      force: true,
    );
    final update = await mission.recomputeAndAwardXP(DateTime.now());
    container.invalidate(todayMissionProvider);
    container.invalidate(userProgressProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '+${update.xpDelta} XP (Protocol effort: ${(update.workoutEffortRatio * 100).round()}%)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launch(BuildContext context) async {
    SfxService.medium();

    final result = await Navigator.of(context).push<SessionResult>(
      MaterialPageRoute(
        builder: (_) =>
            ProtocolActiveScreen(recommendation: widget.recommendation),
      ),
    );

    if (!context.mounted || result == null) return;

    final pct = (result.completionPercent * 100).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _green.withValues(alpha: 0.1),
        shape: const Border(left: BorderSide(color: _green, width: 3)),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'SESSION COMPLETE // $pct% (${result.completedSteps}/${result.totalSteps} STEPS)',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: _green,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

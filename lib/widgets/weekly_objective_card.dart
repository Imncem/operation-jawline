import 'package:flutter/material.dart';

import '../models/weekly_objective.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _surface = Color(0xFF111411);
const _text = Color(0xFFCDD4C0);

class WeeklyObjectiveCard extends StatefulWidget {
  const WeeklyObjectiveCard({super.key, required this.objective});

  final WeeklyObjective objective;

  @override
  State<WeeklyObjectiveCard> createState() => _WeeklyObjectiveCardState();
}

class _WeeklyObjectiveCardState extends State<WeeklyObjectiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(
      begin: 0,
      end: widget.objective.progressRatio.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objective = widget.objective;
    final ratio = objective.progressRatio.clamp(0.0, 1.0);
    final isComplete = ratio >= 1.0;
    final accent = isComplete ? _green : _amber;
    final pct = (ratio * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              border: Border(
                  bottom: BorderSide(color: accent.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 12, color: accent),
                const SizedBox(width: 8),
                Text(
                  'WEEKLY OBJECTIVE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                // Complete badge or pct
                if (isComplete)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: _green.withValues(alpha: 0.5)),
                      color: _green.withValues(alpha: 0.1),
                    ),
                    child: const Text(
                      '✓ COMPLETE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: _green,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Objective title
                Text(
                  objective.objectiveType.title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _text,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),

                // Progress bar
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        color: accent.withValues(alpha: 0.1),
                      ),
                      FractionallySizedBox(
                        widthFactor: _anim.value,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.5),
                                  blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Progress count + XP reward
                Row(
                  children: [
                    // Segment dots
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${objective.progress}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _text,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            ' / ${objective.target}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _text.withValues(alpha: 0.4),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            objective.objectiveType.progressLabel.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              color: _text.withValues(alpha: 0.35),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // XP reward
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: accent.withValues(alpha: 0.4)),
                        color: accent.withValues(alpha: 0.07),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt,
                              size: 11, color: accent.withValues(alpha: 0.8)),
                          const SizedBox(width: 3),
                          Text(
                            '+${objective.rewardXP} XP',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

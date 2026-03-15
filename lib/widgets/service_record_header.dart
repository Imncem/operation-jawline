import 'package:flutter/material.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class ServiceRecordHeader extends StatelessWidget {
  const ServiceRecordHeader({
    super.key,
    required this.rankName,
    required this.level,
    required this.totalXP,
    required this.chainLabel,
    required this.joinDateKey,
  });

  final String rankName;
  final int level;
  final int totalXP;
  final String chainLabel;
  final String? joinDateKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rank block ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank insignia column
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.08),
                      border: Border.all(color: _amber.withValues(alpha: 0.45)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.military_tech_outlined,
                        color: _amber,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: _amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'LVL $level',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Rank name + XP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT RANK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: _text.withValues(alpha: 0.35),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rankName.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _amber,
                        letterSpacing: 2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // XP bar
                    _XpBar(totalXP: totalXP),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: _amber.withValues(alpha: 0.12)),
          const SizedBox(height: 14),

          // ── Stats row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'DISCIPLINE CHAIN',
                  value: chainLabel.toUpperCase(),
                  accent: _green,
                ),
              ),
              Container(width: 1, height: 36, color: _dim),
              Expanded(
                child: _StatCell(
                  label: 'ENLISTED',
                  value: joinDateKey ?? '--',
                  accent: _amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── XP Bar ───────────────────────────────────────────────────────────────────

class _XpBar extends StatefulWidget {
  final int totalXP;

  const _XpBar({required this.totalXP});

  @override
  State<_XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<_XpBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  // Arbitrary XP per level for display purposes
  static const _xpPerLevel = 500;

  @override
  void initState() {
    super.initState();
    final progress =
        ((widget.totalXP % _xpPerLevel) / _xpPerLevel).clamp(0.0, 1.0);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL XP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: _text.withValues(alpha: 0.35),
                letterSpacing: 2,
              ),
            ),
            Text(
              '${widget.totalXP} XP',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _amber.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Stack(
            children: [
              Container(
                  height: 3,
                  width: double.infinity,
                  color: _amber.withValues(alpha: 0.1)),
              FractionallySizedBox(
                widthFactor: _anim.value,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _amber,
                    boxShadow: [
                      BoxShadow(
                          color: _amber.withValues(alpha: 0.5), blurRadius: 5)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat Cell ────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatCell({
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
              color: _text.withValues(alpha: 0.35),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
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

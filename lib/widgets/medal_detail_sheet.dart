import 'package:flutter/material.dart';

import '../models/medal.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _purple = Color(0xFFB39DDB);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

Color _categoryAccent(String category) {
  final c = category.toLowerCase();
  if (c.contains('discipline') || c.contains('chain')) {
    return _amber;
  }
  if (c.contains('mission') || c.contains('protocol')) {
    return _green;
  }
  if (c.contains('recovery') || c.contains('wellness')) {
    return _blue;
  }
  if (c.contains('rank') || c.contains('promo') || c.contains('elite')) {
    return _purple;
  }
  if (c.contains('perfect') || c.contains('resolve')) {
    return _red;
  }
  return _amber;
}

IconData _iconFor(String key) {
  switch (key) {
    case 'radio':
      return Icons.radio_outlined;
    case 'link':
    case 'chain7':
    case 'chain30':
      return Icons.link;
    case 'play':
      return Icons.play_arrow_rounded;
    case 'perfect':
      return Icons.verified_outlined;
    case 'resolve':
      return Icons.shield_outlined;
    case 'recovery':
      return Icons.self_improvement_outlined;
    case 'promotion':
    case 'promotion5':
      return Icons.military_tech_outlined;
    case 'elite':
      return Icons.workspace_premium_outlined;
    case 'calendar':
    case 'week4':
      return Icons.event_available_outlined;
    default:
      return Icons.emoji_events_outlined;
  }
}

class MedalDetailSheet extends StatelessWidget {
  const MedalDetailSheet({super.key, required this.medal});

  final Medal medal;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(medal.category);
    final icon = _iconFor(medal.iconKey);
    final isUnlocked = medal.isUnlocked;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(
          color: isUnlocked
              ? accent.withValues(alpha: 0.45)
              : _dim.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 32,
              height: 3,
              color: accent.withValues(alpha: isUnlocked ? 0.45 : 0.2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Emblem + title block ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hex emblem
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CustomPaint(
                    painter: _HexPainter(accent: accent, locked: !isUnlocked),
                    child: Center(
                      child: Icon(
                        isUnlocked ? icon : Icons.lock_outline,
                        size: 26,
                        color: isUnlocked ? accent : _dim,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: accent.withValues(
                                  alpha: isUnlocked ? 0.45 : 0.2)),
                          color: accent.withValues(
                              alpha: isUnlocked ? 0.08 : 0.03),
                        ),
                        child: Text(
                          medal.category.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            color: accent.withValues(
                                alpha: isUnlocked ? 1.0 : 0.4),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        medal.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _text,
                          letterSpacing: 1.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status row
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isUnlocked ? _green : _dim,
                              shape: BoxShape.circle,
                              boxShadow: isUnlocked
                                  ? [
                                      BoxShadow(
                                        color: _green.withValues(alpha: 0.5),
                                        blurRadius: 5,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isUnlocked
                                ? 'AWARDED ${medal.unlockedAtDateKey ?? '--'}'
                                : 'NOT YET AWARDED',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: isUnlocked ? _green : _dim,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            height: 1,
            color: accent.withValues(alpha: 0.12),
          ),

          // ── Description ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '▸ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: accent.withValues(alpha: 0.5),
                  ),
                ),
                Expanded(
                  child: Text(
                    medal.description,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _text.withValues(alpha: 0.65),
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Hex Painter ─────────────────────────────────────────────────────────────

class _HexPainter extends CustomPainter {
  final Color accent;
  final bool locked;

  _HexPainter({required this.accent, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    List<Offset> hexPoints(double radius) => List.generate(6, (i) {
          final a = (i * 60 - 30) * 3.14159265 / 180;
          return Offset(cx + radius * _cos(a), cy + radius * _sin(a));
        });

    Path hexPath(double radius) {
      final pts = hexPoints(radius);
      return Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..addPolygon(pts, true);
    }

    canvas.drawPath(
        hexPath(r),
        Paint()
          ..color = locked
              ? _dim.withValues(alpha: 0.07)
              : accent.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill);

    canvas.drawPath(
        hexPath(r),
        Paint()
          ..color = locked
              ? _dim.withValues(alpha: 0.25)
              : accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    if (!locked) {
      canvas.drawPath(
          hexPath(r * 0.72),
          Paint()
            ..color = accent.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }
  }

  static double _cos(double r) {
    double x = r % (2 * 3.14159265);
    double res = 1, t = 1;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n - 1) * (2 * n));
      res += t;
    }
    return res;
  }

  static double _sin(double r) {
    double x = r % (2 * 3.14159265);
    double res = x, t = x;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n) * (2 * n + 1));
      res += t;
    }
    return res;
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.accent != accent || old.locked != locked;
}

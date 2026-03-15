import 'package:flutter/material.dart';

import '../progression/ranks.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class RankLadderScreen extends StatelessWidget {
  const RankLadderScreen({
    super.key,
    required this.currentLevel,
    required this.currentRank,
  });

  final int currentLevel;
  final String currentRank;

  @override
  Widget build(BuildContext context) {
    final currentIndex = kRankLadder.indexWhere((r) => r == currentRank);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context, currentIndex),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: kRankLadder.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final rank = kRankLadder[index];
          final minLevel = (index * kLevelsPerRank) + 1;
          final isLast = index == kRankLadder.length - 1;
          final maxLevel = isLast ? null : ((index + 1) * kLevelsPerRank);
          final isCurrent = rank == currentRank;
          final isUnlocked = index <= currentIndex;
          final isNext = index == currentIndex + 1;

          return _RankRow(
            index: index,
            rank: rank,
            minLevel: minLevel,
            maxLevel: maxLevel,
            isLast: isLast,
            isCurrent: isCurrent,
            isUnlocked: isUnlocked,
            isNext: isNext,
          );
        },
      ),
      bottomNavigationBar: _BottomStrip(
        currentRank: currentRank,
        currentLevel: currentLevel,
        currentIndex: currentIndex,
        total: kRankLadder.length,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int currentIndex) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F0D),
          border: Border(bottom: BorderSide(color: _amber, width: 1.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: _amber,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Container(width: 3, height: 32, color: _amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OP: JAWLINE  //  PROGRESSION',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: _amber.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'RANK LADDER',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _text,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CLEARED',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: _text.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${currentIndex + 1} / ${kRankLadder.length}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _amber,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rank Row ─────────────────────────────────────────────────────────────────

class _RankRow extends StatefulWidget {
  final int index;
  final String rank;
  final int minLevel;
  final int? maxLevel;
  final bool isLast;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isNext;

  const _RankRow({
    required this.index,
    required this.rank,
    required this.minLevel,
    required this.maxLevel,
    required this.isLast,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isNext,
  });

  @override
  State<_RankRow> createState() => _RankRowState();
}

class _RankRowState extends State<_RankRow> {
  bool _pressed = false;

  Color get _accent {
    if (widget.isCurrent) return _amber;
    if (widget.isNext) return _amber.withValues(alpha: 0.5);
    if (widget.isUnlocked) return _green;
    return _dim;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final rankNum = (widget.index + 1).toString().padLeft(2, '0');
    final levelRange = widget.isLast
        ? 'LVL ${widget.minLevel}+'
        : 'LVL ${widget.minLevel}–${widget.maxLevel}';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isCurrent
              ? _amber.withValues(alpha: _pressed ? 0.14 : 0.07)
              : _pressed
                  ? accent.withValues(alpha: 0.07)
                  : _surface,
          border: Border.all(
            color: widget.isCurrent
                ? _amber.withValues(alpha: 0.6)
                : widget.isNext
                    ? _amber.withValues(alpha: 0.2)
                    : widget.isUnlocked
                        ? _green.withValues(alpha: 0.2)
                        : _dim.withValues(alpha: 0.2),
            width: widget.isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                rankNum,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: accent.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ),

            // Status icon
            _StatusIcon(
              isCurrent: widget.isCurrent,
              isUnlocked: widget.isUnlocked,
              isNext: widget.isNext,
              accent: accent,
            ),
            const SizedBox(width: 14),

            // Rank name + level range
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rank.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isCurrent
                          ? _amber
                          : widget.isUnlocked
                              ? _text
                              : _dim,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    levelRange,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: accent.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Badge (current / unlocked / locked)
            _StatusBadge(
              isCurrent: widget.isCurrent,
              isUnlocked: widget.isUnlocked,
              isNext: widget.isNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Icon (hex with check/lock/arrow) ──────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final bool isCurrent;
  final bool isUnlocked;
  final bool isNext;
  final Color accent;

  const _StatusIcon({
    required this.isCurrent,
    required this.isUnlocked,
    required this.isNext,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (isCurrent) {
      icon = Icons.military_tech_outlined;
    } else if (isUnlocked) {
      icon = Icons.check;
    } else if (isNext) {
      icon = Icons.arrow_upward_rounded;
    } else {
      icon = Icons.lock_outline;
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _HexPainter(accent: accent),
        child: Center(
          child: Icon(icon, size: 14, color: accent),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color accent;

  _HexPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1.5;

    final pts = List.generate(6, (i) {
      final a = (i * 60 - 30) * 3.14159265 / 180;
      return Offset(cx + r * _cos(a), cy + r * _sin(a));
    });
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..addPolygon(pts, true);

    canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  static double _cos(double r) {
    double x = r % (2 * 3.14159265), res = 1, t = 1;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n - 1) * (2 * n));
      res += t;
    }
    return res;
  }

  static double _sin(double r) {
    double x = r % (2 * 3.14159265), res = x, t = x;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n) * (2 * n + 1));
      res += t;
    }
    return res;
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.accent != accent;
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isCurrent;
  final bool isUnlocked;
  final bool isNext;

  const _StatusBadge({
    required this.isCurrent,
    required this.isUnlocked,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _amber.withValues(alpha: 0.12),
          border: Border.all(color: _amber.withValues(alpha: 0.6)),
        ),
        child: const Text(
          'ACTIVE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: _amber,
            letterSpacing: 2,
          ),
        ),
      );
    }

    if (isNext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _amber.withValues(alpha: 0.25)),
        ),
        child: Text(
          'NEXT',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            color: _amber.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      );
    }

    if (isUnlocked) {
      return Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _green.withValues(alpha: 0.5), blurRadius: 4)
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'CLEARED',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: _green.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
    }

    return Text(
      'LOCKED',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 8,
        color: _dim.withValues(alpha: 0.5),
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Bottom Strip ─────────────────────────────────────────────────────────────

class _BottomStrip extends StatelessWidget {
  final String currentRank;
  final int currentLevel;
  final int currentIndex;
  final int total;

  const _BottomStrip({
    required this.currentRank,
    required this.currentLevel,
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / total;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F0D),
        border: Border(top: BorderSide(color: _amber, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              Stack(
                children: [
                  Container(
                      height: 3,
                      width: double.infinity,
                      color: _amber.withValues(alpha: 0.1)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _amber,
                        boxShadow: [
                          BoxShadow(
                              color: _amber.withValues(alpha: 0.5),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: _amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentRank.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _amber,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'LEVEL $currentLevel',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _text.withValues(alpha: 0.45),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

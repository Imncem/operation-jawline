import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medal.dart';
import '../providers/phase3_providers.dart';
import '../widgets/medal_detail_sheet.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _purple = Color(0xFFB39DDB);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

// ── Icon mapping ──────────────────────────────────────────────────────────────
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

// ── Accent color per category ─────────────────────────────────────────────────
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

class MedalsScreen extends ConsumerWidget {
  const MedalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medalsAsync = ref.watch(medalsStateProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context, medalsAsync),
      body: medalsAsync.when(
        data: (medals) => _MedalContent(medals: medals),
        loading: () => _TacticalLoader(),
        error: (error, _) =>
            _TacticalError(message: error.toString().toUpperCase()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<List<Medal>> medalsAsync,
  ) {
    final earned = medalsAsync.maybeWhen(
      data: (medals) => medals.where((m) => m.isUnlocked).length,
      orElse: () => null,
    );
    final total = medalsAsync.maybeWhen(
      data: (medals) => medals.length,
      orElse: () => null,
    );

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
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _amber,
                      size: 18,
                    ),
                  ),
                ),
                Container(width: 3, height: 32, color: _amber),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OP: JAWLINE  //  COMMENDATIONS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'MEDALS',
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
                const Spacer(),
                if (earned != null && total != null)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'AWARDED',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
                          color: _text.withValues(alpha: 0.4),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$earned / $total',
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

// ─── Medal Content ────────────────────────────────────────────────────────────

class _MedalContent extends StatelessWidget {
  final List<Medal> medals;

  const _MedalContent({required this.medals});

  @override
  Widget build(BuildContext context) {
    final unlocked = medals.where((m) => m.isUnlocked).toList();
    final locked = medals.where((m) => !m.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _MedalProgressBar(earned: unlocked.length, total: medals.length),
        const SizedBox(height: 24),
        if (unlocked.isNotEmpty) ...[
          _SectionDivider(label: 'AWARDED COMMENDATIONS'),
          const SizedBox(height: 14),
          _MedalGrid(medals: unlocked, context: context),
          const SizedBox(height: 24),
        ],
        if (locked.isNotEmpty) ...[
          _SectionDivider(label: 'CLASSIFIED // LOCKED'),
          const SizedBox(height: 14),
          _MedalGrid(medals: locked, context: context, locked: true),
        ],
      ],
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _MedalProgressBar extends StatefulWidget {
  final int earned;
  final int total;

  const _MedalProgressBar({required this.earned, required this.total});

  @override
  State<_MedalProgressBar> createState() => _MedalProgressBarState();
}

class _MedalProgressBarState extends State<_MedalProgressBar>
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
      end: widget.total == 0 ? 0 : widget.earned / widget.total,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMENDATION PROGRESS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _text.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.earned} OF ${widget.total}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _amber,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                    height: 4,
                    width: double.infinity,
                    color: _amber.withValues(alpha: 0.1)),
                FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _amber,
                      boxShadow: [
                        BoxShadow(
                            color: _amber.withValues(alpha: 0.5), blurRadius: 6)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: _amber),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: _amber,
              letterSpacing: 3,
            )),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: _amber.withValues(alpha: 0.2))),
      ],
    );
  }
}

// ─── Medal Grid ───────────────────────────────────────────────────────────────

class _MedalGrid extends StatelessWidget {
  final List<Medal> medals;
  final BuildContext context;
  final bool locked;

  const _MedalGrid({
    required this.medals,
    required this.context,
    this.locked = false,
  });

  @override
  Widget build(BuildContext ctx) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, i) => _MedalTile(
        medal: medals[i],
        locked: locked,
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => MedalDetailSheet(medal: medals[i]),
          );
        },
      ),
    );
  }
}

// ─── Medal Tile ───────────────────────────────────────────────────────────────

class _MedalTile extends StatefulWidget {
  final Medal medal;
  final bool locked;
  final VoidCallback onTap;

  const _MedalTile({
    required this.medal,
    required this.locked,
    required this.onTap,
  });

  @override
  State<_MedalTile> createState() => _MedalTileState();
}

class _MedalTileState extends State<_MedalTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final medal = widget.medal;
    final accent = widget.locked ? _dim : _categoryAccent(medal.category);
    final icon = _iconFor(medal.iconKey);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _pressed
              ? accent.withValues(alpha: 0.12)
              : widget.locked
                  ? _surface.withValues(alpha: 0.5)
                  : _surface,
          border: Border.all(
            color: _pressed
                ? accent
                : widget.locked
                    ? _dim.withValues(alpha: 0.25)
                    : accent.withValues(alpha: 0.35),
            width: _pressed ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: emblem + category chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MedalEmblem(
                  icon: widget.locked ? Icons.lock_outline : icon,
                  accent: accent,
                  locked: widget.locked,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: accent.withValues(
                            alpha: widget.locked ? 0.15 : 0.35)),
                    color:
                        accent.withValues(alpha: widget.locked ? 0.03 : 0.07),
                  ),
                  child: Text(
                    widget.locked
                        ? '???'
                        : medal.category.length > 8
                            ? '${medal.category.toUpperCase().substring(0, 8)}..'
                            : medal.category.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color:
                          accent.withValues(alpha: widget.locked ? 0.3 : 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              widget.locked ? 'CLASSIFIED' : medal.title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.locked ? _dim : _text,
                letterSpacing: 1,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            // Status dot + label
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.locked ? _dim.withValues(alpha: 0.3) : accent,
                    shape: BoxShape.circle,
                    boxShadow: widget.locked
                        ? null
                        : [
                            BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 4)
                          ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.locked ? 'LOCKED' : 'AWARDED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: widget.locked
                        ? _dim.withValues(alpha: 0.4)
                        : accent.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Medal Emblem ─────────────────────────────────────────────────────────────

class _MedalEmblem extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool locked;

  const _MedalEmblem({
    required this.icon,
    required this.accent,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _HexPainter(accent: accent, locked: locked),
        child: Center(
          child: Icon(icon, size: 18, color: locked ? _dim : accent),
        ),
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

    // Fill
    canvas.drawPath(
        hexPath(r),
        Paint()
          ..color = locked
              ? _dim.withValues(alpha: 0.07)
              : accent.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill);

    // Outer border
    canvas.drawPath(
        hexPath(r),
        Paint()
          ..color = locked
              ? _dim.withValues(alpha: 0.25)
              : accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Inner ring
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

// ─── Tactical Loader ──────────────────────────────────────────────────────────

class _TacticalLoader extends StatefulWidget {
  @override
  State<_TacticalLoader> createState() => _TacticalLoaderState();
}

class _TacticalLoaderState extends State<_TacticalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _amber.withValues(alpha: _ctrl.value * 0.8),
                      blurRadius: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RETRIEVING COMMENDATIONS...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _amber.withValues(alpha: 0.6),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Error ───────────────────────────────────────────────────────────

class _TacticalError extends StatelessWidget {
  final String message;

  const _TacticalError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off_outlined, color: _dim, size: 28),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _dim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

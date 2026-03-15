import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/mission/mission_bloc.dart';
import '../bloc/mission/mission_state.dart';
import '../models/enums.dart';
import '../models/recommendation_response.dart';
import '../services/sfx_service.dart';
import 'protocol_active_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFEF5350);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);

class MissionBriefingScreen extends StatefulWidget {
  const MissionBriefingScreen({super.key, required this.recommendation});

  final RecommendationResponse recommendation;

  @override
  State<MissionBriefingScreen> createState() => _MissionBriefingScreenState();
}

class _MissionBriefingScreenState extends State<MissionBriefingScreen>
    with TickerProviderStateMixin {
  // Typewriter controllers — one per line of intel
  late List<_TypewriterController> _typewriters;
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _countdownController;

  bool _allRevealed = false;
  bool _selfDestructStarted = false;
  int _countdown = 5;

  static const _briefingDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Build typewriter lines — will init properly in build when we have state
    _typewriters = [];

    // Kick off reveal sequence after short delay
    Future.delayed(_briefingDelay, _startRevealSequence);
  }

  void _startRevealSequence() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    for (int i = 0; i < _typewriters.length; i++) {
      if (!mounted) return;
      await _typewriters[i].start();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    setState(() => _allRevealed = true);
  }

  void _startSelfDestruct() async {
    if (_selfDestructStarted) return;
    setState(() => _selfDestructStarted = true);
    HapticFeedback.heavyImpact();

    _countdownController.forward();

    for (int i = _countdown; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    for (final t in _typewriters) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readiness = widget.recommendation.readiness;

    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        final chainCompromised = state.snapshot.chainCompromised;
        final chainStatus = chainCompromised ? 'COMPROMISED' : 'STABLE';
        final risk = readiness.riskFlags.isEmpty
            ? 'LOW'
            : readiness.lane.name == 'hard'
                ? 'MODERATE'
                : 'HIGH';

        final Color riskColor = risk == 'LOW'
            ? _green
            : risk == 'MODERATE'
                ? _amber
                : _red;

        // Build typewriter lines if not yet built
        if (_typewriters.isEmpty) {
          _typewriters = [
            _TypewriterController('OPERATIVE: AGENT JAWLINE',
                vsync: this, speed: const Duration(milliseconds: 38)),
            _TypewriterController('CLASSIFICATION: EYES ONLY',
                vsync: this, speed: const Duration(milliseconds: 38)),
            _TypewriterController(
                'OBJECTIVE: ${readiness.focus.label.toUpperCase()}',
                vsync: this,
                speed: const Duration(milliseconds: 42)),
            _TypewriterController(
                'PROTOCOL LANE: ${readiness.lane.label.toUpperCase()}',
                vsync: this,
                speed: const Duration(milliseconds: 42)),
            _TypewriterController('DURATION: ${readiness.durationMinutes} MIN',
                vsync: this, speed: const Duration(milliseconds: 42)),
            _TypewriterController('RISK ASSESSMENT: $risk',
                vsync: this, speed: const Duration(milliseconds: 42)),
            _TypewriterController('CHAIN STATUS: $chainStatus',
                vsync: this, speed: const Duration(milliseconds: 42)),
          ];
          // Restart reveal after building controllers
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startRevealSequence();
          });
        }

        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              // ── Scanline overlay ───────────────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanController,
                  builder: (_, __) => CustomPaint(
                    painter: _ScanlinePainter(_scanController.value),
                  ),
                ),
              ),

              // ── Corner brackets ────────────────────────────────────
              const Positioned(top: 52, left: 20, child: _CornerBracket()),
              const Positioned(
                  top: 52, right: 20, child: _CornerBracket(flipX: true)),
              const Positioned(
                  bottom: 40, left: 20, child: _CornerBracket(flipY: true)),
              const Positioned(
                  bottom: 40,
                  right: 20,
                  child: _CornerBracket(flipX: true, flipY: true)),

              // ── Main content ───────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _amber.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: _amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Header: Classification stamp ───────────────
                      _ClassificationHeader(pulseController: _pulseController),
                      const SizedBox(height: 32),

                      // ── Typewriter intel lines ─────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._typewriters.asMap().entries.map((e) {
                              final i = e.key;
                              final t = e.value;
                              final isSeparator = i == 2;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSeparator) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                        height: 1,
                                        color: _amber.withValues(alpha: 0.2)),
                                    const SizedBox(height: 20),
                                  ],
                                  _TypewriterLine(
                                    controller: t,
                                    isHeader: i < 2,
                                    accentOverride: i == 5
                                        ? riskColor
                                        : i == 6 && chainCompromised
                                            ? _red
                                            : null,
                                  ),
                                  SizedBox(height: i < 2 ? 6 : 14),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                      // ── Self-destruct warning ──────────────────────
                      if (_selfDestructStarted)
                        _SelfDestructBanner(countdown: _countdown),

                      // ── Action buttons ─────────────────────────────
                      AnimatedOpacity(
                        opacity: _allRevealed ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          children: [
                            _MissionButton(
                              label: 'ACCEPT MISSION',
                              icon: Icons.play_arrow_rounded,
                              accent: _green,
                              onTap: () async {
                                SfxService.tap();
                                HapticFeedback.heavyImpact();
                                _startSelfDestruct();
                                if (!context.mounted) return;
                                await Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => ProtocolActiveScreen(
                                        recommendation: widget.recommendation),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _MissionButton(
                              label: 'STAND DOWN',
                              icon: Icons.close_rounded,
                              accent: _red,
                              dimmed: true,
                              onTap: () {
                                SfxService.tap();
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Classification Header ────────────────────────────────────────────────────

class _ClassificationHeader extends StatelessWidget {
  final AnimationController pulseController;

  const _ClassificationHeader({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: pulseController,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _red.withValues(
                          alpha: 0.3 + pulseController.value * 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'INCOMING TRANSMISSION',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _red,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'MISSION\nBRIEFING',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: _text,
            letterSpacing: 4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 80, height: 2, color: _amber),
        const SizedBox(height: 8),
        Text(
          'THIS MESSAGE WILL SELF-DESTRUCT',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber.withValues(alpha: 0.5),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ─── Typewriter Line ──────────────────────────────────────────────────────────

class _TypewriterLine extends StatefulWidget {
  final _TypewriterController controller;
  final bool isHeader;
  final Color? accentOverride;

  const _TypewriterLine({
    required this.controller,
    this.isHeader = false,
    this.accentOverride,
  });

  @override
  State<_TypewriterLine> createState() => _TypewriterLineState();
}

class _TypewriterLineState extends State<_TypewriterLine> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = widget.controller.displayed;
    final isDone = widget.controller.isDone;

    if (displayed.isEmpty) return const SizedBox.shrink();

    // Split label: value at the colon
    final colonIdx = displayed.indexOf(':');
    final hasColon = colonIdx != -1 && colonIdx < displayed.length - 1;
    final label = hasColon ? displayed.substring(0, colonIdx + 1) : displayed;
    final value = hasColon ? displayed.substring(colonIdx + 1).trim() : null;
    final accent = widget.accentOverride ?? _amber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isHeader) ...[
          Text(
            '▸ ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: accent.withValues(alpha: 0.5),
            ),
          ),
        ],
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.isHeader ? 11 : 13,
                    color: widget.isHeader
                        ? _text.withValues(alpha: 0.4)
                        : _text.withValues(alpha: 0.5),
                    letterSpacing: 2,
                  ),
                ),
                if (value != null)
                  TextSpan(
                    text: '  $value',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.isHeader ? 11 : 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isHeader
                          ? _text.withValues(alpha: 0.6)
                          : accent,
                      letterSpacing: 2,
                    ),
                  ),
                // Blinking cursor
                if (!isDone)
                  TextSpan(
                    text: '█',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.isHeader ? 11 : 13,
                      color: accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Typewriter Controller ────────────────────────────────────────────────────

class _TypewriterController extends ChangeNotifier {
  final String fullText;
  final Duration speed;
  String _displayed = '';
  bool _done = false;

  _TypewriterController(this.fullText,
      {required TickerProvider vsync,
      this.speed = const Duration(milliseconds: 40)});

  String get displayed => _displayed;
  bool get isDone => _done;

  Future<void> start() async {
    for (int i = 0; i <= fullText.length; i++) {
      _displayed = fullText.substring(0, i);
      notifyListeners();
      await Future.delayed(speed);
    }
    _done = true;
    notifyListeners();
  }

  void reset() {
    _displayed = '';
    _done = false;
    notifyListeners();
  }
}

// ─── Self Destruct Banner ─────────────────────────────────────────────────────

class _SelfDestructBanner extends StatelessWidget {
  final int countdown;

  const _SelfDestructBanner({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        border: Border.all(color: _red.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _red.withValues(alpha: 0.7), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'THIS MESSAGE WILL SELF-DESTRUCT IN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: _red,
                letterSpacing: 2,
              ),
            ),
          ),
          Text(
            '$countdown',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _red,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mission Button ───────────────────────────────────────────────────────────

class _MissionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool dimmed;

  const _MissionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  State<_MissionButton> createState() => _MissionButtonState();
}

class _MissionButtonState extends State<_MissionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.dimmed
              ? accent.withValues(alpha: _pressed ? 0.1 : 0.04)
              : accent.withValues(alpha: _pressed ? 0.22 : 0.1),
          border: Border.all(
            color: widget.dimmed ? accent.withValues(alpha: 0.35) : accent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon,
                color: widget.dimmed ? accent.withValues(alpha: 0.5) : accent,
                size: 16),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.dimmed ? accent.withValues(alpha: 0.5) : accent,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corner Bracket ───────────────────────────────────────────────────────────

class _CornerBracket extends StatelessWidget {
  final bool flipX;
  final bool flipY;

  const _CornerBracket({this.flipX = false, this.flipY = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _BracketPainter()),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _amber.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, 0)
        ..lineTo(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Scanline Painter ─────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  final double progress;

  _ScanlinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final sweepY = size.height * progress;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _amber.withValues(alpha: 0),
          _amber.withValues(alpha: 0.04),
          _amber.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, sweepY - 60, size.width, 120));

    canvas.drawRect(Rect.fromLTWH(0, sweepY - 60, size.width, 120), sweepPaint);
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}



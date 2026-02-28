import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_settings_service.dart';
import '../services/sfx_service.dart';
import 'app_shell_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _scanController;
  late AnimationController _pulseController;

  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Scanline background ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (_, __) => CustomPaint(
                painter: _ScanlinePainter(_scanController.value),
              ),
            ),
          ),

          // ── Corner decorations ───────────────────────────────────
          const Positioned(top: 48, left: 24, child: _CornerBracket()),
          const Positioned(
              top: 48, right: 24, child: _CornerBracket(flipX: true)),
          const Positioned(
              bottom: 48, left: 24, child: _CornerBracket(flipY: true)),
          const Positioned(
              bottom: 48,
              right: 24,
              child: _CornerBracket(flipX: true, flipY: true)),

          // ── Content ──────────────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) => Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),

                    // ── Classification badge ─────────────────────
                    _ClassificationBadge(pulseController: _pulseController),
                    const SizedBox(height: 28),

                    // ── Title ────────────────────────────────────
                    _TitleBlock(),
                    const SizedBox(height: 36),

                    // ── Directives ───────────────────────────────
                    _DirectiveList(),

                    const Spacer(flex: 3),

                    // ── CTA ──────────────────────────────────────
                    _EnterButton(ref: ref),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Classification Badge ─────────────────────────────────────────────────────

class _ClassificationBadge extends StatelessWidget {
  final AnimationController pulseController;

  const _ClassificationBadge({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(
                      alpha: 0.3 + pulseController.value * 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CLASSIFIED  //  OPERATIONAL BRIEFING',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: _green,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ─── Title Block ──────────────────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPERATION',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: _amber,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'JAWLINE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: _text,
            letterSpacing: 6,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          width: 120,
          color: _amber,
        ),
        const SizedBox(height: 12),
        Text(
          'Facial optimization protocol.\nDiscipline-driven. Results mandatory.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: _text.withValues(alpha: 0.45),
            letterSpacing: 1,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

// ─── Directive List ───────────────────────────────────────────────────────────

class _DirectiveList extends StatelessWidget {
  static const _directives = [
    (
      tag: '01',
      label: 'DAILY CHECK-IN',
      sub: 'Submit field report every 24 hours'
    ),
    (
      tag: '02',
      label: 'EXECUTE PROTOCOL',
      sub: 'Follow ZENITH tactical programming'
    ),
    (tag: '03', label: 'RANK UP', sub: 'Build your discipline chain. Advance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_directives.length, (i) {
        final d = _directives[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DirectiveTile(tag: d.tag, label: d.label, sub: d.sub),
        );
      }),
    );
  }
}

class _DirectiveTile extends StatelessWidget {
  final String tag;
  final String label;
  final String sub;

  const _DirectiveTile({
    required this.tag,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            tag,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _amber.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 14),
          Container(
              width: 1, height: 28, color: _amber.withValues(alpha: 0.25)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _text,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _text.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enter Button ─────────────────────────────────────────────────────────────

class _EnterButton extends StatefulWidget {
  final WidgetRef ref;

  const _EnterButton({required this.ref});

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        SfxService.medium();
        await widget.ref.read(appSettingsProvider.notifier).update(
              (current) => current.copyWith(onboardingShown: true),
            );
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShellScreen()),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _pressed
              ? _amber.withValues(alpha: 0.22)
              : _amber.withValues(alpha: 0.1),
          border: Border.all(color: _amber, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ENTER MISSION CONTROL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _amber,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: _amber, size: 15),
          ],
        ),
      ),
    );
  }
}

// ─── Corner Bracket Decoration ────────────────────────────────────────────────

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
        width: 20,
        height: 20,
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

    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 60, size.width, 120),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}

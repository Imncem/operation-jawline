import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_status.dart';
import '../services/mission_progress_service.dart';
import '../services/sfx_service.dart';
import '../settings/reminder_settings_controller.dart';
import '../session/time_accounting.dart';
import '../session/session_step.dart';
import 'promotion_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);

class ProtocolCompleteScreen extends StatefulWidget {
  const ProtocolCompleteScreen({super.key, required this.result});

  final SessionResult result;

  @override
  State<ProtocolCompleteScreen> createState() => _ProtocolCompleteScreenState();
}

class _ProtocolCompleteScreenState extends State<ProtocolCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _glowController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  MissionUpdateResult? _missionUpdate;

  @override
  void initState() {
    super.initState();
    SfxService.heavy();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
    _syncFinalMissionProgress();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final percent = (result.completionPercent * 100).round();
    final isPerfect = percent == 100;
    final accentColor = isPerfect ? _green : _amber;
    final debriefText = _buildDebriefText(result);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Mission Debriefed Header ─────────────────────────
                _MissionResultHeader(
                  percent: percent,
                  isPerfect: isPerfect,
                  accentColor: accentColor,
                  glowController: _glowController,
                  debriefText: debriefText,
                ),
                const SizedBox(height: 28),

                // ── Divider ──────────────────────────────────────────
                _SectionDivider(label: 'DEBRIEF // PERFORMANCE DATA'),
                const SizedBox(height: 14),

                // ── Stats Grid ───────────────────────────────────────
                _StatsGrid(result: result, accentColor: accentColor),
                const SizedBox(height: 20),
                _EffortStrip(result: result),
                const SizedBox(height: 14),

                // ── Completion Bar ───────────────────────────────────
                _CompletionBar(
                  percent: percent,
                  accentColor: accentColor,
                ),
                if (_missionUpdate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Check-in XP: +${_missionUpdate!.checkInXP}  Protocol XP: +${_missionUpdate!.protocolXP}  Bonus: +${_missionUpdate!.completionBonusXP}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _text.withValues(alpha: 0.6),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TOTAL TODAY: ${_missionUpdate!.xpToday} / ${_missionUpdate!.xpMaxToday}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _text.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Skipped warning (if any) ─────────────────────────
                if (result.skippedSteps > 0) ...[
                  _SkippedWarning(skipped: result.skippedSteps),
                  const SizedBox(height: 20),
                ],

                const Spacer(),

                // ── Return button ────────────────────────────────────
                _ReturnButton(
                  result: result,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildDebriefText(SessionResult result) {
    if (result.completionPercent >= 0.99 && result.skippedSteps == 0) {
      return 'Perfect execution. All objectives completed with zero skips.';
    }
    if (result.skippedSteps > 0) {
      return 'Debrief: objectives were skipped. Re-run protocol to tighten discipline.';
    }
    return 'Solid partial completion. Build consistency and push the next session.';
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
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
                Container(width: 3, height: 20, color: _green),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZENITH // SESSION ENDED',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _text,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'OP: JAWLINE  //  DEBRIEF',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber,
                        letterSpacing: 2,
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

  Future<void> _syncFinalMissionProgress() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final mission = container.read(missionServiceProvider);
    await mission.updateWorkoutEffort(
      DateTime.now(),
      plannedSec: widget.result.plannedSec,
      actualSec: widget.result.actualSec,
      status: widget.result.status,
      force: true,
    );
    final update = await mission.recomputeAndAwardXP(DateTime.now());
    if (widget.result.status == WorkoutStatus.completed) {
      await container
          .read(reminderSettingsProvider.notifier)
          .rescheduleWorkoutForNextDay();
    }
    container.invalidate(todayMissionProvider);
    container.invalidate(userProgressProvider);
    if (!mounted) return;
    setState(() => _missionUpdate = update);
    if (update.xpDelta > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '+${update.xpDelta} XP (Mission ${(update.dailyCompletion * 100).round()}%)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (update.promoted && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PromotionScreen(
            previousRank: update.previousRankName,
            newRank: update.rankName,
          ),
        ),
      );
    }
  }
}

// ─── Mission Result Header ────────────────────────────────────────────────────

class _MissionResultHeader extends StatelessWidget {
  final int percent;
  final bool isPerfect;
  final Color accentColor;
  final AnimationController glowController;
  final String debriefText;

  const _MissionResultHeader({
    required this.percent,
    required this.isPerfect,
    required this.accentColor,
    required this.glowController,
    required this.debriefText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large score block
        AnimatedBuilder(
          animation: glowController,
          builder: (_, __) => Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              border: Border.all(
                color: accentColor.withValues(
                    alpha: 0.4 + glowController.value * 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                      alpha: 0.08 + glowController.value * 0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percent',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: accentColor.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Title block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPerfect ? 'PERFECT' : 'MISSION',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: accentColor,
                  letterSpacing: 4,
                ),
              ),
              Text(
                isPerfect ? 'EXECUTION' : 'COMPLETE',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _text,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                debriefText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _text.withValues(alpha: 0.45),
                  letterSpacing: 1,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
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

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _EffortStrip extends StatelessWidget {
  const _EffortStrip({required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final effortPct = (result.effortRatio * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOCOL EFFORT: $effortPct%',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _amber,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TIME ON TARGET: ${formatMmSs(result.actualSec)} / ${formatMmSs(result.plannedSec)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _text.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final SessionResult result;
  final Color accentColor;

  const _StatsGrid({required this.result, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            tag: '01',
            label: 'TIME ON TARGET',
            value: _formatTime(result.totalElapsedSec),
            accent: accentColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            tag: '02',
            label: 'STEPS COMPLETED',
            value: '${result.completedSteps}/${result.totalSteps}',
            accent: accentColor,
          ),
        ),
      ],
    );
  }

  static String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

class _StatTile extends StatelessWidget {
  final String tag;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.tag,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: accent.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _text,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: _text.withValues(alpha: 0.35),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completion Bar ───────────────────────────────────────────────────────────

class _CompletionBar extends StatefulWidget {
  final int percent;
  final Color accentColor;

  const _CompletionBar({required this.percent, required this.accentColor});

  @override
  State<_CompletionBar> createState() => _CompletionBarState();
}

class _CompletionBarState extends State<_CompletionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _barAnim = Tween<double>(begin: 0, end: widget.percent / 100).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPLETION RATE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _text.withValues(alpha: 0.4),
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.percent}%',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.accentColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  color: widget.accentColor.withValues(alpha: 0.1),
                ),
                FractionallySizedBox(
                  widthFactor: _barAnim.value,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
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

// ─── Skipped Warning ─────────────────────────────────────────────────────────

class _SkippedWarning extends StatelessWidget {
  final int skipped;

  const _SkippedWarning({required this.skipped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.06),
        border: Border.all(color: _red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(color: _red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            '$skipped ${skipped == 1 ? 'STEP' : 'STEPS'} SKIPPED — REVIEW AND IMPROVE',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _red,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Return Button ────────────────────────────────────────────────────────────

class _ReturnButton extends StatefulWidget {
  final SessionResult result;
  final Color accentColor;

  const _ReturnButton({required this.result, required this.accentColor});

  @override
  State<_ReturnButton> createState() => _ReturnButtonState();
}

class _ReturnButtonState extends State<_ReturnButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        SfxService.selection();
        SfxService.tap();
        Navigator.of(context).pop(widget.result);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: _pressed ? 0.22 : 0.1),
          border: Border.all(color: widget.accentColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_rounded, color: widget.accentColor, size: 15),
            const SizedBox(width: 10),
            Text(
              'RETURN TO ZENITH',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

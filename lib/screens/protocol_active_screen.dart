import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_response.dart';
import '../services/mission_progress_service.dart';
import '../services/sfx_service.dart';
import '../session/session_builder.dart';
import '../session/session_controller.dart';
import '../session/session_step.dart';
import 'protocol_complete_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class ProtocolActiveScreen extends StatefulWidget {
  const ProtocolActiveScreen({super.key, required this.recommendation});

  final RecommendationResponse recommendation;

  @override
  State<ProtocolActiveScreen> createState() => _ProtocolActiveScreenState();
}

class _ProtocolActiveScreenState extends State<ProtocolActiveScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final SessionController _controller;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  bool _shouldResumeAfterBackground = false;
  bool _completionRouted = false;
  double _lastProgress = 0;
  ProviderContainer? _providerContainer;
  DateTime _lastMissionSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  double _lastMissionSyncProgress = 0;
  bool _missionSyncInFlight = false;
  bool _missionCompletionToastSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final steps = SessionBuilder().build(widget.recommendation.workoutPlan);
    _controller = SessionController(steps: steps);
    _controller.addListener(_onSessionTick);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer ??= ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _shouldResumeAfterBackground = !_controller.state.isPaused;
      _controller.pause();
    } else if (state == AppLifecycleState.resumed &&
        _shouldResumeAfterBackground) {
      _shouldResumeAfterBackground = false;
      _controller.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onSessionTick);
    _controller.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onSessionTick() {
    final state = _controller.state;
    final progress = state.overallProgress.clamp(0.0, 1.0);
    final now = DateTime.now();
    final dueByTime =
        now.difference(_lastMissionSyncAt) >= const Duration(seconds: 2);
    final dueByProgress = (progress - _lastMissionSyncProgress).abs() >= 0.05;
    final shouldSync = !_missionSyncInFlight &&
        (state.isCompleted || dueByTime || dueByProgress);
    if (!shouldSync) return;

    _missionSyncInFlight = true;
    unawaited(
      _syncMissionProgress(
        progress,
        skipped: state.skippedSteps > 0,
        notifyOnCompletion: state.isCompleted && !_missionCompletionToastSent,
      ),
    );
  }

  Future<void> _syncMissionProgress(
    double progress, {
    required bool skipped,
    required bool notifyOnCompletion,
  }) async {
    try {
      final container = _providerContainer ??
          ProviderScope.containerOf(context, listen: false);
      final mission = container.read(missionServiceProvider);
      await mission.updateWorkoutProgress(DateTime.now(), progress,
          skipped: skipped);
      final update = await mission.recomputeAndAwardXP(DateTime.now());
      _lastMissionSyncAt = DateTime.now();
      _lastMissionSyncProgress = progress;
      container.invalidate(todayMissionProvider);
      container.invalidate(userProgressProvider);

      if (notifyOnCompletion && mounted && update.xpDelta > 0) {
        _missionCompletionToastSent = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '+${update.xpDelta} XP (Mission ${(update.dailyCompletion * 100).round()}%)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _missionSyncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state.isCompleted && state.result != null && !_completionRouted) {
          _completionRouted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ProtocolCompleteScreen(result: state.result!),
              ),
            );
          });
        }

        // Animate progress bar
        if (state.overallProgress != _lastProgress) {
          _lastProgress = state.overallProgress;
          _progressController.animateTo(state.overallProgress,
              curve: Curves.easeOut);
        }

        final current = state.currentStep;
        final isPaused = state.isPaused;

        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(state),
          body: SafeArea(
            child: Column(
              children: [
                // ── HUD Progress Strip ───────────────────────────────
                _HudProgressStrip(
                  progressController: _progressController,
                  state: state,
                  pulseController: _pulseController,
                  isPaused: isPaused,
                ),

                // ── Main Content ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: current == null
                        ? _NoStepsPlaceholder()
                        : _CurrentStepCard(
                            state: state,
                            pulseController: _pulseController,
                            onCompleteSet: () {
                              HapticFeedback.mediumImpact();
                              SfxService.tap();
                              _controller.completeSet();
                            },
                            onTogglePause: () {
                              HapticFeedback.selectionClick();
                              SfxService.tap();
                              _controller.togglePause();
                            },
                            onSkip: () {
                              HapticFeedback.lightImpact();
                              SfxService.tap();
                              _controller.skipCurrentStep();
                            },
                          ),
                  ),
                ),

                // ── Up Next ──────────────────────────────────────────
                _UpNextBanner(state: state),

                // ── Controls ─────────────────────────────────────────
                _ControlBar(
                  state: state,
                  onPrevious: () {
                    HapticFeedback.selectionClick();
                    SfxService.tap();
                    _controller.previousStep();
                  },
                  onTogglePause: () {
                    HapticFeedback.selectionClick();
                    SfxService.tap();
                    _controller.togglePause();
                  },
                  onSkip: () {
                    HapticFeedback.lightImpact();
                    SfxService.tap();
                    _controller.skipCurrentStep();
                  },
                  onEndSession: _confirmEndSession,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SessionState state) {
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
                // Back
                GestureDetector(
                  onTap: _confirmEndSession,
                  child:
                      const Icon(Icons.chevron_left, color: _amber, size: 20),
                ),
                const SizedBox(width: 8),
                Container(width: 3, height: 20, color: _amber),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZENITH // PROTOCOL ACTIVE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _text,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'STEP ${state.currentIndex >= state.totalSteps ? state.totalSteps : state.currentIndex + 1} OF ${state.totalSteps}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Elapsed
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ELAPSED',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: _text.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _formatTime(state.elapsedSec),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
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

  Future<void> _confirmEndSession() async {
    HapticFeedback.heavyImpact();
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _surface,
        shape: const RoundedRectangleBorder(),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _red.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 16, color: _red),
                  const SizedBox(width: 10),
                  const Text(
                    'ABORT PROTOCOL?',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _red,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Current progress will be finalized. This action cannot be undone.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _text.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        SfxService.tap();
                        Navigator.of(context).pop(false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _dim),
                        ),
                        child: const Center(
                          child: Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: _text,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        SfxService.alert();
                        Navigator.of(context).pop(true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.1),
                          border: Border.all(color: _red),
                        ),
                        child: const Center(
                          child: Text(
                            'ABORT',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _red,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldEnd == true) {
      final result = _controller.endSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => ProtocolCompleteScreen(result: result)),
      );
    }
  }

  static String _formatTime(int totalSec) {
    final min = (totalSec ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSec % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

// ─── HUD Progress Strip ───────────────────────────────────────────────────────

class _HudProgressStrip extends StatelessWidget {
  final AnimationController progressController;
  final AnimationController pulseController;
  final SessionState state;
  final bool isPaused;

  const _HudProgressStrip({
    required this.progressController,
    required this.pulseController,
    required this.state,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0D0F0D),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status dot + label
              Row(
                children: [
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPaused ? _amber : _green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPaused ? _amber : _green).withValues(
                                alpha: isPaused
                                    ? 0.4
                                    : pulseController.value * 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaused ? 'PAUSED' : 'ACTIVE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: isPaused ? _amber : _green,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              // Remaining
              Text(
                'ETA ${_formatTime(state.estimatedRemainingSec)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _text.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRect(
            child: AnimatedBuilder(
              animation: progressController,
              builder: (_, __) {
                return Stack(
                  children: [
                    // Track
                    Container(
                      height: 3,
                      width: double.infinity,
                      color: _amber.withValues(alpha: 0.1),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: progressController.value,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: _amber,
                          boxShadow: [
                            BoxShadow(
                              color: _amber.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(int totalSec) {
    final min = (totalSec ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSec % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

// ─── Current Step Card ────────────────────────────────────────────────────────

class _CurrentStepCard extends StatelessWidget {
  final SessionState state;
  final AnimationController pulseController;
  final VoidCallback onCompleteSet;
  final VoidCallback onTogglePause;
  final VoidCallback onSkip;

  const _CurrentStepCard({
    required this.state,
    required this.pulseController,
    required this.onCompleteSet,
    required this.onTogglePause,
    required this.onSkip,
  });

  Color get _phaseColor {
    final label = state.currentStep?.phase.label.toLowerCase() ?? '';
    if (label.contains('warm')) return _blue;
    if (label.contains('cool')) return _blue;
    if (label.contains('finish')) return _red;
    if (label.contains('rest')) return _amber;
    return _green;
  }

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep!;
    final accent = _phaseColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase tag bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: accent.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(width: 3, height: 12, color: accent),
                const SizedBox(width: 8),
                Text(
                  step.phase.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                _KindChip(kind: step.kind, accent: accent),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    step.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _text,
                      letterSpacing: 2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content by step kind
                  if (step.kind == SessionStepKind.set)
                    _SetContent(step: step, state: state, accent: accent)
                  else if (step.kind == SessionStepKind.timed)
                    _TimedContent(
                        state: state,
                        accent: accent,
                        pulseController: pulseController)
                  else
                    _RestContent(
                        state: state, pulseController: pulseController),

                  const Spacer(),

                  // Primary action
                  if (step.kind == SessionStepKind.set)
                    _TacticalButton(
                      label: 'COMPLETE SET',
                      icon: Icons.check,
                      accent: accent,
                      onTap: onCompleteSet,
                    )
                  else if (step.kind == SessionStepKind.timed)
                    _TacticalButton(
                      label: state.isPaused ? 'RESUME TIMER' : 'PAUSE TIMER',
                      icon: state.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      accent: accent,
                      onTap: onTogglePause,
                    )
                  else
                    _TacticalButton(
                      label: 'SKIP REST',
                      icon: Icons.fast_forward_rounded,
                      accent: _amber,
                      onTap: onSkip,
                      dimmed: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final SessionStepKind kind;
  final Color accent;

  const _KindChip({required this.kind, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Text(
        kind.name.toUpperCase(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          color: accent,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ─── Set Content ──────────────────────────────────────────────────────────────

class _SetContent extends StatelessWidget {
  final SessionStep step;
  final SessionState state;
  final Color accent;

  const _SetContent({
    required this.step,
    required this.state,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Set progress
        if (step.setIndex != null && step.totalSets != null) ...[
          _DataRow(
            label: 'SET',
            value: '${step.setIndex} / ${step.totalSets}',
            accent: accent,
          ),
          const SizedBox(height: 8),
          // Set indicator dots
          Row(
            children: List.generate(step.totalSets!, (i) {
              final done = i < (step.setIndex! - 1);
              final current = i == step.setIndex! - 1;
              return Container(
                width: 28,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: done
                      ? accent
                      : current
                          ? accent.withValues(alpha: 0.4)
                          : accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
        if (step.reps != null)
          _DataRow(
              label: 'REPS', value: step.reps!.toUpperCase(), accent: accent),
        if (step.note != null) ...[
          const SizedBox(height: 12),
          _NoteRow(note: step.note!),
        ],
      ],
    );
  }
}

// ─── Timed Content ────────────────────────────────────────────────────────────

class _TimedContent extends StatelessWidget {
  final SessionState state;
  final Color accent;
  final AnimationController pulseController;

  const _TimedContent({
    required this.state,
    required this.accent,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) => Text(
            _formatTime(state.currentStepRemainingSec),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: state.isPaused
                  ? accent.withValues(alpha: 0.3 + pulseController.value * 0.5)
                  : accent,
              letterSpacing: 6,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'REMAINING',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: accent.withValues(alpha: 0.5),
            letterSpacing: 3,
          ),
        ),
        if (state.currentStep?.note != null) ...[
          const SizedBox(height: 14),
          _NoteRow(note: state.currentStep!.note!),
        ],
      ],
    );
  }

  static String _formatTime(int totalSec) {
    final min = (totalSec ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSec % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

// ─── Rest Content ─────────────────────────────────────────────────────────────

class _RestContent extends StatelessWidget {
  final SessionState state;
  final AnimationController pulseController;

  const _RestContent({required this.state, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) => Text(
            _formatTime(state.currentStepRemainingSec),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color:
                  _amber.withValues(alpha: 0.5 + pulseController.value * 0.4),
              letterSpacing: 6,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RECOVERY INTERVAL',
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

  static String _formatTime(int totalSec) {
    final min = (totalSec ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSec % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

// ─── Data Row ─────────────────────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DataRow(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label  ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: accent.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _text,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Note Row ─────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final String note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
        color: _amber.withValues(alpha: 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('▸ ',
              style: TextStyle(
                  color: _amber.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                  fontSize: 10)),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _text.withValues(alpha: 0.6),
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Button ──────────────────────────────────────────────────────────

class _TacticalButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool dimmed;

  const _TacticalButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  State<_TacticalButton> createState() => _TacticalButtonState();
}

class _TacticalButtonState extends State<_TacticalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        SfxService.tap();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.dimmed
              ? accent.withValues(alpha: _pressed ? 0.12 : 0.05)
              : accent.withValues(alpha: _pressed ? 0.25 : 0.12),
          border: Border.all(
            color: widget.dimmed ? accent.withValues(alpha: 0.3) : accent,
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

// ─── Up Next Banner ───────────────────────────────────────────────────────────

class _UpNextBanner extends StatelessWidget {
  final SessionState state;

  const _UpNextBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final next = state.nextStep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F0D),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2420)),
          bottom: BorderSide(color: Color(0xFF1E2420)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'NEXT  ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: _text.withValues(alpha: 0.3),
              letterSpacing: 2,
            ),
          ),
          Container(width: 1, height: 10, color: _dim),
          const SizedBox(width: 10),
          Text(
            next == null ? 'MISSION COMPLETE' : next.name.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: next == null ? _green : _text.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
          if (next == null) ...[
            const SizedBox(width: 8),
            Icon(Icons.emoji_events_outlined,
                size: 12, color: _green.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
  }
}

// ─── Control Bar ─────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final SessionState state;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePause;
  final VoidCallback onSkip;
  final VoidCallback onEndSession;

  const _ControlBar({
    required this.state,
    required this.onPrevious,
    required this.onTogglePause,
    required this.onSkip,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF0D0F0D),
      child: Column(
        children: [
          // Step nav row
          Row(
            children: [
              _ControlButton(
                label: '◂ PREV',
                enabled: state.currentIndex > 0,
                onTap: onPrevious,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                label: state.isPaused ? '▶ RESUME' : '⏸ PAUSE',
                accent: _amber,
                onTap: onTogglePause,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                label: 'SKIP ▸',
                onTap: onSkip,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // End session
          GestureDetector(
            onTap: onEndSession,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: _red.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(
                  'ABORT PROTOCOL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _red.withValues(alpha: 0.6),
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool enabled;

  const _ControlButton({
    required this.label,
    required this.onTap,
    this.accent,
    this.enabled = true,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? _dim;
    final enabled = widget.enabled;

    return Expanded(
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                SfxService.tap();
                widget.onTap();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                _pressed ? accent.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: enabled
                  ? accent.withValues(alpha: 0.4)
                  : _dim.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: enabled ? accent : _dim.withValues(alpha: 0.3),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── No Steps Placeholder ─────────────────────────────────────────────────────

class _NoStepsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _dim),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_off_outlined, color: _dim, size: 32),
            const SizedBox(height: 12),
            const Text(
              'NO STEPS IN PROTOCOL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _dim,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

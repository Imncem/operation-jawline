import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_step.dart';

class SessionState {
  const SessionState({
    required this.steps,
    required this.outcomes,
    required this.currentIndex,
    required this.currentStepRemainingSec,
    required this.currentStepElapsedSec,
    required this.elapsedSec,
    required this.isPaused,
    required this.isCompleted,
    this.result,
  });

  factory SessionState.initial(List<SessionStep> steps) {
    final first = steps.isEmpty ? null : steps.first;
    final firstDuration =
        first?.isTimed == true ? (first!.durationSec ?? 0) : 0;

    return SessionState(
      steps: List.unmodifiable(steps),
      outcomes: List<StepOutcome>.filled(steps.length, StepOutcome.pending),
      currentIndex: steps.isEmpty ? 0 : 0,
      currentStepRemainingSec: firstDuration,
      currentStepElapsedSec: 0,
      elapsedSec: 0,
      isPaused: false,
      isCompleted: steps.isEmpty,
      result: steps.isEmpty
          ? const SessionResult(
              totalSteps: 0,
              completedSteps: 0,
              skippedSteps: 0,
              totalElapsedSec: 0,
              completionPercent: 0,
            )
          : null,
    );
  }

  final List<SessionStep> steps;
  final List<StepOutcome> outcomes;
  final int currentIndex;
  final int currentStepRemainingSec;
  final int currentStepElapsedSec;
  final int elapsedSec;
  final bool isPaused;
  final bool isCompleted;
  final SessionResult? result;

  SessionStep? get currentStep =>
      currentIndex >= 0 && currentIndex < steps.length
          ? steps[currentIndex]
          : null;

  SessionStep? get nextStep =>
      currentIndex + 1 < steps.length ? steps[currentIndex + 1] : null;

  int get totalSteps => steps.length;

  int get completedSteps =>
      outcomes.where((outcome) => outcome == StepOutcome.completed).length;

  int get skippedSteps =>
      outcomes.where((outcome) => outcome == StepOutcome.skipped).length;

  double get stepProgressWithinCurrent {
    if (isCompleted || totalSteps == 0) return 1;

    final current = currentStep;
    if (current == null) return 0;

    if (current.isTimed) {
      final duration = current.durationSec ?? 0;
      if (duration <= 0) return 1;
      return (currentStepElapsedSec / duration).clamp(0, 1);
    }

    final outcome = outcomes[currentIndex];
    return outcome == StepOutcome.pending ? 0 : 1;
  }

  double get overallProgress {
    if (totalSteps == 0) return 0;
    if (isCompleted) return 1;

    return ((currentIndex + stepProgressWithinCurrent) / totalSteps)
        .clamp(0, 1);
  }

  int get estimatedRemainingSec {
    if (isCompleted) return 0;

    var remaining = 0;
    final current = currentStep;
    if (current != null) {
      if (current.isTimed) {
        remaining += currentStepRemainingSec;
      } else if (outcomes[currentIndex] == StepOutcome.pending) {
        remaining += 30;
      }
    }

    for (var i = currentIndex + 1; i < steps.length; i++) {
      final step = steps[i];
      if (outcomes[i] != StepOutcome.pending) continue;
      if (step.isTimed) {
        remaining += step.durationSec ?? 0;
      } else {
        remaining += 30;
      }
    }

    return remaining;
  }

  SessionState copyWith({
    List<SessionStep>? steps,
    List<StepOutcome>? outcomes,
    int? currentIndex,
    int? currentStepRemainingSec,
    int? currentStepElapsedSec,
    int? elapsedSec,
    bool? isPaused,
    bool? isCompleted,
    SessionResult? result,
    bool clearResult = false,
  }) {
    return SessionState(
      steps: steps ?? this.steps,
      outcomes: outcomes ?? this.outcomes,
      currentIndex: currentIndex ?? this.currentIndex,
      currentStepRemainingSec:
          currentStepRemainingSec ?? this.currentStepRemainingSec,
      currentStepElapsedSec:
          currentStepElapsedSec ?? this.currentStepElapsedSec,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class SessionController extends ChangeNotifier {
  SessionController({required List<SessionStep> steps})
      : _state = SessionState.initial(steps) {
    _ensureTicker();
  }

  SessionState _state;
  SessionState get state => _state;

  Timer? _ticker;

  void pause() {
    if (_state.isCompleted || _state.isPaused) return;
    _state = _state.copyWith(isPaused: true);
    notifyListeners();
  }

  void resume() {
    if (_state.isCompleted || !_state.isPaused) return;
    _state = _state.copyWith(isPaused: false);
    _ensureTicker();
    notifyListeners();
  }

  void togglePause() {
    if (_state.isPaused) {
      resume();
    } else {
      pause();
    }
  }

  void completeSet() {
    final current = _state.currentStep;
    if (current == null || current.kind != SessionStepKind.set) return;
    _markCurrentAndAdvance(StepOutcome.completed);
  }

  void skipCurrentStep() {
    if (_state.isCompleted) return;
    _markCurrentAndAdvance(StepOutcome.skipped);
  }

  void completeCurrentTimedStep() {
    if (_state.isCompleted) return;
    _markCurrentAndAdvance(StepOutcome.completed);
  }

  void previousStep() {
    if (_state.currentIndex <= 0 || _state.isCompleted) return;

    final previousIndex = _state.currentIndex - 1;
    final previousStep = _state.steps[previousIndex];

    _state = _state.copyWith(
      currentIndex: previousIndex,
      currentStepRemainingSec:
          previousStep.isTimed ? (previousStep.durationSec ?? 0) : 0,
      currentStepElapsedSec: 0,
      clearResult: true,
    );
    notifyListeners();
  }

  SessionResult endSession() {
    if (!_state.isCompleted) {
      final outcomes = List<StepOutcome>.from(_state.outcomes);
      for (var i = _state.currentIndex; i < outcomes.length; i++) {
        if (outcomes[i] == StepOutcome.pending) {
          outcomes[i] = StepOutcome.skipped;
        }
      }
      _state = _state.copyWith(outcomes: outcomes);
    }

    final result = _buildResult();
    _state = _state.copyWith(isCompleted: true, isPaused: true, result: result);
    notifyListeners();
    return result;
  }

  void _markCurrentAndAdvance(StepOutcome outcome) {
    if (_state.isCompleted || _state.currentIndex >= _state.totalSteps) return;

    final outcomes = List<StepOutcome>.from(_state.outcomes);
    outcomes[_state.currentIndex] = outcome;

    final nextIndex = _state.currentIndex + 1;
    if (nextIndex >= _state.totalSteps) {
      final result = _buildResult(outcomesOverride: outcomes);
      _state = _state.copyWith(
        outcomes: outcomes,
        currentIndex: _state.totalSteps,
        currentStepRemainingSec: 0,
        currentStepElapsedSec: 0,
        isCompleted: true,
        isPaused: true,
        result: result,
      );
      notifyListeners();
      return;
    }

    final nextStep = _state.steps[nextIndex];
    _state = _state.copyWith(
      outcomes: outcomes,
      currentIndex: nextIndex,
      currentStepRemainingSec:
          nextStep.isTimed ? (nextStep.durationSec ?? 0) : 0,
      currentStepElapsedSec: 0,
    );
    _ensureTicker();
    notifyListeners();
  }

  SessionResult _buildResult({List<StepOutcome>? outcomesOverride}) {
    final outcomes = outcomesOverride ?? _state.outcomes;
    final completed =
        outcomes.where((it) => it == StepOutcome.completed).length;
    final skipped = outcomes.where((it) => it == StepOutcome.skipped).length;
    final total = _state.totalSteps;
    final completionPercent = total == 0 ? 0.0 : (completed / total);

    return SessionResult(
      totalSteps: total,
      completedSteps: completed,
      skippedSteps: skipped,
      totalElapsedSec: _state.elapsedSec,
      completionPercent: completionPercent,
    );
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (_state.isPaused || _state.isCompleted) {
      return;
    }

    var nextElapsed = _state.elapsedSec + 1;
    var stepRemaining = _state.currentStepRemainingSec;
    var stepElapsed = _state.currentStepElapsedSec;

    final current = _state.currentStep;
    if (current != null && current.isTimed) {
      stepRemaining = (stepRemaining - 1).clamp(0, 1 << 20);
      stepElapsed = stepElapsed + 1;

      if (stepRemaining <= 0) {
        _state = _state.copyWith(
          elapsedSec: nextElapsed,
          currentStepRemainingSec: 0,
          currentStepElapsedSec: stepElapsed,
        );
        _markCurrentAndAdvance(StepOutcome.completed);
        return;
      }
    }

    _state = _state.copyWith(
      elapsedSec: nextElapsed,
      currentStepRemainingSec: stepRemaining,
      currentStepElapsedSec: stepElapsed,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}

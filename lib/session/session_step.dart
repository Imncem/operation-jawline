import 'package:equatable/equatable.dart';

import '../models/enums.dart';
import '../models/workout_status.dart';

enum SessionStepKind { timed, set, rest }

enum SessionPhase { warmup, main, finisher, cooldown, rest }

enum StepOutcome { pending, completed, skipped }

extension SessionPhaseX on SessionPhase {
  String get label {
    switch (this) {
      case SessionPhase.warmup:
        return 'Warm-up';
      case SessionPhase.main:
        return 'Main';
      case SessionPhase.finisher:
        return 'Main';
      case SessionPhase.cooldown:
        return 'Cooldown';
      case SessionPhase.rest:
        return 'Rest';
    }
  }
}

class SessionStep extends Equatable {
  const SessionStep({
    required this.id,
    required this.kind,
    required this.phase,
    required this.name,
    this.sourceName,
    this.durationSec,
    this.setIndex,
    this.totalSets,
    this.reps,
    this.note,
  });

  final int id;
  final SessionStepKind kind;
  final SessionPhase phase;
  final String name;
  final String? sourceName;
  final int? durationSec;
  final int? setIndex;
  final int? totalSets;
  final String? reps;
  final String? note;

  bool get isTimed =>
      kind == SessionStepKind.timed || kind == SessionStepKind.rest;

  @override
  List<Object?> get props => [
        id,
        kind,
        phase,
        name,
        sourceName,
        durationSec,
        setIndex,
        totalSets,
        reps,
        note,
      ];
}

class SessionResult extends Equatable {
  const SessionResult({
    required this.totalSteps,
    required this.completedSteps,
    required this.skippedSteps,
    required this.totalElapsedSec,
    required this.completionPercent,
    required this.plannedSec,
    required this.actualSec,
    required this.effortRatio,
    required this.status,
    this.lane,
  });

  final int totalSteps;
  final int completedSteps;
  final int skippedSteps;
  final int totalElapsedSec;
  final double completionPercent;
  final int plannedSec;
  final int actualSec;
  final double effortRatio;
  final WorkoutStatus status;
  final TrainingLane? lane;

  @override
  List<Object?> get props => [
        totalSteps,
        completedSteps,
        skippedSteps,
        totalElapsedSec,
        completionPercent,
        plannedSec,
        actualSec,
        effortRatio,
        status,
        lane,
      ];
}

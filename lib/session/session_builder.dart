import '../models/workout_item.dart';
import '../models/workout_plan.dart';
import 'session_step.dart';

class SessionBuilder {
  List<SessionStep> build(WorkoutPlan plan) {
    final steps = <SessionStep>[];
    var id = 0;

    void addStep(SessionStep step) {
      steps.add(step);
      id += 1;
    }

    void addItem(WorkoutItem item, SessionPhase phase) {
      final parsedSec = parseDurationToSec(item.time);
      final sets = item.sets ?? 0;

      if (parsedSec != null) {
        addStep(
          SessionStep(
            id: id,
            kind: SessionStepKind.timed,
            phase: phase,
            name: item.name,
            sourceName: item.name,
            durationSec: parsedSec,
            note: item.note,
          ),
        );
        return;
      }

      if (sets > 0) {
        for (var i = 1; i <= sets; i++) {
          addStep(
            SessionStep(
              id: id,
              kind: SessionStepKind.set,
              phase: phase,
              name: item.name,
              sourceName: item.name,
              setIndex: i,
              totalSets: sets,
              reps: item.reps,
              note: item.note,
            ),
          );

          // Keep rest between sets only; no final trailing rest.
          if (item.restSec != null && item.restSec! > 0 && i < sets) {
            addStep(
              SessionStep(
                id: id,
                kind: SessionStepKind.rest,
                phase: SessionPhase.rest,
                name: 'Rest',
                sourceName: item.name,
                durationSec: item.restSec,
              ),
            );
          }
        }
        return;
      }

      addStep(
        SessionStep(
          id: id,
          kind: SessionStepKind.set,
          phase: phase,
          name: item.name,
          sourceName: item.name,
          setIndex: 1,
          totalSets: 1,
          reps: item.reps,
          note: item.note,
        ),
      );
    }

    for (final item in plan.warmup) {
      addItem(item, SessionPhase.warmup);
    }
    for (final item in plan.main) {
      addItem(item, SessionPhase.main);
    }
    if (plan.finisher != null) {
      addItem(plan.finisher!, SessionPhase.finisher);
    }
    for (final item in plan.cooldown) {
      addItem(item, SessionPhase.cooldown);
    }

    return steps;
  }

  static int? parseDurationToSec(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final lower = raw.toLowerCase();
    final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    if (numericMatch == null) return null;

    final value = double.tryParse(numericMatch.group(1)!);
    if (value == null) return null;

    if (lower.contains('min')) {
      return (value * 60).round();
    }
    if (lower.contains('sec') || lower.contains('s')) {
      return value.round();
    }

    return null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/workout_item.dart';
import 'package:operation_jawline/models/workout_plan.dart';
import 'package:operation_jawline/session/session_builder.dart';
import 'package:operation_jawline/session/session_step.dart';

void main() {
  test('warm-up timed item 3 min becomes one timed step 180 sec', () {
    final plan = WorkoutPlan(
      warmup: const [WorkoutItem(name: 'Walk', time: '3 min')],
      main: const [],
      finisher: null,
      cooldown: const [],
      safetyNotes: const [],
      explanations: const [],
    );

    final steps = SessionBuilder().build(plan);

    expect(steps.length, 1);
    expect(steps.first.kind, SessionStepKind.timed);
    expect(steps.first.durationSec, 180);
    expect(steps.first.phase, SessionPhase.warmup);
  });

  test('main item sets=3 rest=75 creates set/rest chain without final rest',
      () {
    final plan = WorkoutPlan(
      warmup: const [],
      main: const [
        WorkoutItem(name: 'Push-Up', sets: 3, reps: '8-10', restSec: 75),
      ],
      finisher: null,
      cooldown: const [],
      safetyNotes: const [],
      explanations: const [],
    );

    final steps = SessionBuilder().build(plan);

    expect(steps.length, 5);
    expect(steps[0].kind, SessionStepKind.set);
    expect(steps[1].kind, SessionStepKind.rest);
    expect(steps[1].durationSec, 75);
    expect(steps[2].kind, SessionStepKind.set);
    expect(steps[3].kind, SessionStepKind.rest);
    expect(steps[4].kind, SessionStepKind.set);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/readiness_result.dart';
import 'package:operation_jawline/models/workout_item.dart';
import 'package:operation_jawline/models/workout_plan.dart';
import 'package:operation_jawline/zenith/workout_progression.dart';

void main() {
  test('strength progression increases set count to max 4', () {
    const engine = WorkoutProgressionEngine();
    const readiness = ReadinessResult(
      readinessScore: 80,
      lane: TrainingLane.hard,
      focus: WorkoutFocus.strength,
      durationMinutes: 45,
      riskFlags: [],
    );
    final plan = WorkoutPlan(
      templateId: 'strength_full_body_a',
      warmup: const [],
      main: const [
        WorkoutItem(name: 'Squat', sets: 3, reps: '8-10', restSec: 75)
      ],
      cooldown: const [],
      safetyNotes: const [],
      explanations: const [],
    );
    final next = engine.apply(
      plan: plan,
      readiness: readiness,
      templateId: 'strength_full_body_a',
      memory: const WorkoutProgressMemory(
        templateId: 'strength_full_body_a',
        completed: true,
        hadSafetyFlags: false,
      ),
    );
    expect(next.main.first.sets, 4);
  });

  test('mobility plan does not progress', () {
    const engine = WorkoutProgressionEngine();
    const readiness = ReadinessResult(
      readinessScore: 40,
      lane: TrainingLane.light,
      focus: WorkoutFocus.mobility,
      durationMinutes: 20,
      riskFlags: [],
    );
    final plan = WorkoutPlan(
      templateId: 'mobility_recovery',
      warmup: const [],
      main: const [WorkoutItem(name: 'Mobility', time: '10 min')],
      cooldown: const [],
      safetyNotes: const [],
      explanations: const [],
    );
    final next = engine.apply(
      plan: plan,
      readiness: readiness,
      templateId: 'mobility_recovery',
      memory: const WorkoutProgressMemory(
        templateId: 'mobility_recovery',
        completed: true,
        hadSafetyFlags: false,
      ),
    );
    expect(next.main.first.time, '10 min');
  });
}

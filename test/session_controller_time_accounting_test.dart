import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/session/session_controller.dart';
import 'package:operation_jawline/session/session_step.dart';
import 'package:operation_jawline/session/time_accounting.dart';

void main() {
  test('timed and rest steps are counted in actual time', () {
    fakeAsync((async) {
      final controller = SessionController(
        plannedWorkoutSec: 30,
        steps: const [
          SessionStep(
            id: 0,
            kind: SessionStepKind.timed,
            phase: SessionPhase.warmup,
            name: 'Warmup',
            durationSec: 5,
          ),
          SessionStep(
            id: 1,
            kind: SessionStepKind.rest,
            phase: SessionPhase.rest,
            name: 'Rest',
            durationSec: 5,
          ),
        ],
      );

      async.elapse(const Duration(seconds: 11));
      expect(controller.state.actualWorkoutSec, 10);
      expect(controller.state.result?.status, WorkoutStatus.completed);
      controller.dispose();
    });
  });

  test('set steps are capped for counted time', () {
    fakeAsync((async) {
      final controller = SessionController(
        plannedWorkoutSec: 300,
        steps: const [
          SessionStep(
            id: 0,
            kind: SessionStepKind.set,
            phase: SessionPhase.main,
            name: 'Push-up',
            setIndex: 1,
            totalSets: 1,
            reps: '10',
          ),
        ],
      );

      async.elapse(const Duration(seconds: 130));
      expect(controller.state.actualWorkoutSec, kMaxSetStepCountedSec);
      controller.completeSet();
      final result = controller.state.result!;
      expect(result.actualSec, kMaxSetStepCountedSec);
      controller.dispose();
    });
  });
}

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/session/session_controller.dart';
import 'package:operation_jawline/session/session_step.dart';

void main() {
  test('controller does not crash when restSec is null pattern', () {
    final controller = SessionController(
      steps: const [
        SessionStep(
          id: 0,
          kind: SessionStepKind.set,
          phase: SessionPhase.main,
          name: 'Bodyweight Squat',
          setIndex: 1,
          totalSets: 1,
          reps: '10',
        ),
      ],
    );

    controller.completeSet();

    expect(controller.state.isCompleted, true);
    expect(controller.state.result, isNotNull);
    controller.dispose();
  });

  test('pausing stops timer increments and resume continues', () {
    fakeAsync((async) {
      final controller = SessionController(
        steps: const [
          SessionStep(
            id: 0,
            kind: SessionStepKind.timed,
            phase: SessionPhase.warmup,
            name: 'Walk',
            durationSec: 10,
          ),
        ],
      );

      async.elapse(const Duration(seconds: 3));
      expect(controller.state.elapsedSec, 3);
      expect(controller.state.currentStepRemainingSec, 7);

      controller.pause();
      async.elapse(const Duration(seconds: 4));
      expect(controller.state.elapsedSec, 3);
      expect(controller.state.currentStepRemainingSec, 7);

      controller.resume();
      async.elapse(const Duration(seconds: 2));
      expect(controller.state.elapsedSec, 5);
      expect(controller.state.currentStepRemainingSec, 5);
      controller.dispose();
    });
  });

  test('endSession returns summary result object', () {
    final controller = SessionController(
      steps: const [
        SessionStep(
          id: 0,
          kind: SessionStepKind.set,
          phase: SessionPhase.main,
          name: 'Push-Up',
          setIndex: 1,
          totalSets: 1,
          reps: '8-10',
        ),
        SessionStep(
          id: 1,
          kind: SessionStepKind.timed,
          phase: SessionPhase.cooldown,
          name: 'Breathing',
          durationSec: 60,
        ),
      ],
    );

    final result = controller.endSession();

    expect(result.totalSteps, 2);
    expect(result.completedSteps + result.skippedSteps, 2);
    expect(result.completionPercent, inInclusiveRange(0, 1));
    controller.dispose();
  });
}

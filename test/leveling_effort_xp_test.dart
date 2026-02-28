import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/services/leveling.dart';

void main() {
  test('50% effort with check-in gives 80 xp using completion bonus rule', () {
    final effort = 900 / 1800;
    final credit = computeWorkoutCredit(
      status: WorkoutStatus.aborted,
      effortRatio: effort,
    );
    final completion = computeDailyCompletionFromWorkoutCredit(
      checkInDone: true,
      workoutCredit: credit,
    );
    final bonus = computeCompletionBonusXP(
      status: WorkoutStatus.aborted,
      effortRatio: effort,
      dailyCompletion: completion,
    );
    final xp = computeDailyXP(
      dailyMissionCompletion: completion,
      disciplineChain: 0,
      completionBonusXP: bonus,
    );

    expect(completion, closeTo(0.75, 0.0001));
    expect(xp, 80);
  });

  test('5% effort gives no workout credit, check-in only xp', () {
    final effort = 90 / 1800;
    final credit = computeWorkoutCredit(
      status: WorkoutStatus.aborted,
      effortRatio: effort,
    );
    final completion = computeDailyCompletionFromWorkoutCredit(
      checkInDone: true,
      workoutCredit: credit,
    );
    final xp = computeDailyXP(
      dailyMissionCompletion: completion,
      disciplineChain: 0,
      completionBonusXP: computeCompletionBonusXP(
        status: WorkoutStatus.aborted,
        effortRatio: effort,
        dailyCompletion: completion,
      ),
    );
    expect(credit, 0);
    expect(xp, 50);
  });

  test('skipped workout gives 55 xp with check-in', () {
    final credit = computeWorkoutCredit(
      status: WorkoutStatus.skipped,
      effortRatio: 0,
    );
    final completion = computeDailyCompletionFromWorkoutCredit(
      checkInDone: true,
      workoutCredit: credit,
    );
    final xp = computeDailyXP(
      dailyMissionCompletion: completion,
      disciplineChain: 0,
      completionBonusXP: computeCompletionBonusXP(
        status: WorkoutStatus.skipped,
        effortRatio: 0,
        dailyCompletion: completion,
      ),
    );
    expect(completion, closeTo(0.55, 0.0001));
    expect(xp, 55);
  });
}

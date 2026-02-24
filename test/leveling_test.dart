import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/services/leveling.dart';

void main() {
  test('daily mission completion formula', () {
    final completion = computeDailyMissionCompletion(
      checkInDone: true,
      workoutCompletionPercent: 0.6,
      workoutSkipped: false,
    );
    expect(completion, closeTo(0.8, 0.0001));
  });

  test('skip behavior applies workout floor', () {
    final completion = computeDailyMissionCompletion(
      checkInDone: true,
      workoutCompletionPercent: 0.0,
      workoutSkipped: true,
    );
    expect(completion, closeTo(0.55, 0.0001));
  });

  test('streak bonus applies at 7 and 14 days', () {
    expect(
      computeDailyXP(dailyMissionCompletion: 1.0, disciplineChain: 0),
      100,
    );
    expect(
      computeDailyXP(dailyMissionCompletion: 1.0, disciplineChain: 7),
      110,
    );
    expect(
      computeDailyXP(dailyMissionCompletion: 1.0, disciplineChain: 14),
      120,
    );
  });

  test('xp threshold growth is 15 percent rounded', () {
    expect(xpThresholdForLevel(1), 300);
    expect(xpThresholdForLevel(2), 345);
    expect(xpThresholdForLevel(3), 397);
  });
}

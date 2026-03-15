import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/records/personal_records_engine.dart';

void main() {
  const engine = PersonalRecordsEngine();

  DailyMissionRecord mission({
    required String dateKey,
    required int actual,
    required double effort,
    required WorkoutStatus status,
  }) {
    return DailyMissionRecord(
      dateKey: dateKey,
      checkInDone: true,
      xpAwarded: 0,
      completion: 1.0,
      plannedWorkoutSec: 1800,
      actualWorkoutSec: actual,
      workoutEffortRatio: effort,
      workoutStatus: status,
      lastWorkoutUpdateTs: 0,
      workoutLane: TrainingLane.moderate,
    );
  }

  test('longest protocol updates', () {
    final records = engine.recompute(
      missions: [
        mission(
          dateKey: '2026-02-24',
          actual: 1200,
          effort: 0.7,
          status: WorkoutStatus.completed,
        ),
        mission(
          dateKey: '2026-02-25',
          actual: 1500,
          effort: 0.8,
          status: WorkoutStatus.completed,
        ),
      ],
      bestChain: 5,
    );

    expect(records.longestProtocolSec.value, 1500);
    expect(records.longestProtocolSec.dateKey, '2026-02-25');
  });

  test('fastest full protocol updates only when effort is full and completed',
      () {
    final records = engine.recompute(
      missions: [
        mission(
          dateKey: '2026-02-24',
          actual: 1300,
          effort: 0.8,
          status: WorkoutStatus.completed,
        ),
        mission(
          dateKey: '2026-02-25',
          actual: 1400,
          effort: 1.0,
          status: WorkoutStatus.completed,
        ),
        mission(
          dateKey: '2026-02-26',
          actual: 1100,
          effort: 1.0,
          status: WorkoutStatus.aborted,
        ),
      ],
      bestChain: 5,
    );

    expect(records.fastestFullProtocolSec.value, 1400);
    expect(records.fastestFullProtocolSec.dateKey, '2026-02-25');
  });
}

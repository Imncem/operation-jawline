import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/weekly_objective.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/services/mission_progress_service.dart';
import 'package:operation_jawline/services/weekly_objective_service.dart';
import 'package:operation_jawline/weekly/weekly_objective_engine.dart';

class _InMemoryStorage implements MissionStorageAdapter {
  final Map<String, String> _store = {};

  @override
  Future<String?> getString(String key) async => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
}

void main() {
  const engine = WeeklyObjectiveEngine();

  DailyMissionRecord protocol(String dateKey, {TrainingLane? lane}) {
    return DailyMissionRecord(
      dateKey: dateKey,
      checkInDone: true,
      xpAwarded: 0,
      completion: 1.0,
      plannedWorkoutSec: 1800,
      actualWorkoutSec: 900,
      workoutEffortRatio: 0.6,
      workoutStatus: WorkoutStatus.completed,
      lastWorkoutUpdateTs: 0,
      workoutLane: lane ?? TrainingLane.moderate,
    );
  }

  test('correct objective rotation by week', () {
    final week1 = engine.createForWeek('2026-W09');
    final week2 = engine.createForWeek('2026-W10', previousWeekKey: '2026-W09');
    final week3 = engine.createForWeek('2026-W11', previousWeekKey: '2026-W10');

    expect(week1.objectiveType, WeeklyObjectiveType.protocols4);
    expect(week2.objectiveType, WeeklyObjectiveType.chain5);
    expect(week3.objectiveType, WeeklyObjectiveType.recovery2);
  });

  test('progress tracking for protocols_4', () {
    final objective = WeeklyObjective(
      weekKey: '2026-W09',
      objectiveType: WeeklyObjectiveType.protocols4,
      target: 4,
      progress: 0,
      completed: false,
      completedAtDateKey: null,
      rewardXP: 50,
      rewardMedalId: 'weekly_objective_1',
      rewardClaimed: false,
    );

    final updated = engine.recompute(
      objective,
      missions: [
        protocol('2026-02-23'),
        protocol('2026-02-24'),
      ],
      checkIns: const [],
    );

    expect(updated.progress, 2);
    expect(updated.completed, isFalse);
  });

  test('completion reward awarding once', () async {
    final service = WeeklyObjectiveService(storage: _InMemoryStorage());
    final now = DateTime(2026, 2, 25);
    final missions = [
      protocol('2026-02-23'),
      protocol('2026-02-24'),
      protocol('2026-02-25'),
      protocol('2026-02-26'),
    ];
    final checkIns = List.generate(
      4,
      (index) => DailyCheckIn(
        energy: 6,
        sleepHours: 7,
        waterLiters: 2,
        weightKg: 80,
        mood: Mood.good,
        puffiness: 2,
        disciplineChain: 4,
        lastCheckIn: now.add(Duration(days: index)),
      ),
    );

    final first = await service.refresh(
      now: now,
      missions: missions,
      checkIns: checkIns,
    );
    final second = await service.refresh(
      now: now,
      missions: missions,
      checkIns: checkIns,
    );

    expect(first.rewardGranted, isTrue);
    expect(second.rewardGranted, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/medals/medal_catalog.dart';
import 'package:operation_jawline/medals/medal_engine.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/promotion_history_entry.dart';
import 'package:operation_jawline/models/user_progress.dart';
import 'package:operation_jawline/models/workout_status.dart';

void main() {
  const engine = MedalEngine();

  DailyMissionRecord mission({
    required String dateKey,
    bool checkInDone = true,
    double effort = 0,
    WorkoutStatus status = WorkoutStatus.notStarted,
    TrainingLane? lane,
    int actual = 0,
  }) {
    return DailyMissionRecord(
      dateKey: dateKey,
      checkInDone: checkInDone,
      xpAwarded: 0,
      completion: 1.0,
      plannedWorkoutSec: 1800,
      actualWorkoutSec: actual,
      workoutEffortRatio: effort,
      workoutStatus: status,
      lastWorkoutUpdateTs: 0,
      workoutLane: lane,
    );
  }

  UserProgress progress({
    int bestChain = 0,
    String rank = 'Recruit',
    List<PromotionHistoryEntry> promotions = const [],
  }) {
    return UserProgress(
      totalXP: 0,
      level: 1,
      rankName: rank,
      disciplineChain: bestChain,
      lastCheckInDateKey: '2026-03-01',
      joinDateKey: '2026-02-01',
      bestChain: bestChain,
      promotionHistory: promotions,
    );
  }

  test('first_checkin unlocks', () {
    final medals = engine.evaluate(
      medals: kMedalCatalog,
      missions: [mission(dateKey: '2026-03-01')],
      checkIns: const [],
      progress: progress(),
      currentObjective: null,
      objectiveArchive: const [],
      dateKey: '2026-03-01',
    );

    expect(
      medals.firstWhere((item) => item.id == 'first_checkin').isUnlocked,
      isTrue,
    );
  });

  test('chain_3 unlocks', () {
    final medals = engine.evaluate(
      medals: kMedalCatalog,
      missions: const [],
      checkIns: const [],
      progress: progress(bestChain: 3),
      currentObjective: null,
      objectiveArchive: const [],
      dateKey: '2026-03-01',
    );

    expect(
        medals.firstWhere((item) => item.id == 'chain_3').isUnlocked, isTrue);
  });

  test('first_protocol unlocks', () {
    final medals = engine.evaluate(
      medals: kMedalCatalog,
      missions: [
        mission(
          dateKey: '2026-03-01',
          effort: 0.25,
          status: WorkoutStatus.completed,
          actual: 600,
        ),
      ],
      checkIns: const [],
      progress: progress(),
      currentObjective: null,
      objectiveArchive: const [],
      dateKey: '2026-03-01',
    );

    expect(
      medals.firstWhere((item) => item.id == 'first_protocol').isUnlocked,
      isTrue,
    );
  });

  test('first_promotion unlocks', () {
    final medals = engine.evaluate(
      medals: kMedalCatalog,
      missions: const [],
      checkIns: const [],
      progress: progress(
        promotions: const [
          PromotionHistoryEntry(
            dateKey: '2026-03-01',
            fromRank: 'Recruit',
            toRank: 'Private',
          ),
        ],
      ),
      currentObjective: null,
      objectiveArchive: const [],
      dateKey: '2026-03-01',
    );

    expect(
      medals.firstWhere((item) => item.id == 'first_promotion').isUnlocked,
      isTrue,
    );
  });

  test('elite_operator unlocks', () {
    final medals = engine.evaluate(
      medals: kMedalCatalog,
      missions: const [],
      checkIns: const [],
      progress: progress(rank: 'Elite Operator'),
      currentObjective: null,
      objectiveArchive: const [],
      dateKey: '2026-03-01',
    );

    expect(
      medals.firstWhere((item) => item.id == 'elite_operator').isUnlocked,
      isTrue,
    );
  });
}

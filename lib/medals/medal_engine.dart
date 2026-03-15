import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/medal.dart';
import '../models/user_progress.dart';
import '../models/workout_status.dart';
import '../models/weekly_objective.dart';
import '../progression/ranks.dart';
import '../weekly/weekly_objective_engine.dart';

class MedalEngine {
  const MedalEngine();

  List<Medal> evaluate({
    required List<Medal> medals,
    required List<DailyMissionRecord> missions,
    required List<DailyCheckIn> checkIns,
    required UserProgress progress,
    required WeeklyObjective? currentObjective,
    required List<WeeklyObjective> objectiveArchive,
    required String dateKey,
  }) {
    final checkInsByDate = {
      for (final item in checkIns) _dateKey(item.lastCheckIn): item,
    };
    final unlocked = <String>{};

    if (missions.any((m) => m.checkInDone)) unlocked.add('first_checkin');
    if (progress.bestChain >= 3) unlocked.add('chain_3');
    if (progress.bestChain >= 7) unlocked.add('chain_7');
    if (progress.bestChain >= 30) unlocked.add('chain_30');
    if (missions
        .any((m) => m.actualWorkoutSec > 0 && m.workoutEffortRatio >= 0.25)) {
      unlocked.add('first_protocol');
    }
    if (missions.any((m) =>
        m.workoutStatus == WorkoutStatus.completed &&
        m.workoutEffortRatio >= 1.0)) {
      unlocked.add('perfect_protocol');
    }
    if (missions.any((m) {
      final checkIn = checkInsByDate[m.dateKey];
      return checkIn != null &&
          checkIn.energy <= 3 &&
          m.workoutStatus == WorkoutStatus.completed &&
          m.workoutEffortRatio >= 0.75;
    })) {
      unlocked.add('iron_resolve');
    }

    final completedRecoveryDates = missions
        .where((m) =>
            m.workoutLane?.name == 'recovery' &&
            m.workoutStatus == WorkoutStatus.completed &&
            m.workoutEffortRatio >= 0.25)
        .map((m) => m.dateKey)
        .toList()
      ..sort();
    if (_maxConsecutiveDays(completedRecoveryDates) >= 3) {
      unlocked.add('recovery_specialist');
    }

    if (progress.promotionHistory.isNotEmpty) unlocked.add('first_promotion');
    if (progress.promotionHistory.length >= 5) unlocked.add('promotion_5');
    if (progress.rankName == kRankLadder.last) unlocked.add('elite_operator');

    final allObjectives = [
      ...objectiveArchive,
      if (currentObjective != null) currentObjective,
    ];
    if (allObjectives.any((objective) => objective.completed)) {
      unlocked.add('weekly_objective_1');
    }

    final weeklyProtocolCounts = <String, int>{};
    for (final mission in missions) {
      if (mission.workoutEffortRatio >= 0.25 && mission.actualWorkoutSec > 0) {
        final weekKey = isoWeekKey(DateTime.parse(mission.dateKey));
        weeklyProtocolCounts.update(weekKey, (value) => value + 1,
            ifAbsent: () => 1);
      }
    }
    if (weeklyProtocolCounts.values.any((count) => count >= 4)) {
      unlocked.add('weekly_protocol_4');
    }

    return medals.map((medal) {
      if (medal.isUnlocked || !unlocked.contains(medal.id)) return medal;
      return medal.copyWith(isUnlocked: true, unlockedAtDateKey: dateKey);
    }).toList();
  }

  int _maxConsecutiveDays(List<String> dateKeys) {
    if (dateKeys.isEmpty) return 0;
    var best = 1;
    var current = 1;
    for (var i = 1; i < dateKeys.length; i++) {
      final prev = DateTime.parse(dateKeys[i - 1]);
      final next = DateTime.parse(dateKeys[i]);
      if (next.difference(prev).inDays == 1) {
        current += 1;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

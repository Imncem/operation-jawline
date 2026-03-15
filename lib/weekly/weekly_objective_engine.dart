import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/enums.dart';
import '../models/weekly_objective.dart';

class WeeklyObjectiveEngine {
  const WeeklyObjectiveEngine();

  static const List<WeeklyObjectiveType> rotation = [
    WeeklyObjectiveType.protocols4,
    WeeklyObjectiveType.chain5,
    WeeklyObjectiveType.recovery2,
    WeeklyObjectiveType.completion80_5,
  ];

  WeeklyObjective createForWeek(String weekKey, {String? previousWeekKey}) {
    final previousType = previousWeekKey == null
        ? null
        : rotation[(rotation.indexOf(_typeForWeek(previousWeekKey)) + 1) %
            rotation.length];
    final type = previousWeekKey == null
        ? WeeklyObjectiveType.protocols4
        : previousType ?? WeeklyObjectiveType.protocols4;
    return WeeklyObjective(
      weekKey: weekKey,
      objectiveType: type,
      target: _targetFor(type),
      progress: 0,
      completed: false,
      completedAtDateKey: null,
      rewardXP: 50,
      rewardMedalId: 'weekly_objective_1',
      rewardClaimed: false,
    );
  }

  WeeklyObjective recompute(
    WeeklyObjective objective, {
    required List<DailyMissionRecord> missions,
    required List<DailyCheckIn> checkIns,
  }) {
    final progress = switch (objective.objectiveType) {
      WeeklyObjectiveType.protocols4 => missions
          .where((m) => m.workoutEffortRatio >= 0.25 && m.actualWorkoutSec > 0)
          .length,
      WeeklyObjectiveType.chain5 => missions.where((m) => m.checkInDone).length,
      WeeklyObjectiveType.recovery2 => missions
          .where((m) =>
              m.workoutLane == TrainingLane.recovery &&
              m.workoutStatus.name == 'completed' &&
              m.workoutEffortRatio >= 0.25)
          .length,
      WeeklyObjectiveType.completion80_5 =>
        missions.where((m) => m.completion >= 0.80).length,
    };
    final completed = progress >= objective.target;
    return objective.copyWith(
      progress: progress,
      completed: completed,
      completedAtDateKey: completed
          ? missions.isNotEmpty
              ? missions.last.dateKey
              : null
          : null,
    );
  }

  int _targetFor(WeeklyObjectiveType type) {
    switch (type) {
      case WeeklyObjectiveType.protocols4:
        return 4;
      case WeeklyObjectiveType.chain5:
        return 5;
      case WeeklyObjectiveType.recovery2:
        return 2;
      case WeeklyObjectiveType.completion80_5:
        return 5;
    }
  }

  WeeklyObjectiveType _typeForWeek(String weekKey) {
    final weekNumber = int.tryParse(weekKey.split('W').last) ?? 1;
    return rotation[(weekNumber - 1) % rotation.length];
  }
}

String isoWeekKey(DateTime date) {
  final thursday =
      date.add(Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)));
  final firstDay = DateTime(thursday.year, 1, 1);
  final week = (((thursday.difference(firstDay).inDays) + firstDay.weekday) / 7)
          .floor() +
      1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

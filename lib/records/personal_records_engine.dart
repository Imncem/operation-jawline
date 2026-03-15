import '../models/daily_mission_record.dart';
import '../models/personal_records.dart';
import '../models/workout_status.dart';
import '../weekly/weekly_objective_engine.dart';

class PersonalRecordsEngine {
  const PersonalRecordsEngine();

  PersonalRecords recompute({
    required List<DailyMissionRecord> missions,
    required int bestChain,
  }) {
    var longest = const PersonalRecordEntry(value: 0, dateKey: null);
    var bestCompletion = const PersonalRecordEntry(value: 0, dateKey: null);
    var fastestFull = const PersonalRecordEntry(value: 0, dateKey: null);

    final weekCounts = <String, int>{};
    for (final mission in missions) {
      if (mission.actualWorkoutSec > longest.value) {
        longest = PersonalRecordEntry(
          value: mission.actualWorkoutSec,
          dateKey: mission.dateKey,
        );
      }

      final completionPct = (mission.workoutEffortRatio * 100).round();
      if (completionPct > bestCompletion.value) {
        bestCompletion = PersonalRecordEntry(
          value: completionPct,
          dateKey: mission.dateKey,
        );
      }

      if (mission.workoutStatus == WorkoutStatus.completed &&
          mission.workoutEffortRatio >= 1.0 &&
          mission.actualWorkoutSec > 0 &&
          (fastestFull.value == 0 ||
              mission.actualWorkoutSec < fastestFull.value)) {
        fastestFull = PersonalRecordEntry(
          value: mission.actualWorkoutSec,
          dateKey: mission.dateKey,
        );
      }

      if (mission.actualWorkoutSec > 0 && mission.workoutEffortRatio >= 0.25) {
        final weekKey = isoWeekKey(DateTime.parse(mission.dateKey));
        weekCounts.update(weekKey, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    PersonalRecordEntry mostProtocols = const PersonalRecordEntry(
      value: 0,
      dateKey: null,
    );
    weekCounts.forEach((weekKey, count) {
      if (count > mostProtocols.value) {
        mostProtocols = PersonalRecordEntry(value: count, dateKey: weekKey);
      }
    });

    return PersonalRecords(
      longestProtocolSec: longest,
      bestCompletionPercent: bestCompletion,
      fastestFullProtocolSec: fastestFull,
      mostProtocolsInWeek: mostProtocols,
      bestChain: PersonalRecordEntry(value: bestChain, dateKey: null),
    );
  }
}

import 'workout_status.dart';
import 'enums.dart';

class DailyMissionRecord {
  const DailyMissionRecord({
    required this.dateKey,
    required this.checkInDone,
    required this.xpAwarded,
    required this.completion,
    required this.plannedWorkoutSec,
    required this.actualWorkoutSec,
    required this.workoutEffortRatio,
    required this.workoutStatus,
    required this.lastWorkoutUpdateTs,
    required this.workoutLane,
  });

  factory DailyMissionRecord.empty(String dateKey) {
    return DailyMissionRecord(
      dateKey: dateKey,
      checkInDone: false,
      xpAwarded: 0,
      completion: 0,
      plannedWorkoutSec: 0,
      actualWorkoutSec: 0,
      workoutEffortRatio: 0,
      workoutStatus: WorkoutStatus.notStarted,
      lastWorkoutUpdateTs: 0,
      workoutLane: null,
    );
  }

  final String dateKey;
  final bool checkInDone;
  final int xpAwarded;
  final double completion;
  final int plannedWorkoutSec;
  final int actualWorkoutSec;
  final double workoutEffortRatio;
  final WorkoutStatus workoutStatus;
  final int lastWorkoutUpdateTs;
  final TrainingLane? workoutLane;

  double get workoutPercent => workoutEffortRatio;
  bool get workoutSkipped => workoutStatus == WorkoutStatus.skipped;

  DailyMissionRecord copyWith({
    String? dateKey,
    bool? checkInDone,
    int? xpAwarded,
    double? completion,
    int? plannedWorkoutSec,
    int? actualWorkoutSec,
    double? workoutEffortRatio,
    WorkoutStatus? workoutStatus,
    int? lastWorkoutUpdateTs,
    TrainingLane? workoutLane,
    bool clearWorkoutLane = false,
  }) {
    return DailyMissionRecord(
      dateKey: dateKey ?? this.dateKey,
      checkInDone: checkInDone ?? this.checkInDone,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completion: completion ?? this.completion,
      plannedWorkoutSec: plannedWorkoutSec ?? this.plannedWorkoutSec,
      actualWorkoutSec: actualWorkoutSec ?? this.actualWorkoutSec,
      workoutEffortRatio: workoutEffortRatio ?? this.workoutEffortRatio,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      lastWorkoutUpdateTs: lastWorkoutUpdateTs ?? this.lastWorkoutUpdateTs,
      workoutLane: clearWorkoutLane ? null : (workoutLane ?? this.workoutLane),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'checkInDone': checkInDone,
      'xpAwarded': xpAwarded,
      'completion': completion,
      'plannedWorkoutSec': plannedWorkoutSec,
      'actualWorkoutSec': actualWorkoutSec,
      'workoutEffortRatio': workoutEffortRatio,
      'workoutStatus': workoutStatus.toJsonValue(),
      'lastWorkoutUpdateTs': lastWorkoutUpdateTs,
      'workoutLane': workoutLane?.toJsonValue(),
    };
  }

  factory DailyMissionRecord.fromMap(Map<String, dynamic> map) {
    final legacyPercent = (map['workoutPercent'] as num?)?.toDouble() ?? 0;
    final legacySkipped = map['workoutSkipped'] as bool? ?? false;
    final fallbackStatus = legacySkipped
        ? WorkoutStatus.skipped
        : legacyPercent > 0
            ? WorkoutStatus.inProgress
            : WorkoutStatus.notStarted;

    return DailyMissionRecord(
      dateKey: map['dateKey'] as String,
      checkInDone: map['checkInDone'] as bool? ?? false,
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      completion: (map['completion'] as num?)?.toDouble() ?? 0,
      plannedWorkoutSec: map['plannedWorkoutSec'] as int? ?? 0,
      actualWorkoutSec: map['actualWorkoutSec'] as int? ?? 0,
      workoutEffortRatio:
          (map['workoutEffortRatio'] as num?)?.toDouble() ?? legacyPercent,
      workoutStatus: map.containsKey('workoutStatus')
          ? WorkoutStatusX.fromJsonValue(map['workoutStatus'] as String?)
          : fallbackStatus,
      lastWorkoutUpdateTs: map['lastWorkoutUpdateTs'] as int? ?? 0,
      workoutLane: map['workoutLane'] == null
          ? null
          : TrainingLaneX.fromJsonValue(map['workoutLane'] as String),
    );
  }
}

class DailyMissionRecord {
  const DailyMissionRecord({
    required this.dateKey,
    required this.checkInDone,
    required this.workoutPercent,
    required this.workoutSkipped,
    required this.xpAwarded,
    required this.completion,
  });

  factory DailyMissionRecord.empty(String dateKey) {
    return DailyMissionRecord(
      dateKey: dateKey,
      checkInDone: false,
      workoutPercent: 0,
      workoutSkipped: false,
      xpAwarded: 0,
      completion: 0,
    );
  }

  final String dateKey;
  final bool checkInDone;
  final double workoutPercent;
  final bool workoutSkipped;
  final int xpAwarded;
  final double completion;

  DailyMissionRecord copyWith({
    String? dateKey,
    bool? checkInDone,
    double? workoutPercent,
    bool? workoutSkipped,
    int? xpAwarded,
    double? completion,
  }) {
    return DailyMissionRecord(
      dateKey: dateKey ?? this.dateKey,
      checkInDone: checkInDone ?? this.checkInDone,
      workoutPercent: workoutPercent ?? this.workoutPercent,
      workoutSkipped: workoutSkipped ?? this.workoutSkipped,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completion: completion ?? this.completion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'checkInDone': checkInDone,
      'workoutPercent': workoutPercent,
      'workoutSkipped': workoutSkipped,
      'xpAwarded': xpAwarded,
      'completion': completion,
    };
  }

  factory DailyMissionRecord.fromMap(Map<String, dynamic> map) {
    return DailyMissionRecord(
      dateKey: map['dateKey'] as String,
      checkInDone: map['checkInDone'] as bool? ?? false,
      workoutPercent: (map['workoutPercent'] as num?)?.toDouble() ?? 0,
      workoutSkipped: map['workoutSkipped'] as bool? ?? false,
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      completion: (map['completion'] as num?)?.toDouble() ?? 0,
    );
  }
}

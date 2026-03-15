enum WeeklyObjectiveType {
  protocols4,
  chain5,
  recovery2,
  completion80_5,
}

extension WeeklyObjectiveTypeX on WeeklyObjectiveType {
  String get jsonValue => name;

  String get title {
    switch (this) {
      case WeeklyObjectiveType.protocols4:
        return 'Execute 4 protocols';
      case WeeklyObjectiveType.chain5:
        return 'Hold chain for 5 days';
      case WeeklyObjectiveType.recovery2:
        return 'Complete 2 recovery sessions';
      case WeeklyObjectiveType.completion80_5:
        return 'Hit 80% mission completion on 5 days';
    }
  }

  String get progressLabel {
    switch (this) {
      case WeeklyObjectiveType.protocols4:
        return 'protocols';
      case WeeklyObjectiveType.chain5:
        return 'days';
      case WeeklyObjectiveType.recovery2:
        return 'recovery runs';
      case WeeklyObjectiveType.completion80_5:
        return 'high-completion days';
    }
  }

  static WeeklyObjectiveType fromJsonValue(String? value) {
    return WeeklyObjectiveType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => WeeklyObjectiveType.protocols4,
    );
  }
}

class WeeklyObjective {
  const WeeklyObjective({
    required this.weekKey,
    required this.objectiveType,
    required this.target,
    required this.progress,
    required this.completed,
    required this.completedAtDateKey,
    required this.rewardXP,
    required this.rewardMedalId,
    required this.rewardClaimed,
  });

  factory WeeklyObjective.initial(String weekKey) {
    return const WeeklyObjective(
      weekKey: '',
      objectiveType: WeeklyObjectiveType.protocols4,
      target: 4,
      progress: 0,
      completed: false,
      completedAtDateKey: null,
      rewardXP: 50,
      rewardMedalId: 'weekly_objective_1',
      rewardClaimed: false,
    ).copyWith(weekKey: weekKey);
  }

  final String weekKey;
  final WeeklyObjectiveType objectiveType;
  final int target;
  final int progress;
  final bool completed;
  final String? completedAtDateKey;
  final int rewardXP;
  final String? rewardMedalId;
  final bool rewardClaimed;

  double get progressRatio =>
      target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  WeeklyObjective copyWith({
    String? weekKey,
    WeeklyObjectiveType? objectiveType,
    int? target,
    int? progress,
    bool? completed,
    String? completedAtDateKey,
    bool clearCompletedAtDateKey = false,
    int? rewardXP,
    String? rewardMedalId,
    bool clearRewardMedalId = false,
    bool? rewardClaimed,
  }) {
    return WeeklyObjective(
      weekKey: weekKey ?? this.weekKey,
      objectiveType: objectiveType ?? this.objectiveType,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      completedAtDateKey: clearCompletedAtDateKey
          ? null
          : (completedAtDateKey ?? this.completedAtDateKey),
      rewardXP: rewardXP ?? this.rewardXP,
      rewardMedalId:
          clearRewardMedalId ? null : (rewardMedalId ?? this.rewardMedalId),
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekKey': weekKey,
      'objectiveType': objectiveType.jsonValue,
      'target': target,
      'progress': progress,
      'completed': completed,
      'completedAtDateKey': completedAtDateKey,
      'rewardXP': rewardXP,
      'rewardMedalId': rewardMedalId,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory WeeklyObjective.fromMap(Map<String, dynamic> map) {
    return WeeklyObjective(
      weekKey: map['weekKey'] as String? ?? '',
      objectiveType:
          WeeklyObjectiveTypeX.fromJsonValue(map['objectiveType'] as String?),
      target: map['target'] as int? ?? 4,
      progress: map['progress'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
      completedAtDateKey: map['completedAtDateKey'] as String?,
      rewardXP: map['rewardXP'] as int? ?? 50,
      rewardMedalId: map['rewardMedalId'] as String?,
      rewardClaimed: map['rewardClaimed'] as bool? ?? false,
    );
  }
}

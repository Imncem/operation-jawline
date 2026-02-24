class UserProgress {
  const UserProgress({
    required this.totalXP,
    required this.level,
    required this.disciplineChain,
    required this.lastCheckInDateKey,
  });

  factory UserProgress.initial() {
    return const UserProgress(
      totalXP: 0,
      level: 1,
      disciplineChain: 0,
      lastCheckInDateKey: null,
    );
  }

  final int totalXP;
  final int level;
  final int disciplineChain;
  final String? lastCheckInDateKey;

  UserProgress copyWith({
    int? totalXP,
    int? level,
    int? disciplineChain,
    String? lastCheckInDateKey,
    bool clearLastCheckInDateKey = false,
  }) {
    return UserProgress(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      disciplineChain: disciplineChain ?? this.disciplineChain,
      lastCheckInDateKey: clearLastCheckInDateKey
          ? null
          : (lastCheckInDateKey ?? this.lastCheckInDateKey),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalXP': totalXP,
      'level': level,
      'disciplineChain': disciplineChain,
      'lastCheckInDateKey': lastCheckInDateKey,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalXP: map['totalXP'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      disciplineChain: map['disciplineChain'] as int? ?? 0,
      lastCheckInDateKey: map['lastCheckInDateKey'] as String?,
    );
  }
}

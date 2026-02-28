class UserProgress {
  const UserProgress({
    required this.totalXP,
    required this.level,
    required this.rankName,
    required this.disciplineChain,
    required this.lastCheckInDateKey,
  });

  factory UserProgress.initial() {
    return const UserProgress(
      totalXP: 0,
      level: 1,
      rankName: 'Recruit',
      disciplineChain: 0,
      lastCheckInDateKey: null,
    );
  }

  final int totalXP;
  final int level;
  final String rankName;
  final int disciplineChain;
  final String? lastCheckInDateKey;

  UserProgress copyWith({
    int? totalXP,
    int? level,
    String? rankName,
    int? disciplineChain,
    String? lastCheckInDateKey,
    bool clearLastCheckInDateKey = false,
  }) {
    return UserProgress(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      rankName: rankName ?? this.rankName,
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
      'rankName': rankName,
      'disciplineChain': disciplineChain,
      'lastCheckInDateKey': lastCheckInDateKey,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalXP: map['totalXP'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      rankName: map['rankName'] as String? ?? 'Recruit',
      disciplineChain: map['disciplineChain'] as int? ?? 0,
      lastCheckInDateKey: map['lastCheckInDateKey'] as String?,
    );
  }
}

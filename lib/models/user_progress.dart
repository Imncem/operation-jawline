import 'promotion_history_entry.dart';

class UserProgress {
  UserProgress({
    required this.totalXP,
    required this.level,
    required this.rankName,
    required this.disciplineChain,
    required this.lastCheckInDateKey,
    required this.joinDateKey,
    required this.bestChain,
    required this.promotionHistory,
  });

  factory UserProgress.initial() {
    return UserProgress(
      totalXP: 0,
      level: 1,
      rankName: 'Recruit',
      disciplineChain: 0,
      lastCheckInDateKey: null,
      joinDateKey: null,
      bestChain: 0,
      promotionHistory: const [],
    );
  }

  final int totalXP;
  final int level;
  final String rankName;
  final int disciplineChain;
  final String? lastCheckInDateKey;
  final String? joinDateKey;
  final int bestChain;
  final List<PromotionHistoryEntry> promotionHistory;

  UserProgress copyWith({
    int? totalXP,
    int? level,
    String? rankName,
    int? disciplineChain,
    String? lastCheckInDateKey,
    String? joinDateKey,
    int? bestChain,
    List<PromotionHistoryEntry>? promotionHistory,
    bool clearLastCheckInDateKey = false,
    bool clearJoinDateKey = false,
  }) {
    return UserProgress(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      rankName: rankName ?? this.rankName,
      disciplineChain: disciplineChain ?? this.disciplineChain,
      lastCheckInDateKey: clearLastCheckInDateKey
          ? null
          : (lastCheckInDateKey ?? this.lastCheckInDateKey),
      joinDateKey: clearJoinDateKey ? null : (joinDateKey ?? this.joinDateKey),
      bestChain: bestChain ?? this.bestChain,
      promotionHistory: promotionHistory ?? this.promotionHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalXP': totalXP,
      'level': level,
      'rankName': rankName,
      'disciplineChain': disciplineChain,
      'lastCheckInDateKey': lastCheckInDateKey,
      'joinDateKey': joinDateKey,
      'bestChain': bestChain,
      'promotionHistory': promotionHistory.map((e) => e.toMap()).toList(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    final promotionHistoryRaw =
        map['promotionHistory'] as List<dynamic>? ?? const [];
    return UserProgress(
      totalXP: map['totalXP'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      rankName: map['rankName'] as String? ?? 'Recruit',
      disciplineChain: map['disciplineChain'] as int? ?? 0,
      lastCheckInDateKey: map['lastCheckInDateKey'] as String?,
      joinDateKey: map['joinDateKey'] as String?,
      bestChain: map['bestChain'] as int? ?? 0,
      promotionHistory: promotionHistoryRaw
          .whereType<Map>()
          .map((e) =>
              PromotionHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

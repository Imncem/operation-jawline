class PromotionHistoryEntry {
  const PromotionHistoryEntry({
    required this.dateKey,
    required this.fromRank,
    required this.toRank,
  });

  final String dateKey;
  final String fromRank;
  final String toRank;

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'fromRank': fromRank,
      'toRank': toRank,
    };
  }

  factory PromotionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PromotionHistoryEntry(
      dateKey: map['dateKey'] as String? ?? '',
      fromRank: map['fromRank'] as String? ?? 'Recruit',
      toRank: map['toRank'] as String? ?? 'Recruit',
    );
  }
}

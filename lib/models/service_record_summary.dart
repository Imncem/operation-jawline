import 'personal_records.dart';
import 'promotion_history_entry.dart';

class CareerStats {
  const CareerStats({
    required this.missionsCompleted,
    required this.protocolsExecuted,
    required this.totalTimeOnTargetSec,
    required this.bestDisciplineChain,
    required this.perfectProtocols,
    required this.promotionsAchieved,
  });

  final int missionsCompleted;
  final int protocolsExecuted;
  final int totalTimeOnTargetSec;
  final int bestDisciplineChain;
  final int perfectProtocols;
  final int promotionsAchieved;
}

class ServiceRecordSummary {
  const ServiceRecordSummary({
    required this.rankName,
    required this.level,
    required this.totalXP,
    required this.disciplineChainLabel,
    required this.joinDateKey,
    required this.careerStats,
    required this.promotionHistory,
    required this.personalRecords,
  });

  final String rankName;
  final int level;
  final int totalXP;
  final String disciplineChainLabel;
  final String? joinDateKey;
  final CareerStats careerStats;
  final List<PromotionHistoryEntry> promotionHistory;
  final PersonalRecords personalRecords;
}

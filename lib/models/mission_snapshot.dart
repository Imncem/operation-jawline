import 'package:equatable/equatable.dart';

import 'daily_check_in.dart';

class MissionSnapshot extends Equatable {
  const MissionSnapshot({
    required this.latestCheckIn,
    required this.disciplineChain,
    required this.chainCompromised,
    required this.recommendation,
  });

  factory MissionSnapshot.empty() {
    return const MissionSnapshot(
      latestCheckIn: null,
      disciplineChain: 0,
      chainCompromised: false,
      recommendation: null,
    );
  }

  final DailyCheckIn? latestCheckIn;
  final int disciplineChain;
  final bool chainCompromised;
  final String? recommendation;

  String get rank {
    if (disciplineChain >= 31) return 'Jawline Commander';
    if (disciplineChain >= 15) return 'Enforcer';
    if (disciplineChain >= 8) return 'Operative';
    if (disciplineChain >= 4) return 'Cadet';
    return 'Civilian';
  }

  int get rankStartDay {
    if (disciplineChain >= 31) return 31;
    if (disciplineChain >= 15) return 15;
    if (disciplineChain >= 8) return 8;
    if (disciplineChain >= 4) return 4;
    return 0;
  }

  int? get nextRankAtDay {
    if (disciplineChain >= 31) return null;
    if (disciplineChain >= 15) return 31;
    if (disciplineChain >= 8) return 15;
    if (disciplineChain >= 4) return 8;
    return 4;
  }

  String? get nextRank {
    if (disciplineChain >= 31) return null;
    if (disciplineChain >= 15) return 'Jawline Commander';
    if (disciplineChain >= 8) return 'Enforcer';
    if (disciplineChain >= 4) return 'Operative';
    return 'Cadet';
  }

  int get levelInRank {
    return disciplineChain - rankStartDay + 1;
  }

  int get levelCapInRank {
    final nextAt = nextRankAtDay;
    if (nextAt == null) return 99;
    return nextAt - rankStartDay;
  }

  int? get daysToNextRank {
    final nextAt = nextRankAtDay;
    if (nextAt == null) return null;
    final remaining = nextAt - disciplineChain;
    return remaining <= 0 ? 0 : remaining;
  }

  double get levelProgress {
    final cap = levelCapInRank;
    if (cap <= 0) return 1;
    return (levelInRank / cap).clamp(0, 1);
  }

  String get puffinessStatus {
    final checkIn = latestCheckIn;
    if (checkIn == null) {
      return 'Awaiting field report';
    }
    if (checkIn.waterLiters < 1.5) {
      return 'Threat Level Rising';
    }
    if (checkIn.sleepHours < 6) {
      return 'Recovery Compromised';
    }
    return 'Sharp Mode Stable';
  }

  MissionSnapshot copyWith({
    DailyCheckIn? latestCheckIn,
    int? disciplineChain,
    bool? chainCompromised,
    String? recommendation,
  }) {
    return MissionSnapshot(
      latestCheckIn: latestCheckIn ?? this.latestCheckIn,
      disciplineChain: disciplineChain ?? this.disciplineChain,
      chainCompromised: chainCompromised ?? this.chainCompromised,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  @override
  List<Object?> get props => [
        latestCheckIn,
        disciplineChain,
        chainCompromised,
        recommendation,
      ];
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_record_summary.dart';
import '../models/weekly_objective.dart';
import '../services/medal_service.dart';
import '../services/mission_progress_service.dart';
import '../services/personal_records_service.dart';
import '../services/weekly_objective_service.dart';

final medalServiceProvider = Provider<MedalService>((ref) {
  return MedalService(storage: SharedPrefsMissionStorageAdapter());
});

final weeklyObjectiveServiceProvider = Provider<WeeklyObjectiveService>((ref) {
  return WeeklyObjectiveService(storage: SharedPrefsMissionStorageAdapter());
});

final personalRecordsServiceProvider = Provider<PersonalRecordsService>((ref) {
  return PersonalRecordsService(storage: SharedPrefsMissionStorageAdapter());
});

final medalsStateProvider = FutureProvider((ref) async {
  return ref.watch(medalServiceProvider).load();
});

final weeklyObjectiveProvider = FutureProvider<WeeklyObjective>((ref) async {
  return ref.watch(weeklyObjectiveServiceProvider).loadCurrent(DateTime.now());
});

final weeklyObjectiveArchiveProvider =
    FutureProvider<List<WeeklyObjective>>((ref) async {
  return ref.watch(weeklyObjectiveServiceProvider).loadArchive();
});

final personalRecordsProvider = FutureProvider((ref) async {
  return ref.watch(personalRecordsServiceProvider).load();
});

final serviceRecordProvider = FutureProvider<ServiceRecordSummary>((ref) async {
  final missionService = ref.watch(missionServiceProvider);
  final personalRecordsService = ref.watch(personalRecordsServiceProvider);
  final progress = await missionService.getUserProgress();
  final missions = await missionService.loadMissionRecordHistory();
  final records = await personalRecordsService.load();

  final missionsCompleted =
      missions.where((item) => item.completion >= 1.0).length;
  final protocolsExecuted = missions
      .where((item) =>
          item.actualWorkoutSec > 0 && item.workoutEffortRatio >= 0.10)
      .length;
  final totalTime =
      missions.fold<int>(0, (sum, item) => sum + item.actualWorkoutSec);
  final perfectProtocols = missions
      .where((item) =>
          item.workoutEffortRatio >= 1.0 &&
          item.workoutStatus.name == 'completed')
      .length;

  return ServiceRecordSummary(
    rankName: progress.rankName,
    level: progress.level,
    totalXP: progress.totalXP,
    disciplineChainLabel:
        progress.lastCheckInDateKey == null ? 'Compromised' : 'Stable',
    joinDateKey: progress.joinDateKey,
    careerStats: CareerStats(
      missionsCompleted: missionsCompleted,
      protocolsExecuted: protocolsExecuted,
      totalTimeOnTargetSec: totalTime,
      bestDisciplineChain: progress.bestChain,
      perfectProtocols: perfectProtocols,
      promotionsAchieved: progress.promotionHistory.length,
    ),
    promotionHistory: progress.promotionHistory.reversed.toList(),
    personalRecords: records,
  );
});

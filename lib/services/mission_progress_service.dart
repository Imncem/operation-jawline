import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_mission_record.dart';
import '../models/daily_check_in.dart';
import '../models/enums.dart';
import '../models/promotion_history_entry.dart';
import '../models/user_progress.dart';
import '../models/workout_status.dart';
import '../progression/ranks.dart';
import 'leveling.dart';

abstract class MissionStorageAdapter {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPrefsMissionStorageAdapter implements MissionStorageAdapter {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

class MissionUpdateResult {
  const MissionUpdateResult({
    required this.xpDelta,
    required this.newTotalXP,
    required this.level,
    required this.dailyCompletion,
    required this.xpToday,
    required this.xpMaxToday,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
    required this.previousRankName,
    required this.rankName,
    required this.promoted,
    required this.checkInXP,
    required this.protocolXP,
    required this.completionBonusXP,
    required this.workoutEffortRatio,
    required this.workoutStatus,
  });

  final int xpDelta;
  final int newTotalXP;
  final int level;
  final double dailyCompletion;
  final int xpToday;
  final int xpMaxToday;
  final int xpToNextLevel;
  final double progressToNextLevel;
  final String previousRankName;
  final String rankName;
  final bool promoted;
  final int checkInXP;
  final int protocolXP;
  final int completionBonusXP;
  final double workoutEffortRatio;
  final WorkoutStatus workoutStatus;
}

class ProgressAwardResult {
  const ProgressAwardResult({
    required this.xpDelta,
    required this.newTotalXP,
    required this.level,
    required this.previousRankName,
    required this.rankName,
    required this.promoted,
  });

  final int xpDelta;
  final int newTotalXP;
  final int level;
  final String previousRankName;
  final String rankName;
  final bool promoted;
}

class MissionProgressService {
  MissionProgressService({required MissionStorageAdapter storage})
      : _storage = storage;

  static const String _recordsKey = 'daily_mission_records_v1';
  static const String _userProgressKey = 'user_progress_v1';
  static const String _checkInHistoryKey = 'daily_checkin_history_v1';

  final MissionStorageAdapter _storage;

  Future<DailyMissionRecord> getToday() async {
    return _getByDate(DateTime.now());
  }

  Future<List<DailyMissionRecord>> loadMissionRecordHistory() async {
    final all = await _loadAllRecords();
    final values = all.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return values;
  }

  Future<UserProgress> getUserProgress() async {
    final raw = await _storage.getString(_userProgressKey);
    if (raw == null || raw.isEmpty) {
      final initial = UserProgress.initial().copyWith(
        joinDateKey: _dateKey(DateTime.now()),
      );
      await _saveUserProgress(initial);
      return initial;
    }
    final parsed =
        UserProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    final normalized = parsed.copyWith(
      rankName: rankForLevel(parsed.level),
      joinDateKey: parsed.joinDateKey ?? _dateKey(DateTime.now()),
    );
    if (normalized.joinDateKey != parsed.joinDateKey ||
        normalized.rankName != parsed.rankName) {
      await _saveUserProgress(normalized);
    }
    return normalized;
  }

  Future<void> appendCheckIn(DailyCheckIn checkIn) async {
    final all = await loadCheckInHistory();
    final next = [...all];
    final idx = next.indexWhere(
        (it) => _dateKey(it.lastCheckIn) == _dateKey(checkIn.lastCheckIn));
    if (idx >= 0) {
      next[idx] = checkIn;
    } else {
      next.add(checkIn);
    }
    await _storage.setString(
      _checkInHistoryKey,
      jsonEncode(next.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<DailyCheckIn>> loadCheckInHistory() async {
    final raw = await _storage.getString(_checkInHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DailyCheckIn.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.lastCheckIn.compareTo(b.lastCheckIn));
  }

  Future<void> setDisciplineChain(int chain) async {
    final progress = await getUserProgress();
    await _saveUserProgress(
      progress.copyWith(
        disciplineChain: math.max(0, chain),
        bestChain: math.max(progress.bestChain, math.max(0, chain)),
      ),
    );
  }

  Future<void> markCheckInDone(DateTime date) async {
    final dateKey = _dateKey(date);
    final record = await _getByDate(date);
    final updated = record.copyWith(checkInDone: true);
    await _saveRecord(updated);

    final progress = await getUserProgress();
    await _saveUserProgress(
      progress.copyWith(
        lastCheckInDateKey: dateKey,
        joinDateKey: progress.joinDateKey ?? dateKey,
        bestChain: math.max(progress.bestChain, progress.disciplineChain),
      ),
    );
  }

  Future<void> updateWorkoutProgress(
    DateTime date,
    double percent, {
    bool skipped = false,
  }) async {
    final status = skipped ? WorkoutStatus.skipped : WorkoutStatus.inProgress;
    final planned = 1000;
    final actual = (planned * percent.clamp(0, 1)).round();
    await updateWorkoutEffort(
      date,
      plannedSec: planned,
      actualSec: actual,
      status: status,
      force: true,
    );
  }

  Future<void> updateWorkoutEffort(
    DateTime date, {
    required int plannedSec,
    required int actualSec,
    required WorkoutStatus status,
    TrainingLane? lane,
    bool force = false,
  }) async {
    final record = await _getByDate(date);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nextPlanned =
        math.max(record.plannedWorkoutSec, math.max(0, plannedSec));
    final nextActual =
        math.max(record.actualWorkoutSec, math.max(0, actualSec));
    var nextRatio =
        nextPlanned <= 0 ? 0.0 : (nextActual / nextPlanned).clamp(0.0, 1.0);
    if (status == WorkoutStatus.completed && nextRatio < 1.0) {
      nextRatio = 1.0;
    }

    final allowByTime = nowMs - record.lastWorkoutUpdateTs >= 2000;
    final allowByRatio = (nextRatio - record.workoutEffortRatio).abs() >= 0.05;
    if (!force && !allowByTime && !allowByRatio) {
      return;
    }

    final updated = record.copyWith(
      plannedWorkoutSec: nextPlanned,
      actualWorkoutSec: nextActual,
      workoutEffortRatio: nextRatio,
      workoutStatus: status,
      lastWorkoutUpdateTs: nowMs,
      workoutLane: lane ?? record.workoutLane,
    );
    await _saveRecord(updated);
  }

  Future<ProgressAwardResult> awardBonusXP(
    int xp, {
    DateTime? date,
  }) async {
    final safeXp = math.max(0, xp);
    final progress = await getUserProgress();
    final previousRankName = progress.rankName;
    final newTotal = progress.totalXP + safeXp;
    final level = computeLevelFromTotalXP(newTotal);
    final rankName = rankForLevel(level);
    final promoted = safeXp > 0 && previousRankName != rankName;
    final nextPromotionHistory = promoted
        ? [
            ...progress.promotionHistory,
            PromotionHistoryEntry(
              dateKey: _dateKey(date ?? DateTime.now()),
              fromRank: previousRankName,
              toRank: rankName,
            ),
          ]
        : progress.promotionHistory;

    await _saveUserProgress(
      progress.copyWith(
        totalXP: newTotal,
        level: level,
        rankName: rankName,
        promotionHistory: nextPromotionHistory,
      ),
    );

    return ProgressAwardResult(
      xpDelta: safeXp,
      newTotalXP: newTotal,
      level: level,
      previousRankName: previousRankName,
      rankName: rankName,
      promoted: promoted,
    );
  }

  Future<MissionUpdateResult> recomputeAndAwardXP(DateTime date) async {
    final record = await _getByDate(date);
    final progress = await getUserProgress();
    final workoutCredit = computeWorkoutCredit(
      status: record.workoutStatus,
      effortRatio: record.workoutEffortRatio,
    );
    final completion = computeDailyCompletionFromWorkoutCredit(
      checkInDone: record.checkInDone,
      workoutCredit: workoutCredit,
    );
    final checkInXP =
        record.checkInDone ? (kCheckInWeight * kBaseDailyXP).round() : 0;
    final protocolXP = (kWorkoutWeight * workoutCredit * kBaseDailyXP).round();
    final completionBonusXP = computeCompletionBonusXP(
      status: record.workoutStatus,
      effortRatio: record.workoutEffortRatio,
      dailyCompletion: completion,
    );

    final xpTarget = computeDailyXP(
      dailyMissionCompletion: completion,
      disciplineChain: progress.disciplineChain,
      completionBonusXP: completionBonusXP,
    );
    final xpMaxToday = computeDailyXP(
      dailyMissionCompletion: 1.0,
      disciplineChain: progress.disciplineChain,
      completionBonusXP: kCompletionBonusFull,
    );

    final xpDelta = math.max(0, xpTarget - record.xpAwarded);
    final newTotal = progress.totalXP + xpDelta;
    final newLevel = computeLevelFromTotalXP(newTotal);
    final previousRankName = progress.rankName;
    final rankName = rankForLevel(newLevel);
    final promoted = xpDelta > 0 && previousRankName != rankName;
    final nextXp = xpToNextLevel(newTotal);
    final nextProgress = progressToNextLevel(newTotal);

    final nextPromotionHistory = promoted
        ? [
            ...progress.promotionHistory,
            PromotionHistoryEntry(
              dateKey: _dateKey(date),
              fromRank: previousRankName,
              toRank: rankName,
            ),
          ]
        : progress.promotionHistory;

    final updatedRecord = record.copyWith(
      completion: completion,
      xpAwarded: record.xpAwarded + xpDelta,
    );
    final updatedUser = progress.copyWith(
      totalXP: newTotal,
      level: newLevel,
      rankName: rankName,
      joinDateKey: progress.joinDateKey ?? _dateKey(date),
      bestChain: math.max(progress.bestChain, progress.disciplineChain),
      promotionHistory: nextPromotionHistory,
    );

    await _saveRecord(updatedRecord);
    await _saveUserProgress(updatedUser);

    return MissionUpdateResult(
      xpDelta: xpDelta,
      newTotalXP: newTotal,
      level: newLevel,
      dailyCompletion: completion,
      xpToday: updatedRecord.xpAwarded,
      xpMaxToday: xpMaxToday,
      xpToNextLevel: nextXp,
      progressToNextLevel: nextProgress,
      previousRankName: previousRankName,
      rankName: rankName,
      promoted: promoted,
      checkInXP: checkInXP,
      protocolXP: protocolXP,
      completionBonusXP: completionBonusXP,
      workoutEffortRatio: record.workoutEffortRatio,
      workoutStatus: record.workoutStatus,
    );
  }

  Future<DailyMissionRecord> _getByDate(DateTime date) async {
    final key = _dateKey(date);
    final all = await _loadAllRecords();
    return all[key] ?? DailyMissionRecord.empty(key);
  }

  Future<Map<String, DailyMissionRecord>> _loadAllRecords() async {
    final raw = await _storage.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      return MapEntry(
        key,
        DailyMissionRecord.fromMap(value as Map<String, dynamic>),
      );
    });
  }

  Future<void> _saveRecord(DailyMissionRecord record) async {
    final all = await _loadAllRecords();
    all[record.dateKey] = record;
    final encoded = jsonEncode(
      all.map((key, value) => MapEntry(key, value.toMap())),
    );
    await _storage.setString(_recordsKey, encoded);
  }

  Future<void> _saveUserProgress(UserProgress progress) {
    return _storage.setString(_userProgressKey, jsonEncode(progress.toMap()));
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final missionServiceProvider = Provider<MissionProgressService>((ref) {
  return MissionProgressService(storage: SharedPrefsMissionStorageAdapter());
});

final todayMissionProvider = FutureProvider<DailyMissionRecord>((ref) async {
  return ref.watch(missionServiceProvider).getToday();
});

final userProgressProvider = FutureProvider<UserProgress>((ref) async {
  return ref.watch(missionServiceProvider).getUserProgress();
});

final checkInHistoryProvider = FutureProvider<List<DailyCheckIn>>((ref) async {
  return ref.watch(missionServiceProvider).loadCheckInHistory();
});

final missionHistoryProvider =
    FutureProvider<List<DailyMissionRecord>>((ref) async {
  return ref.watch(missionServiceProvider).loadMissionRecordHistory();
});

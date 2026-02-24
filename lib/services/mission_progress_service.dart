import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_mission_record.dart';
import '../models/user_progress.dart';
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
  });

  final int xpDelta;
  final int newTotalXP;
  final int level;
  final double dailyCompletion;
  final int xpToday;
  final int xpMaxToday;
  final int xpToNextLevel;
  final double progressToNextLevel;
}

class MissionProgressService {
  MissionProgressService({required MissionStorageAdapter storage})
      : _storage = storage;

  static const String _recordsKey = 'daily_mission_records_v1';
  static const String _userProgressKey = 'user_progress_v1';

  final MissionStorageAdapter _storage;

  Future<DailyMissionRecord> getToday() async {
    return _getByDate(DateTime.now());
  }

  Future<UserProgress> getUserProgress() async {
    final raw = await _storage.getString(_userProgressKey);
    if (raw == null || raw.isEmpty) return UserProgress.initial();
    return UserProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setDisciplineChain(int chain) async {
    final progress = await getUserProgress();
    await _saveUserProgress(
        progress.copyWith(disciplineChain: math.max(0, chain)));
  }

  Future<void> markCheckInDone(DateTime date) async {
    final dateKey = _dateKey(date);
    final record = await _getByDate(date);
    final updated = record.copyWith(checkInDone: true);
    await _saveRecord(updated);

    final progress = await getUserProgress();
    await _saveUserProgress(progress.copyWith(lastCheckInDateKey: dateKey));
  }

  Future<void> updateWorkoutProgress(
    DateTime date,
    double percent, {
    bool skipped = false,
  }) async {
    final record = await _getByDate(date);
    final normalized = percent.clamp(0.0, 1.0);
    final floor =
        (skipped && kApplyWorkoutSkipFloor) ? kWorkoutSkipPercentFloor : 0.0;
    final mergedPercent =
        math.max(record.workoutPercent, math.max(normalized, floor));

    final updated = record.copyWith(
      workoutPercent: mergedPercent,
      workoutSkipped: record.workoutSkipped || skipped,
    );
    await _saveRecord(updated);
  }

  Future<MissionUpdateResult> recomputeAndAwardXP(DateTime date) async {
    final record = await _getByDate(date);
    final progress = await getUserProgress();

    final completion = computeDailyMissionCompletion(
      checkInDone: record.checkInDone,
      workoutCompletionPercent: record.workoutPercent,
      workoutSkipped: record.workoutSkipped,
    );

    final xpTarget = computeDailyXP(
      dailyMissionCompletion: completion,
      disciplineChain: progress.disciplineChain,
    );
    final xpMaxToday = computeDailyXP(
      dailyMissionCompletion: 1.0,
      disciplineChain: progress.disciplineChain,
    );

    final xpDelta = math.max(0, xpTarget - record.xpAwarded);
    final newTotal = progress.totalXP + xpDelta;
    final newLevel = computeLevelFromTotalXP(newTotal);
    final nextXp = xpToNextLevel(newTotal);
    final nextProgress = progressToNextLevel(newTotal);

    final updatedRecord = record.copyWith(
      completion: completion,
      xpAwarded: record.xpAwarded + xpDelta,
    );
    final updatedUser = progress.copyWith(
      totalXP: newTotal,
      level: newLevel,
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

import 'dart:convert';

import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/weekly_objective.dart';
import '../weekly/weekly_objective_engine.dart';
import 'mission_progress_service.dart';

class WeeklyObjectiveUpdateResult {
  const WeeklyObjectiveUpdateResult({
    required this.objective,
    required this.archive,
    required this.rewardGranted,
    required this.rewardXP,
  });

  final WeeklyObjective objective;
  final List<WeeklyObjective> archive;
  final bool rewardGranted;
  final int rewardXP;
}

class WeeklyObjectiveService {
  WeeklyObjectiveService({
    required MissionStorageAdapter storage,
    WeeklyObjectiveEngine? engine,
  })  : _storage = storage,
        _engine = engine ?? const WeeklyObjectiveEngine();

  static const _currentKey = 'weekly_objective_current_v1';
  static const _archiveKey = 'weekly_objective_archive_v1';

  final MissionStorageAdapter _storage;
  final WeeklyObjectiveEngine _engine;

  Future<WeeklyObjective> loadCurrent(DateTime now) async {
    final raw = await _storage.getString(_currentKey);
    if (raw == null || raw.isEmpty) {
      final created = _engine.createForWeek(isoWeekKey(now));
      await saveCurrent(created);
      return created;
    }
    return WeeklyObjective.fromMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<List<WeeklyObjective>> loadArchive() async {
    final raw = await _storage.getString(_archiveKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => WeeklyObjective.fromMap(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
        .toList();
  }

  Future<void> saveCurrent(WeeklyObjective objective) {
    return _storage.setString(_currentKey, jsonEncode(objective.toMap()));
  }

  Future<void> saveArchive(List<WeeklyObjective> archive) {
    return _storage.setString(
      _archiveKey,
      jsonEncode(archive.map((item) => item.toMap()).toList()),
    );
  }

  Future<WeeklyObjectiveUpdateResult> refresh({
    required DateTime now,
    required List<DailyMissionRecord> missions,
    required List<DailyCheckIn> checkIns,
  }) async {
    final weekKey = isoWeekKey(now);
    var current = await loadCurrent(now);
    var archive = await loadArchive();

    if (current.weekKey != weekKey) {
      archive = [...archive, current];
      current =
          _engine.createForWeek(weekKey, previousWeekKey: current.weekKey);
      await saveArchive(archive);
    }

    final weekMissions = missions
        .where((item) => isoWeekKey(DateTime.parse(item.dateKey)) == weekKey)
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final weekCheckIns = checkIns
        .where((item) => isoWeekKey(item.lastCheckIn) == weekKey)
        .toList()
      ..sort((a, b) => a.lastCheckIn.compareTo(b.lastCheckIn));

    final updated = _engine.recompute(
      current,
      missions: weekMissions,
      checkIns: weekCheckIns,
    );

    final rewardGranted = updated.completed && !updated.rewardClaimed;
    final next =
        rewardGranted ? updated.copyWith(rewardClaimed: true) : updated;

    await saveCurrent(next);
    return WeeklyObjectiveUpdateResult(
      objective: next,
      archive: archive,
      rewardGranted: rewardGranted,
      rewardXP: rewardGranted ? next.rewardXP : 0,
    );
  }
}

import 'dart:convert';

import '../medals/medal_catalog.dart';
import '../medals/medal_engine.dart';
import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/medal.dart';
import '../models/user_progress.dart';
import '../models/weekly_objective.dart';
import 'mission_progress_service.dart';

class MedalService {
  MedalService({
    required MissionStorageAdapter storage,
    MedalEngine? engine,
  })  : _storage = storage,
        _engine = engine ?? const MedalEngine();

  static const _medalsKey = 'medals_v1';

  final MissionStorageAdapter _storage;
  final MedalEngine _engine;

  Future<List<Medal>> load() async {
    final raw = await _storage.getString(_medalsKey);
    if (raw == null || raw.isEmpty) return kMedalCatalog;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => Medal.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Medal>> evaluateAndSave({
    required List<DailyMissionRecord> missions,
    required List<DailyCheckIn> checkIns,
    required UserProgress progress,
    required WeeklyObjective? currentObjective,
    required List<WeeklyObjective> objectiveArchive,
    required String dateKey,
  }) async {
    final current = await load();
    final next = _engine.evaluate(
      medals: current,
      missions: missions,
      checkIns: checkIns,
      progress: progress,
      currentObjective: currentObjective,
      objectiveArchive: objectiveArchive,
      dateKey: dateKey,
    );
    await _storage.setString(
      _medalsKey,
      jsonEncode(next.map((item) => item.toMap()).toList()),
    );
    return next;
  }
}

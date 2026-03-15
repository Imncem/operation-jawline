import 'dart:convert';

import '../models/daily_mission_record.dart';
import '../models/personal_records.dart';
import '../records/personal_records_engine.dart';
import 'mission_progress_service.dart';

class PersonalRecordsService {
  PersonalRecordsService({
    required MissionStorageAdapter storage,
    PersonalRecordsEngine? engine,
  })  : _storage = storage,
        _engine = engine ?? const PersonalRecordsEngine();

  static const _key = 'personal_records_v1';

  final MissionStorageAdapter _storage;
  final PersonalRecordsEngine _engine;

  Future<PersonalRecords> load() async {
    final raw = await _storage.getString(_key);
    if (raw == null || raw.isEmpty) return PersonalRecords.initial();
    return PersonalRecords.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<PersonalRecords> recomputeAndSave({
    required List<DailyMissionRecord> missions,
    required int bestChain,
  }) async {
    final next = _engine.recompute(missions: missions, bestChain: bestChain);
    await _storage.setString(_key, jsonEncode(next.toMap()));
    return next;
  }
}

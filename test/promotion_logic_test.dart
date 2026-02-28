import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/services/mission_progress_service.dart';

class _InMemoryStorage implements MissionStorageAdapter {
  final Map<String, String> _store = {};

  @override
  Future<String?> getString(String key) async => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }
}

void main() {
  test('promotion event triggers when rank boundary is crossed', () async {
    final storage = _InMemoryStorage();
    await storage.setString(
      'user_progress_v1',
      jsonEncode({
        'totalXP': 1035,
        'level': 3,
        'rankName': 'Recruit',
        'disciplineChain': 0,
      }),
    );

    final service = MissionProgressService(storage: storage);
    final date = DateTime(2026, 2, 25);
    await service.markCheckInDone(date);
    await service.updateWorkoutProgress(date, 1.0);
    final update = await service.recomputeAndAwardXP(date);

    expect(update.promoted, isTrue);
    expect(update.previousRankName, 'Recruit');
    expect(update.rankName, 'Private');
  });
}

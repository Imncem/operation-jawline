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
  late MissionProgressService service;
  final now = DateTime(2026, 2, 24, 10, 0, 0);

  setUp(() async {
    service = MissionProgressService(storage: _InMemoryStorage());
    await service.setDisciplineChain(0);
  });

  test('awarding XP does not double count', () async {
    await service.markCheckInDone(now);
    final first = await service.recomputeAndAwardXP(now);
    final second = await service.recomputeAndAwardXP(now);

    expect(first.xpDelta, 50);
    expect(second.xpDelta, 0);
    expect(second.xpToday, 50);
  });

  test('updating workout progress awards only XP delta', () async {
    await service.markCheckInDone(now);
    await service.recomputeAndAwardXP(now);

    await service.updateWorkoutProgress(now, 0.4);
    final updated = await service.recomputeAndAwardXP(now);

    expect(updated.xpDelta, 20);
    expect(updated.xpToday, 70);
  });

  test('check-in after workout awards missing delta', () async {
    await service.updateWorkoutProgress(now, 0.6);
    final workoutOnly = await service.recomputeAndAwardXP(now);

    await service.markCheckInDone(now);
    final afterCheckIn = await service.recomputeAndAwardXP(now);

    expect(workoutOnly.xpToday, 30);
    expect(afterCheckIn.xpDelta, 55);
    expect(afterCheckIn.xpToday, 85);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/workout_status.dart';
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
  test('xp awards only delta as workout effort increases', () async {
    final service = MissionProgressService(storage: _InMemoryStorage());
    final date = DateTime(2026, 2, 25);

    await service.markCheckInDone(date);
    final base = await service.recomputeAndAwardXP(date);
    expect(base.xpDelta, 50);

    await service.updateWorkoutEffort(
      date,
      plannedSec: 1800,
      actualSec: 450,
      status: WorkoutStatus.inProgress,
      force: true,
    );
    final u1 = await service.recomputeAndAwardXP(date);
    expect(u1.xpDelta, greaterThan(0));

    await service.updateWorkoutEffort(
      date,
      plannedSec: 1800,
      actualSec: 900,
      status: WorkoutStatus.inProgress,
      force: true,
    );
    final u2 = await service.recomputeAndAwardXP(date);
    expect(u2.xpDelta, greaterThan(0));

    final repeat = await service.recomputeAndAwardXP(date);
    expect(repeat.xpDelta, 0);
    expect(repeat.xpToday, greaterThanOrEqualTo(u2.xpToday));
  });
}

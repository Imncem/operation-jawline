import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/intel/insight_engine.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';

void main() {
  test('insight engine detects upward energy and lower puffiness', () {
    const engine = InsightEngine();
    final checkIns = [
      DailyCheckIn(
        energy: 4,
        sleepHours: 7,
        waterLiters: 1.8,
        mood: Mood.neutral,
        puffiness: 4,
        disciplineChain: 2,
        lastCheckIn: DateTime(2026, 2, 1),
      ),
      DailyCheckIn(
        energy: 7,
        sleepHours: 7.5,
        waterLiters: 2.2,
        mood: Mood.good,
        puffiness: 2,
        disciplineChain: 3,
        lastCheckIn: DateTime(2026, 2, 2),
      ),
    ];

    final records = [
      DailyMissionRecord.empty('2026-02-01').copyWith(completion: 0.4),
      DailyMissionRecord.empty('2026-02-02').copyWith(completion: 0.7),
    ];
    final insights =
        engine.buildInsights(checkIns: checkIns, missionRecords: records);

    expect(insights.any((x) => x.contains('Energy trending upward')), isTrue);
    expect(insights.any((x) => x.contains('Puffiness decreasing')), isTrue);
  });
}

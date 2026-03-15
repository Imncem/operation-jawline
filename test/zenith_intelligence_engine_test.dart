import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/intel/zenith_intelligence_engine.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/models/zenith_analysis_result.dart';

void main() {
  group('ZenithIntelligenceEngine', () {
    const engine = ZenithIntelligenceEngine();

    test('falling energy and rising puffiness push recovery bias', () {
      final bundle = engine.analyze(
        checkIns: [
          _checkIn(day: 1, energy: 8, water: 2.4, puffiness: 2),
          _checkIn(day: 2, energy: 7, water: 2.2, puffiness: 3),
          _checkIn(day: 3, energy: 5, water: 2.0, puffiness: 4),
          _checkIn(day: 4, energy: 3, water: 1.8, puffiness: 5),
        ],
        missionRecords: [
          _mission(day: 1, completion: 1, effort: 1, status: WorkoutStatus.completed),
          _mission(day: 3, completion: 0.7, effort: 0.8, status: WorkoutStatus.completed),
        ],
      );

      expect(bundle.analysis.summaryTitle, 'Recovery Pressure Detected');
      expect(bundle.analysis.laneBias, ZenithLaneBias.recovery);
      expect(bundle.analysis.focusBias, ZenithFocusBias.mobility);
      expect(bundle.adjustment.restrictHighIntensity, isTrue);
    });

    test('strong consistency supports progression', () {
      final bundle = engine.analyze(
        checkIns: List.generate(
          7,
          (index) => _checkIn(
            day: index + 1,
            energy: 7 + (index.isEven ? 1 : 0),
            water: 2.3,
            puffiness: 2,
          ),
        ),
        missionRecords: List.generate(
          7,
          (index) => _mission(
            day: index + 1,
            completion: 0.9,
            effort: 0.85,
            status: WorkoutStatus.completed,
          ),
        ),
      );

      expect(bundle.analysis.summaryTitle, 'Training Stability Confirmed');
      expect(
        bundle.analysis.laneBias,
        anyOf(ZenithLaneBias.moderate, ZenithLaneBias.hard),
      );
      expect(bundle.analysis.focusBias, ZenithFocusBias.strength);
      expect(bundle.adjustment.durationDeltaMin, 5);
    });

    test('low hydration and volatility create caution', () {
      final bundle = engine.analyze(
        checkIns: [
          _checkIn(day: 1, energy: 6, water: 0.9, puffiness: 3),
          _checkIn(day: 2, energy: 6, water: 2.8, puffiness: 3),
          _checkIn(day: 3, energy: 5, water: 1.0, puffiness: 3),
          _checkIn(day: 4, energy: 5, water: 2.7, puffiness: 4),
        ],
        missionRecords: [
          _mission(day: 1, completion: 0.5, effort: 0.4, status: WorkoutStatus.aborted),
          _mission(day: 2, completion: 0.6, effort: 0.5, status: WorkoutStatus.completed),
        ],
      );

      expect(bundle.analysis.cautionFlags, isNotEmpty);
      expect(bundle.analysis.focusBias, anyOf(ZenithFocusBias.mixed, ZenithFocusBias.mobility));
      expect(bundle.analysis.laneBias, anyOf(ZenithLaneBias.light, ZenithLaneBias.recovery));
    });

    test('insufficient data stays low confidence and neutral', () {
      final bundle = engine.analyze(
        checkIns: [_checkIn(day: 1, energy: 6, water: 2.0, puffiness: 3)],
        missionRecords: const [],
      );

      expect(bundle.analysis.confidenceScore, lessThan(0.45));
      expect(bundle.analysis.laneBias, ZenithLaneBias.none);
      expect(bundle.analysis.summaryTitle, isNotEmpty);
    });
  });
}

DailyCheckIn _checkIn({
  required int day,
  required int energy,
  required double water,
  required int puffiness,
}) {
  return DailyCheckIn(
    energy: energy,
    sleepHours: 7,
    waterLiters: water,
    weightKg: 80,
    mood: Mood.good,
    puffiness: puffiness,
    disciplineChain: day,
    lastCheckIn: DateTime(2026, 3, day),
  );
}

DailyMissionRecord _mission({
  required int day,
  required double completion,
  required double effort,
  required WorkoutStatus status,
}) {
  return DailyMissionRecord(
    dateKey: '2026-03-${day.toString().padLeft(2, '0')}',
    checkInDone: true,
    xpAwarded: 0,
    completion: completion,
    plannedWorkoutSec: 1800,
    actualWorkoutSec: (1800 * effort).round(),
    workoutEffortRatio: effort,
    workoutStatus: status,
    lastWorkoutUpdateTs: 0,
    workoutLane: TrainingLane.moderate,
  );
}

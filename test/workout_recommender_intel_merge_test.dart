import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/readiness_result.dart';
import 'package:operation_jawline/models/zenith_adjustment.dart';
import 'package:operation_jawline/models/zenith_analysis_result.dart';
import 'package:operation_jawline/services/workout_recommender.dart';

void main() {
  group('WorkoutRecommender intel merge', () {
    final recommender = WorkoutRecommender();
    final checkIn = DailyCheckIn(
      energy: 7,
      sleepHours: 7.5,
      waterLiters: 2.2,
      weightKg: 80,
      mood: Mood.good,
      puffiness: 2,
      disciplineChain: 5,
      lastCheckIn: DateTime(2026, 3, 15),
    );

    test('recovery bias downgrades moderate readiness', () {
      const readiness = ReadinessResult(
        readinessScore: 60,
        lane: TrainingLane.moderate,
        focus: WorkoutFocus.strength,
        durationMinutes: 35,
        riskFlags: [],
      );
      const adjustment = ZenithAdjustment(
        laneOverrideSuggestion: ZenithLaneBias.recovery,
        laneNudge: -1,
        focusSuggestion: ZenithFocusBias.mobility,
        durationDeltaMin: -10,
        restrictHighIntensity: true,
        preferRecovery: true,
        rationale: ['Recovery pressure'],
      );

      final merged = recommender.mergeReadinessWithAdjustment(
        readiness: readiness,
        checkIn: checkIn,
        adjustment: adjustment,
      );

      expect(merged.lane, anyOf(TrainingLane.light, TrainingLane.recovery));
      expect(merged.durationMinutes, lessThanOrEqualTo(30));
    });

    test('positive stability can safely extend duration', () {
      const readiness = ReadinessResult(
        readinessScore: 65,
        lane: TrainingLane.moderate,
        focus: WorkoutFocus.strength,
        durationMinutes: 35,
        riskFlags: [],
      );
      const adjustment = ZenithAdjustment(
        laneOverrideSuggestion: ZenithLaneBias.moderate,
        laneNudge: 1,
        focusSuggestion: ZenithFocusBias.strength,
        durationDeltaMin: 5,
        restrictHighIntensity: false,
        preferRecovery: false,
        rationale: ['Stability confirmed'],
      );

      final merged = recommender.mergeReadinessWithAdjustment(
        readiness: readiness,
        checkIn: checkIn,
        adjustment: adjustment,
      );

      expect(merged.durationMinutes, 40);
      expect(merged.lane, anyOf(TrainingLane.moderate, TrainingLane.hard));
    });

    test('fatigue risk blocks hard lane', () {
      final fatiguedCheckIn = checkIn.copyWith(energy: 8, sleepHours: 7.5);
      const readiness = ReadinessResult(
        readinessScore: 82,
        lane: TrainingLane.hard,
        focus: WorkoutFocus.mixed,
        durationMinutes: 45,
        riskFlags: [],
      );
      const adjustment = ZenithAdjustment(
        laneOverrideSuggestion: ZenithLaneBias.recovery,
        laneNudge: -1,
        focusSuggestion: ZenithFocusBias.mobility,
        durationDeltaMin: -10,
        restrictHighIntensity: true,
        preferRecovery: true,
        rationale: ['Fatigue risk'],
      );

      final merged = recommender.mergeReadinessWithAdjustment(
        readiness: readiness,
        checkIn: fatiguedCheckIn,
        adjustment: adjustment,
      );

      expect(merged.lane, isNot(TrainingLane.hard));
      expect(merged.riskFlags, isNotEmpty);
    });
  });
}
